defmodule DeeperServerWeb.Nostr.KeyController do
  use DeeperServerWeb, :controller

  alias DeeperServer.Nostr.Key

  action_fallback DeeperServerWeb.FallbackController

  def create(conn, %{"public_key" => public_key}) do
    case Key.create_changeset(%Key{}, %{public_key: public_key}) |> DeeperServer.Repo.insert() do
      {:ok, key} ->
        conn
        |> put_status(:created)
        |> json(%{message: "Chave pública registrada com sucesso!", key: key})
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{message: "Falha ao registrar chave pública.", errors: changeset.errors})
    end
  end

  def show(conn, %{"public_key" => public_key}) do
    case DeeperServer.Repo.get_by(Key, public_key: public_key) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{message: "Chave pública não encontrada."})
      key ->
        conn
        |> put_status(:ok)
        |> json(%{key: key})
    end
  end
end