from modules.ethernet.sockets import UdpSocketClient
from modules.ethernet.eth_process import reorder_pixels
import numpy as np

PORT=3001
ADDRESS=('172.16.0.236', PORT)
KERNEL = 0

conn = UdpSocketClient()
conn.client.bind(('',PORT)) 

count = 129
RESOLUTION = (198,14)
img = np.zeros(RESOLUTION, dtype=np.uint8)
for i in range(img.shape[0]-8, img.shape[0]):
    for j in range(img.shape[1]):
        img[i][j] = count % 256
        if (count != 256):
            count += 1

padded = np.pad(img, pad_width=1, constant_values=0)
padded.astype(np.uint8)

reordered_bytes = bytes()
for i in range(0, padded.shape[0], 4):
    reordered_bytes += padded[:,i:i+4].tobytes()

metadata = np.array(range(16),dtype=np.uint8)
metadata[0] = KERNEL
data_to_send = metadata.tobytes() + reordered_bytes

conn.send_bytes(data_to_send, ADDRESS)

received, _ = conn.receive_bytes(len(data_to_send))

metadata_recv = received[0:16]
img_recv = reorder_pixels(received[16:], (RESOLUTION[0]+2, RESOLUTION[1]+2))

img_recv = img_recv[1:-1,2:]

for i in range(img.shape[0]-10, img.shape[0]):
    print(f"{i}. S: ", img[i])
    print(f"{i}. R: ", img_recv[i])
