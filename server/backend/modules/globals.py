from modules.ipc import SharedMemory

# image constants
RESOLUTION = (480, 640)
IMG_SIZE = RESOLUTION[0]*RESOLUTION[1]

# ipc constants
KEY1 = "MEM1"
KEY2 = "MEM2"
KEY3 = "MEM3"
PROCESSED_BUFFER = SharedMemory(KEY1, IMG_SIZE)
BUFFER_TO_PROCESS = SharedMemory(KEY2, IMG_SIZE)

TRANSFORMATION = SharedMemory(KEY3, 2) 
TRANSFORMATION_OPTIONS = {
    "none": b'00',
    "edges": b'01',
    "rotate": b'10'
}

# socket
HOST = '0.0.0.0' # ip of video processing server
PORT = 3001
FRAME_SIZE = IMG_SIZE + len(TRANSFORMATION_OPTIONS["none"])
USE_TCP = True
