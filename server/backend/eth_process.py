import time
import ipc
from globals import SEMAPHORE, MEMORY

def ethInterface():
    i = 0
    while (True):
        # get image to process

        # process the image
        SEMAPHORE.acquire()
        ipc.write_to_memory(MEMORY, "hello world"+str(i))
        SEMAPHORE.release()
        i+=1

        # send processed image

        time.sleep(.25)
