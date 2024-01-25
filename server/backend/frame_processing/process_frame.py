import numpy as np
from frame_processing.tool._fixedInt import *

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
    #Reacomodo el kernel para iterarlo mas facil
    kernel = kernel.reshape((kernel_size**2))
    #Variable de punto fijo para guardar los resultados de las operaciones
    result = DeFixedInt(20,14,'S','round','saturate')
    #NDarray para guardar la imagen final
    convolution = np.zeros_like(frame, dtype=np.uint8)
        
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

# KERNELS
edges = np.array([[-1,-1,-1], [-1,8,-1], [-1,-1,-1]]) /8
gaussian_blur = np.array([[1,2,1], [2,4,2], [1,2,1]]) /16
sharpen = np.array([[0,-1,0], [-1,5,-1], [0,-1,0]])   /5
identity = np.array([[0,0,0], [0,1,0], [0,0,0]])

KERNELS = {
    "edges": edges,
    "gaussian_blur": gaussian_blur,
    "sharpen": sharpen,
    "identity": identity
 }

def process_frame(frame, transformation):
    """Processes a frame, applying a transformation with a kernel"""
    kernel = KERNELS[transformation]
    
    # ---------------------------------------------------------------------------------
    # cambiar esta linea llamando a la funcion que haga falta para hacer la convolucion
    # ---------------------------------------------------------------------------------
    processed = convolve_frame_manual(frame, kernel) 
    return processed
