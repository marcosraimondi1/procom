import numpy as np
import matplotlib.pyplot as plt
from prbs9 import generar_bpsk
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
Ntaps = 16  # Cantidad de coeficientes del filtro
Nsym = 1000  # Cantidad de simbolos a transmitir
seedI = 0x1AA  # Semilla para el generador de PRBS9 parte real
seedQ = 0x1FE  # Semilla para el generador de PRBS9 parte imaginaria
Nfreqs = 256  # Cantidad de frecuencias a evaluar (para la respuesta en frecuencia)
Tclk = 1 / Fclk  # Periodo de Reloj [s]
Ts = Tclk / os  # Frecuencia de muestreo

# TRANSMISOR ---------------------------------------------------------------

# Generar la secuencia de simbolos QPSK
simbolosI = np.array(generar_bpsk(seedI, Nsym))
simbolosQ = np.array(generar_bpsk(seedQ, Nsym))

# UpSampling
simbolos_upI = np.zeros(Nsym * os)
simbolos_upI[::os] = simbolosI
simbolos_upQ = np.zeros(Nsym * os)
simbolos_upQ[::os] = simbolosQ

# Filtro de Coseno Alzado
t, h_filter = rcosine(beta, Tclk, os, Ntaps, False)

H0, _, F0 = resp_freq(h_filter, Ts, Nfreqs)

filteredI = np.convolve(h_filter, simbolos_upI, "same")
filteredQ = np.convolve(h_filter, simbolos_upQ, "same")

# RECEPTOR ---------------------------------------------------------------

# DownSampling
offset = 1
simbolos_downI = filteredI[offset::os]
simbolos_downQ = filteredQ[offset::os]

# Ber
ber = sum(abs((simbolos_downI != simbolosI) ^ (simbolos_downQ != simbolosQ))) / Nsym

# correlacion
correlacion = np.correlate(simbolos_downI, simbolosI, "same")

print("BER: {}".format(ber))


# GRAFICOS -----------------------------------------------------------------
noPlots = False
if noPlots:
    exit()


# RESPUESTA AL IMPULSO
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
plt.title("TX SIGNAL")
plt.plot(filteredI[offset:])
plt.stem(simbolos_upI, "r")
plt.xlim([100, 150])
plt.legend(["Filtered", "Upsampled"])
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

# CORRELACION
plt.figure()
plt.title("Correlacion")
plt.plot(correlacion)
plt.grid()
plt.show()

plt.show()
