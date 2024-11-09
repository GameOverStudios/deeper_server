import socket

def test_echo_server(host='localhost', port=5556, message="Hello, Ranch!"):
    try:
        # Cria o socket TCP
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            # Conecta ao servidor de eco
            s.connect((host, port))
            print(f"Conectado ao servidor {host}:{port}")

            # Envia a mensagem
            s.sendall(message.encode())
            print(f"Mensagem enviada: {message}")

            # Recebe a resposta do servidor
            data = s.recv(1024)
            print(f"Resposta recebida: {data.decode()}")

    except Exception as e:
        print(f"Erro ao conectar ao servidor: {e}")

# Executa o teste
test_echo_server()