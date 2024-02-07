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

    # return np.array(result, dtype=np.uint8)
    return np.array(result)


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

    # Tamaño de la imagen SIN padding
    frame_height = frame.shape[0]   
    frame_width  = frame.shape[1]
    
    #Normalizo los valores
    frame = frame/256
    
    # Agrego padding al frame
    padded_frame = np.pad(frame, pad_width=1, constant_values=0)
    
    # aux = np.zeros_like(padded_frame)   # Para guardar el estimulo para el testbench
    
    # Convierto los valores cada pixel a punto fijo
    temp = DeFixedInt(8,7,'S','round','saturate')
    for i in range(frame_height):
        for j in range(frame_width):
            temp.value = frame[i,j]
            frame[i,j] = temp.fValue
            # aux[i+1, j+1] = bin(temp.intvalue)[2:]
    
    # Guardo la imagen con padding para el testbench
    # np.savetxt('test1_input.txt', aux, fmt='%08d', delimiter='\n')

    # Creo una matriz (punto fijo) del tamaño del kernel para los productos parciales 
    product = arrayFixedInt(16, 14, np.zeros(kernel_size**2), signedMode='S', roundMode='round', saturateMode='saturate')
    # Reacomodo el kernel para iterarlo mas facil
    kernel = kernel.reshape((kernel_size**2))
    # Variables de punto fijo para guardar los resultados de las operaciones
    sum    = DeFixedInt(20,14,'S','round','saturate')
    result = DeFixedInt(8, 7, 'S','round','saturate')

    fifo_2px = np.zeros((frame_height+2,2))

    subframe4 = np.zeros((4))
    subframe12 = np.zeros((3,4))
    subframe18 = np.zeros((3,6))

    convolution = np.zeros_like(frame)    # NDarray para guardar la imagen final

    cont_row = 0    # Contadores para la FSM
    cont_col = 0

    INIT_FIRST_COL = 0
    CONV_FIRST_COL = 1
    INIT_ANY_COL   = 2
    CONV_ANY_COL   = 3
    
    state = INIT_FIRST_COL
    next_state = state
    for col in range(int((frame_width+2)/4)):
        for row in range(frame_height+2):

            #########################################################
            ### Tiempo t
            #########################################################

            # padded_frame
            # [  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11] 
            # [ 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23] 
            # [ 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35] 
            # [ 36, 37, 37, 39, 40, 41, 42, 43, 44, 45, 46, 47] 
            
            subframe4 = padded_frame[row , col*4:col*4+4]   # Paquete de 4 pixeles que llegan del AXI
            # print("subframe4: ")
            # print(subframe4*256)

            # subframe18 (wire) -> Contiene todos los pixeles involucrados en la convolución 
            # de los 4 pixeles actuales (7, 8, 9, 10)
            # [  0,  1,  2,  3,  4,  5]
            # [  6,  7,  8,  9, 10, 11]
            # [ 12, 13, 14, 15, 16, 17]

            # [  -,  -,  2,  3,  4,  5]
            for x in range(4):
                subframe18[0 , x+2] = subframe12[0][x] 
            # [  -,  -,  8,  9, 10, 11]
            for x in range(4):
                subframe18[1 , x+2] = subframe12[1][x] 
            # [  -,  -, 14, 15, 16, 17]
            for x in range(4):
                subframe18[2 , x+2] = subframe12[2][x] 


            # [  0,  1,  -,  -,  -,  -]
            for x in range(2):
                subframe18[0 , x] = fifo_2px[0][x]
            # [  6,  7,  -,  -,  -,  -]
            for x in range(2):
                subframe18[1 , x] = fifo_2px[1][x]
            # [ 12, 13,  -,  -,  -,  -]
            for x in range(2):
                subframe18[2 , x] = fifo_2px[2][x]

            print("#########################################")
            print("subframe18")
            print(subframe18*256)
            #########################################################
            # Convolutor 1
            sum.value = 0
            for k in range(kernel_size**2):
                product[k].value = subframe18[int(k/3) , k%3] * kernel[k]
                sum.value = sum.fValue + product[k].fValue
                    
            result.value = sum.fValue   # El resultado tiene resolucion S(20,14), lo trunco para pasar a S(8,7)
            convolutor1 = sum.fValue
            # convolutor1 = result.fValue
            #########################################################

            #########################################################
            # Convolutor 2
            sum.value = 0
            for k in range(kernel_size**2):
                product[k].value = subframe18[int(k/3) , k%3 + 1] * kernel[k]
                sum.value = sum.fValue + product[k].fValue
            
            result.value = sum.fValue   # El resultado tiene resolucion S(20,14), lo trunco para pasar a S(8,7)
            convolutor2 = sum.fValue
            # convolutor2 = result.fValue
            #########################################################

            #########################################################
            # Convolutor 3
            sum.value = 0
            # print(kernel)
            for k in range(kernel_size**2):
                # print("k: " + str(k) + "subframe18: " + str(256*subframe18[int(k/3) , k%3 + 2]))
                product[k].value = subframe18[int(k/3) , k%3 + 2] * kernel[k]
                sum.value = sum.fValue + product[k].fValue
            

            result.value = sum.fValue   # El resultado tiene resolucion S(20,14), lo trunco para pasar a S(8,7)
            convolutor3 = sum.fValue
            # convolutor3 = result.fValue
            #########################################################

            #########################################################
            # Convolutor 4
            # subframe = padded_frame[row:row+kernel_size , col:col+kernel_size] # es un shift register de kernel size
            sum.value = 0
            for k in range(kernel_size**2):
                product[k].value = subframe18[int(k/3) , k%3 + 3] * kernel[k]
                sum.value = sum.fValue + product[k].fValue
            
            result.value = sum.fValue   # El resultado tiene resolucion S(20,14), lo trunco para pasar a S(8,7)
            convolutor4 = sum.fValue
            # convolutor4 = result.fValue
            #########################################################

            print("STATE: " + str(state))
            print("cont_row:" + str(cont_row))
            print("cont_col:" + str(cont_col))

            # CONEXIONES DE LOS CONVOLVER CON LA SALIDA
            if state == INIT_FIRST_COL:
                pass
            elif state == CONV_FIRST_COL:
                convolution[cont_row - 3, cont_col - 2 + 2] = convolutor3   
                convolution[cont_row - 3, cont_col - 2 + 3] = convolutor4
            elif ((state == INIT_ANY_COL) or (state == CONV_ANY_COL)):
                convolution[cont_row - 3, cont_col - 2    ] = convolutor1   
                convolution[cont_row - 3, cont_col - 2 + 1] = convolutor2   
                convolution[cont_row - 3, cont_col - 2 + 2] = convolutor3   
                convolution[cont_row - 3, cont_col - 2 + 3] = convolutor4

            print("convolution:")
            print(convolution*256)
            
            #########################################################
            ### Tiempo t+1
            #########################################################

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

            # subframe4
            # [  0,  1,  2,  3] 

            print("fifo_2px:")
            print(fifo_2px*256)
            for x in range(frame_height+2):
                if x<(frame_height+2-1):
                    fifo_2px[x] = fifo_2px[x+1]
                else:
                    fifo_2px[x] = subframe12[0][2:4]

            # subframe12
            # [  0,  1,  2,  3] 
            # [  4,  5,  6,  7] 
            # [ 12, 13, 14, 15]

            # [  -,  -,  2,  3,  4,  5]
            subframe12[0] = subframe12[1] 

            # [  -,  -,  8,  9, 10, 11]
            subframe12[1] = subframe12[2] 

            # [  -,  -, 14, 15, 16, 17]
            subframe12[2] = subframe4 


            # INIT_FIRST_COL -> Espera a que lleguen 3 paquetes de 4 pixeles (transicion)
            #                   Solo son validos 2 pixeles de salida
            # CONV_FIRST_COL -> Recibe de a un paquete mientras hace la convolucion
            #                   Solo son validos 2 pixeles de salida
            # INIT_ANY_COL   -> Espera a que lleguen 3 paquetes de 4 pixeles (transicion)
            #                   Son validos los 4 pixeles de salida
            # CONV_ANY_COL   -> Recibe de a un paquete mientras hace la convolucion
            #                   Son validos los 4 pixeles de salida

            # FSM
            if state == INIT_FIRST_COL:
                if cont_row == 2:
                    next_state = CONV_FIRST_COL

            elif state == CONV_FIRST_COL:
                if cont_row == frame_height+2:
                    next_state = INIT_ANY_COL

            elif state == INIT_ANY_COL:
                if cont_row == 2:
                    next_state = CONV_ANY_COL

            elif CONV_ANY_COL:
                if cont_row == frame_height+2:
                    if cont_col == frame_width + 2 - 4:
                        next_state = INIT_FIRST_COL
                    else:
                        next_state = INIT_ANY_COL

            ## CONTADORES
            # contador columna
            if state == INIT_FIRST_COL:
                cont_col = 0

            elif state == CONV_FIRST_COL:
                if cont_row == frame_height+2:
                    cont_col = cont_col + 4

            elif state == INIT_ANY_COL:
                cont_col = cont_col

            elif state == CONV_ANY_COL:
                if cont_row == frame_height+2:
                    if cont_col == frame_width + 2 - 4:
                        cont_col = 0
                    else:
                        cont_col = cont_col + 4

            # contador fila
            if state == INIT_FIRST_COL:
                cont_row = cont_row + 1

            elif state == CONV_FIRST_COL:
                if cont_row == frame_height+2:
                    cont_row = 1 #SI TENEMOS UN VALID, SINO VALDRIA 0
                else:
                    cont_row = cont_row + 1

            elif state == INIT_ANY_COL:
                cont_row = cont_row + 1

            elif state == CONV_ANY_COL:
                if cont_row == frame_height+2:
                    cont_row = 1 #SI TENEMOS UN VALID, SINO VALDRIA 0
                else:
                    cont_row = cont_row + 1

            print(" ")
            state = next_state

    ### REPITO UN CICLO MAS
    #########################################################
    ### Tiempo t
    #########################################################

    subframe4 = padded_frame[row , col*4:col*4+4]
    # print("subframe4: ")
    # print(subframe4*256)
    # subframe18 (wire)
    # [  0,  1,  2,  3,  4,  5]
    # [  6,  7,  8,  9, 10, 11]
    # [ 12, 13, 14, 15, 16, 17]

    # [  -,  -,  2,  3,  4,  5]
    for x in range(4):
        subframe18[0 , x+2] = subframe12[0][x] 
    # [  -,  -,  8,  9, 10, 11]
    for x in range(4):
        subframe18[1 , x+2] = subframe12[1][x] 
    # [  -,  -, 14, 15, 16, 17]
    for x in range(4):
        subframe18[2 , x+2] = subframe12[2][x] 


    # [  0,  1,  -,  -,  -,  -]
    for x in range(2):
        subframe18[0 , x] = fifo_2px[0][x]
    # [  6,  7,  -,  -,  -,  -]
    for x in range(2):
        subframe18[1 , x] = fifo_2px[1][x]
    # [ 12, 13,  -,  -,  -,  -]
    for x in range(2):
        subframe18[2 , x] = fifo_2px[2][x]
    print("subframe18")
    print(subframe18*256)
    #########################################################
    # Convolutor 1
    sum.value = 0
    for k in range(kernel_size**2):
        product[k].value = subframe18[int(k/3) , k%3] * kernel[k]
        sum.value = sum.fValue + product[k].fValue
            
    result.value = sum.fValue   # El resultado tiene resolucion S(20,14), lo trunco para pasar a S(8,7)
    convolutor1 = sum.fValue
    # convolutor1 = result.fValue
    #########################################################

    #########################################################
    # Convolutor 2
    sum.value = 0
    for k in range(kernel_size**2):
        product[k].value = subframe18[int(k/3) , k%3 + 1] * kernel[k]
        sum.value = sum.fValue + product[k].fValue
    
    result.value = sum.fValue   # El resultado tiene resolucion S(20,14), lo trunco para pasar a S(8,7)
    convolutor2 = sum.fValue
    # convolutor2 = result.fValue
    #########################################################

    #########################################################
    # Convolutor 3
    sum.value = 0
    # print(kernel)
    for k in range(kernel_size**2):
        # print("k: " + str(k) + "subframe18: " + str(256*subframe18[int(k/3) , k%3 + 2]))
        product[k].value = subframe18[int(k/3) , k%3 + 2] * kernel[k]
        sum.value = sum.fValue + product[k].fValue
    

    result.value = sum.fValue   # El resultado tiene resolucion S(20,14), lo trunco para pasar a S(8,7)
    convolutor3 = sum.fValue
    # convolutor3 = result.fValue
    #########################################################

    #########################################################
    # Convolutor 4
    # subframe = padded_frame[row:row+kernel_size , col:col+kernel_size] # es un shift register de kernel size
    sum.value = 0
    for k in range(kernel_size**2):
        product[k].value = subframe18[int(k/3) , k%3 + 3] * kernel[k]
        sum.value = sum.fValue + product[k].fValue
    
    result.value = sum.fValue   # El resultado tiene resolucion S(20,14), lo trunco para pasar a S(8,7)
    convolutor4 = sum.fValue
    # convolutor4 = result.fValue
    #########################################################
    print("STATE: " + str(state))
    print("cont_row:" + str(cont_row))
    print("cont_col:" + str(cont_col))
    
    # SALIDAS
    if state == INIT_FIRST_COL:
        pass
    elif state == CONV_FIRST_COL:
        convolution[cont_row - 3, cont_col - 2 + 2] = convolutor3   
        convolution[cont_row - 3, cont_col - 2 + 3] = convolutor4
    elif state == INIT_ANY_COL:
        convolution[cont_row - 3, cont_col - 2    ] = convolutor1   
        convolution[cont_row - 3, cont_col - 2 + 1] = convolutor2   
        convolution[cont_row - 3, cont_col - 2 + 2] = convolutor3   
        convolution[cont_row - 3, cont_col - 2 + 3] = convolutor4
    elif state == CONV_ANY_COL:
        convolution[cont_row - 3, cont_col - 2    ] = convolutor1   
        convolution[cont_row - 3, cont_col - 2 + 1] = convolutor2   
        convolution[cont_row - 3, cont_col - 2 + 2] = convolutor3   
        convolution[cont_row - 3, cont_col - 2 + 3] = convolutor4

    print("convolution:")
    print(convolution*256)


    return convolution

def main():
    """Main function"""
    original = load_frame(path)
    # pre_processed = pre_process_frame(original, (200, 200))
    # pre_processed = np.ones((10,10)) * 100   # "Imagen" de prueba
    image_width  = 10   #Las dimensiones (+padding) deben ser múltiplos de 4
    image_height = 10
    pre_processed = np.arange(image_width*image_height) # IMAGEN SIN PADDING
    pre_processed = pre_processed.reshape((image_height, image_width))

    processed_hw = convolve_like_hw(pre_processed, kernel)
    # processed_manual = convolve_frame_manual(pre_processed, kernel)
    processed = convolve_frame(pre_processed, kernel)

    print("pre_processed")
    print(pre_processed)
    print("processed_hw")
    print(processed_hw*256)
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
    
    assert(np.array_equal(processed_hw*256, processed))

if __name__ == "__main__":
    main()
