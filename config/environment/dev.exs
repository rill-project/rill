use Mix.Config

config :logger,
  backends: [Scribble],
  utc_log: true,
  compile_time_purge_matching: [
    [level_lower_than: :debug]
  ]
