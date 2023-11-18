import time
import sysv_ipc

NULL_CHAR = '\0'

def get_safe_semaphore(key):
    try:
        sem = sysv_ipc.Semaphore(key, sysv_ipc.IPC_CREX)
    except sysv_ipc.ExistentialError:
        # One of my peers created the semaphore already
        sem = sysv_ipc.Semaphore(key)
        # Waiting for that peer to do the first acquire or release
        while not sem.o_time:
            time.sleep(.1)
    else:
        # Initializing sem.o_time to nonzero value
        sem.release()
    # Now the semaphore is safe to use.
    return sem

def get_shared_memory(key, size):
    memory = sysv_ipc.SharedMemory(key, sysv_ipc.IPC_CREAT, size=size)
    return memory

def write_to_memory(memory, s):
    s += NULL_CHAR
    s = s.encode()
    memory.write(s)

def read_from_memory(memory):
    s = memory.read()
    s = s.decode()
    i = s.find(NULL_CHAR)
    if i != -1:
        s = s[:i]
    return s

