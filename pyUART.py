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

    while 1:
        print("Comandos:")
        print("\t- toggle <led> <red> <green> <blue>")
        print("\t- leer")
        print("\t- exit")
        print("led = 0-3")
        print("colores = 0-255\n")
        print('Ingrese un comando:\r')
        inputData = input("<< ")
        inputData = inputData.split(" ")

        opt = inputData[0]

        if opt == 'exit':
            ser.close()
            exit()

        elif opt == 'leer':

            print("Wait Input Data\n")

            ser.write(str('3').encode())

            time.sleep(2)

            readData = ser.read(1)

            out = str(int.from_bytes(readData, byteorder='big'))

            if out != '':
                print(">> "+out)

        elif opt == 'toggle':
            ser.write(input("led=").encode())
            time.sleep(1)
        else:
            print("Operacion no admitida\n")


def main():
    launch_app()


if __name__ == "__main__":
    main()
