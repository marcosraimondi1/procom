import numpy as np
import matplotlib.pyplot as plt
from prbs9 import prbs9
from rcosine import rcosine, resp_freq, eyeDiagram
from utils import fixArray, fixNumber

"""
1. Disenar en Python un simulador en punto flotante que contemple todo el diseño 
en donde la representacion de la PRBS9 es una secuencia aleatoria y la estimacion de
la BER es una comparacion de vectores.

a) Realizar los siguientes graficos:
    - Bits transmitidos
    - Respuesta al impulso y frecuencia del filtro Tx.
    - Salida y diagrama de ojo del filtro Tx.
    - Diagrama de constelacion a la salida del filtro Tx (por cada fase).
"""

# PARAMETROS ---------------------------------------------------------------
# Simulacion
OUTPUT_FILE = ".\\sim_fijo\\data.txt"
saveData   = True
showPlots  = True

# Generales
sim_len = 511*5 # 263000    # Cantidad de simbolos a transmitir
os      = 4         # Oversampling Factor
Nfreqs  = 256       # Cantidad de frecuencias a evaluar (para la respuesta en frecuencia)
seedI   = 0x1AA     # Semilla para el generador de PRBS9 parte real
seedQ   = 0x1FE     # Semilla para el generador de PRBS9 parte imaginaria

Fclk    = 100e6     # Frecuencia de Reloj [Hz]
Tclk    = 1 / Fclk  # Periodo de Reloj [s]
Ts      = Tclk / os # Frecuencia de muestreo

# Filtro
beta    = 0.5       # Factor de roll-off
Nbauds  = 6         # Cantidad de simbolos que entran en el filtro

# Receptor
offset = 0

# Punto Fijo
NBI             = 1             # bits parte entera + signo 
NBF             = 7             # bits fraccionarios
NB              = NBI + NBF     # bits totales
signedMode      = "S"           # S o U
roundMode       = "trunc"       # trunc o round
saturateMode    = "saturate"    # saturate o wrap (overflow)

# VARIABLES ---------------------------------------------------------------

# Generadores de Bits PRBS9
prbs_genI = prbs9(seedI)
prbs_genQ = prbs9(seedQ)

# FILTRO POLIFASICO
t, h_filter         = rcosine(beta, Tclk, os, Nbauds, True) 
t                   = t[0:os*Nbauds]
h_filter            = h_filter[0:os*Nbauds] # para que los filtros de cada fase tengan la misma longitud

h_filter = fixArray(NB, NBF, h_filter, signedMode, roundMode, saturateMode) # cuantizacion del filtro

h_i = []  # filtro polifasico, OS filtros
for i in range(os):
    h_i.append(h_filter[i::os])

# variables del sistema
filterShiftRegI = np.zeros(Nbauds)      # registro de desplazamiento para el filtro
filterShiftRegQ = np.zeros(Nbauds)
rxBufferI       = np.zeros(os)          # buffer de recepcion del cual se elige con el offset
rxBufferQ       = np.zeros(os)
bufferRefI      = np.zeros(512)         # buffer de referencia para la sincronizacion
bufferRefQ      = np.zeros(512)
erroresI        = 0                     # acumulador de errores after sync
erroresQ        = 0
synced          = False                 # flag para indicar que se sincronizo el receptor
error_cum_sumI  = 0                     # acumulador de errores before sync
error_cum_sumQ  = 0                     
latencia        = 0                     # latencia del sistema
min_latencia    = 0                     # latencia minima
min_error       = -1                    # error minimo     

# variables de analisis
simbolos_upI    = []
simbolos_upQ    = []
filteredIArray  = []
filteredQArray  = []
bitsTxI         = []
bitsTxQ         = []
bitsRxI         = []
bitsRxQ         = []

# SIMULACION ---------------------------------------------------------------

