import struct
import numpy as np
import time
from typing import Text, Tuple

# multiprocessing
import multiprocessing as mp
from multiprocessing import Process

# custom modules
from modules.globals import *
from modules.transformations import *
from modules.ethernet.sockets import SocketClient, UdpSocketClient, TcpSocketClient

def startEthInterface()->None:
    """Starts the ethernet daemon processes (send and receive frames)"""
    conn = get_connection(USE_TCP)
    
    mp.set_start_method('fork')

    send_process = Process(target=send_frames, args=(conn,), daemon=True)

    receive_process = Process(target=receive_frames, args=(conn,), daemon=True)

    receive_process.start()
    send_process.start()


def get_connection(use_tcp:bool)->SocketClient:
    if (use_tcp):
        print("using TCP")
        conn = TcpSocketClient((HOST,PORT))
    else:
        print("using UDP")
        conn = UdpSocketClient(True)
        #conn.client.bind(('',PORT)) # comment this line if running eth_process.py on the same machine as the server

    return conn

prep_image_bytes = bytes()

def send_frames(conn:SocketClient)->None:
    NEW_FRAME.write_bytes(b'0')
    print("Send process started ...")

    while (True):
        wait_new_frame()
        # get image to process
        img = BUFFER_TO_PROCESS.read_array(RESOLUTION)

        # get type of transformation
        transformation = TRANSFORMATION.read_bytes()

        # pre process frame
        preprocessed_bytes = preprocess(img)

        timestamp = int(time.time() * 1000)
        timestamp_bytes = struct.pack('Q', timestamp)

        to_send_bytes =  transformation + timestamp_bytes + preprocessed_bytes

        # send image to socket
        conn.send_bytes(to_send_bytes, (HOST,PORT))

def wait_new_frame()->None:
    while(NEW_FRAME.read_bytes() == b'0'):
        time.sleep(0.01)
    NEW_FRAME.write_bytes(b'0')

def preprocess(img:np.ndarray)->bytes:
    # cut image
    start_x = RESOLUTION[0]//2 - CUT_SIZE//2
    start_y = RESOLUTION[1]//2 - CUT_SIZE//2
    img = img[start_x:start_x+CUT_SIZE, start_y:start_y+CUT_SIZE]

    # resize img
    resized_img = cv2.resize(img, (ETH_RESOLUTION[1], ETH_RESOLUTION[0]))

    # pad image
    padded_frame = np.pad(resized_img, pad_width=1, constant_values=0)
    padded_frame.astype(np.uint8)
                
    #  reorder pixels
    reordered_bytes = bytes()
    
    for i in range(0, padded_frame.shape[0], 4):
        reordered_bytes += padded_frame[:,i:i+4].tobytes()

    return reordered_bytes

def receive_frames(conn:SocketClient)->None:
    print("Receive process started ...")
    while (True):
        # get image from socket
        data, _ = conn.receive_bytes(UDP_DATAGRAM_TO_PROCESS_SIZE)

        if len(data) != UDP_DATAGRAM_TO_PROCESS_SIZE:
            continue

        img_bytes, _, timestamp_bytes = process_data(data)

        sent_timestamp = struct.unpack('Q', timestamp_bytes)[0]

        new_img = postprocess(img_bytes)

        recv_timestamp = int(time.time() * 1000)
        new_img = addText(new_img, f"processing time: {recv_timestamp-sent_timestamp} ms", (20,75), 1)

        # send processed image
        PROCESSED_BUFFER.write_array(new_img)

def process_data(data:bytes)->Tuple:
    idx = len(TRANSFORMATION_OPTIONS["identity"])
    transformation = data[0:idx]
    timestamp = data[idx:idx+TIMESTAMP_SIZE]
    image = data[idx+TIMESTAMP_SIZE:]
    return image,transformation,timestamp

def postprocess(img_bytes:bytes)->np.ndarray:
    reordered_bytes = bytes()

    for i in range(0, ETH_RESOLUTION_PADDED[1]):
        for j in range(i*4, len(img_bytes), 4*ETH_RESOLUTION_PADDED[1]):
            reordered_bytes += img_bytes[j:j+4]

    img = np.frombuffer(reordered_bytes, dtype=np.uint8).reshape(ETH_RESOLUTION_PADDED)

    new_img = cv2.resize(img, (CUT_SIZE, CUT_SIZE))

    start_x = RESOLUTION[0]//2 - CUT_SIZE//2
    start_y = RESOLUTION[1]//2 - CUT_SIZE//2

    uncut = np.zeros((RESOLUTION[0], RESOLUTION[1]), dtype=np.uint8)
    uncut[start_x:start_x+CUT_SIZE, start_y:start_y+CUT_SIZE] = new_img

    return uncut

def addText(img:np.ndarray, text:Text, position:Tuple, scale:float)->np.ndarray:
    font = cv2.FONT_HERSHEY_SIMPLEX
    font_thickness = 2
    font_color = (255, 255, 255)
    cv2.putText(img, text, position, font, scale, font_color, font_thickness)
    return img
