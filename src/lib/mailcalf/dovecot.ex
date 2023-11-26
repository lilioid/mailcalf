defmodule Mailcalf.Dovecot do
  @moduledoc """
  A GenServer implementation for interactions with the dovecot mailbox daemon.
  """

  require Logger
  use GenServer

  @doc """
  Start this modules GenServer process
  """
  def start_link(init_args) do
    GenServer.start_link(__MODULE__, init_args, [name: Mailcalf.Dovecot])
  end

  @impl true
  def init(_init_arg = []) do
    Mailcalf.Dovecot.Config.render_config_files()
    port = Mailcalf.Dovecot.Process.start_dovecot()
    {:ok, [port: port]}
  end

  @impl true
  def terminate(_reason, [port: port]) do
    Mailcalf.Dovecot.Process.stop_dovecot(port)
  end

  # Server API handlers

  @impl true
  def handle_cast({:reconfigure}, [port: port]) do
    Mailcalf.Dovecot.Process.stop_dovecot(port)
    Mailcalf.Dovecot.Config.render_config_files()
    port = Mailcalf.Dovecot.Process.start_dovecot()
    {:noreply, [port: port]}
  end

  # Client API

  @doc """
  Reconfigure dovecot so that the config-files on disk
  """
  def reconfigure() do
    GenServer.cast(__MODULE__, {:reconfigure})
  end
end
