# config/config.exs
import Config

config :elixir_ranch, ElixirRanch.Protocols.EchoServer,
  server_opts: [
    :link,
    :monitor,
    {:priority, :high},
    {:fullsweep_after, 10},
    {:min_heap_size, 512},
    {:min_bin_vheap_size, 2048},
    {:max_heap_size, %{size: 10000, kill: true, error_logger: false}},
    {:message_queue_data, :off_heap}
  ]