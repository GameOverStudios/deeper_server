defmodule ElixirRanch.Protocols.EchoServer do
  use GenServer
  require Logger

  @behaviour :ranch_protocol
  @default_timeout 5000

  def start_link(ref, transport, opts \\ []) do
    server_opts = Application.get_env(:elixir_ranch, __MODULE__)[:server_opts] || []
    timeout = Keyword.get(opts, :timeout, @default_timeout)

    Logger.debug("Iniciando EchoServer com referência: #{inspect(ref)}")
    {:ok, :proc_lib.spawn_link(__MODULE__, :init, [{ref, transport, server_opts, timeout}])}
  end

  def init({ref, transport, _server_opts, timeout}) do
    {:ok, socket} = :ranch.handshake(ref)
    :ok = transport.setopts(socket, active: :once)
    Logger.debug("Conexão estabelecida com socket: #{inspect(socket)}")

    # Entra no loop do GenServer com o timeout e as configurações do servidor
    :gen_server.enter_loop(__MODULE__, [], {socket, transport}, timeout)
  end

  def handle_info({:tcp, socket, data}, {socket, transport} = state) do
    Logger.debug("Dados recebidos via TCP: #{inspect(data)}")
    :ok = transport.send(socket, data)
    Logger.debug("Dados enviados de volta via TCP: #{inspect(data)}")
    :ok = transport.setopts(socket, active: :once)
    {:noreply, state, @default_timeout}
  end

  def handle_info({:ssl, socket, data}, {socket, transport} = state) do
    Logger.debug("Dados recebidos via SSL: #{inspect(data)}")
    :ok = transport.send(socket, data)
    Logger.debug("Dados enviados de volta via SSL: #{inspect(data)}")
    :ok = transport.setopts(socket, active: :once)
    {:noreply, state, @default_timeout}
  end

  def handle_info({:tcp_closed, socket}, {socket, _} = state) do
    Logger.debug("Conexão TCP fechada para socket: #{inspect(socket)}")
    {:stop, :normal, state}
  end

  def handle_info({:ssl_closed, socket}, {socket, _} = state) do
    Logger.debug("Conexão SSL fechada para socket: #{inspect(socket)}")
    {:stop, :normal, state}
  end

  def handle_info(msg, state) do
    Logger.debug("Mensagem inesperada recebida: #{inspect(msg)}")
    {:noreply, state}
  end
end
