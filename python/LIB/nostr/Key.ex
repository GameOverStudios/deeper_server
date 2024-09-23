defmodule DeeperServer.Nostr.Key do
  @moduledoc """
  Schema para chaves públicas Nostr.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "nostr_keys" do
    field :public_key, :binary, primary_key: true
    field :created_at, :naive_datetime

    timestamps()
  end

  @doc false
  def changeset(key, attrs) do
    key
    |> cast(attrs, [:public_key, :created_at])
    |> validate_required([:public_key])
    |> unique_constraint(:public_key)
  end
end
