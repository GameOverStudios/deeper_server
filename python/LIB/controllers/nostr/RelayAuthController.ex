defmodule DeeperServerWeb.Nostr.RelayAuthController do
  use DeeperServerWeb, :controller

  alias DeeperServer.Nostr.Event

  action_fallback DeeperServerWeb.FallbackController

  def authenticate(conn, %{"event" => event_params}) do
    with {:ok, relay_key} <- find_relay_key(event_params["pubkey"]),
         {:ok, event} <- verify_event(event_params, relay_key) do
      conn
      |> put_status(:ok)
      |> json(%{message: "Relay autenticado com sucesso!", event: event})
    else
      {:error, reason} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{message: "Falha na autenticação do relay: #{reason}"})
    end
  end

  defp find_relay_key(public_key) do
    # ... lógica para buscar a chave pública do relay no banco de dados ...
  end

  defp verify_event(event, relay_key) do
    case Event.verify(event, relay_key.public_key) do
      true ->
        # ... lógica para processar o evento de autenticação do relay ...
        {:ok, :valid_signature}

      false ->
        {:error, :invalid_signature}
    end
  end
end
