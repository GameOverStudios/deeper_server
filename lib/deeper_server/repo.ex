defmodule DeeperServer.Repo do
  use Ecto.Repo,
    otp_app: :deeper_server,
    adapter: Ecto.Adapters.Postgres
end
