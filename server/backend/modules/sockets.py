import socket

class TcpSocketClient:
    def __init__(self, address):
        self.client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.address = address

        if (address[0] == ''):
            self.server = self.client
            with self.server:
                self.server.bind(address)
                self.server.listen(1)
                self.client, self.address = self.server.accept()
            
        else:
            try:
                self.client.connect(address)
            except Exception as e:
                print("Failed connecting")
                print(e)


    def send_bytes(self, data, address):
        try:
            self.client.sendall(data)
        except Exception as e:
            print("Failed sending")
            print(e)

    def receive_bytes(self, size):
        data = b''
        try:
            data = b''
            while len(data) < size:
                data += self.client.recv(size-len(data))
        except Exception as e:
            print("Failed receiving")
            print(e)
        return data, self.address


class UdpSocketClient:
    MAX_PACKET_SIZE = 61444
    RECEIVE_TIMEOUT_S = 0.05 
    HEADER = b'001100101111000011'

    def __init__(self):
        self.client = socket.socket(socket.AF_INET, socket.SOCK_DGRAM) 
        self.client.settimeout(self.RECEIVE_TIMEOUT_S)

    def chunk_bytes(self, bytes):
        chunks = [bytes[i:i + self.MAX_PACKET_SIZE] for i in range(0, len(bytes), self.MAX_PACKET_SIZE)]
        return chunks

    def send_bytes(self, data, address):
        frame = self.HEADER + data
        chunks = self.chunk_bytes(frame)
        for chunk in chunks:
            try:
                self.client.sendto(chunk, address)
            except Exception as e:
                print("Failed sending")
                print(e)
                break

    def receive_bytes(self, size):
        address = ('', 0)
        frame = b''
        frame_size = size + len(self.HEADER)

        try:
            while len(frame) < frame_size:
                data_bytes, address = self.client.recvfrom(frame_size-len(frame))
                frame += data_bytes

        except TimeoutError:
            pass

        except Exception as e:
            print("Failed receiving")
            print(e)

        data = self.check_frame(frame, frame_size)
        return data, address


    def check_frame(self, frame:bytes, frame_size:int)->bytes:
        if (len(frame) != frame_size):
            return b''

        header = frame[:len(self.HEADER)]
        if (header != self.HEADER):
            return b''

        return frame[len(self.HEADER):]
