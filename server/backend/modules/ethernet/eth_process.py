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
        conn = UdpSocketClient()
        if HOST not in ['', '127.0.0.1', '0.0.0.0']:
            conn.client.bind(('',PORT))

    return conn

prep_image_bytes = bytes()

def send_frames(conn:SocketClient)->None:
    NEW_FRAME.write_bytes(b'0')
    print("Send process started ...")

    while (True):
        wait_new_frame(SEND_DELAY_S)

        # get image to process
        img = BUFFER_TO_PROCESS.read_array(RESOLUTION)

        # pre process frame
        preprocessed_bytes = preprocess(img, RESOLUTION, CUT_SIZE, ETH_RESOLUTION)

        # metadata
        # get type of transformation
        transformation = TRANSFORMATION.read_bytes()

        # add timestamp
        timestamp = int(time.time() * 1000)
        timestamp_bytes = struct.pack('Q', timestamp)

        # make metadata multiple of 4
        meta_size = len(timestamp_bytes)+len(transformation)
        zeros = np.zeros(METADATA_SIZE-meta_size, dtype=np.uint8)
        metadata_bytes = transformation + timestamp_bytes + zeros.tobytes();
        to_send_bytes =  metadata_bytes + preprocessed_bytes

        # send image to socket
        conn.send_bytes(to_send_bytes, (HOST,PORT))

def wait_new_frame(delay_s:float)->None:
    wait_start = time.time()
    while(NEW_FRAME.read_bytes() == b'0'):
        time.sleep(0.01)
    NEW_FRAME.write_bytes(b'0')

    now = time.time()
    while (now - wait_start) < delay_s:
        now = time.time()

def preprocess(img:np.ndarray, full_resolution:Tuple, cut_size:int, send_resolution:Tuple)->bytes:
    # cut image
    start_x = full_resolution[0]//2 - cut_size//2
    start_y = full_resolution[1]//2 - cut_size//2
    img = img[start_x:start_x+cut_size, start_y:start_y+cut_size]

    # resize img
    resized_img = cv2.resize(img, (send_resolution[1]-2, send_resolution[0]-2)) # -2 for padding

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

        img_bytes, metadata = process_data(data, ETH_RESOLUTION)

        _, sent_timestamp = process_metadata(metadata)

        new_img = postprocess(img_bytes, RESOLUTION, CUT_SIZE, ETH_RESOLUTION)

        recv_timestamp = int(time.time() * 1000)
        new_img = addText(new_img, f"processing time: {recv_timestamp-sent_timestamp} ms", (20,75), 1)

        # send processed image
        PROCESSED_BUFFER.write_array(new_img)

def process_data(data:bytes, resolution:Tuple)->Tuple:
    image_size = resolution[0]*resolution[1]
    split_indx = len(data) - image_size
    image = data[split_indx:]
    metadata = data[:split_indx]

    return image,metadata

def process_metadata(metadata:bytes)->Tuple:

    transformation = metadata[0:len(TRANSFORMATION_OPTIONS["identity"])]
    timestamp_bytes = metadata[len(TRANSFORMATION_OPTIONS["identity"]):len(TRANSFORMATION_OPTIONS["identity"])+TIMESTAMP_SIZE]

    timestamp = struct.unpack('Q', timestamp_bytes)[0]

    return transformation, timestamp

def postprocess(img_bytes:bytes, full_resolution:Tuple, cut_size:int, received_resolution:Tuple)->np.ndarray:
    img = reorder_pixels(img_bytes, received_resolution)

    cleaned_img = img[2:][2:] # remove invalid pixels from padded convolution

    # first resize with interpolation
    new_img = cv2.resize(cleaned_img, (cut_size, cut_size))


    # now resize to resolution, centering the image and completing with zeros
    start_x = full_resolution[0]//2 - cut_size//2
    start_y = full_resolution[1]//2 - cut_size//2

    uncut = np.zeros((full_resolution[0], full_resolution[1]), dtype=np.uint8)
    uncut[start_x:start_x+cut_size, start_y:start_y+cut_size] = new_img

    return uncut

def reorder_pixels(img_bytes:bytes, resolution:Tuple)->np.ndarray:
    """
    UNORDERED:
     0  1  2  3  8  9  10 11 16 17 18 19 24 25 26 27 32 33 34 35 40 41 42 43 48 49 50 51 56 57 58 59 4  5  6  7  12 13 14 15 20 21 22 23 28 29 30 31 36 37 38 39 44 45 46 47 52 53 54 55 60 61 62 63

    ORDERED:
     0  1  2  3  4  5  6  7
     8  9  10 11 12 13 14 15
     16 17 18 19 20 21 22 23
     24 25 26 27 28 29 30 31
     32 33 34 35 36 37 38 39
     40 41 42 43 44 45 46 47
     48 49 50 51 52 53 54 55
     56 57 58 59 60 61 62 63
    """
    pixels = np.frombuffer(img_bytes, dtype=np.uint8)
    img = np.zeros(resolution, dtype=np.uint8)
    row = 0
    col = 0
    for i in range(0, len(img_bytes), 4):
        img[row][col:col+4] = pixels[i:i+4]
        row += 1
        if row == resolution[0]:
            row = 0
            col += 4
            if col >= resolution[1]:
                break

    return img

def addText(img:np.ndarray, text:Text, position:Tuple, scale:float)->np.ndarray:
    font = cv2.FONT_HERSHEY_SIMPLEX
    font_thickness = 2
    font_color = (255, 255, 255)
    cv2.putText(img, text, position, font, scale, font_color, font_thickness)
    return img
