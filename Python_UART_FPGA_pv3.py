import time
import serial

"""
El usuario debe:
    1. Encender/Apagar los leds (0,1,2,3) indicando el color que desea prender
    cada led. R,G,B
    2. Leer el estado de los switch
"""


def init_serial():
    print("Ingrese N° puerto USB: ", end="")
    portUSB = input("Ingrese N° puerto USB: ")
    ser = serial.Serial(
        port='/dev/ttyUSB{}'.format(int(portUSB)),  # Configurar con el puerto
        baudrate=115200,
        parity=serial.PARITY_NONE,
        stopbits=serial.STOPBITS_ONE,
        bytesize=serial.EIGHTBITS
    )

    ser.isOpen()
    ser.timeout = None
    print(ser.timeout)
    return ser


def launch_app():

    ser = init_serial()

    while 1:
        print('Ingrese un comando:\r\n')
        print("Comandos: \n")
        print("\t- toggle <led> <red> <green> <blue>\n")
        print("\t- leer")
        print("\t- exit\n")
        print("led = 0-3\n")
        print("colores = 0-255\n")
        inputData = input("<< ")
        inputData = inputData.split(" ")

        opt = inputData[0]

        if opt == 'exit':
            ser.close()
            exit()

        elif opt == 'leer':

            print("Wait Input Data\n")

            op_code = 3
            # data<1:0> = op_code<1:0>
            data = op_code
            trama = armar_trama(data)

            # eviar trama
            ser.write(trama)

            time.sleep(2)

            while (ser.inWaiting() == 0):
                continue

            try:
                received_data = read_trama(ser)
            except Exception as e:
                print(e)
                continue

            out = str(int.from_bytes(received_data, byteorder='big'))
            print(ser.inWaiting())
            if out != '':
                print(">>" + out)

        elif opt == 'toggle':
            if len(inputData != 5):
                print("Missing Arguments for toggle")
                continue

            op_code = 1
            led = int(inputData[1]) % 4
            red = int(inputData[2]) % 256
            green = int(inputData[3]) % 256
            blue = int(inputData[4]) % 256

            # data<29:0> = op_code<29:28> + led<27:24> + red<23:16>
            # + green<15:8> + blue<7:0>
            data = op_code << 28 + led << 24 + red << 16 + green << 8 + blue

            # crear trama
            trama = armar_trama(data)

            # enviar trama
            ser.write(trama)
            time.sleep(1)
        else:
            print("Operacion no admitida\n")


INICIO_DE_TRAMA = 0xA0  # 10100000
FIN_DE_TRAMA = 0x40  # 01000000


def armar_trama(data):
    # recibe datos a enviar en binario
    # retorna una trama lista para enviar
    # ej: b'\xa8\x00\x00\x00\data\x48'
    # trama corta es hasta 15 bytes = 120 bits

    size = 0  # cantidad de bytes a transmitir
    aux = data

    while (aux != 0):
        size += 1
        aux = aux >> 8

    if size > 16:
        # requiere trama larga
        raise Exception("Trama Size too big!")

    # primer byte
    trama = (INICIO_DE_TRAMA + size).to_bytes(1)

    # 3 bytes mas
    trama += b"\x00"  # L.size(High)
    trama += b"\x00"  # L.size(Low)
    trama += b"\x00"  # Device

    # bytes de datos
    trama += data.to_bytes(size)

    # ultimo byte
    trama += (FIN_DE_TRAMA + size).to_bytes(1)

    return trama


def read_trama(ser):
    # lee una trama y retorna los datos recibidos
    # verifica que cumpla con la trama acordada, sino levanta excepcion
    # ej: b'\xa8\x00\x00\x00\data\x48'

    # verificar inicio de trama
    byte = ser.read(1)[0]
    primeros4_bits = byte & 0xF0

    if primeros4_bits != INICIO_DE_TRAMA:
        ser.flushInput()
        raise Exception("ERROR: inicio de trama incorrecto")

    size = byte & 0x0F  # size = cantidad de bytes de datos que recibo

    if (size == 0):
        # no se recibieroin datos o es trama larga
        return 0

    ser.read(3)  # los tres bytes siguientes no se usan

    # read_data
    received_data = ser.read(size)

    # verificar fin de trama
    byte = ser.read(1)[0]

    if byte != (FIN_DE_TRAMA + size):
        ser.flushInput()
        raise Exception("ERROR: fin de trama incorrecto")

    return received_data


def main():
    launch_app()


if __name__ == "__main__":
    main()
