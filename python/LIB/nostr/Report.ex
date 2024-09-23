defmodule DeeperServer.Nostr.Report do
  use Ecto.Schema
  import Ecto.Changeset

  schema "nostr_reports" do
    field :event_id, :binary
    field :public_key, :binary
    field :reason, :string

    timestamps()
  end

  @doc false
  def changeset(report, attrs) do
    report
    |> cast(attrs, [:event_id, :public_key, :reason])
    |> validate_required([:event_id, :public_key, :reason])
  end
end