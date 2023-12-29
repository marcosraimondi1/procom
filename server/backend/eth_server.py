import numpy as np

from modules.transformations import edgeDetection, rotate
from modules.sockets import UdpSocketClient, TcpSocketClient
from modules.globals import *

def process_data(data:bytes):
    transformation = data[-len(TRANSFORMATION_OPTIONS["none"]):]
    image = data[:-len(TRANSFORMATION_OPTIONS["none"])]
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
                new_img = edgeDetection(img)
            elif (transformation == TRANSFORMATION_OPTIONS["rotate"]):
                new_img = rotate(img)
            else:
                new_img = img

            data = new_img.tobytes() + transformation
            
            # send image to socket
            conn.send_bytes(data, address)

while(True):
    try:
        listen()
    except Exception as e:
        print(e)

