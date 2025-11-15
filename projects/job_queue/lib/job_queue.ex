defmodule JobQueue do
  @moduledoc """
  JobQueue - A background job processing system with worker pools.

  Features:
  - Priority-based job queue
  - Configurable worker pool
  - Automatic retry with exponential backoff
  - Job scheduling for future execution
  - Job statistics and monitoring

  ## Examples

      # Enqueue a job
      JobQueue.enqueue(MyModule, :my_function, [arg1, arg2])

      # Enqueue with high priority
      JobQueue.enqueue(MyModule, :urgent_task, [], priority: 1)

      # Schedule a job for 60 seconds from now
      JobQueue.schedule(MyModule, :delayed_task, [], 60)

      # Check queue statistics
      JobQueue.stats()
      #=> %{pending: 5, processing: 2, completed: 100, failed: 3}

  """

  alias JobQueue.Job

  @doc """
  Enqueues a job for processing.

  ## Options

    * `:priority` - Job priority (lower = higher priority), default: 5
    * `:max_retries` - Maximum retry attempts, default: 3

  ## Examples

      JobQueue.enqueue(EmailWorker, :send_email, ["user@example.com", "Hello"])
      JobQueue.enqueue(DataWorker, :process, [data], priority: 1, max_retries: 5)

  """
  def enqueue(module, function, args, opts \\ []) do
    job = Job.new(module, function, args, opts)
    JobQueue.Store.enqueue(job)
  end

  @doc """
  Schedules a job to run in the future.

  ## Examples

      # Run in 60 seconds
      JobQueue.schedule(CleanupWorker, :cleanup_old_data, [], 60)

      # Run in 1 hour with high priority
      JobQueue.schedule(ReportWorker, :generate, [user_id], 3600, priority: 1)

  """
  def schedule(module, function, args, seconds_from_now, opts \\ []) do
    schedule_at = System.system_time(:second) + seconds_from_now
    opts = Keyword.put(opts, :schedule_at, schedule_at)
    enqueue(module, function, args, opts)
  end

  @doc """
  Returns statistics about the job queue.

  Returns a map with:
  - `:pending` - Jobs waiting to be processed
  - `:processing` - Jobs currently being processed
  - `:completed` - Successfully completed jobs
  - `:failed` - Jobs that failed after max retries
  """
  def stats do
    JobQueue.Store.stats()
  end

  @doc """
  Gets a specific job by ID.
  """
  def get_job(job_id) do
    JobQueue.Store.get_job(job_id)
  end
end
