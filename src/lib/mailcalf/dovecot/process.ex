defmodule Mailcalf.Dovecot.Process do
  @moduledoc """
  Management of the external postgres process
  """
  require Logger
  use GenServer

  @impl true
  def init(_args) do
    port = start_dovecot()
    {:ok, [port: port]}
  end

  @impl true
  def terminate(_reason, [port: port]) do
    stop_dovecot(port)
  end

  @spec start_dovecot() :: port()
  def start_dovecot() do
    Logger.info("starting dovecot process")
    dovecot_path = System.find_executable("dovecot")
    Port.open({:spawn_executable, "/usr/local/bin/elixir_wrap_program.sh"}, [args: [dovecot_path, "-F"]])
  end

  @spec stop_dovecot(port()) :: true
  def stop_dovecot(port) do
    Logger.info("stopping dovecot process")
    Port.close(port)
  end
end
