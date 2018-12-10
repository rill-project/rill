defmodule Rill.Logger do
  require Logger

  defmacro debug(chardata_or_fun, metadata \\ []) do
    quote bind_quoted: [chardata_or_fun: chardata_or_fun, metadata: metadata] do
      require Logger
      Logger.debug(chardata_or_fun, metadata)
    end
  end

  defmacro info(chardata_or_fun, metadata \\ []) do
    quote bind_quoted: [chardata_or_fun: chardata_or_fun, metadata: metadata] do
      require Logger
      Logger.info(chardata_or_fun, metadata)
    end
  end

  defmacro warn(chardata_or_fun, metadata \\ []) do
    quote bind_quoted: [chardata_or_fun: chardata_or_fun, metadata: metadata] do
      require Logger
      Logger.warn(chardata_or_fun, metadata)
    end
  end

  defmacro error(chardata_or_fun, metadata \\ []) do
    quote bind_quoted: [chardata_or_fun: chardata_or_fun, metadata: metadata] do
      require Logger
      Logger.error(chardata_or_fun, metadata)
    end
  end

  defmacro log(level, chardata_or_fun, metadata \\ []) do
    quote bind_quoted: [
            level: level,
            chardata_or_fun: chardata_or_fun,
            metadata: metadata
          ] do
      require Logger
      Logger.log(level, chardata_or_fun, metadata)
    end
  end

  defmacro trace(chardata_or_fun, metadata \\ []) do
    quote bind_quoted: [chardata_or_fun: chardata_or_fun, metadata: metadata] do
      require Logger

      Logger.debug(
        fn ->
          out =
            if is_function(chardata_or_fun) do
              chardata_or_fun.()
            else
              chardata_or_fun
            end

          out =
            if is_tuple(out) do
              out
            else
              {out, metadata}
            end

          {msg, out_metadata} = out
          out_metadata = Keyword.merge(metadata, out_metadata)
          level = out_metadata[:level] || :trace
          out_metadata = Keyword.put(out_metadata, :level, level)
          {msg, out_metadata}
        end,
        metadata
      )
    end
  end

  defdelegate format(level, message, time, metadata), to: Rill.Logger.Formatter
end
