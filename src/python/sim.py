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
    
    # Convierto los valores a punto fijo
    temp = DeFixedInt(8,7,'S','round','saturate')
    for i in range(frame_height):
        for j in range(frame_width):
            temp.value = padded_frame[i,j]
            padded_frame[i,j] = temp.fValue
    
    # np.savetxt('preprocessed.txt', padded_frame, fmt='%1.7f', delimiter=' ')

    subframe = np.zeros_like(kernel)
    #Creo una matriz (punto fijo) del tamaño del kernel para los productos parciales 
    product = arrayFixedInt(16, 14, np.zeros(kernel_size**2), signedMode='S', roundMode='round', saturateMode='saturate')
    #Reacomodo el kernel para iterarlo mas facil
    kernel = kernel.reshape((kernel_size**2))
    #Variable de punto fijo para guardar los resultados de las operaciones
    result = DeFixedInt(20,14,'S','round','saturate')
    #NDarray para guardar la imagen final
    convolution = np.zeros_like(frame)
        
    for i in range(frame_height):
        for j in range(frame_width):
            # Get the subframe of the kernel size
            subframe = padded_frame[i:i+kernel_size, j:j+kernel_size] # es un shift register de kernel size
            subframe = subframe.reshape((kernel_size**2))
            
            for k in range(kernel_size**2):
                product[k].value = subframe[k] * kernel[k]
                result.value = result.fValue + product[k].fValue
            
            convolution[i, j] = result.fValue * 256
            result.value = 0
            
    return convolution

def main():
    """Main function"""
    original = load_frame(path)
    pre_processed = pre_process_frame(original)

    processed_manual = convolve_frame_manual(pre_processed, kernel)
    processed = convolve_frame(pre_processed, kernel)
    post_processed = post_process_frame(processed, original.shape[:2])
    post_processed_manual = post_process_frame(processed_manual, original.shape[:2])
    
    # display_frame(original, "Original")
    display_frame(pre_processed, "Pre-processed")
    display_frame(processed, "Processed")
    display_frame(processed_manual, "Processed Manual")
    display_frame(post_processed, "Post-processed")
    display_frame(post_processed_manual, "Post-processed Manual")
    
    assert(np.array_equal(processed_manual, processed))

if __name__ == "__main__":
    main()
