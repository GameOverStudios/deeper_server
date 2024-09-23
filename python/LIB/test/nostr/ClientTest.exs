defmodule DeeperServer.Nostr.ClientTest do
  use ExUnit.Case, async: true

  alias DeeperServer.Nostr.Client
  alias DeeperServerWeb.Endpoint

  import Mox

  setup :verify_on_exit!

  test "connect/1 conecta a um relay" do
    relay_url = "wss://relay.example.com"
    pid = self()

    expect(Endpoint, :start_link, fn -> {:ok, pid} end)

    assert {:ok, %{pid: ^pid, url: ^relay_url}} = Client.connect(relay_url)
  end

  test "publish_event/2 publica um evento" do
    relay_pid = self()
    event = %{}

    expect(Endpoint, :broadcast, fn ^relay_pid, "nostr:lobby", "event:published", %{event: _} -> :ok end)

    assert :ok = Client.publish_event(%{pid: relay_pid}, event)
  end

  test "subscribe_to_events/2 assina eventos" do
    relay_pid = self()
    filters = [%{}]

    expect(Endpoint, :broadcast, fn ^relay_pid, "nostr:lobby", "events:subscribe", %{filters: ^filters} -> :ok end)

    assert :ok = Client.subscribe_to_events(%{pid: relay_pid}, filters)
  end

  test "send_eose/2 envia uma mensagem EOSE" do
    relay_pid = self()
    subscription_id = "subscription-123"

    expect(Endpoint, :broadcast, fn ^relay_pid, "nostr:lobby", "eose:sent", %{subscription_id: ^subscription_id} -> :ok end)

    assert :ok = Client.send_eose(relay_pid, subscription_id)
  end
end
