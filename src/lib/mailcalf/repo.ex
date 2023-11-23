defmodule Mailcalf.Repo do
  use Ecto.Repo,
    otp_app: :mailcalf,
    adapter: Ecto.Adapters.SQLite3
end
