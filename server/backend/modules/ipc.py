from typing import Tuple
import numpy as np
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

def unlink_mem(mapfile):
    mapfile.close()

def unlink_sem(sem):
    sem.unlink()

def init_semaphore_to_one(sem):
    if (sem.value == 0):
        sem.release()

class SharedMemory():
    def __init__(self, key, size):
        self.key = key
        self.semaphore = get_semaphore(key)
        self.memory = get_shared_memory(key, size)

        init_semaphore_to_one(self.semaphore)

        # initialize memory to zeros
        zeros = np.zeros(size, dtype=np.uint8)
        self.write_array(zeros)

    def write_array(self, array):
        self.write_bytes(array.tobytes())

    def write_bytes(self, data):
        with self.semaphore:
            self.memory.seek(0)
            self.memory.write(data)

    def read_array(self, shape):
        data = self.read_bytes()
        array = np.frombuffer(data, dtype=np.uint8).reshape(shape)
        return array

    def read_bytes(self):
        with self.semaphore:
            self.memory.seek(0)
            data = self.memory.read()
        return data

    def release(self):
        unlink_mem(self.memory)
        unlink_sem(self.semaphore)
