defmodule JobQueue.PoolSupervisor do
  use Supervisor

  @moduledoc """
  Supervisor for the worker pool.

  Creates and supervises a configurable number of worker processes.
  """

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    pool_size = Keyword.get(opts, :pool_size, 5)

    children =
      for i <- 1..pool_size do
        Supervisor.child_spec(
          {JobQueue.Worker, []},
          id: {:worker, i}
        )
      end

    Supervisor.init(children, strategy: :one_for_one)
  end
end
