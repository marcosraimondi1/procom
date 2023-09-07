import serial
import sys
import os

sys.path.insert(0, "./modules")  # Insert the path of modules folder
import calculadora
import graficadora


def init_serial():
    ser = serial.serial_for_url(
        "loop://", timeout=1
    )  # abre el puerto serie con loopback
    ser.timeout = None
    ser.flushInput()  # limpia buffer de entrada
    ser.flushOutput()  # limpia buffer de salida
    return ser


def ejercicio_a_b():
    ser = init_serial()
    while True:
        print("Ingrese comando y presione Enter\n")
        print("Operaciones Admitidas\n")
        print("\t- Calculadora o\t'1'\n")
        print("\t- Graficar o\t'2'\n")
        print("\t- exit \t(exit)")

        operacion = input("Operacion: ").lower()

        ser.write(operacion.encode())

        # recibir datos
        received_op = ""  # operacion recibida

        while ser.inWaiting() > 0:
            # leo de a un byte todos los bytes que estan en el buffer
            read_data = ser.read(1)
            received_op += read_data.decode()

        if received_op != "":
            print(">> " + received_op)

        if received_op not in ["1", "2", "calculadora", "graficar", "exit"]:
            os.system("cls")
            print("Operacion no admitida")
            continue

        if received_op == "1" or received_op == "calculadora":
            print("Ejecutando Calculadora....")
            calculadora.main()

        elif received_op == "2" or received_op == "graficar":
            print("Ejecutando Graficadora....")
            graficadora.main()

        elif received_op == "exit":
            # cerrar puerto y salir
            if ser.isOpen():
                ser.close()
            break

        os.system("cls")


INICIO_DE_TRAMA = 0xA0  # 10100000
FIN_DE_TRAMA = 0x40  # 01000000


def armar_trama(data):
    # recibe datos a enviar en una lista de caracteres
    # retorna una trama lista para enviar
    # ej: b'\xa8\x00\x00\x00graficar\x48'

    if len(data) > 16:
        # requiere trama larga
        return

    size = len(data)

    # primer byte
    trama = (INICIO_DE_TRAMA + size).to_bytes(1)

    # 3 bytes mas
    trama += b"\x00"  # L.size(High)
    trama += b"\x00"  # L.size(Low)
    trama += b"\x00"  # Device

    # bytes de datos
    for char in data:
        trama += char.encode()

    # ultimo byte
    trama += (FIN_DE_TRAMA + size).to_bytes(1)

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
    received_data = ser.read(size)

    # verificar fin de trama
    byte = ser.read(1)[0]

    if byte != (FIN_DE_TRAMA + size):
        ser.flushInput()
        raise Exception("ERROR: fin de trama incorrecto")

    return received_data


def ejercicio_c():
    ser = init_serial()
    while True:
        print("Ingrese comando y presione Enter\n")
        print("Operaciones Admitidas\n")
        print("\t- Calculadora \n")
        print("\t- Graficar\n")
        print("\t- exit ")

        operacion = input("Operacion: ").lower()

        trama = armar_trama([*operacion])

        print("TRAMA: ", trama)

        # enviar operacion
        ser.write(trama)

        # recibir datos
        received_data = ""

        if ser.inWaiting() > 0:  # leo una sola trama asique no uso while
            try:
                received_data = read_trama(ser)  # leo la trama
            except Exception as e:
                print(e)
                continue

        received_op = received_data.decode()

        if received_op != "":
            print(">> " + received_op)

        if received_op not in ["calculadora", "graficar", "exit"]:
            # os.system("cls")
            print("Operacion no admitida")
            continue

        if received_op == "calculadora":
            print("Ejecutando Calculadora....")
            calculadora.main()

        elif received_op == "graficar":
            print("Ejecutando Graficadora....")
            graficadora.main()

        elif received_op == "exit":
            # cerrar puerto y salir
            if ser.isOpen():
                ser.close()
            break

        # os.system("cls")


def main():
    ejercicio_c()


if __name__ == "__main__":
    main()
