defmodule DeeperServer.Nostr.Client do
  @moduledoc """
  Cliente para interagir com relays Nostr.
  """

  alias DeeperServer.Nostr.Event
  alias DeeperServerWeb.Endpoint

  @spec connect(String.t()) :: {:ok, pid}
  def connect(relay_url) do
    {:ok, pid} = Endpoint.start_link()
    {:ok, %{pid: pid, url: relay_url}}
  end

  @spec publish_event(map, Event.t()) :: :ok
  def publish_event(%{pid: pid, url: _relay_url}, event) do
    DeeperServerWeb.Endpoint.broadcast(pid, "nostr:lobby", "event:published", %{event: Event.serialize(event)})
  end

  @spec subscribe_to_events(map, list(map)) :: :ok
  def subscribe_to_events(%{pid: pid, url: _relay_url}, filters) do
    DeeperServerWeb.Endpoint.broadcast(pid, "nostr:lobby", "events:subscribe", %{filters: filters})
  end

  @spec send_eose(pid, String.t()) :: :ok
  def send_eose(pid, subscription_id) do
    DeeperServerWeb.Endpoint.broadcast(pid, "nostr:lobby", "eose:sent", %{subscription_id: subscription_id})
  end

  defp generate_subscription_id do
    prefix = Application.get_env(:deeper_server, :nostr)[:subscription_id_prefix] # Busca o prefixo da configuração
    "#{prefix}#{:rand.uniform(99999999)}"
  end

end
