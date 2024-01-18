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


def convolve_frame_manual(frame, kernel):
    """Convolves a frame with a kernel using zero padding, returns result of same size as input frame"""
    # Get kernel size
    kernel_size = 3

    # Get frame size
    frame_size = frame.shape[0]

    # Add zero padding to the frame
    padded = np.pad(frame, pad_width=1, constant_values=0)

    # Create a new frame for the result
    result = np.zeros_like(frame, dtype=np.uint8)

    product = np.zeros_like(kernel, dtype=np.uint8)

    # Iterate over the frame
    for i in range(frame_size):
        for j in range(frame_size):
            # Get the subframe of the kernel size
            subframe = padded[i:i+kernel_size, j:j+kernel_size] # es un shift register de kernel size

            # Multiply element wise the subframe with the kernel
            product[0,0] = subframe[0,0] * kernel[0,0]
            product[0,1] = subframe[0,1] * kernel[0,1]
            product[0,2] = subframe[0,2] * kernel[0,2]

            product[1,0] = subframe[1,0] * kernel[1,0]
            product[1,1] = subframe[1,1] * kernel[1,1]
            product[1,2] = subframe[1,2] * kernel[1,2]

            product[2,0] = subframe[2,0] * kernel[2,0]
            product[2,1] = subframe[2,1] * kernel[2,1]
            product[2,2] = subframe[2,2] * kernel[2,2]

            
            # Add all the elements of the product
            result[i, j] = np.sum(product)

    return result

def main():
    """Main function"""
    original = load_frame(path)
    pre_processed = pre_process_frame(original)

    processed1 = convolve_frame_manual(pre_processed, kernel)
    print(processed1)

    # processed = convolve_frame(pre_processed, kernel)
    # post_processed = post_process_frame(processed)
    # display_frame(pre_processed, "Pre-processed")
    # display_frame(processed, "Processed")

if __name__ == "__main__":
    main()
