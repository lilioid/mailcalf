defmodule Mailcalf.Dovecot.Config do
  require EEx
  require Logger

  @dovecot_dir "/etc/dovecot"

  def write_config_files() do
    config = Mailcalf.Config.get()
    Logger.debug("rendering dovecot config", [config: config])

    ensure_directories([
      @dovecot_dir,
      Path.join(@dovecot_dir, "sieve"),
      Path.join(@dovecot_dir, "sieve_extprograms")
    ])
    write_file("dovecot.conf", render_main_config(config))
    write_file("dovecot-oauth2.conf.ext", render_oauth_args(config))
    write_file("sieve/file_spam.sieve", render_file_spam())
    write_file("sieve/report_ham.sieve", render_report_ham())
    write_file("sieve/report_spam.sieve", render_report_spam())
    write_file("sieve_extprograms/rspamd_learn_ham.sh", render_rspamd_learn_ham(), 0o755)
    write_file("sieve_extprograms/rspamd_learn_spam.sh", render_rspamd_learn_spam(), 0o755)
  end

  defp ensure_directories([]) do end
  defp ensure_directories([dir | remainder]) do
    Logger.debug("ensuring that #{dir} exists")
    case File.mkdir(dir) do
      :ok -> ensure_directories(remainder)
      {:error, :eexist} -> ensure_directories(remainder)
      result -> raise "cannot ensure that #{dir} exists: #{inspect(result)}"
    end
  end

  defp write_file(path, content) do
    Logger.debug("writing dovecot config file #{path}")
    File.open!(Path.join(@dovecot_dir, path), [:utf8, :write], fn file ->
      IO.write(file, content)
    end)
  end

  defp write_file(path, content, mode) do
    write_file(path, content)
    File.chmod!(Path.join(@dovecot_dir, path), mode)
  end

  # Embedded Files and Templates
  @priv_configs Path.join([:code.priv_dir(:mailcalf), "configs", "dovecot"])
  EEx.function_from_file(:def, :render_main_config, Path.join(@priv_configs, "dovecot.conf.eex"), [:config])
  EEx.function_from_file(:def, :render_oauth_args, Path.join(@priv_configs, "dovecot-oauth2.conf.ext.eex"), [:config])
  EEx.function_from_file(:def, :render_file_spam, Path.join([@priv_configs, "sieve", "file_spam.sieve"]))
  EEx.function_from_file(:def, :render_report_ham, Path.join([@priv_configs, "sieve", "report_ham.sieve"]))
  EEx.function_from_file(:def, :render_report_spam, Path.join([@priv_configs, "sieve", "report_spam.sieve"]))
  EEx.function_from_file(:def, :render_rspamd_learn_ham, Path.join([@priv_configs, "sieve_extprograms", "rspamd_learn_ham.sh"]))
  EEx.function_from_file(:def, :render_rspamd_learn_spam, Path.join([@priv_configs, "sieve_extprograms", "rspamd_learn_spam.sh"]))
end
