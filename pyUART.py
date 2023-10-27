import time
import serial
"""
El usuario debe:
    1. Encender/Apagar los leds (0,1,2,3) indicando el color que desea prender
    cada led. R,G,B
    2. Leer el estado de los switch
"""
DEBUG = False
INICIO_DE_TRAMA = 0xA0
FIN_DE_TRAMA = 0x40
SER_TIMEOUT = 1000000
COMANDOS = {
    "RESET"     :  1    ,
    "EN_TX"     :  2    ,
    "EN_RX"     :  3    ,
    "PH_SEL"    :  4    ,
    "RUN_MEM"   :  5    ,
    "RD_MEM"    :  6    ,
    "IS_FULL"   :  7    ,
    "BER_S_I"   :  8    ,
    "BER_S_Q"   :  9    ,
    "BER_E_I"   :  10   ,
    "BER_E_Q"   :  11
}

def launch_app():
    ser = init_serial()
    ser.flushInput()
    ser.flushOutput()

    print("Comandos:")
    print("\t- exit")
    print("\t- reset")
    print("\t- phase <0-3>")
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
            start_cmd(ser, enable)
            continue

        if opt == 'read':
            read_cmd(ser)
            continue
        
        if opt == 'reset':
            reset_cmd(ser)
            continue

        if opt == 'phase':
            if len(inputData) < 2:
                print("Falta parametro")
                continue
            phase = int(inputData[1]) & 3
            phase_cmd(ser, phase)
            continue

        if int(opt) not in COMANDOS.values():
            print("Comando no valido")
            print("Comandos: ", COMANDOS)
            continue

        # ENVIAR COMANDO INDIVIDUAL
        op_code = int(opt)
        params = 0

        if len(inputData) > 1:
            params = int(inputData[1]) & 0x007FFFFF
        send_single_cmd(ser, op_code, params)

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

def wait_for_trama(ser, timeout):
    """
    Espera hasta que llegue una trama.
    Devuelve True si se acabo el tiempo.
    """
    count = 0
    while ser.inWaiting() == 0:
        count += 1
        if count == timeout:
            return True
        continue
    return False

def send_command(ser, command, data):
    """
    Envia un comando al microcontrolador.
    """
    data = (command << (8*3)) + data
    ser.write(encapsular(data, 4).encode())

def start_cmd(ser, enable):
    # enable/disable tx
    send_command(ser, COMANDOS["EN_TX"], enable)
    wait_for_trama(ser, SER_TIMEOUT)
    ser.flushInput()

    # enable/disable rx
    send_command(ser, COMANDOS["EN_RX"], enable)
    wait_for_trama(ser, SER_TIMEOUT)
    ser.flushInput()

def read_cmd(ser):
    # save to memory
    send_command(ser, COMANDOS["RUN_MEM"], 0)
    wait_for_trama(ser, SER_TIMEOUT)
    ser.flushInput()

    # read if full
    send_command(ser, COMANDOS["IS_FULL"], 0)
    if wait_for_trama(ser, SER_TIMEOUT):
        print("Time out!")
        ser.flushInput()
        return

    try:
        received_data = read_trama(ser)  # leo la trama
    except Exception as e:
        print(e)
        return

    is_full = int.from_bytes(received_data, byteorder='big')
    if is_full == 0:
        print("Memoria no llena")
        return

    # read memory and save to file
    print("Leyendo memoria...")
    f = open("./data.txt", "w+")
    for i in range(1024):
        send_command(ser, COMANDOS["RD_MEM"], i)
        wait_for_trama(ser, SER_TIMEOUT)
        try:
            received_data = read_trama(ser)  # leo la trama
        except Exception as e:
            print(e)
            break
        out = str(int.from_bytes(received_data, byteorder='big'))
        print(str(i)+" "+out)
        f.write(out)
        f.write(",")
    f.close()

def phase_cmd(ser, phase):
    send_command(ser, COMANDOS["PH_SEL"], phase)
    wait_for_trama(ser, SER_TIMEOUT)
    ser.flushInput()

def reset_cmd(ser):
    send_command(ser, COMANDOS["RESET"], 1)
    wait_for_trama(ser, SER_TIMEOUT)
    ser.flushInput()
    
    send_command(ser, COMANDOS["RESET"], 0)
    wait_for_trama(ser, SER_TIMEOUT)
    ser.flushInput()

def send_single_cmd(ser, op_code, params):
    # <31:24> = op_code
    # 23 = enable // no se usa en python
    # <22:0> = data

    send_command(ser, op_code, params)

    if wait_for_trama(ser, SER_TIMEOUT):
        print("Time out!")
        ser.flushInput()
        return

    try:
        received_data = read_trama(ser)  # leo la trama
    except Exception as e:
        print(e)
        return

    out = str(int.from_bytes(received_data, byteorder='big'))

    if out != '':
        print(">> "+out)
    print("\n")

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

def main():
    launch_app()

if __name__ == "__main__":
    main()
