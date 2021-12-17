defmodule Strd.Repo do
  use Ecto.Repo,
    otp_app: :strd,
    adapter: Ecto.Adapters.Postgres
end
