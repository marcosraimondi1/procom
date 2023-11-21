import time
import numpy as np

# custom modules
from modules.globals import *
from modules.transformations import *
from modules.ipc import read_from_memory, write_to_memory

def ethInterface():
    # initialize memory to zeros
    if (SEM_1.value == 0):
        SEM_1.release()
    if (SEM_2.value == 0):
        SEM_2.release()

    zeros = np.zeros(RESOLUTION, dtype=np.uint8)
    with SEM_1:
        write_to_memory(MEM_1, zeros.tobytes())

    with SEM_2:
        write_to_memory(MEM_2, zeros.tobytes())

    print("Ethernet Subprocess Started ...")
    while (True):
        # get image to process
        with SEM_2:
            bytes = read_from_memory(MEM_2)

        img = np.frombuffer(bytes, dtype=np.uint8).reshape(RESOLUTION)

        # process the image
        new_img = edgeDetection(img)

        # send processed image
        with SEM_1:
            write_to_memory(MEM_1, new_img.tobytes())

        time.sleep(.035)

