import modules.ipc as ipc

# ipc constants
KEY1 = "MEM1"
KEY2 = "MEM2"
SEM_1 = ipc.get_semaphore(KEY1)
SEM_2 = ipc.get_semaphore(KEY2)
MEM_1 = ipc.get_shared_memory(KEY1, 640*480)
MEM_2 = ipc.get_shared_memory(KEY2, 640*480)

# image constants
RESOLUTION = (480, 640)

# socket
HOST = '192.168.100.35'
PORT = 3001

