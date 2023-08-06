import numpy as np
import matplotlib.pyplot as plt
from prbs9 import generar_bpsk, generar_prbs9, deco_bpsk
from rcosine import rcosine, resp_freq, eyeDiagram

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

Fclk = 100e6  # Frecuencia de Reloj [Hz]
os = 4  # Oversampling Factor
beta = 0.5  # Factor de roll-off
Nbauds = 6  # Cantidad de simbolos que entran en el filtro
Nsym = 1000  # Cantidad de simbolos a transmitir
seedI = 0x1AA  # Semilla para el generador de PRBS9 parte real
seedQ = 0x1FE  # Semilla para el generador de PRBS9 parte imaginaria
Nfreqs = 256  # Cantidad de frecuencias a evaluar (para la respuesta en frecuencia)
Tclk = 1 / Fclk  # Periodo de Reloj [s]
Ts = Tclk / os  # Frecuencia de muestreo

showPlots = True

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

# Filtro de Coseno Alzado
t, h_filter = rcosine(beta, Tclk, os, Nbauds, False)

H0, _, F0 = resp_freq(h_filter, Ts, Nfreqs)

filteredI = np.convolve(h_filter, simbolos_upI, "same")
filteredQ = np.convolve(h_filter, simbolos_upQ, "same")

# RECEPTOR ---------------------------------------------------------------

# DownSampling
offset = 0
simbolos_downI = filteredI[offset::os]
simbolos_downQ = filteredQ[offset::os]

# Decodificacion
bitsI_rec = deco_bpsk(simbolos_downI)
bitsQ_rec = deco_bpsk(simbolos_downQ)

# correlacion
correlacionI = np.correlate(simbolos_downI, simbolosI, "same")
correlacionQ = np.correlate(simbolos_downQ, simbolosQ, "same")

# ser
erroresI_sym = (Nsym - max(correlacionI)) // 2
erroresQ_sym = (Nsym - max(correlacionQ)) // 2

serI = erroresI_sym / Nsym # symbol error rate
serQ = erroresQ_sym / Nsym # symbol error rate

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
plt.xlim([0, 50])
plt.legend(["FilteredI", "UpsampledI"])
plt.grid()

plt.subplot(2, 1, 2)
plt.plot(filteredQ[offset:])
plt.stem(simbolos_upQ, "r")
plt.xlim([0, 50])
plt.legend(["FilteredQ", "UpsampledQ"])
plt.grid()


# CONSTELACION + OFFSETs
plt.figure()
plt.suptitle("Constelacion")
for i in range(os):
    plt.subplot(2, os//2, i + 1)
    plt.grid()
    plt.plot(filteredI[i :: os], filteredQ[i :: os], ".")
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
