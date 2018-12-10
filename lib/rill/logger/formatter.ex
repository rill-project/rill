defmodule Rill.Logger.Formatter do
  def levelpad(:info), do: " "
  def levelpad(:warn), do: " "
  def levelpad(_), do: ""

  def pretty_time(time_tuple) do
    {date, {hours, minutes, seconds, micro}} = time_tuple
    time = {hours, minutes, seconds}
    micro = {micro * 1000, 6}

    naive = NaiveDateTime.from_erl!({date, time}, micro)

    NaiveDateTime.to_iso8601(naive)
  end

  def pretty_level(level) do
    level
    |> to_string()
    |> String.upcase()
  end

  def pretty_module(metadata) do
    "#{metadata[:module]}.#{metadata[:function]}"
  end

  def get_level(level, metadata) do
    metadata[:level] || level
  end

  # Metadata
  # [
  #   tags: [:fetch],
  #   pid: #PID<0.104.0>,
  #   line: 118,
  #   function: "fetch/6",
  #   module: Rill.EntityStore,
  #   file: "lib/rill/entity_store.ex",
  #   application: :rill
  # ]
  # "\n$time $metadata[$level] $levelpad$message\n"

  def format(level, message, time, metadata) do
    level = get_level(level, metadata)
    time = pretty_time(time)
    target = pretty_module(metadata)
    text_level = pretty_level(level)
    pad = levelpad(level)

    "[#{time}] #{target} #{text_level}: #{pad}#{message}\n"
  rescue
    _ -> "could not format: #{inspect({level, message, metadata})}"
  end
end
