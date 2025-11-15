defmodule JobQueue.Worker do
  use GenServer
  require Logger

  @moduledoc """
  A worker process that continuously pulls jobs from the queue and executes them.

  Workers check the queue for jobs, execute them, and report results back to the store.
  If no jobs are available, workers wait before checking again.
  """

  # Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    schedule_work()
    {:ok, %{jobs_processed: 0}}
  end

  @impl true
  def handle_info(:work, state) do
    case JobQueue.Store.dequeue() do
      nil ->
        # No jobs available, wait longer
        schedule_work(1000)
        {:noreply, state}

      job ->
        execute_job(job)
        # Get next job immediately
        schedule_work(0)
        {:noreply, %{state | jobs_processed: state.jobs_processed + 1}}
    end
  end

  # Private Functions

  defp execute_job(job) do
    Logger.info("Worker #{inspect(self())} executing job #{job.id}")

    try do
      JobQueue.Job.execute(job)
      JobQueue.Store.complete(job.id)
      Logger.info("Job #{job.id} completed successfully")
    rescue
      error ->
        error_message = Exception.format(:error, error, __STACKTRACE__)
        Logger.error("Job #{job.id} failed: #{error_message}")
        JobQueue.Store.fail(job.id, error_message)
    catch
      kind, value ->
        error_message = "Caught #{kind}: #{inspect(value)}"
        Logger.error("Job #{job.id} failed: #{error_message}")
        JobQueue.Store.fail(job.id, error_message)
    end
  end

  defp schedule_work(delay \\ 100) do
    Process.send_after(self(), :work, delay)
  end
end
