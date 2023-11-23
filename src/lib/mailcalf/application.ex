defmodule Mailcalf.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MailcalfWeb.Telemetry,
      Mailcalf.Repo,
      {Ecto.Migrator,
        repos: Application.fetch_env!(:mailcalf, :ecto_repos),
        skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:mailcalf, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Mailcalf.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Mailcalf.Finch},
      # Start a worker by calling: Mailcalf.Worker.start_link(arg)
      # {Mailcalf.Worker, arg},
      # Start to serve requests, typically the last entry
      MailcalfWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Mailcalf.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MailcalfWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    # By default, sqlite migrations are run when using a release
    System.get_env("RELEASE_NAME") != nil
  end
end
