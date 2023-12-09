import numpy as np

from modules.transformations import edgeDetection
from modules.globals import RESOLUTION, PORT, USE_TCP
from modules.sockets import UdpSocketClient, TcpSocketClient

IMG_SIZE = RESOLUTION[0]*RESOLUTION[1]

def listen():
    print("listening....")

    if USE_TCP:
        conn = TcpSocketClient(('', PORT))
    else:
        conn = UdpSocketClient()

    with conn.client:

        if (not USE_TCP):
            conn.client.bind(('', PORT))

        while True:
            # receive image
            data, address = conn.receive_bytes(IMG_SIZE)

            if (len(data) != IMG_SIZE):
                continue

            # process image
            # img = np.frombuffer(data, dtype=np.uint8).reshape(RESOLUTION)
            # new_img = edgeDetection(img)
            # data = new_img.tobytes()
            
            # send image to socket
            conn.send_bytes(data, address)

while(True):
    try:
        listen()
    except Exception as e:
        print(e)

