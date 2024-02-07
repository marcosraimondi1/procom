from modules.ethernet.sockets import UdpSocketClient
import numpy as np
import time 

RESOLUTION=(200,200)
SIM_LEN=100000
PORT=3001
ADDRESS=('172.16.0.236', PORT)

data = np.ones(RESOLUTION, dtype=np.uint8)

conn = UdpSocketClient()
conn.client.bind(('',PORT))
conn.client.settimeout(0.7)

dropped_datagrams = 0
time_avg = 0

for i in range(SIM_LEN):
    tic = time.time()
    conn.send_bytes(data.tobytes(), ADDRESS)
    recieved, _ = conn.receive_bytes(45000)
    toc = time.time()

    if (len(recieved) == 0):
        dropped_datagrams += 1
        continue

    throughput = 1/(toc-tic)

    time_avg = (toc-tic)/SIM_LEN
    
    print(f"{throughput} frame/s")

print("Sim Ended")
print(f"Throughput = {(SIM_LEN)/time_avg}")
print(f"Dropped = {dropped_datagrams}")


