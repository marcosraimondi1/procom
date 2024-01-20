import numpy as np
import time
from typing import Tuple

# multiprocessing
import multiprocessing as mp
from multiprocessing import Process

# custom modules
from modules.globals import *
from modules.transformations import *
from modules.ethernet.sockets import UdpSocketClient, TcpSocketClient
from modules.video_proccessing import addTimeStamp

def process_data(data:bytes)->Tuple:
    transformation = data[-len(TRANSFORMATION_OPTIONS["identity"]):]
    image = data[:-len(TRANSFORMATION_OPTIONS["identity"])]
    return image,transformation

def get_connection(use_tcp):
    if (use_tcp):
        print("using TCP")
        conn = TcpSocketClient((HOST,PORT))
    else:
        print("using UDP")
        conn = UdpSocketClient(True)
        conn.client.bind(('',PORT)) # comment this line if running eth_process.py on the same machine as the server

    return conn

def wait_new_frame():
    while(NEW_FRAME.read_bytes() == b'0'):
        time.sleep(0.01)
    NEW_FRAME.write_bytes(b'0')

def isValidData(data):
    return (len(data) == FRAME_SIZE)

def receive_frames(conn):
    print("Receive process started ...")
    while (True):
        # get image from socket
        data, _ = conn.receive_bytes(FRAME_SIZE)

        if not isValidData(data):
            continue

        img_bytes, transformation = process_data(data)

        # resize image
        img = np.frombuffer(img_bytes, dtype=np.uint8).reshape(ETH_RESOLUTION)
        new_img = cv2.resize(img, (RESOLUTION[1], RESOLUTION[0]))

        if (transformation == TRANSFORMATION_OPTIONS["identity"]):
            new_img = addTimeStamp("2. eth recv ", new_img, (50,75), 0.7)

        # send processed image
        PROCESSED_BUFFER.write_array(new_img)

def send_frames(conn):
    NEW_FRAME.write_bytes(b'0')
    print("Send process started ...")

    while (True):
        wait_new_frame()
        # get image to process
        img = BUFFER_TO_PROCESS.read_array(RESOLUTION)

        # get type of transformation
        transformation = TRANSFORMATION.read_bytes()

        if (transformation == TRANSFORMATION_OPTIONS["identity"]):
            img = addTimeStamp("1. eth send ", img, (50,50), 0.7)

        # resize img
        resized_img = cv2.resize(img, (ETH_RESOLUTION[1], ETH_RESOLUTION[0]))

        to_send_bytes = resized_img.tobytes() + transformation

        # send image to socket
        conn.send_bytes(to_send_bytes, (HOST,PORT))

def startEthInterface():
    """Starts the ethernet daemon processes (send and receive frames)"""
    conn = get_connection(USE_TCP)
    
    mp.set_start_method('fork')

    send_process = Process(target=send_frames, args=(conn,), daemon=True)

    receive_process = Process(target=receive_frames, args=(conn,), daemon=True)

    receive_process.start()
    send_process.start()
