defmodule DeeperServer.Nostr.Event do
  @moduledoc """
  Schema para eventos Nostr.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias DeeperServer.Nostr.Key

  @typedoc """
  Tipo para tags de evento Nostr.
  """
  @type tag :: {String.t(), list(String.t())}

  schema "nostr_events" do
    field :created_at, :utc_datetime
    field :kind, :integer
    field :tags, {:array, :map}
    field :content, :string
    field :sig, :binary
    belongs_to :key, Key, foreign_key: :public_key, references: :public_key, type: :binary

    timestamps()
  end

   @doc false
   def changeset(event, attrs) do
    event
    |> cast(attrs, [:public_key, :created_at, :kind, :tags, :content, :sig])
    |> validate_required([:public_key, :created_at, :kind, :tags, :content, :sig])
    |> validate_length(:content, max: 65535) # Adiciona validação de tamanho para o conteúdo
  end

  @spec serialize(Event.t()) :: map
  def serialize(event) do
    %{
      id: event.id,
      pubkey: event.public_key,
      created_at: DateTime.to_unix(event.created_at),
      kind: event.kind,
      tags: event.tags,
      content: event.content,
      sig: event.sig
    }
  end

  @spec verify(map, binary) :: boolean
  def verify(event, public_key) do
    serialized_event =
      event
      |> Map.take([:id, :pubkey, :created_at, :kind, :tags, :content])
      |> Jason.encode!()

    Nostr.verify_signature(serialized_event, event["sig"], public_key)
  end

  @spec apply_event_count_expiration(map, integer) :: map
  def apply_event_count_expiration(event, event_count) do
    Map.put(event, "expiration_event_count", event_count)
  end

  @spec extract_mentions(String.t()) :: list(binary)
  def extract_mentions(content) do
    Regex.scan(~r/(?<=^@)npub1[a-z0-9]+/i, content)
    |> List.flatten()
    |> Enum.map(&Base.decode16!(&1, case: :lower))
  end

  @spec get_d_tag(list) :: String.t() | nil
  def get_d_tag(tags) do
    Enum.find_value(tags, fn
      {"d", [d_tag]} -> d_tag
      _ -> nil
    end)
  end

  @spec is_replaceable?(Event.t()) :: boolean
  def is_replaceable?(event) do
    event.kind in [0, 1, 2, 3, 4, 5, 7, 40, 41, 42]
  end

  @spec is_parameterized_replaceable?(Event.t()) :: boolean
  def is_parameterized_replaceable?(event) do
    event.kind in [10000, 10001, 10002]
  end

  @spec match_filters?(map, list(map)) :: boolean
  def match_filters?(event, filters) do
    Enum.all?(filters, fn filter ->
      case filter do
        %{"ids" => ids} -> Enum.member?(ids, event["id"])
        %{"kinds" => kinds} -> Enum.member?(event["kind"], kinds)
        %{"authors" => authors} -> Enum.member?(authors, event["pubkey"])
        # ... outros filtros ...
      end
    end)
  end

end
