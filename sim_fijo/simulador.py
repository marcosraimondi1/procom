import numpy as np
import matplotlib.pyplot as plt
from prbs9 import generar_bpsk, generar_prbs9, deco_bpsk, slicer
from rcosine import rcosine, resp_freq, eyeDiagram
from utils import fixArray
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

# Punto Fijo
NB              = 8             # bits totales
NBF             = 7             # bits fraccionarios
signedMode      = "S"           # S o U
roundMode       = "round"       # trunc o round
saturateMode    = "saturate"    # saturate o wrap (overflow)

# Graficos
showPlots   = True

# TRANSMISOR ---------------------------------------------------------------

# Generar bits a transmitir
bitsI = generar_prbs9(seedI, Nsym)
bitsQ = generar_prbs9(seedQ, Nsym)

# Generar la secuencia de simbolos QPSK (Codificacion)
simbolosI = np.array(generar_bpsk(bitsI))
simbolosQ = np.array(generar_bpsk(bitsQ))

# UpSampling
simbolos_upI = np.zeros(Nsym * os)
simbolos_upI[::os] = simbolosI
simbolos_upQ = np.zeros(Nsym * os)
simbolos_upQ[::os] = simbolosQ

# FILTRO POLIFASICO
t, h_filter = rcosine(beta, Tclk, os, Nbauds, True) 
t = t[0:os*Nbauds]
h_filter = h_filter[0:os*Nbauds] # para que los filtros de cada fase tengan la misma longitud

h_fixed = fixArray(NB, NBF, h_filter, signedMode, roundMode, saturateMode)

h_i = []  # filtro polifasico, OS filtros
for i in range(os):
    h_i.append(h_fixed[i::os])

H0, _, F0 = resp_freq(h_filter, Ts, Nfreqs)

filteredI = np.convolve(h_filter, simbolos_upI, "same")
filteredQ = np.convolve(h_filter, simbolos_upQ, "same")

# RECEPTOR ---------------------------------------------------------------

# DownSampling
muestrasI = filteredI[offset::os]
muestrasQ = filteredQ[offset::os]

# simbolos_estimadosI = slicer(muestrasI)
# simbolos_estimadosQ = slicer(muestrasQ)
simbolos_estimadosI = muestrasI
simbolos_estimadosQ = muestrasQ

# Decodificacion
bitsI_rec = deco_bpsk(simbolos_estimadosI)
bitsQ_rec = deco_bpsk(simbolos_estimadosQ)

# correlacion
correlacionI = np.correlate(simbolos_estimadosI, simbolosI, "same")
correlacionQ = np.correlate(simbolos_estimadosQ, simbolosQ, "same")

# ser
erroresI_sym = (Nsym - max(correlacionI)) // 2
erroresQ_sym = (Nsym - max(correlacionQ)) // 2

serI = erroresI_sym / Nsym  # symbol error rate
serQ = erroresQ_sym / Nsym  # symbol error rate

print("SER I: {}".format(serI))
print("SER Q: {}".format(serQ))

# ber
erroresI_bit = sum(abs(np.array(bitsI_rec) - np.array(bitsI)))
erroresQ_bit = sum(abs(np.array(bitsQ_rec) - np.array(bitsQ)))

berI = erroresI_bit / len(bitsI)
berQ = erroresQ_bit / len(bitsQ)

print("BER I: {}".format(berI))
print("BER Q: {}".format(berQ))


# GRAFICOS -----------------------------------------------------------------
if not showPlots:
    exit()


# RESPUESTA AL IMPULSO y FRECUENCIA
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

# BITS TRANSMITIDOS
plt.figure()
plt.suptitle("TX SIGNAL")
plt.subplot(2, 1, 1)
plt.plot(filteredI[offset:])
plt.stem(simbolos_upI, "r")
plt.xlim([100, 150])
plt.legend(["FilteredI", "UpsampledI"])
plt.grid()

plt.subplot(2, 1, 2)
plt.plot(filteredQ[offset:])
plt.stem(simbolos_upQ, "r")
plt.xlim([100, 150])
plt.legend(["FilteredQ", "UpsampledQ"])
plt.grid()


# CONSTELACION + OFFSETs
plt.figure()
plt.suptitle("Constelacion")
for i in range(os):
    plt.subplot(2, 2, i + 1)
    plt.grid()
    plt.plot(filteredI[100 + i :: os], filteredQ[100 + i :: os], ".")
    plt.legend(["Offset: {}".format(i)])

# EYE DIAGRAM
eyeDiagram(filteredI[offset:], 2, 100, os)
eyeDiagram(filteredQ[offset:], 2, 100, os)

# CORRELACION
plt.figure()
plt.suptitle("Correlacion")
plt.subplot(2, 1, 1)
plt.plot(correlacionI)
plt.legend("In Phase")
plt.grid()

plt.subplot(2, 1, 2)
plt.plot(correlacionQ)
plt.legend("Quadrature")
plt.grid()

plt.show()
