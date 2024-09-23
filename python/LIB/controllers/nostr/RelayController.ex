defmodule DeeperServerWeb.Nostr.RelayController do
  use DeeperServerWeb, :controller

  alias DeeperServer.Nostr.RelayMetadata

  action_fallback DeeperServerWeb.FallbackController

  def show(conn, %{"relay_url" => relay_url}) do
    case RelayMetadata.get_relay_information(relay_url) do
      {:ok, relay_info} ->
        conn
        |> put_status(:ok)
        |> json(%{relay: relay_info})

      {:error, reason} ->
        conn
        |> put_status(:not_found)
        |> json(%{message: "Falha ao obter informações do relay: #{reason}"})
    end
  end

  def index(conn, _params) do
    relays = Application.get_env(:deeper_server, :nostr)[:relays]

    conn
    |> put_status(:ok)
    |> json(%{relays: relays})
  end

end
