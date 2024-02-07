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
    "identity": bytearray([0,0]),
    "edges": bytearray([0,1]),
    "gaussian_blur": bytearray([1,0]),
    "sharpen": bytearray([1,1]),
}

# socket connection to processing server (FPGA)
HOST = '127.0.0.1' # '172.16.0.231' # '192.168.100.64' #'0.0.0.0' # '192.168.100.35' ip of video processing server
PORT = 3001
USE_TCP = False

# data flow control
SEND_DELAY_S = 0.03
ETH_RESOLUTION = (200,200) # tiene que ser multiplo de 4
CUT_SIZE = 480

TIMESTAMP_SIZE = 8
UDP_DATAGRAM_TO_PROCESS_SIZE = ETH_RESOLUTION[0]*ETH_RESOLUTION[1] +  len(TRANSFORMATION_OPTIONS["identity"]) + TIMESTAMP_SIZE
