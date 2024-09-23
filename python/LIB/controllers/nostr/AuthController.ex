defmodule DeeperServerWeb.Nostr.AuthController do
  use DeeperServerWeb, :controller

  alias DeeperServer.Nostr.Auth

  action_fallback DeeperServerWeb.FallbackController

  def authenticate(conn, %{"public_key" => public_key, "event" => event}) do
    case Auth.authenticate_user(conn, %{"public_key" => public_key, "event" => event}) do
      {:ok, conn} -> conn
      {:error, conn} -> conn
    end
  end
end
