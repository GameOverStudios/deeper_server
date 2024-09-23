defmodule DeeperServer.Nostr.Bech32Encoding do
  @moduledoc """
  Implementação do NIP-19: bech32-encoded entities.
  """

  @spec encode(binary, String.t()) :: String.t()
  def encode(data, hrp) do
    Bech32.encode(hrp, Bech32.convert_bits(data, 8, 5, pad: false))
  end

  @spec decode(String.t()) :: {:ok, {String.t(), binary}} | {:error, atom}
  def decode(bech32_string) do
    case Bech32.decode(bech32_string) do
      {:ok, {hrp, data}} ->
        {:ok, {hrp, Bech32.convert_bits(data, 5, 8, pad: false)}}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
