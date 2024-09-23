defmodule DeeperServer.Nostr.RelayMetadata do
  @moduledoc """
  Implementação do NIP-11: Relay Information Document.
  """

  alias DeeperServer.Nostr.Relay

  @spec get_relay_information(String.t()) :: {:ok, map} | {:error, atom}
  def get_relay_information(relay_url) do
    with {:ok, response} <- Finch.build(:get, relay_url <> "/.well-known/nostr.json") |> Finch.request(),
         {:ok, body} <- Jason.decode(response.body) do
      {:ok, body}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec create_relay(map) :: {:ok, Relay.t()} | {:error, Ecto.Changeset.t()}
  def create_relay(relay_info) do
    Relay.changeset(%Relay{}, relay_info) |> DeeperServer.Repo.insert()
  end
end
