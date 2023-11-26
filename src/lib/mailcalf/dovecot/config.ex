defmodule Mailcalf.Dovecot.Config do
  require EEx
  require Logger

  @dovecot_dir "/etc/dovecot"

  def render_config_files() do
    config = Mailcalf.Config.get()
    Logger.debug("rendering dovecot config", [config: config])

    ensure_directory()
    write_main_config(config)
    write_oauth_args(config)
  end

  defp ensure_directory() do
    case File.mkdir(@dovecot_dir) do
      {:ok} -> :ok
      {:error, :eexist} -> :ok
      _ -> raise "cannot ensure that #{@dovecot_dir} exists"
    end
  end

  defp write_main_config(config) do
    File.open!(Path.join(@dovecot_dir, "dovecot.conf"), [:utf8, :write], fn file ->
      IO.write(file, render_main_config(config))
    end)
  end

  defp write_oauth_args(config) do
    File.open!(Path.join(@dovecot_dir, "oauth2-args.conf.ext"), [:utf8, :write], fn file ->
      IO.write(file, render_oauth_args(config))
    end)
  end

  EEx.function_from_file(:def, :render_main_config, Path.join([__DIR__, "templates", "dovecot.conf.eex"]), [:config])
  EEx.function_from_file(:def, :render_oauth_args, Path.join([__DIR__, "templates", "dovecot.conf.eex"]), [:config])
end
