# custom modules
from modules.globals import *
from modules.transformations import *
from modules.sockets import UdpSocketClient, TcpSocketClient


def ethInterface():
    print("Subprocess Started ...")

    if (USE_TCP):
        conn = TcpSocketClient((HOST,PORT))
    else:
        conn = UdpSocketClient()

    with conn.client:

        while (True):
            # get image to process
            img = BUFFER_TO_PROCESS.read_bytes()

            # get type of transformation
            transformation = TRANSFORMATION.read_bytes()

            # send image to socket
            conn.send_bytes(img+transformation, (HOST,PORT))

            # get image from socket
            img, _ = conn.receive_bytes(FRAME_SIZE-len(TRANSFORMATION_OPTIONS["none"]))

            if (len(img) != FRAME_SIZE-len(TRANSFORMATION_OPTIONS["none"])):
                continue

            # send processed image
            PROCESSED_BUFFER.write_bytes(img)
