# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :mailcalf,
  ecto_repos: [Mailcalf.Repo],
  generators: [timestamp_type: :utc_datetime],
  mailserver: %{
    postmaster_address: "postmaster@ftsell.de",
    hostname: "example.localhost",
    storage_dir: "/usr/local/src/mailcalf/dev_storage",
    tls: %{},
    imap: %{
      enable: true,
      listeners: ["imap"]
    },
    oauth: %{
      debug: false,
      grant_url: "https://example.com/token",
      introspection_url: "https://example.com/introspect",
      client_id: "example-client",
      client_secret: "foobar123",
      username_attribute: "preferred_username",
    },
    extra: %{},
  }

# Configures the endpoint
config :mailcalf, MailcalfWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Phoenix.Endpoint.Cowboy2Adapter,
  render_errors: [
    formats: [html: MailcalfWeb.ErrorHTML, json: MailcalfWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Mailcalf.PubSub,
  live_view: [signing_salt: "9DtJ3C9a"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :mailcalf, Mailcalf.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.3.2",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
