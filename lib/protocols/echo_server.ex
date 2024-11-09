defmodule ElixirRanch.Protocols.EchoServer do
  use GenServer
  require Logger

  @behaviour :ranch_protocol
  @timeout 5000

  def start_link(ref, transport, _opts) do
    opts = [
      :link,
      :monitor,
      {:priority, :high},
      {:fullsweep_after, 10},
      {:min_heap_size, 512},
      {:min_bin_vheap_size, 2048},
      {:max_heap_size, %{size: 10000, kill: true, error_logger: false}},
      {:message_queue_data, :off_heap}
    ]
    Logger.debug("Iniciando EchoServer com referência: #{inspect(ref)}")
    {:ok, :proc_lib.spawn_link(__MODULE__, :init, [{ref, transport, opts}])}
  end

  def init({ref, transport, _opts}) do
    {:ok, socket} = :ranch.handshake(ref)
    :ok = transport.setopts(socket, active: :once)
    Logger.debug("Conexão estabelecida com socket: #{inspect(socket)}")
    :gen_server.enter_loop(__MODULE__, [], {socket, transport}, @timeout)
  end

  def handle_info({:tcp, socket, data}, {socket, transport} = state) do
    Logger.debug("Dados recebidos via TCP: #{inspect(data)}")
    :ok = transport.send(socket, data)
    Logger.debug("Dados enviados de volta via TCP: #{inspect(data)}")
    :ok = transport.setopts(socket, active: :once)
    {:noreply, state, @timeout}
  end

  def handle_info({:ssl, socket, data}, {socket, transport} = state) do
    Logger.debug("Dados recebidos via SSL: #{inspect(data)}")
    :ok = transport.send(socket, data)
    Logger.debug("Dados enviados de volta via SSL: #{inspect(data)}")
    :ok = transport.setopts(socket, active: :once)
    {:noreply, state, @timeout}
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
