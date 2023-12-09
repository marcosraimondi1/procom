import numpy as np

from modules.transformations import edgeDetection
from modules.globals import RESOLUTION, PORT
from modules.eth_process import UdpSocketClient

IMG_SIZE = RESOLUTION[0]*RESOLUTION[1]

def listen():
    udp = UdpSocketClient()

    with udp.client:
        print("listening....")
        udp.client.bind(('', PORT))

        while True:
            # receive image
            bytes, address = udp.receive_bytes(IMG_SIZE)

            if (len(bytes) != IMG_SIZE):
                continue

            # process image
            # img = np.frombuffer(bytes, dtype=np.uint8).reshape(RESOLUTION)
            # new_img = edgeDetection(img)
            # bytes = new_img.tobytes()
            
            # send image to socket
            udp.send_bytes(bytes, address)

while(True):
    try:
        listen()
    except Exception as e:
        print(e)

