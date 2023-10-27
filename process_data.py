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


for i in range(len(data)):
    data[i] = fixedIntToFloat(data[i], 8, 7)

plt.figure()
plt.stem(data)
plt.plot(data, '--^r', linewidth=1.5, markersize=7)
plt.xlim(0, 50)
plt.ylim(-1.5, 1.5)
plt.xlabel("Samples")
plt.ylabel("Amplitude")
plt.title("Filter Output")
plt.grid()
plt.show()

f.close()
