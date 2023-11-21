import socket
import numpy as np
from modules.globals import PORT, RESOLUTION
from modules.transformations import edgeDetection

def listen():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server:
        print("listening....")
        server.bind(('', PORT))
        server.listen(1)
        conn, addr = server.accept()
        with conn:
            print('Connected by', addr)
            while True:
                bytes = b''
                while len(bytes) < (RESOLUTION[0]*RESOLUTION[1]):
                    bytes += conn.recv(RESOLUTION[0]*RESOLUTION[1]-len(bytes))

                
                img = np.frombuffer(bytes, dtype=np.uint8).reshape(RESOLUTION)

                new_img = edgeDetection(img)

                conn.sendall(new_img.tobytes())

while(True):
    try:
        listen()
    except Exception as e:
        print(e)

