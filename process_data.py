import matplotlib.pyplot as plt

def fixedIntToFloat(intValue, nBits, nFrac):
    signo = (intValue >> (nBits-1)) & 1
    signo = -1 if signo == 1 else 1

    # parte entera
    parteEntera = 0
    if nBits-nFrac > 1:
        parteEntera = intValue & ~(1<<(nBits-1)) # quito el bit de signo
        parteEntera = parteEntera >> nFrac

    # parte fraccionaria
    parteFrac = 0
    fracBits = intValue & ((1<<nFrac)-1)

    for i in range(nFrac):
        bit_i = (fracBits >> (nFrac-i-1)) & 1
        parteFrac += bit_i/(2**(i+1))

    value = signo*(parteEntera + parteFrac)
    
    return value

f = open("./data.txt", mode='r')

line = f.readline()

data = []
while line:
    data += list(map(lambda x: int(x), line.split(",")))
    line = f.readline()

dataI = []
dataQ = []
for i in range(len(data)):
    dataI.append(data[i] & 0xFF)
    dataQ.append((data[i] >> 8) & 0xFF)

for i in range(len(data)):
    dataI[i] = fixedIntToFloat(dataI[i], 8, 7)
    dataQ[i] = fixedIntToFloat(dataQ[i], 8, 7)

plt.figure()
plt.subplot(2,1,1)
plt.title("Filter Output I")
plt.stem(dataI)
plt.plot(dataI, '--^r', linewidth=1.5, markersize=7)
plt.xlim(0, 50)
plt.ylim(-1.5, 1.5)
plt.ylabel("Amplitude")
plt.grid()

plt.subplot(2,1,2)
plt.title("Filter Output Q")
plt.stem(dataQ)
plt.plot(dataQ, '--^r', linewidth=1.5, markersize=7)
plt.xlim(0, 50)
plt.ylim(-1.5, 1.5)
plt.xlabel("Samples")
plt.ylabel("Amplitude")
plt.grid()

plt.show()

f.close()
