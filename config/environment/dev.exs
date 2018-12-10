use Mix.Config

config :logger,
  backends: [:console],
  utc_log: true,
  compile_time_purge_matching: [
    [level_lower_than: :debug]
  ]

config :logger, :console,
  format: {Rill.Logger, :format},
  device: :standard_error,
  metadata: :all
