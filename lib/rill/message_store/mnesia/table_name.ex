defmodule Rill.MessageStore.Mnesia.TableName do
  @moduledoc false

  @table Message
  @table_position Message.Position
  @table_global Message.Global

  def concat(ns, table), do: Module.concat(ns, table)

  def table(ns), do: concat(ns, @table)
  def position(ns), do: concat(ns, @table_position)
  def global(ns), do: concat(ns, @table_global)

  def tables(ns) do
    [
      table(ns),
      position(ns),
      global(ns)
    ]
  end
end
