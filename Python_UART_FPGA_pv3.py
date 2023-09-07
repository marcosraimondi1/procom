import time
import serial
import sys

portUSB = sys.argv[1]

ser = serial.Serial(
    port='/dev/ttyUSB{}'.format(int(portUSB)),	#Configurar con el puerto
    baudrate=115200,
    parity=serial.PARITY_NONE,
    stopbits=serial.STOPBITS_ONE,
    bytesize=serial.EIGHTBITS
)

ser.isOpen()
ser.timeout=None
print(ser.timeout)

print ('Ingrese un comando:[0,1,2,3]\r\n')

while 1 :
    inputData = input("<< ")	
    if str(inputData) == 'exit':
        ser.close()
        exit()
    elif(str(inputData) == '3'):
        print ("Wait Input Data")
        ser.write(str(inputData).encode())
        time.sleep(2)
        readData = ser.read(1)
        out = str(int.from_bytes(readData,byteorder='big'))
        print(ser.inWaiting())
        if out != '':
            print (">>" + out)
    else:
        ser.write(str(inputData).encode())
        time.sleep(1)
