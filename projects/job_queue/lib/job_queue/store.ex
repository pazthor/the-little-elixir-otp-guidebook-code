defmodule JobQueue.Store do
  use GenServer
  require Logger

  @moduledoc """
  Job storage and queue management using ETS.

  Maintains two ETS tables:
  - :jobs - Stores complete job data by job ID
  - :queue - Priority queue of pending jobs
  """

  # Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Enqueues a job for processing.
  """
  def enqueue(job) do
    GenServer.call(__MODULE__, {:enqueue, job})
  end

  @doc """
  Dequeues the highest priority job that is ready to run.
  """
  def dequeue do
    GenServer.call(__MODULE__, :dequeue)
  end

  @doc """
  Marks a job as completed.
  """
  def complete(job_id) do
    GenServer.cast(__MODULE__, {:complete, job_id})
  end

  @doc """
  Marks a job as failed and handles retry logic.
  """
  def fail(job_id, error) do
    GenServer.cast(__MODULE__, {:fail, job_id, error})
  end

  @doc """
  Gets statistics about the job queue.
  """
  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  @doc """
  Gets a specific job by ID.
  """
  def get_job(job_id) do
    GenServer.call(__MODULE__, {:get_job, job_id})
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    :ets.new(:jobs, [:named_table, :public, :set])
    :ets.new(:queue, [:named_table, :public, :ordered_set])

    Logger.info("JobQueue.Store started")

    {:ok, %{
      pending: 0,
      processing: 0,
      completed: 0,
      failed: 0
    }}
  end

  @impl true
  def handle_call({:enqueue, job}, _from, state) do
    # Store job
    :ets.insert(:jobs, {job.id, job})

    # Add to priority queue (lower number = higher priority)
    # Key format: {priority, enqueue_time, job_id} for stable sorting
    :ets.insert(:queue, {{job.priority, job.enqueued_at, job.id}, job.id})

    new_state = %{state | pending: state.pending + 1}
    Logger.debug("Job #{job.id} enqueued with priority #{job.priority}")

    {:reply, {:ok, job.id}, new_state}
  end

  @impl true
  def handle_call(:dequeue, _from, state) do
    case :ets.first(:queue) do
      :"$end_of_table" ->
        {:reply, nil, state}

      key ->
        [{^key, job_id}] = :ets.lookup(:queue, key)
        [{^job_id, job}] = :ets.lookup(:jobs, job_id)

        # Check if scheduled for future
        now = System.system_time(:second)
        if job.scheduled_at && job.scheduled_at > now do
          {:reply, nil, state}
        else
          :ets.delete(:queue, key)

          # Update job status
          updated_job = %{job |
            status: :processing,
            started_at: now
          }
          :ets.insert(:jobs, {job_id, updated_job})

          new_state = %{state |
            pending: state.pending - 1,
            processing: state.processing + 1
          }

          Logger.debug("Job #{job_id} dequeued for processing")

          {:reply, updated_job, new_state}
        end
    end
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:get_job, job_id}, _from, state) do
    case :ets.lookup(:jobs, job_id) do
      [{^job_id, job}] -> {:reply, {:ok, job}, state}
      [] -> {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_cast({:complete, job_id}, state) do
    [{^job_id, job}] = :ets.lookup(:jobs, job_id)

    updated_job = %{job |
      status: :completed,
      completed_at: System.system_time(:second)
    }
    :ets.insert(:jobs, {job_id, updated_job})

    new_state = %{state |
      processing: state.processing - 1,
      completed: state.completed + 1
    }

    Logger.info("Job #{job_id} completed successfully")

    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:fail, job_id, error}, state) do
    [{^job_id, job}] = :ets.lookup(:jobs, job_id)

    if job.retries < job.max_retries do
      # Re-enqueue with exponential backoff
      backoff = :math.pow(2, job.retries) |> round()

      updated_job = %{job |
        status: :pending,
        retries: job.retries + 1,
        scheduled_at: System.system_time(:second) + backoff,
        error: error
      }

      :ets.insert(:jobs, {job_id, updated_job})
      :ets.insert(:queue, {{updated_job.priority, updated_job.enqueued_at, job_id}, job_id})

      new_state = %{state |
        processing: state.processing - 1,
        pending: state.pending + 1
      }

      Logger.warn("Job #{job_id} failed (retry #{job.retries + 1}/#{job.max_retries}), retrying in #{backoff}s")

      {:noreply, new_state}
    else
      # Move to dead letter queue (mark as failed)
      updated_job = %{job |
        status: :failed,
        completed_at: System.system_time(:second),
        error: error
      }
      :ets.insert(:jobs, {job_id, updated_job})

      new_state = %{state |
        processing: state.processing - 1,
        failed: state.failed + 1
      }

      Logger.error("Job #{job_id} permanently failed after #{job.max_retries} retries: #{error}")

      {:noreply, new_state}
    end
  end
end
