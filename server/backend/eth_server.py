import time
import numpy as np

from frame_processing.process_frame import process_frame
from modules.ethernet.sockets import UdpSocketClient, TcpSocketClient
from modules.globals import *

def process_data(data:bytes):
    transformation = data[-len(TRANSFORMATION_OPTIONS["identity"]):]
    image = data[:-len(TRANSFORMATION_OPTIONS["identity"])]

    return image,transformation

def listen():
    print("listening....")

    if USE_TCP:
        conn = TcpSocketClient(('', PORT))
        print(f"using tcp, listening {conn.address}")
    else:
        print("using udp")
        conn = UdpSocketClient(True)

    with conn.client:

        if (not USE_TCP):
            conn.client.bind(('', PORT))

        while True:
            # receive image
            time.sleep(1)
            data, address = conn.receive_bytes(UDP_DATAGRAM_TO_PROCESS_SIZE)

            if (len(data) != UDP_DATAGRAM_TO_PROCESS_SIZE):
                continue

            img_bytes, transformation = process_data(data)

            # process image
            img = np.frombuffer(img_bytes, dtype=np.uint8).reshape(ETH_RESOLUTION_PADDED)
            print(f"received: {img.shape}")
            
            if (transformation == TRANSFORMATION_OPTIONS["edges"]):
                kernel = "edges"
            elif (transformation == TRANSFORMATION_OPTIONS["gaussian_blur"]):
                kernel = "gaussian_blur"
            elif (transformation == TRANSFORMATION_OPTIONS["sharpen"]):
                kernel = "sharpen"
            else:
                kernel = "identity"
        
            new_img = process_frame(img, kernel)
            print(f"processed_frame: {new_img.shape}")

            data = new_img.tobytes() + transformation
            
            # send image to socket
            conn.send_bytes(data, address)

while(True):
    try:
        listen()
    except Exception as e:
        print(e)

