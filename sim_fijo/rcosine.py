import numpy as np
import matplotlib.pyplot as plt

def rcosine(beta, Tbaud, oversampling, Nbauds, Norm):
    """
    Respuesta al impulso del pulso de caida cosenoidal
    Arguments:
        - beta: factor de roll-off
        - Tbaud: duracion del simbolo en segundos
        - oversampling: cantidad de muestras por simbolo
        - Nbauds: cantidad de coeficientes del filtro
        - Norm: booleano para normalizar la respuesta
    Returns:
        - t_vect: vector de tiempos
        - y_vect: coeficientes del filtro
    """
    t_vect = np.arange(
        -0.5 * Nbauds * Tbaud, 0.5 * Nbauds * Tbaud, float(Tbaud) / oversampling
    )

    y_vect = []
    for t in t_vect:
        y_vect.append(
            np.sinc(t / Tbaud)
            * (
                np.cos(np.pi * beta * t / Tbaud)
                / (1 - (4.0 * beta * beta * t * t / (Tbaud * Tbaud)))
            )
        )

    y_vect = np.array(y_vect)

    if Norm:
        return (t_vect, y_vect / max(abs(y_vect)))
        # return (t_vect, y_vect / np.sqrt(np.sum(y_vect**2)))
    else:
        return (t_vect, y_vect)
    
def resp_freq(filt, Ts, Nfreqs):
    """
    Computo de la respuesta en frecuencia de cualquier filtro FIR
    Arguments:
        - filt: coeficientes del filtro
        - Ts: periodo de muestreo
        - Nfreqs: cantidad de frecuencias a evaluar
    Returns:
        - H: magnitud de la respuesta en frecuencia
        - A: fase de la respuesta en frecuencia
        - freqs: vector de frecuencias
    """
    H = []  # Lista de salida de la magnitud
    A = []  # Lista de salida de la fase
    filt_len = len(filt)

    #### Genero el vector de frecuencias
    freqs = np.matrix(np.linspace(0, 1.0 / (2.0 * Ts), Nfreqs))
    #### Calculo cuantas muestras necesito para 20 ciclo de
    #### la mas baja frec diferente de cero
    Lseq = 20.0 / (freqs[0, 1] * Ts)

    #### Genero el vector tiempo
    t = np.matrix(np.arange(0, Lseq)) * Ts

    #### Genero la matriz de 2pifTn
    Omega = 2.0j * np.pi * (t.transpose() * freqs)

    #### Valuacion de la exponencial compleja en todo el
    #### rango de frecuencias
    fin = np.exp(Omega)

    #### Suma de convolucion con cada una de las exponenciales complejas
    for i in range(0, np.size(fin, 1)):
        fout = np.convolve(np.squeeze(np.array(fin[:, i].transpose())), filt)
        mfout = abs(fout[filt_len : len(fout) - filt_len])
        afout = np.angle(fout[filt_len : len(fout) - filt_len])
        H.append(mfout.sum() / len(mfout))
        A.append(afout.sum() / len(afout))

    return [H, A, list(np.squeeze(np.array(freqs)))]

def eyeDiagram(data,nT,nSegments,sps):
    """
    EYEDIAGRAM dibuja el diagrama de ojo de la funcion
      Parameters:
        - data        : funcion a dibujar el diagrama
        - nT          : numero de periodos a graficar 
        - nSegments   : cantidad de nT periodos a graficar
        - sps         : factor de over sampling (samples per symbol)
    """
    t = np.arange(0,nT*sps+1)
    plt.figure()
    plt.grid()
    plt.title("Eye Diagram")
    plt.xlabel("Time Index - n")
    plt.ylabel("Amplitude")

    for j in range(nSegments):
        start = j*nT*sps
        stop  = start + sps*nT+1
        
        plt.plot(t,data[start:stop],'-r')

class PolyFilter:
    def __init__(self,h,os,Nbauds):
        self.os         = os                    # factor de sobremuestreo
        self.Nbauds     = Nbauds                # cantidad de simbolos que abarca el filtro
        self.shiftReg   = np.zeros(Nbauds)      # registro de desplazamiento para el filtro
        self.out        = np.zeros(os)          # salida del filtro (os muestras por filtrado)

        h_i = []  
        for i in range(os):
            h_i.append(h[i::os])

        self.filters    = h_i                   # filtros para cada fase, OS filtros


    def filter(self, i_bit):
        # ingresa una muestra al registro
        self.shiftReg       = np.roll(self.shiftReg, 1)
        self.shiftReg[0]    = i_bit

        for i in range(self.os):
            h_i         = self.filters[i]               # filtro para este tiempo de clock
            prod        = [h_i[x] if self.shiftReg[x] == 0 else -h_i[x] for x in range(self.Nbauds) ]  # producto (optimizado para hardware)
            self.out[i] = sum(prod)                     # salida del filtro
        
        return self.out


# SIMULACION DEL FILTRO

# from utils import fixArray, floatArrayToFixedIntArray

# filter_input    = [1,0,1,0,1,0,1,1,0,0,0,0,1,1,0,1,1,1,1,0,1,0,0,1,1,0,1,1,1,0,0,1,0,0,0,1,0,1,0,0,0,0,1,0,1,0,1,1,0,1,0,0,1,1,1,1,1,1,0,1,1,0,0,1,0,0,1,0,0,1,0,1,1,0,1,1,1,1,1,1,0,0,1,0,0,1,1,0,1,0,1,0,0,1,1,0,0,1,1,0,0,0,0,0,0,0,1,1,0,0,0,1,1,0,0,1,0,1,0,0,0,1,1,0,1,0,0,1,0,1,1,1,1,1,1,1,0,1,0,0,0,1,0,1,1,0,0,0,1,1,1,0,1,0,1,1,0,0,1,0,1,1,0,0,1,1,1,1,0,0,0,1,1,1,1,1,0,1,1,1,0,1,0,0,0,0,0,1,1,0,1,0,1,1,0,1,1,0,1,1]
# NBI             = 1             # bits parte entera + signo 
# NBF             = 7             # bits fraccionarios
# NB              = NBI + NBF     # bits totales
# signedMode      = "S"           # S o U
# roundMode       = "trunc"       # trunc o round
# saturateMode    = "saturate"    # saturate o wrap (overflow)
# os              = 4         # Oversampling Factor
# Fclk            = 100e6     # Frecuencia de Reloj [Hz]
# Tclk            = 1 / Fclk  # Periodo de Reloj [s]
# beta            = 0.5       # Factor de roll-off
# Nbauds          = 6         # Cantidad de simbolos que entran en el filtro

# # FILTRO POLIFASICO
# t, h_filter     = rcosine(beta, Tclk, os, Nbauds, True) 
# t               = t[0:os*Nbauds]
# h_filter        = h_filter[0:os*Nbauds] # para que los filtros de cada fase tengan la misma longitud
# h_filter        = fixArray(NB, NBF, h_filter, signedMode, roundMode, saturateMode) # cuantizacion del filtro
# polyFilter      = PolyFilter(h_filter,os,Nbauds)
# filteredArray   = []

# for bit in filter_input:
#     filter_out      = polyFilter.filter(bit)
#     filter_out      = fixArray(NB, NBF, filter_out, signedMode, roundMode, saturateMode)
#     filteredArray  += list(filter_out)

# print(["8'd"+str(x) for x in floatArrayToFixedIntArray(NB, NBF, filteredArray, signedMode, roundMode, saturateMode)])

# plt.figure()
# plt.plot(filteredArray[0:50])
# plt.grid()
# plt.show()
