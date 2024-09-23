defmodule DeeperServer.Nostr.GenericTagQueries do
  @moduledoc """
  Implementação do NIP-12: Generic Tag Queries.
  """

  alias DeeperServer.Nostr.Event

  @spec filter_events(list(map), list(Event.tag)) :: list(map)
  def filter_events(events, filters) do
    Enum.filter(events, fn event ->
      Enum.all?(filters, fn filter ->
        case filter do
          {"id", [id]} -> event["id"] == id
          {"kind", [kind]} -> event["kind"] == String.to_integer(kind)
          {"authors", authors} -> Enum.member?(authors, event["pubkey"])
          {"#e", event_ids} -> Enum.member?(event_ids, event["id"])
          {"#p", pubkeys} -> Enum.any?(pubkeys, &Enum.member?(&1, get_p_tags(event)))
          _ -> true
        end
      end)
    end)
  end

  @spec get_p_tags(map) :: list(String.t())
  defp get_p_tags(event) do
    Enum.flat_map(event["tags"], fn
      {"p", pubkeys} -> pubkeys
      _ -> []
    end)
  end
end
