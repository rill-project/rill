defmodule Rill.ComponentHost do
  use Supervisor

  @spec start_link(children :: list(module()), opts :: keyword()) :: term()
  def start_link(children \\ [], opts \\ []) do
    IO.inspect({children, opts})
    Supervisor.start_link(__MODULE__, children, opts)
  end

  @impl true
  def init(children) do
    Supervisor.init(children, strategy: :one_for_one)
  end

  defmacro __using__(children) when is_list(children) do
    quote do
      def child_spec(_) do
        %{
          id: __MODULE__,
          start: {
            unquote(__MODULE__),
            :start_link,
            [unquote(children), [name: __MODULE__]]
          }
        }
      end
    end
  end
end
