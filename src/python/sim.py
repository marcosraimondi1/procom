import numpy as np
import cv2 # opencv-python
from scipy import signal
from tool._fixedInt import *

from utils import KERNELS, load_frame, pre_process_frame, post_process_frame, display_frame

kernel = KERNELS["identity"]

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
    frame_height = frame.shape[0]
    frame_width  = frame.shape[1]
    
    #Normalizo los valores
    frame = frame/256
    
    # Agrego padding al frame
    padded_frame = np.pad(frame, pad_width=1, constant_values=0)
    aux = np.zeros_like(padded_frame)
    temp = DeFixedInt(8,7,'S','round','saturate')
    
    for i in range(frame_height):
        for j in range(frame_width):
            temp.value = frame[i,j]
            frame[i,j] = temp.fValue
            aux[i+1, j+1] = bin(temp.intvalue)[2:]
    # print(frame)
    # Guardo la imagen con padding para el testbench
    np.savetxt('test1_input.txt', aux, fmt='%08d', delimiter='\n')

    subframe = np.zeros_like(kernel)
    #Creo una matriz (punto fijo) del tamaño del kernel para los productos parciales 
    product = arrayFixedInt(16, 14, np.zeros(kernel_size**2), signedMode='S', roundMode='round', saturateMode='saturate')
    #Reacomodo el kernel para iterarlo mas facil
    kernel = kernel.reshape((kernel_size**2))
    #Variable de punto fijo para guardar los resultados de las operaciones
    sum    = DeFixedInt(20,14,'S','round','saturate')
    result = DeFixedInt(8, 7, 'S','round','saturate')
    #NDarray para guardar la imagen final
    convolution = np.zeros_like(frame)
    
    aux = np.zeros_like(frame)
        
    for i in range(frame_height):
        for j in range(frame_width):
            # Get the subframe of the kernel size
            subframe = padded_frame[i:i+kernel_size, j:j+kernel_size] # es un shift register de kernel size
            subframe = subframe.reshape((kernel_size**2))
            
            for k in range(kernel_size**2):
                product[k].value = subframe[k] * kernel[k]
                sum.value = sum.fValue + product[k].fValue
            
            result.value = sum.fValue   # El resultado tiene resolucion S(20,14), lo trunco para pasar a S(8,7)
            convolution[i, j] = result.fValue   
            aux[i, j] = bin(result.intvalue)[2:]
            sum.value = 0

    #Salida de la convolución en punto fijo 
    np.savetxt('test1_output.txt', aux, fmt='%08d', delimiter='\n')
            
    return convolution

def main():
    """Main function"""
    original = load_frame(path)
    # pre_processed = pre_process_frame(original, (200, 200))
    pre_processed = np.ones((1,10)) * 100   # "Imagen" de prueba

    processed_manual = convolve_frame_manual(pre_processed, kernel)
    processed = convolve_frame(pre_processed, kernel)
    print("pre_processed")
    print(pre_processed)
    print("processed_manual")
    print(processed_manual)
    # print("processed")
    # print(processed)
    # post_processed = post_process_frame(processed, original.shape[:2])
    # post_processed_manual = post_process_frame(processed_manual, original.shape[:2])
    
    # display_frame(original, "Original")
    # display_frame(pre_processed, "Pre-processed")
    # display_frame(processed, "Processed")
    # display_frame(processed_manual, "Processed Manual")
    # display_frame(post_processed, "Post-processed")
    # display_frame(post_processed_manual, "Post-processed Manual")
    
    # assert(np.array_equal(processed_manual, processed))

if __name__ == "__main__":
    main()
