import numpy as np
import cv2
from scipy import signal

from utils import KERNELS, load_frame, pre_process_frame, post_process_frame, display_frame

kernel = KERNELS["gaussian_blur"]

# FRAME
car = "./car.jpg"
gioconda = "./gioconda.jpg"
path = car

def convolve_frame(frame, kernel):
    """Convolves a frame with a kernel using zero padding, returns result of same size as input frame"""
    result = signal.convolve2d(frame, kernel, mode='same', boundary='fill', fillvalue=0)

    return np.array(result, dtype=np.uint8)


def main():
    """Main function"""
    original = load_frame(path)
    pre_processed = pre_process_frame(original)
    processed = convolve_frame(pre_processed, kernel)
    # post_processed = post_process_frame(processed)

    display_frame(pre_processed, "Pre-processed")
    display_frame(processed, "Processed")

if __name__ == "__main__":
    main()
