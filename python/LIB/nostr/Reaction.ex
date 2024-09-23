defmodule DeeperServer.Nostr.Reaction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "nostr_reactions" do
    field :event_id, :binary
    field :public_key, :binary
    field :reaction, :string

    timestamps()
  end

  @doc false
  def changeset(reaction, attrs) do
    reaction
    |> cast(attrs, [:event_id, :public_key, :reaction])
    |> validate_required([:event_id, :public_key, :reaction])
  end
end