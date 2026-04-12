cat > /usr/bin/ws-stunnel << 'END'
#!/usr/bin/python3
import socket, threading, sys

def proxy(client, target_host, target_port):
    target = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        target.connect((target_host, target_port))
    except:
        client.close()
        return

    def forward(source, destination):
        try:
            while True:
                data = source.recv(4096)
                if not data: break
                destination.sendall(data)
        except: pass
        finally:
            source.close()
            destination.close()

    threading.Thread(target=forward, args=(client, target)).start()
    threading.Thread(target=forward, args=(target, client)).start()

def main():
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 80
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(('0.0.0.0', port))
    server.listen(100)

    while True:
        client, addr = server.accept()
        try:
            data = client.recv(1024).decode('utf-8', errors='ignore')
            if "Upgrade: websocket" in data:
                client.send(b"HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n")
                proxy(client, '127.0.0.1', 22) # Diarahkan ke SSH Dropbear/OpenSSH
            else:
                client.close()
        except:
            client.close()

if __name__ == "__main__":
    main()
END
chmod +x /usr/bin/ws-stunnel
