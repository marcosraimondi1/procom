import numpy as np
import cv2 # opencv-python
from scipy import signal
from tool._fixedInt import *

from utils import KERNELS, load_frame, pre_process_frame, post_process_frame, display_frame

kernel = KERNELS["gaussian_blur"]

# FRAME
car = "./car.jpg"
gioconda = "./gioconda.jpg"
pencil = "./pencil.jpg"
path = pencil

def convolve_frame(frame, kernel):
    """Convolves a frame with a kernel using zero padding, returns result of same size as input frame"""
    result = signal.convolve2d(frame, kernel, mode='same', boundary='fill', fillvalue=0)

    return np.array(result, dtype=np.uint8)


def convolve_frame_manual(frame, kernel):
    """Convolves a frame with a kernel using zero padding, returns result of same size as input frame"""
    # Get kernel size
    kernel_size = 3
    
    # Get frame size
    frame_width  = frame.shape[0]
    frame_height = frame.shape[1]

    # Agrego padding al frame y normalizo los valores
    padded_frame = np.pad(frame, pad_width=1, constant_values=0)
    padded_frame = padded_frame/256

    subframe = np.zeros_like(kernel)
    #Creo una matriz (punto fijo) del tamaño del kernel para los productos parciales 
    product = arrayFixedInt(16, 14, np.zeros(kernel_size**2), signedMode='S', roundMode='round', saturateMode='saturate')

    kernel = kernel.reshape((kernel_size**2))
    
    # result = DeFixedInt(20,14,'S','round','saturate')
    result = arrayFixedInt(20, 14, np.zeros(frame_height*frame_width), signedMode='S', roundMode='round', saturateMode='saturate')
    result = result.reshape((frame_height,frame_width))
    
    convolution = np.zeros_like(frame)
        
    for i in range(frame_height):
        for j in range(frame_width):
            # Get the subframe of the kernel size
            subframe = padded_frame[i:i+kernel_size, j:j+kernel_size] # es un shift register de kernel size
            subframe = subframe.reshape((kernel_size**2))
            
            for k in range(kernel_size**2):
                product[k].value = subframe[k] * kernel[k]
                result[i, j].value = result[i, j].fValue + product[k].fValue

            convolution[i, j] = result[i, j].fValue * 256
            
    display_frame(convolution, 'Convolucion')
    return convolution

def main():
    """Main function"""
    original = load_frame(path)
    pre_processed = pre_process_frame(original)

    processed_manual = convolve_frame_manual(pre_processed, kernel)
    processed = convolve_frame(pre_processed, kernel)
    post_processed = post_process_frame(processed_manual, original.shape[:2])
    
    display_frame(original, "Original")
    display_frame(pre_processed, "Pre-processed")
    display_frame(processed, "Processed")
    display_frame(processed_manual, "Processed Manual")
    display_frame(post_processed, "Post-processed")
    
    # np.savetxt("pre_processed.txt", pre_processed, fmt='%d', delimiter=', ')
    # np.savetxt("processed.txt", processed, fmt='%d', delimiter=', ')
    # np.savetxt("processed_manual.txt", processed_manual, fmt='%d', delimiter=', ')
    
    assert(np.array_equal(processed_manual, processed))

if __name__ == "__main__":
    main()
