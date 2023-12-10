import numpy as np

from modules.transformations import edgeDetection, rotate
from modules.globals import RESOLUTION, PORT, TRANSFORMATION_OPTIONS, USE_TCP, FRAME_SIZE
from modules.sockets import UdpSocketClient, TcpSocketClient

def listen():
    print("listening....")

    if USE_TCP:
        conn = TcpSocketClient(('', PORT))
        print(f"listening {conn.address}")
    else:
        conn = UdpSocketClient()

    with conn.client:

        if (not USE_TCP):
            conn.client.bind(('', PORT))

        while True:
            # receive image
            data, address = conn.receive_bytes(FRAME_SIZE)

            if (len(data) != FRAME_SIZE):
                continue

            transformation = data[-2:]

            # process image
            img = np.frombuffer(data[:-2], dtype=np.uint8).reshape(RESOLUTION)
            if (transformation == TRANSFORMATION_OPTIONS["edges"]):
                new_img = edgeDetection(img)
            elif (transformation == TRANSFORMATION_OPTIONS["rotate"]):
                new_img = rotate(img)
            else:
                new_img = img

            data = new_img.tobytes()
            
            # send image to socket
            conn.send_bytes(data, address)

while(True):
    try:
        listen()
    except Exception as e:
        print(e)

