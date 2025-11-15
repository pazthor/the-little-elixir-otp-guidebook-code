# JobQueue

A background job processing system with worker pools, priority queues, and automatic retry logic.

## Concepts Demonstrated

- **Worker Pool Pattern**: Multiple worker processes processing jobs concurrently
- **Priority Queue**: Jobs are processed based on priority (lower number = higher priority)
- **ETS Storage**: Fast in-memory storage for job data
- **Retry Logic**: Automatic retry with exponential backoff for failed jobs
- **Supervision**: Worker pool managed by supervisor for fault tolerance
- **Job Scheduling**: Schedule jobs to run at a specific time in the future

## Architecture

```
[JobQueue.Supervisor]
├── [JobQueue.Store] - Job storage and queue management (ETS)
└── [JobQueue.PoolSupervisor]
    └── [JobQueue.WorkerSupervisor]
        ├── [Worker1] - Processes jobs from queue
        ├── [Worker2]
        ├── [Worker3]
        ├── [Worker4]
        └── [Worker5]
```

## Features

- **Priority-based queue**: Lower priority number = higher priority
- **Configurable worker pool**: Default 5 workers, configurable
- **Automatic retry**: Failed jobs retry with exponential backoff (2^n seconds)
- **Job scheduling**: Schedule jobs for future execution
- **Job statistics**: Track pending, processing, completed, and failed jobs
- **Dead letter queue**: Jobs that exceed max retries are marked as failed
- **Job metadata**: Track execution time, errors, and retry attempts

## Installation

```bash
cd projects/job_queue
mix deps.get
```

## Running

```bash
iex -S mix
```

## Usage Examples

### Basic Usage

```elixir
# Define a worker module
defmodule EmailWorker do
  def send_email(to, subject, body) do
    # Send email logic
    IO.puts("Sending email to #{to}: #{subject}")
    Process.sleep(1000)  # Simulate work
    :ok
  end
end

# Enqueue a job
{:ok, job_id} = JobQueue.enqueue(EmailWorker, :send_email, ["user@example.com", "Hello", "Welcome!"])

# Check job status
JobQueue.get_job(job_id)
```

### Priority Jobs

```elixir
# Low priority (default is 5)
JobQueue.enqueue(CleanupWorker, :cleanup, [], priority: 10)

# High priority
JobQueue.enqueue(AlertWorker, :send_alert, [user_id], priority: 1)

# Jobs with priority 1 will be processed before priority 10
```

### Scheduled Jobs

```elixir
# Schedule a job to run in 60 seconds
JobQueue.schedule(ReportWorker, :generate_daily_report, [], 60)

# Schedule with priority
JobQueue.schedule(BackupWorker, :backup_database, [], 3600, priority: 1)
```

### Custom Retry Configuration

```elixir
# Allow 5 retry attempts instead of default 3
JobQueue.enqueue(DataWorker, :process_data, [data], max_retries: 5)

# No retries
JobQueue.enqueue(OneTimeWorker, :task, [], max_retries: 0)
```

### Monitoring Queue Statistics

```elixir
JobQueue.stats()
#=> %{
#     pending: 10,      # Jobs waiting in queue
#     processing: 5,    # Jobs currently being processed
#     completed: 1234,  # Successfully completed jobs
#     failed: 12        # Jobs that failed after max retries
#   }
```

### Example Worker Modules

```elixir
defmodule ImageProcessor do
  def resize_image(image_path, width, height) do
    # Image processing logic
    IO.puts("Resizing #{image_path} to #{width}x#{height}")
    Process.sleep(2000)  # Simulate work
    :ok
  end

  def generate_thumbnail(image_path) do
    # Thumbnail generation logic
    IO.puts("Generating thumbnail for #{image_path}")
    Process.sleep(1000)
    :ok
  end
end

defmodule DataWorker do
  def import_csv(file_path) do
    # CSV import logic
    IO.puts("Importing #{file_path}")
    Process.sleep(3000)
    :ok
  end

  def export_report(user_id, format) do
    # Report generation logic
    IO.puts("Generating #{format} report for user #{user_id}")
    Process.sleep(2000)
    :ok
  end
end

# Usage
JobQueue.enqueue(ImageProcessor, :resize_image, ["/path/to/image.jpg", 800, 600])
JobQueue.enqueue(ImageProcessor, :generate_thumbnail, ["/path/to/image.jpg"], priority: 2)
JobQueue.enqueue(DataWorker, :import_csv, ["/path/to/data.csv"])
JobQueue.enqueue(DataWorker, :export_report, [123, "pdf"], priority: 1)
```

