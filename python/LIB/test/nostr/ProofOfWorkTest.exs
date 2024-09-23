defmodule DeeperServer.Nostr.ProofOfWorkTest do
  use ExUnit.Case

  alias DeeperServer.Nostr.ProofOfWork

  describe "calculate_pow/2" do
    test "calcula o nonce correto para a dificuldade dada" do
      data = "teste"
      difficulty = 5
      nonce = ProofOfWork.calculate_pow(data, difficulty)
      assert ProofOfWork.verify_pow(data, nonce, difficulty)
    end
  end

  describe "verify_pow/3" do
    test "verifica o Proof of Work corretamente" do
      data = "teste"
      difficulty = 5
      nonce = ProofOfWork.calculate_pow(data, difficulty)
      assert ProofOfWork.verify_pow(data, nonce, difficulty)
    end

    test "retorna falso para um nonce inválido" do
      data = "teste"
      difficulty = 5
      nonce = 123
      refute ProofOfWork.verify_pow(data, nonce, difficulty)
    end
  end
end
