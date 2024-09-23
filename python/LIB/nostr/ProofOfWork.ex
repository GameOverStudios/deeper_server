defmodule DeeperServer.Nostr.ProofOfWork do
  @moduledoc """
  Implementação do NIP-13: Proof of Work.
  """

  @spec calculate_pow(String.t(), integer, integer) :: binary
  def calculate_pow(data, difficulty, nonce \\ 0) do
    hash = :crypto.hash(:sha256, data <> Integer.to_string(nonce)) |> Base.encode16(case: :lower)

    if String.starts_with?(hash, String.duplicate("0", difficulty)) do
      nonce
    else
      calculate_pow(data, difficulty, nonce + 1)
    end
  end

  @spec verify_pow(String.t(), binary, integer) :: boolean
  def verify_pow(data, nonce, difficulty) do
    hash = :crypto.hash(:sha256, data <> Integer.to_string(nonce)) |> Base.encode16(case: :lower)
    String.starts_with?(hash, String.duplicate("0", difficulty))
  end
end
