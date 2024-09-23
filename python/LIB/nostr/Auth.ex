defmodule DeeperServer.Nostr.Auth do
  @moduledoc """
  Módulo responsável pela autenticação e autorização de usuários no Deeper Server.
  """

  use DeeperServerWeb, :controller

  alias DeeperServer.Repo
  alias DeeperServer.Nostr.Key
  alias DeeperServer.Nostr.Event

  @spec authenticate_user(Plug.Conn.t(), map) :: Plug.Conn.t()
  def authenticate_user(conn, params) do
    with {:ok, key} <- find_key(params["public_key"]),
         {:ok, event} <- verify_event(params["event"], key) do
      conn
      |> put_session(:user_id, key.id)
      |> put_status(:ok)
      |> json(%{message: "Usuário autenticado com sucesso!", event: event})
    else
      {:error, reason} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{message: "Falha na autenticação: #{reason}"})
    end
  end

  @spec find_key(binary) :: {:ok, Key.t()} | {:error, atom}
  defp find_key(public_key) do
    case Repo.get_by(Key, public_key: public_key) do
      nil -> {:error, :key_not_found}
      key -> {:ok, key}
    end
  end

  @spec verify_event(map, Key.t()) :: {:ok, Event.t()} | {:error, atom}
  defp verify_event(event, key) do
    case Event.verify(event, key.public_key) do
      true ->
        event =
          event
          |> Map.put(:key_id, key.id)
          |> Event.create_changeset()
          |> Repo.insert!()

        {:ok, event}

      false ->
        {:error, :invalid_signature}
    end
  end
end
