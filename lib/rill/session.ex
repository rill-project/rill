defmodule Rill.Session do
  defstruct message_store: nil, database: nil, config: %{}

  @type t :: %__MODULE__{
          message_store: module(),
          database: module(),
          config: map()
        }

  def new(message_store, database) do
    %__MODULE__{}
    |> put_message_store(message_store)
    |> put_database(database)
  end

  def get_config(%__MODULE__{} = session, key, default \\ nil) do
    Map.get(session.config, key, default)
  end

  def put_config(%__MODULE__{} = session, key, value) do
    config = Map.put(session.config, key, value)

    Map.put(session, :config, config)
  end

  def put_message_store(%__MODULE__{} = session, value) do
    Map.put(session, :message_store, value)
  end

  def put_database(%__MODULE__{} = session, value) do
    Map.put(session, :database, value)
  end

  def get_message_store(%__MODULE__{} = session) do
    Map.get(session, :message_store)
  end

  def get_database(%__MODULE__{} = session) do
    Map.get(session, :database)
  end
end
