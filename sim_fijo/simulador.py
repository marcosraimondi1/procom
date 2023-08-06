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
showPlots  = False

# Generales
Nsym    = 1000      # Cantidad de simbolos a transmitir
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
delay  = Nbauds*os//2 + offset # teniendo en cuenta el transitorio del filtro

# Punto Fijo
NBI             = 2             # bits parte entera + signo 
NBF             = 7             # bits fraccionarios
NB              = NBI + NBF     # bits totales
signedMode      = "S"           # S o U
roundMode       = "round"       # trunc o round
saturateMode    = "saturate"    # saturate o wrap (overflow)

# Generadores de Bits PRBS9
prbs_genI = prbs9(seedI)
prbs_genQ = prbs9(seedQ)

prbs_genI_receptor = prbs9(seedI)
prbs_genQ_receptor = prbs9(seedQ)

# FILTRO POLIFASICO
t, h_filter = rcosine(beta, Tclk, os, Nbauds, True) 
t = t[0:os*Nbauds]
h_filter = h_filter[0:os*Nbauds] # para que los filtros de cada fase tengan la misma longitud

h_filter = fixArray(NB, NBF, h_filter, signedMode, roundMode, saturateMode)

h_i = []  # filtro polifasico, OS filtros
for i in range(os):
    h_i.append(h_filter[i::os])

filterShiftRegI = np.zeros(Nbauds)
filterShiftRegQ = np.zeros(Nbauds)
rxBufferI       = np.zeros(Nbauds*os)
rxBufferQ       = np.zeros(Nbauds*os)
erroresI        = 0
erroresQ        = 0

simbolos_upI    = []
simbolos_upQ    = []
filteredIArray  = []
filteredQArray  = []
bitsTxI         = []
bitsTxQ         = []
bitsRxI         = []
bitsRxQ         = []

for i in range(Nsym*os):

    # 📡📡📡 TRANSMISOR 📡📡📡

    # ⌚⌚⌚⌚⌚⌚ T = Tclk ⌚⌚⌚⌚⌚⌚
    if (i%os == 0):
        
        # Generar bits prbs9
        bitI = next(prbs_genI)
        bitQ = next(prbs_genQ)

        bitsTxI.append(bitI)
        bitsTxQ.append(bitQ)

        # Codificar
        simboloI = 1 if bitI == 1 else -1
        simboloQ = 1 if bitQ == 1 else -1
    
        # introduzco una muestra en el registro de entrada del filtro
        filterShiftRegI = np.roll(filterShiftRegI, 1)
        filterShiftRegI[0] = simboloI

        filterShiftRegQ = np.roll(filterShiftRegQ, 1)
        filterShiftRegQ[0] = simboloQ

    else:
        simboloI = 0
        simboloQ = 0
    
    simbolos_upI.append(simboloI)
    simbolos_upQ.append(simboloQ)

    # ⌚⌚⌚⌚⌚⌚ T = Tclk / os ⌚⌚⌚⌚⌚⌚

    filtro_i = h_i[i%os] # filtro para este tiempo de clock

    # filtro full resolution
    filteredI = sum(filtro_i*filterShiftRegI) # salida del filtro
    filteredQ = sum(filtro_i*filterShiftRegQ) # salida del filtro
    
    # cuantizo la salida del filtro
    filteredI = fixNumber(NB, NBF, filteredI, signedMode, roundMode, saturateMode)
    filteredQ = fixNumber(NB, NBF, filteredQ, signedMode, roundMode, saturateMode)
    
    filteredIArray.append(filteredI)
    filteredQArray.append(filteredQ)

    # 📡📡📡 RECEPTOR 📡📡📡
    rxBufferI[i%os] = filteredI 
    rxBufferQ[i%os] = filteredQ
    
    if (i%os != 0):
        continue

    # ⌚⌚⌚⌚⌚⌚ T = Tclk ⌚⌚⌚⌚⌚⌚

    # DownSampling
    muestraI = rxBufferI[offset]
    muestraQ = rxBufferQ[offset]

    simbolo_estimadoI = muestraI
    simbolo_estimadoQ = muestraQ

    # Decodificacion
    bitI_rec = 1 if simbolo_estimadoI > 0 else 0
    bitQ_rec = 1 if simbolo_estimadoQ > 0 else 0

    bitsRxI.append(bitI_rec)
    bitsRxQ.append(bitQ_rec)

    # ber
    # para contar errores tengo en cuenta el delay del filtro
    if (i < delay):
        continue
    
    bitI = next(prbs_genI_receptor)
    bitQ = next(prbs_genQ_receptor)

    errorI = abs(bitI_rec - bitI)
    errorQ = abs(bitQ_rec - bitQ)

    erroresI += errorI
    erroresQ += errorQ

berI = erroresI / Nsym
berQ = erroresQ / Nsym


if saveData:
    f = open(OUTPUT_FILE, "w+")
    f.write("PARAMETERS\n")
    f.write("Nsym: " + str(Nsym) + "\n")
    f.write("os: " + str(os) + "\n")
    f.write("offset: " + str(offset) + "\n")
    
    f.write("filter\tNbauds: " + str(Nbauds) + "\n")
    f.write("filter\ttaps: " + str([int(c*(2**NBF)) for c in h_filter]) + "\n")

    f.write("fixed\tNB: " + str(NB) + "\n")
    f.write("fixed\tNBF: " + str(NBF) + "\n")
    f.write("fixed\tsignedMode: " + str(signedMode) + "\n")
    f.write("fixed\troundMode: " + str(roundMode) + "\n")
    f.write("fixed\tsaturateMode: " + str(saturateMode) + "\n")
    
        
    f.write("RESULTS\n")
    f.write("Filter Output I: " + str([int(f*(2**NBF)) for f in filteredIArray]) + "\n")
    
    f.write("BER I: " + str(berI) + "\n")

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
plt.plot(filteredIArray)
plt.stem(simbolos_upI, "r")
plt.xlim([0, 50])
plt.legend(["FilteredI", "UpsampledI"])
plt.grid()

plt.subplot(2, 1, 2)
plt.title("Sin Retardo")
plt.plot(filteredIArray[delay:])
plt.stem(simbolos_upI, "r")
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
    plt.plot(filteredIArray[i :: os], filteredQArray[i :: os], ".")
    plt.legend(["Offset: {}".format(i)])

# EYE DIAGRAM
eyeDiagram(filteredIArray[delay:], 2, 100, os)

# BITS TX vs BITS RX
plt.figure()
plt.suptitle("BITS TX vs RX")
plt.subplot(2, 1, 1)
plt.title("Con Retardo")
plt.stem(bitsTxI, 'g')
plt.stem(bitsRxI, markerfmt='D', linefmt='r')
plt.legend(["TxI", "RxI"])
plt.xlim([0, 50])
plt.grid()

plt.subplot(2, 1, 2)
plt.title("Sin Retardo")
plt.stem(bitsTxI, 'g')
plt.stem(bitsRxI[Nbauds//2:], markerfmt='D', linefmt='r')
plt.legend(["RxI", "RxI"])
plt.xlim([0, 50])
plt.grid()
plt.subplots_adjust(hspace=0.5)


plt.show()

print("BER I: {}".format(berI))
print("BER Q: {}".format(berQ))