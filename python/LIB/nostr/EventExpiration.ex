defmodule DeeperServer.Nostr.EventExpiration do
  @moduledoc """
  Implementação do NIP-40: Expiration Timestamp.
  """

  alias DeeperServer.Nostr.Event

  @spec create_event_with_expiration(integer, list(Event.tag), String.t(), binary, DateTime.t()) :: map
  def create_event_with_expiration(kind, tags, content, private_key, expiration_datetime) do
    expiration_timestamp = DateTime.to_unix(expiration_datetime)

    Event.build(kind, tags ++ [
      {"expiration", [Integer.to_string(expiration_timestamp)]}
    ], content, private_key)
  end
end
