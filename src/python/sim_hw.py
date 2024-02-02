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


def convolve_like_hw(frame, kernel):
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
    # np.savetxt('test1_input.txt', aux, fmt='%08d', delimiter='\n')

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

    ##############################################
    # MAQUINA DE ESTADOS
    # INIT_FIRST_COL -> Espera a que lleguen 3 paquetes de 4 pixeles (transicion)
    #                   Solo son validos 2 pixeles de salida
    # CONV_FIRST_COL -> Recibe de a un paquete mientras hace la convolucion
    #                   Solo son validos 2 pixeles de salida
    # INIT_ANY_COL   -> Espera a que lleguen 3 paquetes de 4 pixeles (transicion)
    #                   Son validos los 4 pixeles de salida
    # CONV_ANY_COL   -> Recibe de a un paquete mientras hace la convolucion
    #                   Son validos los 4 pixeles de salida
    ###############################################

    padded_frame = np.arange(36)
    padded_frame.reshape(padded_frame)

    fifo_2px = np.zeros((frame_height,2))


    convolution = np.zeros_like(frame)
    for col in range(frame_width):
        for row in range(int(frame_width/4)):
            
            # subframe12
            # [  0,  1,  2,  3] 
            # [  4,  5,  6,  7] 
            # [ 12, 13, 14, 15] 

            # padded_frame
            # [  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11] 
            # [ 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23] 
            # [ 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35] 
            # [ 36, 37, 37, 39, 40, 41, 42, 43, 44, 45, 46, 47] 


            # subframe4
            # [  0,  1,  2,  3] 
            subframe4 = np.zeros((4))

            # subframe12
            # [  0,  1,  2,  3] 
            # [  4,  5,  6,  7] 
            # [ 12, 13, 14, 15]
            subframe12 = np.zeros((3,4))

            # [  -,  -,  2,  3,  4,  5]
            subframe12[0] = subframe12[1] 
            # for x in range(4):
                # subframe12[0 , x] = subframe12[1 , x] 
            

            # [  -,  -,  8,  9, 10, 11]
            subframe12[1] = subframe12[2] 
            # for x in range(4):
                # subframe12[1 , x] = subframe12[2 , x] 

            subframe12[2] = subframe4 
            # [  -,  -, 14, 15, 16, 17]
            # for x in range(4):
                # subframe12[2 , x] = subframe4[x] 


            # fifo_2px
            # [ 0,  1]    0
            # [ 2,  3]    1
            # [ 4,  5]    2
            # [ 6,  7]    3
            # [ 8,  9]    4
            # [ 10, 11]   5
            # [ 12, 13]   6
            # [ 14, 15]   7
            # [ 16, 17]   8
            # [ 18, 19]   9
            # [ 20, 21]  10
            # [ 22, 23]  11

            
            for x in range(frame_height):
                if x<(frame_height-1):
                    fifo_2px[x] = fifo_2px[x+1]
                else:
                    fifo_2px[x] = subframe4[2:3]


            
            # subframe18 (wire)
            # [  0,  1,  2,  3,  4,  5]
            # [  6,  7,  8,  9, 10, 11]
            # [ 12, 13, 14, 15, 16, 17]
            subframe18 = np.zeros((3,6))


            # [  -,  -,  2,  3,  4,  5]
            for x in range(4):
                subframe18[0 , x+2] = subframe12[0][x] 

            # [  -,  -,  8,  9, 10, 11]
            for x in range(4):
                subframe18[0 , x+2] = subframe12[1][x] 

            # [  -,  -, 14, 15, 16, 17]
            for x in range(4):
                subframe18[0 , x+2] = subframe12[2][x] 


            # [  0,  1,  -,  -,  -,  -]
            for x in range(2):
                subframe18[0 , x] = fifo_2px[0][x]

            # [  6,  7,  -,  -,  -,  -]
            for x in range(2):
                subframe18[0 , x] = fifo_2px[1][x]

            # [ 12, 13,  -,  -,  -,  -]
            for x in range(2):
                subframe18[0 , x] = fifo_2px[2][x]




            for x in range(12):
                subframe_12[int(x/4), x%4] = padded_frame[row + int(x/4) , 4*col + x%4]

            subframe_18 = np.zeros((3,6))

            # subframe_18
            # [  0,  1,  2,  3,  4,  5]
            # [  6,  7,  8,  9, 10, 11]
            # [ 12, 13, 14, 15, 16, 17]

            for x in range(18):
                if (x%6)>=2:
                    subframe_18[int(x/6) , x%6] = padded_frame[int(x/6) , x%6 - 2]
                else:
                    subframe_18[int(x/6) , x%6] = padded_frame[int(x/6) , x%6]


            # for x in range(12):
            #     subframe_18[int(x/4) + 2 , x%4 + 2] = padded_frame[int(x/4) + 2 , 4*col + x%4 + 2]



            #########################################################
            # Convolutor 1
            sum.value = 0
            for k in range(kernel_size):
                for l in range(kernel_size):
                    product[k].value = subframe_18[0:0+k , 0:0+l] * kernel[k]
                    sum.value = sum.fValue + product[k].fValue
                    
            result.value = sum.fValue   # El resultado tiene resolucion S(20,14), lo trunco para pasar a S(8,7)
            convolutor1 = result.value
            #########################################################

            #########################################################
            # Convolutor 2
            sum.value = 0
            for k in range(kernel_size):
                for l in range(kernel_size):
                    product[k].value = subframe_18[1:1+k , 1:1+l] * kernel[k]
                    sum.value = sum.fValue + product[k].fValue
            
            result.value = sum.fValue   # El resultado tiene resolucion S(20,14), lo trunco para pasar a S(8,7)
            convolutor2 = result.value
            #########################################################

            #########################################################
            # Convolutor 3
            sum.value = 0
            for k in range(kernel_size):
                for l in range(kernel_size):
                    product[k].value = subframe_18[2:2+k , 2:2+l] * kernel[k]
                    sum.value = sum.fValue + product[k].fValue
            
            result.value = sum.fValue   # El resultado tiene resolucion S(20,14), lo trunco para pasar a S(8,7)
            convolutor3 = result.value
            #########################################################

            #########################################################
            # Convolutor 4
            # subframe = padded_frame[row:row+kernel_size , col:col+kernel_size] # es un shift register de kernel size
            sum.value = 0
            for k in range(kernel_size):
                for l in range(kernel_size):
                    product[k].value = subframe_18[3:3+k , 3:3+l] * kernel[k]
                    sum.value = sum.fValue + product[k].fValue
            
            result.value = sum.fValue   # El resultado tiene resolucion S(20,14), lo trunco para pasar a S(8,7)
            convolutor4 = result.value
            #########################################################

            if col>0:
                convolution[row , col]     = convolutor1   
                convolution[row , col + 1] = convolutor2   
                convolution[row , col + 2] = convolutor3   
                convolution[row , col + 3] = convolutor4
            else:
                convolution[row , col]     = convolutor3   
                convolution[row , col + 1] = convolutor4   

            
    return convolution

def main():
    """Main function"""
    original = load_frame(path)
    # pre_processed = pre_process_frame(original, (200, 200))
    # pre_processed = np.ones((10,10)) * 100   # "Imagen" de prueba
    pre_processed = np.arange(100)
    pre_processed.reshape((10,10))


    processed_hw = convolve_like_hw(pre_processed, kernel)
    # processed_manual = convolve_frame_manual(pre_processed, kernel)
    # processed = convolve_frame(pre_processed, kernel)
    print("pre_processed")
    print(pre_processed)
    print("processed_manual")
    print(processed_manual)
    print("processed")
    print(processed)
    # post_processed = post_process_frame(processed, original.shape[:2])
    # post_processed_manual = post_process_frame(processed_manual, original.shape[:2])
    
    # display_frame(original, "Original")
    # display_frame(pre_processed, "Pre-processed")
    # display_frame(processed, "Processed")
    # display_frame(processed_manual, "Processed Manual")
    # display_frame(post_processed, "Post-processed")
    # display_frame(post_processed_manual, "Post-processed Manual")
    
    assert(np.array_equal(processed_manual*256, processed))

if __name__ == "__main__":
    main()
