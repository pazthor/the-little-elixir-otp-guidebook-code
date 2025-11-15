defmodule JobQueue.Application do
  use Application

  @moduledoc """
  The JobQueue application supervisor.

  Starts the job storage and worker pool supervisor.
  """

  def start(_type, _args) do
    children = [
      JobQueue.Store,
      {JobQueue.PoolSupervisor, pool_size: 5}
    ]

    opts = [strategy: :one_for_one, name: JobQueue.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
