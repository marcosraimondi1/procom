import numpy as np

from process_frame import process_frame
from modules.sockets import UdpSocketClient, TcpSocketClient
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
            data, address = conn.receive_bytes(FRAME_SIZE)

            if (len(data) != FRAME_SIZE):
                continue

            img_bytes, transformation = process_data(data)

            # process image
            img = np.frombuffer(img_bytes, dtype=np.uint8).reshape(ETH_RESOLUTION)

            if (transformation == TRANSFORMATION_OPTIONS["edges"]):
                kernel = "edges"
            elif (transformation == TRANSFORMATION_OPTIONS["gaussian_blur"]):
                kernel = "gaussian_blur"
            elif (transformation == TRANSFORMATION_OPTIONS["sharpen"]):
                kernel = "sharpen"
            else:
                kernel = "identity"
        
            new_img = process_frame(img, kernel)

            data = new_img.tobytes() + transformation
            
            # send image to socket
            conn.send_bytes(data, address)

while(True):
    try:
        listen()
    except Exception as e:
        print(e)

