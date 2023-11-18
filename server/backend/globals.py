# ipc constants
import ipc
KEY = 64
SEMAPHORE = ipc.get_safe_semaphore(KEY)
MEMORY = ipc.get_shared_memory(KEY, 640*480 + 1000)

