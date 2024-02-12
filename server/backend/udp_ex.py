from modules.ethernet.sockets import UdpSocketClient

PORT=3001
ADDRESS=('172.16.0.236', PORT)

conn = UdpSocketClient()
conn.client.bind(('',PORT)) 

while(True):
    user_in = input("To Send (exit to end): ")

    if user_in == "exit":
        break

    conn.send_bytes(user_in.encode('utf-8'), ADDRESS)
    recieved, _ = conn.receive_bytes(1024)

    print("received: ", recieved.decode('utf-8'))

