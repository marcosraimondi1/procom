# custom modules
from typing import Tuple
from modules.globals import *
from modules.transformations import *
from modules.sockets import UdpSocketClient, TcpSocketClient

def process_data(data:bytes)->Tuple:
    transformation = data[-len(TRANSFORMATION_OPTIONS["none"]):]
    image = data[:-len(TRANSFORMATION_OPTIONS["none"])]
    return image,transformation

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
            data, _ = conn.receive_bytes(FRAME_SIZE)

            if (len(data) != FRAME_SIZE):
                continue

            img, _ = process_data(data)

            # send processed image
            PROCESSED_BUFFER.write_bytes(img)
