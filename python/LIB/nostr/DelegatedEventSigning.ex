defmodule DeeperServer.Nostr.DelegatedEventSigning do
  @moduledoc """
  Implementação do NIP-26: Delegated Event Signing.
  """

  alias DeeperServer.Nostr.Event

  @spec create_delegated_event(integer, list(Event.tag), String.t(), binary, binary, map) :: map
  def create_delegated_event(kind, tags, content, delegator_private_key, delegatee_public_key, conditions) do
    delegation_token =
      Event.build(30004, [
        {"delegatee", [delegatee_public_key]},
        {"conditions", [Jason.encode!(conditions)]}
      ], "", delegator_private_key)

    event = Event.build(kind, tags, content, delegatee_public_key)

    %{
      delegation_token: delegation_token,
      event: event
    }
  end
end
