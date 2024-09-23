defmodule DeeperServer.Nostr.EventTreatmentTest do
  use ExUnit.Case

  alias DeeperServer.Nostr.EventTreatment
  alias DeeperServer.Nostr.Event
  alias DeeperServer.Factory

  test "process_event/2 processa um evento de acordo com o NIP-16" do
    event = Factory.build(:nostr_event)
    relay_metadata = %{}

    processed_event = EventTreatment.process_event(event, relay_metadata)

    # Asserções para verificar o evento processado
    assert processed_event == event
  end
end
