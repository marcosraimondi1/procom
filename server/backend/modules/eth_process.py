import time
import numpy as np
import socket

# custom modules
from modules.globals import *
from modules.transformations import *
from modules.ipc import read_from_memory, write_to_memory

def ethInterface():
    if (SEM_1.value == 0):
        SEM_1.release()
    if (SEM_2.value == 0):
        SEM_2.release()

    # initialize memory to zeros
    zeros = np.zeros(RESOLUTION, dtype=np.uint8)
    with SEM_1:
        write_to_memory(MEM_1, zeros.tobytes())

    with SEM_2:
        write_to_memory(MEM_2, zeros.tobytes())

    print("Subprocess Started ...")

    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as client:

        isConnected = True
        try:
            client.connect((HOST, PORT))
        except Exception as e:
            isConnected = False
            print("Failed connecting")
            print(e)

        while (isConnected):
            # get image to process
            with SEM_2:
                bytes = read_from_memory(MEM_2)

            # send image to socket
            try:
                client.sendall(bytes)
            except Exception as e:
                print("Failed sending")
                print(e)
                break
            

            # get image from socket
            try:
                bytes = b''
                while len(bytes) < (RESOLUTION[0]*RESOLUTION[1]):
                    bytes += client.recv(RESOLUTION[0]*RESOLUTION[1]-len(bytes))
            except Exception as e:
                print("Failed receiving")
                print(e)
                break

            # send processed image
            with SEM_1:
                write_to_memory(MEM_1, bytes)

            time.sleep(.002)


