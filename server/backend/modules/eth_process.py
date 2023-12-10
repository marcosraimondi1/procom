import time
from typing import Tuple

# custom modules
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
        print("using TCP")
        conn = TcpSocketClient((HOST,PORT))
    else:
        print("using UDP")
        conn = UdpSocketClient()

    with conn.client:
        last = 0

        while (True):

            while(NEW_FRAME.read_bytes() == b'0'):
                time.sleep(0.01)


            NEW_FRAME.write_bytes(b'0')

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

            fps = 1/(time.time()-last)
            last = time.time()
            print(f"FPS {fps}", end='\r')
