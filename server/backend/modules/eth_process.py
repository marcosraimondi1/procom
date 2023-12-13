import numpy as np
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

        samples = 0
        sum = 0
        while (True):

            while(NEW_FRAME.read_bytes() == b'0'):
                time.sleep(0.01)

            NEW_FRAME.write_bytes(b'0')

            # get image to process
            img = BUFFER_TO_PROCESS.read_array(RESOLUTION)

            # get type of transformation
            transformation = TRANSFORMATION.read_bytes()

            # resize img
            resized_img = cv2.resize(img, (200, 200))

            # send image to socket
            to_send_bytes = resized_img.tobytes() + transformation
            conn.send_bytes(to_send_bytes, (HOST,PORT))

            # get image from socket
            data, _ = conn.receive_bytes(len(to_send_bytes))

            if (len(data) != len(to_send_bytes)):
                continue

            img_bytes, _ = process_data(data)
            img = np.frombuffer(img_bytes, dtype=np.uint8).reshape((200,200))
            new_img = cv2.resize(img, (640, 480))

            # send processed image
            PROCESSED_BUFFER.write_array(new_img)


            fps = 1/(time.time()-last)
            last = time.time()

            samples += 1
            if (samples == 1000):
                sum = 0
                samples = 1
            sum += fps
            print(f"FPS {sum/samples}", end='\r')
