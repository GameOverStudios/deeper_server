defmodule DeeperServer.Nostr.LongFormContent do
  @moduledoc """
  Implementação do NIP-23: Long-form Content.
  """

  alias DeeperServer.Nostr.Event

  @spec create_long_form_event(String.t(), binary) :: map
  def create_long_form_event(content, private_key) do
    Event.build(30023, [], content, private_key)
  end
end