for i in range(sim_len):

    # 📡📡📡 TRANSMISOR 📡📡📡

    # ⌚⌚⌚⌚⌚⌚ T = Tclk ⌚⌚⌚⌚⌚⌚
        
    # Generar bits prbs9
    bitI = next(prbs_genI)
    bitQ = next(prbs_genQ)

    bitsTxI.append(bitI)
    bitsTxQ.append(bitQ)

    # introduzco una muestra en el registro de entrada del filtro
    filterShiftRegI = np.roll(filterShiftRegI, 1)
    filterShiftRegI[0] = bitI

    filterShiftRegQ = np.roll(filterShiftRegQ, 1)
    filterShiftRegQ[0] = bitQ

    simbolos_upI.append(1 if bitI == 0 else -1)
    simbolos_upQ.append(1 if bitQ == 0 else -1)

    # ⌚⌚⌚⌚⌚⌚ T = Tclk / os ⌚⌚⌚⌚⌚⌚
    for j in range(os):
        filtro_p = h_i[j] # filtro para este tiempo de clock

        # filtro full resolution
        filtro_pI = [filtro_p[x] if filterShiftRegI[x] == 0 else -filtro_p[x] for x in range(Nbauds)] # mux que elige coef positivo o negativo para evitar productos
        filtro_pQ = [filtro_p[x] if filterShiftRegQ[x] == 0 else -filtro_p[x] for x in range(Nbauds)] # mux que elige coef positivo o negativo para evitar productos

        filteredI = sum(filtro_pI) # salida del filtro
        filteredQ = sum(filtro_pQ) # salida del filtro
        
        # cuantizo la salida del filtro
        filteredI = fixNumber(NB, NBF, filteredI, signedMode, roundMode, saturateMode)
        filteredQ = fixNumber(NB, NBF, filteredQ, signedMode, roundMode, saturateMode)
        
        filteredIArray.append(filteredI)
        filteredQArray.append(filteredQ)

        # 📡📡📡 RECEPTOR 📡📡📡
        rxBufferI[j] = filteredI 
        rxBufferQ[j] = filteredQ

        if (j != 0):
            simbolos_upI.append(0)
            simbolos_upQ.append(0)

    # ⌚⌚⌚⌚⌚⌚ T = Tclk ⌚⌚⌚⌚⌚⌚

    # DownSampling
    muestraI = rxBufferI[offset]
    muestraQ = rxBufferQ[offset]

    # Decodificacion - Slicer, me fijo en el signo
    bitI_rec = 0 if muestraI > 0 else 1
    bitQ_rec = 0 if muestraQ > 0 else 1

    bitsRxI.append(bitI_rec)
    bitsRxQ.append(bitQ_rec)

    # sync, enganche del sistema
    bufferRefI       = np.roll(bufferRefI, 1)
    bufferRefI[0]    = bitI 
    
    bufferRefQ       = np.roll(bufferRefQ, 1)
    bufferRefQ[0]    = bitQ

    if (not synced):
        error_cum_sumI   += bool(bufferRefI[latencia]) != bool(bitI_rec) # xor para ver si hay error
        error_cum_sumQ   += bool(bufferRefQ[latencia]) != bool(bitQ_rec) # xor para ver si hay error

        if (i%511 == 0 and i != 0):
            # verifico si es el error minimo
            if (min_error > error_cum_sumI or min_error == -1):
                min_error       = error_cum_sumI
                min_latencia    = latencia
                
                # si no hay ruido en el canal
                if (min_error == 0):
                    synced = True
                    continue

            # reseteo los contadores 
            error_cum_sumI = 0
            error_cum_sumQ = 0

            # verifico si llegue al final del buffer de referencia
            if (latencia == 511):
                synced = True
                latencia = min_latencia
                continue

            # avanzo un lugar de retardo el buffer de referencia
            latencia       += 1
        
        # no estoy sincronizado, continuo
        continue

    # ber
    # cuento errores despues de sincronizar el sistema
    
    errorI = abs(bitI_rec - bufferRefI[latencia])
    errorQ = abs(bitQ_rec - bufferRefQ[latencia])

    erroresI += errorI
    erroresQ += errorQ

berI = erroresI / sim_len
berQ = erroresQ / sim_len

# FIN SIMULACION -----------------------------------------------------------

