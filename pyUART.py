import time
import serial
"""
El usuario debe:
    1. Encender/Apagar los leds (0,1,2,3) indicando el color que desea prender
    cada led. R,G,B
    2. Leer el estado de los switch
"""
DEBUG = False

# COMANDOS
RESET    = 1
EN_TX    = 2
EN_RX    = 3
PH_SEL   = 4
RUN_MEM  = 5
RD_MEM   = 6
IS_FULL  = 7
BER_S_I  = 8
BER_S_Q  = 9
BER_E_I  = 10
BER_E_Q  = 11
COMANDOS = {
    "RESET": RESET,
    "EN_TX": EN_TX,
    "EN_RX": EN_RX,
    "PH_SEL": PH_SEL,
    "RUN_MEM": RUN_MEM,
    "RD_MEM": RD_MEM,
    "IS_FULL": IS_FULL,
    "BER_S_I": BER_S_I,
    "BER_S_Q": BER_S_Q,
    "BER_E_I": BER_E_I,
    "BER_E_Q": BER_E_Q
    }

def init_serial():
    if (DEBUG):
        ser = serial.serial_for_url(
            "loop://", timeout=1
        )  # abre el puerto serie con loopback

    else:
        portUSB = input("Ingrese N° puerto USB: ")
        ser = serial.Serial(
            # Configurar con el puerto
            port='/dev/ttyUSB{}'.format(int(portUSB)),
            baudrate=115200,
            parity=serial.PARITY_NONE,
            stopbits=serial.STOPBITS_ONE,
            bytesize=serial.EIGHTBITS
        )

    ser.timeout = None
    return ser


def launch_app():

    ser = init_serial()
    ser.flushInput()
    ser.flushOutput()

    print("Comandos:")
    print("\t- exit")
    print("\t- start")
    print("\t- stop")
    print("\t- read")
    print("\t- <num comando> <data value>")
    print(COMANDOS)

    while 1:
        inputData = input("cmd << ")
        inputData = inputData.split(" ")

        opt = inputData[0].lower()

        if opt == 'exit':
            ser.close()
            exit()

        if opt == 'start' or opt == 'stop':
            enable = opt == 'start'

            # enable/disable tx
            data = (COMANDOS["EN_TX"] << (8*3)) + enable
            ser.write(encapsular(data, 4).encode())
            while ser.inWaiting() == 0:
                continue
            ser.flushInput()

            # enable/disable rx
            data = (COMANDOS["EN_RX"] << (8*3)) + enable
            ser.write(encapsular(data, 4).encode())
            while ser.inWaiting() == 0:
                continue
            ser.flushInput()

            continue

        if opt == 'read':
            # save to memory
            data = (COMANDOS["RUN_MEM"] << (8*3)) + 0
            ser.write(encapsular(data, 4).encode())
            while ser.inWaiting() == 0:
                continue
            ser.flushInput()

            # read if full
            data = (COMANDOS["IS_FULL"] << (8*3)) + 0
            ser.write(encapsular(data, 4).encode())
            while ser.inWaiting() == 0:
                continue
            try:
                received_data = read_trama(ser)  # leo la trama
                ser.flushInput()
                ser.flushOutput()
            except Exception as e:
                print(e)
                continue
            is_full = int.from_bytes(received_data, byteorder='big')
            if is_full == 0:
                print("Memoria no llena")
                continue

            # read memory
            f = open("./data.txt", "w+")
            for i in range(1024):
                data = (COMANDOS["RD_MEM"] << (8*3)) + i
                ser.write(encapsular(data, 4).encode())
                while ser.inWaiting() == 0:
                    continue
                try:
                    received_data = read_trama(ser)  # leo la trama
                    ser.flushInput()
                    ser.flushOutput()
                except Exception as e:
                    print(e)
                    break
                out = str(int.from_bytes(received_data, byteorder='big'))
                print(str(i)+" "+out)
                f.write(out)
                f.write(",")
            f.close()
            continue

        if int(opt) not in COMANDOS.values():
            print("Comando no valido")
            print("Comandos: ", COMANDOS)
            continue

        # ENVIAR COMANDO

        op_code = int(opt)
        nBytes = 4
        params = 0

        if len(inputData) > 1:
            params = int(inputData[1]) & 0x007FFFFF

        # <31:24> = op_code
        # 23 = enable // no se usa en python
        # <22:0> = data

        data = (op_code << (8*3)) + params

        ser.write(encapsular(data, nBytes).encode())

        # time.sleep(2)
        time_out = 1000000000000000000
        while ser.inWaiting() == 0:
            time_out -= 1
            if time_out == 0:
                print("Time out!")
                break
            continue

        if ser.inWaiting() > 0:  # leo una sola trama asique no uso while
            try:
                received_data = read_trama(ser)  # leo la trama
                ser.flushInput()
                ser.flushOutput()
            except Exception as e:
                print(e)
                continue
        else:
            print("No se recibio respuesta")
            continue

        out = str(int.from_bytes(received_data, byteorder='big'))

        if out != '':
            print(">> "+out)
        print("\n")


INICIO_DE_TRAMA = 0xA0
FIN_DE_TRAMA = 0x40
def encapsular(data, nBytes):
    """
    Crea un string con bytes codificados en ascii.
    Encapsula los datos en una trama.
    """
    if nBytes > 16:
        # requiere trama larga
        raise Exception("Trama Size too big!")

    cabecera = chr(INICIO_DE_TRAMA+nBytes)
    unused3 = "000"  # sizeH, sizeL, Device
    data_s = ""

    for i in range(nBytes):
        # numero a string codificado en ascii
        data_s += chr((data >> (8*(nBytes-i-1))) & 0x0F)

    end = chr(FIN_DE_TRAMA+nBytes)

    trama = cabecera+unused3+data_s+end

    return trama

def read_trama(ser):
    # lee una trama y retorna los datos recibidos
    # verifica que cumpla con la trama acordada, sino levanta excepcion
    # ej: b'\xa8\x00\x00\x00graficar\x48'

    # verificar inicio de trama
    byte = ser.read(1)[0]
    primeros4_bits = byte & 0xF0

    if primeros4_bits != INICIO_DE_TRAMA:
        ser.flushInput()
        raise Exception("ERROR: inicio de trama incorrecto")

    size = byte & 0x0F  # size = cantidad de bytes de datos que recibo

    ser.read(3)  # los tres bytes siguientes no se usan

    # read_data
    #print("reading ",size," bytes")
    received_data = ser.read(size)

    #print("finished reading ",size," bytes")

    # verificar fin de trama
    byte = ser.read(1)[0]

    if byte != (FIN_DE_TRAMA + size):
        ser.flushInput()
        raise Exception("ERROR: fin de trama incorrecto")

    #print("finished reading trama")
    return received_data

def main():
    launch_app()


if __name__ == "__main__":
    main()
