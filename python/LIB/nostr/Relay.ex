defmodule DeeperServer.Nostr.Relay do
  @moduledoc """
  Schema para informações de relays Nostr.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "nostr_relays" do
    field :url, :string, primary_key: true
    field :name, :string
    field :description, :string
    field :pubkey, :string
    field :contact, :string
    field :supported_nips, {:array, :string}
    field :software, :string
    field :version, :string

    timestamps()
  end

  @doc false
  def changeset(relay, attrs) do
    relay
    |> cast(attrs, [:url, :name, :description, :pubkey, :contact, :supported_nips, :software, :version])
    |> validate_required([:url])
    |> unique_constraint(:url)
  end
end
