import time
import numpy as np

# custom modules
from globals import *
from transformations import *

def ethInterface():
    print(SEM_1.value)
    print(SEM_2.value)

    # initialize memory to zeros
    zeros = np.zeros(RESOLUTION, dtype=np.uint8)
    SEM_1.acquire()
    MEM_1.write(zeros.tobytes())
    SEM_1.release()
    SEM_2.acquire()
    MEM_2.write(zeros.tobytes())
    SEM_2.release()

    while (True):
        # get image to process
        SEM_2.acquire()
        bytes = MEM_2.read()
        SEM_2.release()

        img = np.frombuffer(bytes, dtype=np.uint8).reshape(RESOLUTION)

        # process the image
        new_img = edgeDetection(img)

        # send processed image
        SEM_1.acquire()
        MEM_1.write(new_img.tobytes())
        SEM_1.release()

        time.sleep(.035)