## Testing

```bash
mix test
```

Note: Some tests use `Process.sleep` to wait for async operations, so tests may take a few seconds to complete.

## Configuration

### Changing Worker Pool Size

Edit `lib/job_queue/application.ex`:

```elixir
children = [
  JobQueue.Store,
  {JobQueue.PoolSupervisor, pool_size: 10}  # Increase to 10 workers
]
```

### Retry Backoff Strategy

The current implementation uses exponential backoff: 2^(retry_count) seconds.

- Retry 1: 2 seconds
- Retry 2: 4 seconds
- Retry 3: 8 seconds
- etc.

You can modify this in `lib/job_queue/store.ex`:

```elixir
# Current: exponential backoff
backoff = :math.pow(2, job.retries) |> round()

# Alternative: linear backoff (5 seconds each)
backoff = 5

# Alternative: fixed backoff
backoff = 10
```

## Extensions to Try

1. **Persistence**: Store jobs in PostgreSQL for durability across restarts
2. **Web Dashboard**: Add Phoenix LiveView dashboard to monitor jobs
3. **Job Dependencies**: Implement DAG (directed acyclic graph) for job dependencies
4. **Distributed Queue**: Distribute jobs across multiple nodes
5. **Job Cancellation**: Add ability to cancel pending jobs
6. **Job Timeout**: Add timeout for long-running jobs
7. **Worker Metrics**: Track jobs processed per worker, average execution time
8. **Job Progress**: Add callbacks for job progress updates
9. **Batch Jobs**: Add support for batch job processing
10. **Rate Limiting**: Limit jobs per time period

## Learning Points

### 1. Worker Pool Pattern

Worker pools allow you to:
- Process jobs concurrently (limited by pool size)
- Avoid overwhelming system resources
- Scale by adjusting pool size
- Isolate failures (one worker crash doesn't affect others)

### 2. Priority Queue

Using ETS ordered_set with composite keys:
```elixir
# Key format: {priority, enqueued_at, job_id}
:ets.insert(:queue, {{5, 1234567890, "job123"}, "job123"})
```

This ensures:
- Jobs are sorted by priority first
- Within same priority, FIFO order (enqueued_at)
- Unique keys (job_id as tiebreaker)

### 3. Exponential Backoff

Prevents overwhelming failing services:
```elixir
backoff = :math.pow(2, job.retries) |> round()
scheduled_at = now + backoff
```

### 4. ETS for Fast Storage

ETS (Erlang Term Storage) provides:
- Fast in-memory storage
- Concurrent reads
- Atomic operations
- No serialization overhead

### 5. GenServer Message Loop

Workers use `send_after` for periodic polling:
```elixir
def handle_info(:work, state) do
  process_job()
  schedule_work()
  {:noreply, state}
end
```

## Comparison with Production Libraries

### vs Oban
- **Oban**: PostgreSQL-backed, more features, production-ready
- **JobQueue**: In-memory, educational, simpler

### vs Exq
- **Exq**: Redis-backed, Sidekiq-compatible
- **JobQueue**: ETS-backed, no external dependencies

### vs Broadway
- **Broadway**: Stream processing, backpressure
- **JobQueue**: Simple queue, no backpressure

## Production Considerations

For production use, consider:

1. **Persistence**: Use PostgreSQL or Redis
2. **Monitoring**: Add metrics, logging, alerting
3. **Observability**: Track job execution time, failure rates
4. **Graceful Shutdown**: Finish processing jobs before shutdown
5. **Job Uniqueness**: Prevent duplicate jobs
6. **Dead Letter Queue**: Separate storage for permanently failed jobs
7. **Job Cleanup**: Remove old completed jobs
8. **Backpressure**: Prevent queue from growing unbounded
9. **Testing**: Test with production-like load

## Next Steps

After mastering this project:

1. **Add PostgreSQL persistence** using Ecto
2. **Build a Phoenix LiveView dashboard** for job monitoring
3. **Implement job dependencies** with DAG
4. **Make it distributed** across multiple nodes
5. **Study production libraries** like Oban for advanced features
6. **Build a real application** that needs background jobs

## Resources

- [GenServer documentation](https://hexdocs.pm/elixir/GenServer.html)
- [ETS documentation](https://www.erlang.org/doc/man/ets.html)
- [Oban - Production job queue](https://github.com/sorentwo/oban)
- [Exq - Redis-backed job queue](https://github.com/akira/exq)
- [Broadway - Data ingestion](https://github.com/dashbitco/broadway)
