use Mix.Config

config :logger,
  backends: [:console],
  utc_log: true,
  compile_time_purge_level: :error