if saveData:
    f = open(OUTPUT_FILE, "w+")
    f.write("PARAMETERS\n")
    f.write("Sim Len: " + str(sim_len) + "\n")
    f.write("os: " + str(os) + "\n")
    f.write("offset: " + str(offset) + "\n")
    f.write("latency: " + str(latencia) + "\n")
    
    f.write("filter\tNbauds: " + str(Nbauds) + "\n")
    f.write("filter\ttaps: " + str([int(c*(2**NBF)) for c in h_filter]) + "\n")

    f.write("fixed\tNB: " + str(NB) + "\n")
    f.write("fixed\tNBF: " + str(NBF) + "\n")
    f.write("fixed\tsignedMode: " + str(signedMode) + "\n")
    f.write("fixed\troundMode: " + str(roundMode) + "\n")
    f.write("fixed\tsaturateMode: " + str(saturateMode) + "\n")
    
    f.write("RESULTS\n")
    f.write("BITS TX I: " + str(bitsTxI[0:100]) + "\n")
    f.write("Filter Output I: " + str([int(f*(2**NBF)) for f in filteredIArray[0:100]]) + "\n")
    
    f.write("ber\tBER I: " + str(berI) + "\n")
    f.write("ber\terrores: " + str(erroresI) + "\n")

    f.close()


if not showPlots:
    exit()

# GRAFICOS -----------------------------------------------------------------

# RESPUESTA AL IMPULSO y FRECUENCIA
H0, _, F0 = resp_freq(h_filter, Ts, Nfreqs)

plt.figure()
plt.suptitle("Filtro Tx")
plt.subplot(2, 1, 1)
plt.plot(t, h_filter, "o-")
plt.legend("Tiempo")
plt.grid()

plt.subplot(2, 1, 2)
plt.semilogx(F0, 20 * np.log10(H0))
plt.legend("Frecuencia")
plt.grid()
plt.subplots_adjust(hspace=0.5)

# FILTER OUT
plt.figure()
plt.suptitle("FILTER OUT")
plt.subplot(2, 1, 1)
plt.title("Con Retardo")
plt.plot(filteredIArray[0:50])
plt.stem(simbolos_upI[0:50], "r")
plt.xlim([0, 50])
plt.legend(["FilteredI", "UpsampledI"])
plt.grid()

plt.subplot(2, 1, 2)
plt.title("Sin Retardo")
plt.plot(filteredIArray[latencia*os+offset:50+latencia*os+offset])
plt.stem(simbolos_upI[0:50], "r")
plt.xlim([0, 50])
plt.legend(["FilteredI", "UpsampledI"])
plt.grid()
plt.subplots_adjust(hspace=0.5)

# CONSTELACION + OFFSETs
plt.figure()
plt.suptitle("Constelacion")
for i in range(os):
    plt.subplot(2, os//2, i + 1)
    plt.grid()
    plt.plot(filteredIArray[i :100*os: os], filteredQArray[i :100*os: os], ".")
    plt.legend(["Offset: {}".format(i)])

# EYE DIAGRAM
eyeDiagram(filteredIArray[latencia*os+offset:], 2, 100, os)

# BITS TX vs BITS RX
plt.figure()
plt.suptitle("BITS TX vs RX")
plt.subplot(2, 1, 1)
plt.title("Con Retardo")
plt.stem(bitsTxI[0:50], 'g')
plt.stem(bitsRxI[0:50], markerfmt='D', linefmt='r')
plt.legend(["TxI", "RxI"])
plt.xlim([0, 50])
plt.grid()

plt.subplot(2, 1, 2)
plt.title("Sin Retardo")
plt.stem(bitsTxI[0:50], 'g')
plt.stem(bitsRxI[latencia:50+latencia], markerfmt='D', linefmt='r')
plt.legend(["RxI", "RxI"])
plt.xlim([0, 50])
plt.grid()
plt.subplots_adjust(hspace=0.5)


plt.show()

print("BER I: {}".format(berI))
print("BER Q: {}".format(berQ))
print("Latencia: {}".format(latencia))