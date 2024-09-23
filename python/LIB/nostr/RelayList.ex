defmodule DeeperServer.Nostr.RelayList do
  use Ecto.Schema
  import Ecto.Changeset

  schema "nostr_relay_lists" do
    field :name, :string
    field :description, :string
    field :relays, {:array, :string}

    timestamps()
  end

  @doc false
  def changeset(relay_list, attrs) do
    relay_list
    |> cast(attrs, [:name, :description, :relays])
    |> validate_required([:name, :relays])
  end
end