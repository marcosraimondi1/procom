from modules.ipc import SharedMemory

# image constants
RESOLUTION = (480, 640)
IMG_SIZE = RESOLUTION[0]*RESOLUTION[1]

# ipc constants
KEY1 = "MEM1"
KEY2 = "MEM2"
KEY3 = "MEM3"
KEY4 = "MEM4"
PROCESSED_BUFFER = SharedMemory(KEY1, IMG_SIZE)
BUFFER_TO_PROCESS = SharedMemory(KEY2, IMG_SIZE)
NEW_FRAME = SharedMemory(KEY4, 1) 

TRANSFORMATION = SharedMemory(KEY3, 2) 
TRANSFORMATION_OPTIONS = {
    "none": b'00',
    "edges": b'01',
    "rotate": b'10'
}

# socket
HOST = '0.0.0.0' # '192.168.100.35' ip of video processing server
PORT = 3001
ETH_RESOLUTION = (256, 192)
FRAME_SIZE = ETH_RESOLUTION[0]*ETH_RESOLUTION[1] + len(TRANSFORMATION_OPTIONS["none"])
USE_TCP = False
