defmodule DeeperServer.Nostr.FileMetadata do
  @moduledoc """
  Implementação do NIP-33: File Metadata.
  """

  alias DeeperServer.Nostr.Event

  @spec create_file_metadata_event(map, binary) :: map
  def create_file_metadata_event(file_metadata, private_key) do
    Event.build(30033, [
      {"file-sha256", [file_metadata["sha256"]]},
      {"file-name", [file_metadata["name"]]},
      {"file-size", [Integer.to_string(file_metadata["size"])]},
      {"file-type", [file_metadata["type"]]}
    ], Jason.encode!(file_metadata), private_key)
  end
end
