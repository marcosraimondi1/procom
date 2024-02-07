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
        conn = UdpSocketClient()
        conn.client.bind(('', PORT))

    with conn.client:

        while True:
            # receive image
            data, address = conn.receive_bytes(UDP_DATAGRAM_TO_PROCESS_SIZE)

            if (len(data) != UDP_DATAGRAM_TO_PROCESS_SIZE):
                continue

            # send image to socket
            conn.send_bytes(data, address)

while(True):
    try:
        listen()
    except Exception as e:
        print(e)

