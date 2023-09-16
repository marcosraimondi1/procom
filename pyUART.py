import time
import serial

"""
El usuario debe:
    1. Encender/Apagar los leds (0,1,2,3) indicando el color que desea prender
    cada led. R,G,B
    2. Leer el estado de los switch
"""
DEBUG = False


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

    print("Comandos:")
    print("\t- toggle")
    print("\t- leer")
    print("\t- exit")

    while 1:
        inputData = input("cmd << ")
        inputData = inputData.split(" ")

        opt = inputData[0]

        if opt == 'exit':
            ser.close()
            exit()

        elif opt == 'leer':

            print("Wait Input Data")

            op_code = 3

            nBytes = 1

            data = op_code

            ser.write(encapsular(data, nBytes).encode())

            time.sleep(2)

            readData = ser.read(1)

            out = str(int.from_bytes(readData, byteorder='big'))

            if out != '':
                print(">> "+out)
            print("\n")
        elif opt == 'toggle':
            led = int(input("led = ")) % 4
            rgb = input("r g b = ").split()

            if (len(rgb) != 3):
                print("failed rgb pattern\n")
                continue

            r = int(rgb[0]) % 256
            g = int(rgb[1]) % 256
            b = int(rgb[2]) % 256

            op_code = 1

            # nBytes = 5
            # byte 4 = op_code
            # byte 3 = led
            # byte <2:0> = rgb

            data = (op_code << (8*4)) + (led << (8*3)) + \
                (r << (8*2)) + (g << 8) + b

            nBytes = 5
            trama = encapsular(data, nBytes)
            ser.write(trama.encode())
            time.sleep(1)
            print("\n")
        else:
            print("Operacion no admitida\n")


def encapsular(data, nBytes):
    """
    Crea un string con bytes codificados en ascii.
    Encapsula los datos en una trama.
    """
    if nBytes > 16:
        # requiere trama larga
        raise Exception("Trama Size too big!")

    cabecera = chr(0xA0+nBytes)
    unused3 = "000"  # sizeH, sizeL, Device
    data_s = ""

    for i in range(nBytes):
        # numero a string codificado en ascii
        data_s += chr((data >> (8*(nBytes-i-1))) & 0x0F)

    end = chr(0x40+nBytes)

    trama = cabecera+unused3+data_s+end

    return trama


def main():
    launch_app()


if __name__ == "__main__":
    main()
