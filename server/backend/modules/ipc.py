import mmap
import posix_ipc

NULL_CHAR = '\0'

def get_semaphore(key):
    sem = posix_ipc.Semaphore(key, posix_ipc.O_CREAT)
    return sem

def get_shared_memory(key, size):
    memory = posix_ipc.SharedMemory(key, posix_ipc.O_CREAT, size=size)
    mapfile = mmap.mmap(memory.fd, memory.size)
    memory.close_fd()
    return mapfile

def write_to_memory(mapfile, bytes):
    mapfile.seek(0) # ir al inicio de la memoria
    mapfile.write(bytes)

def read_from_memory(mapfile):
    mapfile.seek(0)
    bytes = mapfile.read()
    return bytes

def unlink_mem(mapfile):
    mapfile.close()

def unlink_sem(sem):
    sem.unlink()
