use Mix.Config

config :logger,
  backends: [:console],
  utc_log: true,
  format:
    "\n$time {$metadata[$application]} $metadata[$level] $levelpad$message\n",
  compile_time_purge_matching: [
    [level_lower_than: :debug]
  ],
  device: :standard_error
