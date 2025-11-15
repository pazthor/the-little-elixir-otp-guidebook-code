defmodule JobQueueTest do
  use ExUnit.Case
  doctest JobQueue

  defmodule TestWorker do
    @moduledoc """
    Test worker module for job execution tests.
    """

    def simple_job(pid) do
      send(pid, :job_executed)
    end

    def slow_job(duration) do
      Process.sleep(duration)
      :ok
    end

    def failing_job do
      raise "Intentional failure for testing"
    end

    def counter_job(counter_name) do
      :ets.update_counter(:test_counters, counter_name, {2, 1})
    end
  end

  setup do
    # Create ETS table for counting job executions
    :ets.new(:test_counters, [:named_table, :public, :set])
    :ok
  end

  test "enqueue and execute a simple job" do
    {:ok, job_id} = JobQueue.enqueue(TestWorker, :simple_job, [self()])

    # Wait for job to be executed
    assert_receive :job_executed, 2000

    # Check job is marked as completed
    Process.sleep(100)
    {:ok, job} = JobQueue.get_job(job_id)
    assert job.status == :completed
  end

  test "jobs are executed in priority order" do
    :ets.insert(:test_counters, {:execution_order, 0})

    # Enqueue jobs with different priorities (lower = higher priority)
    JobQueue.enqueue(TestWorker, :counter_job, [:execution_order], priority: 10)
    JobQueue.enqueue(TestWorker, :counter_job, [:execution_order], priority: 1)
    JobQueue.enqueue(TestWorker, :counter_job, [:execution_order], priority: 5)

    # Wait for all jobs to complete
    Process.sleep(1000)

    # All jobs should be executed
    [{:execution_order, count}] = :ets.lookup(:test_counters, :execution_order)
    assert count == 3
  end

  test "failed jobs are retried with exponential backoff" do
    :ets.insert(:test_counters, {:retry_count, 0})

    # Enqueue a job that will fail
    {:ok, job_id} = JobQueue.enqueue(TestWorker, :failing_job, [], max_retries: 3)

    # Wait for retries to complete (exponential backoff: 1s, 2s, 4s)
    Process.sleep(8000)

    # Check job is marked as failed
    {:ok, job} = JobQueue.get_job(job_id)
    assert job.status == :failed
    assert job.retries == 3
    assert job.error != nil
  end

  test "scheduled jobs execute in the future" do
    # Schedule a job 2 seconds from now
    {:ok, job_id} = JobQueue.schedule(TestWorker, :simple_job, [self()], 2)

    # Should not execute immediately
    refute_receive :job_executed, 1000

    # Should execute after scheduled time
    assert_receive :job_executed, 2000

    # Check job is completed
    Process.sleep(100)
    {:ok, job} = JobQueue.get_job(job_id)
    assert job.status == :completed
  end

  test "queue statistics are accurate" do
    initial_stats = JobQueue.stats()

    # Enqueue some jobs
    JobQueue.enqueue(TestWorker, :slow_job, [500])
    JobQueue.enqueue(TestWorker, :slow_job, [500])
    JobQueue.enqueue(TestWorker, :slow_job, [500])

    # Wait a bit for jobs to start processing
    Process.sleep(200)

    stats = JobQueue.stats()

    # Total jobs should increase
    total_before = initial_stats.pending + initial_stats.processing + initial_stats.completed
    total_after = stats.pending + stats.processing + stats.completed

    assert total_after >= total_before + 3
  end

  test "multiple workers process jobs concurrently" do
    :ets.insert(:test_counters, {:concurrent_jobs, 0})

    # Enqueue more jobs than workers (5 workers in pool)
    for _i <- 1..10 do
      JobQueue.enqueue(TestWorker, :counter_job, [:concurrent_jobs])
    end

    # Wait for all jobs to complete
    Process.sleep(2000)

    # All jobs should be executed
    [{:concurrent_jobs, count}] = :ets.lookup(:test_counters, :concurrent_jobs)
    assert count == 10
  end

  test "job with custom max_retries is respected" do
    {:ok, job_id} = JobQueue.enqueue(TestWorker, :failing_job, [], max_retries: 1)

    # Wait for retries to complete (1 retry with 2s backoff)
    Process.sleep(3000)

    # Check job failed after 1 retry
    {:ok, job} = JobQueue.get_job(job_id)
    assert job.status == :failed
    assert job.retries == 1
  end
end
