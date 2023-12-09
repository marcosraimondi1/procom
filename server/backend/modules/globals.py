from modules.ipc import SharedMemory

# image constants
RESOLUTION = (480, 640)

# ipc constants
KEY1 = "MEM1"
KEY2 = "MEM2"
MEM_1 = SharedMemory(KEY1, RESOLUTION[0]*RESOLUTION[1])
MEM_2 = SharedMemory(KEY2, RESOLUTION[0]*RESOLUTION[1])

# socket
HOST = '0.0.0.0'
PORT = 3001
USE_TCP = False
