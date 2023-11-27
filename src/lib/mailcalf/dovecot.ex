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
    Mailcalf.Dovecot.Config.write_config_files()
    port = Mailcalf.Dovecot.Process.start_dovecot()
    monitor = Port.monitor(port)
    {:ok, [port: port, monitor: monitor]}
  end

  @impl true
  def terminate(:dovecot_quit, []) do end
  def terminate(_reason, [port: port]) do
    Mailcalf.Dovecot.Process.stop_dovecot(port)
  end

  # Server API handlers

  @impl true
  def handle_cast({:reconfigure}, [port: port, monitor: monitor]) do
    Port.demonitor(monitor)
    Mailcalf.Dovecot.Process.stop_dovecot(port)
    Mailcalf.Dovecot.Config.write_config_files()
    port = Mailcalf.Dovecot.Process.start_dovecot()
    monitor = Port.monitor(port)
    {:noreply, [port: port, monitor: monitor]}
  end

  # A handler for when the port monitor detects that the dovecot process has quit
  @impl true
  def handle_info({:DOWN, monitor, :port, port, reason}, [port: port, monitor: monitor]) do
    Logger.error("dovecot has quit unexpectedly", [reason: reason])
    Port.demonitor(monitor)
    {:stop, :dovecot_quit, []}
  end

  # A handler for when dovecot sends messages on stdout
  def handle_info({_src, {:data, msg}}, state) do
    IO.puts(msg)
    {:noreply, state}
  end

  # Client API

  @doc """
  Reconfigure dovecot so that the config-files on disk
  """
  def reconfigure() do
    GenServer.cast(__MODULE__, {:reconfigure})
  end
end
