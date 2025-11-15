defmodule JobQueue.Job do
  @moduledoc """
  Represents a job to be executed.

  Jobs contain the module, function, and arguments to execute,
  along with metadata like priority, retries, and status.
  """

  @enforce_keys [:id, :module, :function, :args]
  defstruct [
    :id,
    :module,
    :function,
    :args,
    priority: 5,
    retries: 0,
    max_retries: 3,
    status: :pending,
    scheduled_at: nil,
    enqueued_at: nil,
    started_at: nil,
    completed_at: nil,
    error: nil
  ]

  @doc """
  Creates a new job.

  ## Options

    * `:priority` - Job priority (lower number = higher priority), default: 5
    * `:max_retries` - Maximum retry attempts, default: 3
    * `:schedule_at` - Unix timestamp to execute job at, default: nil (execute immediately)

  ## Examples

      Job.new(MyModule, :my_function, [arg1, arg2])
      Job.new(MyModule, :my_function, [arg1], priority: 1, max_retries: 5)

  """
  def new(module, function, args, opts \\ []) do
    %__MODULE__{
      id: generate_id(),
      module: module,
      function: function,
      args: args,
      priority: Keyword.get(opts, :priority, 5),
      max_retries: Keyword.get(opts, :max_retries, 3),
      scheduled_at: Keyword.get(opts, :schedule_at),
      enqueued_at: System.system_time(:second)
    }
  end

  @doc """
  Executes the job by calling the specified module, function, and arguments.
  """
  def execute(%__MODULE__{} = job) do
    apply(job.module, job.function, job.args)
  end

  # Generate a unique ID for the job
  defp generate_id do
    :crypto.strong_rand_bytes(16) |> Base.encode16()
  end
end
