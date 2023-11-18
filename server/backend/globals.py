# ipc constants
import ipc
KEY1 = 64
KEY2 = 65
SEM_1 = ipc.get_safe_semaphore(KEY1)
SEM_2 = ipc.get_safe_semaphore(KEY2)
MEM_1 = ipc.get_shared_memory(KEY1, 640*480)
MEM_2 = ipc.get_shared_memory(KEY2, 640*480)

# image constants
RESOLUTION = (480, 640)

