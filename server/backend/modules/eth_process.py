# custom modules
from modules.globals import MEM_1, MEM_2, HOST, PORT, RESOLUTION, USE_TCP
from modules.transformations import *
from modules.sockets import UdpSocketClient, TcpSocketClient

IMG_SIZE = RESOLUTION[0]*RESOLUTION[1]

def ethInterface():
    print("Subprocess Started ...")

    if (USE_TCP):
        conn = TcpSocketClient((HOST,PORT))
    else:
        conn = UdpSocketClient()

    with conn.client:

        while (True):
            # get image to process
            img = MEM_2.read_bytes()

            # send image to socket
            conn.send_bytes(img, (HOST,PORT))

            # get image from socket
            img, _ = conn.receive_bytes(IMG_SIZE)

            if (len(img) != IMG_SIZE):
                continue

            # send processed image
            MEM_1.write_bytes(img)
