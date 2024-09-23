defmodule DeeperServerWeb.Nostr.RelayListController do
  use DeeperServerWeb, :controller

  alias DeeperServer.Nostr.RelayList

  action_fallback DeeperServerWeb.FallbackController

  def create(conn, %{"relay_list" => relay_list_params}) do
    with {:ok, relay_list} <- RelayList.create_changeset(%RelayList{}, relay_list_params) |> DeeperServer.Repo.insert() do
      conn
      |> put_status(:created)
      |> json(%{message: "Lista de relays criada com sucesso!", relay_list: relay_list})
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{message: "Falha ao criar lista de relays.", errors: changeset.errors})
    end
  end

  def show(conn, %{"id" => id}) do
    case DeeperServer.Repo.get(RelayList, id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{message: "Lista de relays não encontrada."})

      relay_list ->
        conn
        |> put_status(:ok)
        |> json(%{relay_list: relay_list})
    end
  end
end