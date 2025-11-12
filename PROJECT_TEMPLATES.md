# Elixir OTP Project Templates

Practical project templates to apply your Elixir OTP knowledge. Each template includes architecture, starter code, and implementation steps.

---

## Table of Contents
- [Project 1: Chat Server](#project-1-chat-server)
- [Project 2: Job Queue](#project-2-job-queue)
- [Project 3: Distributed Cache](#project-3-distributed-cache)
- [Project 4: Rate Limiter](#project-4-rate-limiter)
- [Project 5: Real-Time Metrics Collector](#project-5-real-time-metrics-collector)

---

## Project 1: Chat Server

**Difficulty:** Beginner
**Concepts:** GenServer, Supervision, Message Passing, Registry
**Time:** 2-3 days

### Architecture

```
[ChatApp.Supervisor]
├── [Registry] - Process registry for users
├── [ChatApp.RoomSupervisor] - Dynamic supervisor for rooms
│   └── [ChatApp.Room] - GenServer per room
└── [ChatApp.UserSupervisor] - Dynamic supervisor for users
    └── [ChatApp.User] - GenServer per user
```

### Features
- Multiple chat rooms
- User join/leave notifications
- Broadcast messages to room
- Private messages between users
- List users in room
- Message history (last 100 messages)

### Implementation Guide

#### Step 1: Create Project
```bash
mix new chat_app --sup
cd chat_app
```

#### Step 2: User Module (`lib/chat_app/user.ex`)
```elixir
defmodule ChatApp.User do
  use GenServer

  # Client API
  def start_link(username) do
    GenServer.start_link(__MODULE__, username, name: via_tuple(username))
  end

  def send_message(username, message) do
    GenServer.cast(via_tuple(username), {:message, message})
  end

  defp via_tuple(username) do
    {:via, Registry, {ChatApp.UserRegistry, username}}
  end

  # Server Callbacks
  def init(username) do
    {:ok, %{username: username, messages: []}}
  end

  def handle_cast({:message, message}, state) do
    IO.puts("[#{state.username}] #{message}")
    {:noreply, %{state | messages: [message | state.messages]}}
  end
end
```

#### Step 3: Room Module (`lib/chat_app/room.ex`)
```elixir
defmodule ChatApp.Room do
  use GenServer

  # Client API
  def start_link(room_name) do
    GenServer.start_link(__MODULE__, room_name, name: via_tuple(room_name))
  end

  def join(room_name, username) do
    GenServer.call(via_tuple(room_name), {:join, username})
  end

  def leave(room_name, username) do
    GenServer.call(via_tuple(room_name), {:leave, username})
  end

  def broadcast(room_name, username, message) do
    GenServer.cast(via_tuple(room_name), {:broadcast, username, message})
  end

  def list_users(room_name) do
    GenServer.call(via_tuple(room_name), :list_users)
  end

  defp via_tuple(room_name) do
    {:via, Registry, {ChatApp.RoomRegistry, room_name}}
  end

  # Server Callbacks
  def init(room_name) do
    {:ok, %{
      name: room_name,
      users: MapSet.new(),
      messages: []
    }}
  end

  def handle_call({:join, username}, _from, state) do
    new_users = MapSet.put(state.users, username)
    broadcast_system_message(new_users, "#{username} joined the room")
    {:reply, :ok, %{state | users: new_users}}
  end

  def handle_call({:leave, username}, _from, state) do
    new_users = MapSet.delete(state.users, username)
    broadcast_system_message(new_users, "#{username} left the room")
    {:reply, :ok, %{state | users: new_users}}
  end

  def handle_call(:list_users, _from, state) do
    {:reply, MapSet.to_list(state.users), state}
  end

  def handle_cast({:broadcast, username, message}, state) do
    formatted = "[#{state.name}] #{username}: #{message}"

    # Send to all users in room
    Enum.each(state.users, fn user ->
      ChatApp.User.send_message(user, formatted)
    end)

    # Store message history (keep last 100)
    new_messages =
      [formatted | state.messages]
      |> Enum.take(100)

    {:noreply, %{state | messages: new_messages}}
  end

  defp broadcast_system_message(users, message) do
    Enum.each(users, fn user ->
      ChatApp.User.send_message(user, "[SYSTEM] #{message}")
    end)
  end
end
```

#### Step 4: Supervisors (`lib/chat_app/application.ex`)
```elixir
defmodule ChatApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      # Registries
      {Registry, keys: :unique, name: ChatApp.UserRegistry},
      {Registry, keys: :unique, name: ChatApp.RoomRegistry},

      # Dynamic supervisors
      {DynamicSupervisor, strategy: :one_for_one, name: ChatApp.UserSupervisor},
      {DynamicSupervisor, strategy: :one_for_one, name: ChatApp.RoomSupervisor}
    ]

    opts = [strategy: :one_for_one, name: ChatApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

#### Step 5: Public API (`lib/chat_app.ex`)
```elixir
defmodule ChatApp do
  @moduledoc """
  Public API for ChatApp
  """

  def create_user(username) do
    DynamicSupervisor.start_child(
      ChatApp.UserSupervisor,
      {ChatApp.User, username}
    )
  end

  def create_room(room_name) do
    DynamicSupervisor.start_child(
      ChatApp.RoomSupervisor,
      {ChatApp.Room, room_name}
    )
  end

  def join_room(room_name, username) do
    ChatApp.Room.join(room_name, username)
  end

  def leave_room(room_name, username) do
    ChatApp.Room.leave(room_name, username)
  end

  def send_message(room_name, username, message) do
    ChatApp.Room.broadcast(room_name, username, message)
  end

  def list_users(room_name) do
    ChatApp.Room.list_users(room_name)
  end
end
```

#### Step 6: Test It
```elixir
# iex -S mix

# Create users
ChatApp.create_user("alice")
ChatApp.create_user("bob")
ChatApp.create_user("charlie")

# Create room
ChatApp.create_room("general")

# Join room
ChatApp.join_room("general", "alice")
ChatApp.join_room("general", "bob")
ChatApp.join_room("general", "charlie")

# Send messages
ChatApp.send_message("general", "alice", "Hello everyone!")
ChatApp.send_message("general", "bob", "Hi Alice!")
ChatApp.send_message("general", "charlie", "Hey folks!")

# List users
ChatApp.list_users("general")

# Leave room
ChatApp.leave_room("general", "bob")
```

### Extensions
1. Add private messaging
2. Add message persistence (PostgreSQL/ETS)
3. Add Phoenix web interface
4. Add WebSocket support with Phoenix Channels
5. Add user authentication
6. Add room moderation features
7. Add message encryption

---

## Project 2: Job Queue

**Difficulty:** Intermediate
**Concepts:** Worker Pools, Supervision, Queue Management, Monitoring
**Time:** 3-4 days

### Architecture

```
[JobQueue.Supervisor]
├── [JobQueue.Store] - Job storage (ETS)
├── [JobQueue.Scheduler] - Periodic job scheduler
└── [JobQueue.PoolSupervisor]
    └── [JobQueue.WorkerSupervisor]
        ├── [Worker1]
        ├── [Worker2]
        └── [WorkerN]
```

### Features
- Enqueue jobs with priority
- Worker pool for parallel processing
- Retry failed jobs with exponential backoff
- Schedule jobs for future execution
- Job statistics and monitoring
- Dead letter queue for failed jobs

### Implementation Guide

#### Step 1: Create Project
```bash
mix new job_queue --sup
cd job_queue
```

Add dependencies to `mix.exs`:
```elixir
defp deps do
  [
    {:uuid, "~> 1.1"}
  ]
end
```

#### Step 2: Job Structure (`lib/job_queue/job.ex`)
```elixir
defmodule JobQueue.Job do
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

  def new(module, function, args, opts \\ []) do
    %__MODULE__{
      id: UUID.uuid4(),
      module: module,
      function: function,
      args: args,
      priority: Keyword.get(opts, :priority, 5),
      max_retries: Keyword.get(opts, :max_retries, 3),
      scheduled_at: Keyword.get(opts, :schedule_at),
      enqueued_at: System.system_time(:second)
    }
  end

  def execute(%__MODULE__{} = job) do
    apply(job.module, job.function, job.args)
  end
end
```

#### Step 3: Job Store (`lib/job_queue/store.ex`)
```elixir
defmodule JobQueue.Store do
  use GenServer

  # Client API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def enqueue(job) do
    GenServer.call(__MODULE__, {:enqueue, job})
  end

  def dequeue do
    GenServer.call(__MODULE__, :dequeue)
  end

  def complete(job_id) do
    GenServer.cast(__MODULE__, {:complete, job_id})
  end

  def fail(job_id, error) do
    GenServer.cast(__MODULE__, {:fail, job_id, error})
  end

  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  # Server Callbacks
  def init(_opts) do
    :ets.new(:jobs, [:named_table, :public, :set])
    :ets.new(:queue, [:named_table, :public, :ordered_set])

    {:ok, %{
      pending: 0,
      processing: 0,
      completed: 0,
      failed: 0
    }}
  end

  def handle_call({:enqueue, job}, _from, state) do
    # Store job
    :ets.insert(:jobs, {job.id, job})

    # Add to priority queue (lower number = higher priority)
    :ets.insert(:queue, {{job.priority, job.enqueued_at, job.id}, job.id})

    new_state = %{state | pending: state.pending + 1}
    {:reply, {:ok, job.id}, new_state}
  end

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

          {:reply, updated_job, new_state}
        end
    end
  end

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

    {:noreply, new_state}
  end

  def handle_cast({:fail, job_id, error}, state) do
    [{^job_id, job}] = :ets.lookup(:jobs, job_id)

    if job.retries < job.max_retries do
      # Re-enqueue with incremented retries
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

      {:noreply, new_state}
    else
      # Move to dead letter queue
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

      {:noreply, new_state}
    end
  end

  def handle_call(:stats, _from, state) do
    {:reply, state, state}
  end
end
```

#### Step 4: Worker (`lib/job_queue/worker.ex`)
```elixir
defmodule JobQueue.Worker do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(_opts) do
    schedule_work()
    {:ok, %{}}
  end

  def handle_info(:work, state) do
    case JobQueue.Store.dequeue() do
      nil ->
        # No jobs, wait longer
        schedule_work(1000)

      job ->
        execute_job(job)
        # Get next job immediately
        schedule_work(0)
    end

    {:noreply, state}
  end

  defp execute_job(job) do
    Logger.info("Executing job #{job.id}")

    try do
      JobQueue.Job.execute(job)
      JobQueue.Store.complete(job.id)
      Logger.info("Job #{job.id} completed")
    rescue
      error ->
        Logger.error("Job #{job.id} failed: #{inspect(error)}")
        JobQueue.Store.fail(job.id, inspect(error))
    end
  end

  defp schedule_work(delay \\ 100) do
    Process.send_after(self(), :work, delay)
  end
end
```

#### Step 5: Public API (`lib/job_queue.ex`)
```elixir
defmodule JobQueue do
  alias JobQueue.Job

  def enqueue(module, function, args, opts \\ []) do
    job = Job.new(module, function, args, opts)
    JobQueue.Store.enqueue(job)
  end

  def schedule(module, function, args, seconds_from_now, opts \\ []) do
    schedule_at = System.system_time(:second) + seconds_from_now
    opts = Keyword.put(opts, :schedule_at, schedule_at)
    enqueue(module, function, args, opts)
  end

  def stats do
    JobQueue.Store.stats()
  end
end
```

#### Step 6: Application (`lib/job_queue/application.ex`)
```elixir
defmodule JobQueue.Application do
  use Application

  def start(_type, _args) do
    children = [
      JobQueue.Store,
      {JobQueue.PoolSupervisor, pool_size: 5}
    ]

    opts = [strategy: :one_for_one, name: JobQueue.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

defmodule JobQueue.PoolSupervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

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
```

#### Step 7: Test It
```elixir
# Create test module
defmodule TestJobs do
  def slow_job(n) do
    Process.sleep(1000)
    IO.puts("Completed job #{n}")
  end

  def failing_job do
    raise "Intentional failure"
  end
end

# iex -S mix

# Enqueue jobs
JobQueue.enqueue(TestJobs, :slow_job, [1])
JobQueue.enqueue(TestJobs, :slow_job, [2], priority: 1)
JobQueue.enqueue(TestJobs, :slow_job, [3], priority: 10)

# Schedule future job
JobQueue.schedule(TestJobs, :slow_job, [99], 10)

# Check stats
JobQueue.stats()

# Enqueue failing job to test retries
JobQueue.enqueue(TestJobs, :failing_job, [])
```

### Extensions
1. Add job persistence (PostgreSQL)
2. Add web dashboard (Phoenix LiveView)
3. Add job dependencies (DAG)
4. Add distributed queue across nodes
5. Add job cancellation
6. Add job timeout
7. Add worker metrics

---

## Project 3: Distributed Cache

**Difficulty:** Advanced
**Concepts:** Distribution, Consistent Hashing, Replication, GenServer
**Time:** 5-7 days

### Architecture

```
[CacheCluster]
├── Node1
│   ├── [Cache.Server]
│   ├── [Cache.Ring] - Consistent hash ring
│   └── [Cache.Replicator]
└── Node2
    ├── [Cache.Server]
    ├── [Cache.Ring]
    └── [Cache.Replicator]
```

### Features
- Distributed key-value storage
- Consistent hashing for key distribution
- Replication (configurable factor)
- Automatic node discovery
- Read-your-writes consistency
- TTL support
- LRU eviction

### Implementation Outline

#### Key Modules

1. **Cache.Ring** - Consistent hash ring
   - Add/remove nodes
   - Find node for key
   - Virtual nodes for better distribution

2. **Cache.Server** - Local cache storage
   - Get/Put/Delete operations
   - TTL management
   - LRU eviction
   - ETS for storage

3. **Cache.Replicator** - Handle replication
   - Replicate writes to N nodes
   - Read repair
   - Anti-entropy (periodic sync)

4. **Cache.Cluster** - Node management
   - Node discovery
   - Gossip protocol
   - Health checks

### Starter Code Structure
```
lib/
├── cache.ex              # Public API
├── cache/
│   ├── application.ex    # Supervision tree
│   ├── ring.ex          # Consistent hashing
│   ├── server.ex        # Local storage
│   ├── replicator.ex    # Replication
│   └── cluster.ex       # Cluster management
```

---

## Project 4: Rate Limiter

**Difficulty:** Intermediate
**Concepts:** GenServer, Token Bucket, Sliding Window
**Time:** 2-3 days

### Features
- Multiple rate limiting algorithms
  - Token bucket
  - Sliding window
  - Fixed window
- Per-user/per-IP limiting
- Distributed rate limiting
- HTTP middleware
- Redis-compatible protocol

### Implementation

#### Token Bucket Algorithm
```elixir
defmodule RateLimiter.TokenBucket do
  use GenServer

  defmodule State do
    defstruct [
      :capacity,
      :tokens,
      :refill_rate,
      :last_refill
    ]
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def check(pid, cost \\ 1) do
    GenServer.call(pid, {:check, cost})
  end

  def init(opts) do
    state = %State{
      capacity: Keyword.fetch!(opts, :capacity),
      tokens: Keyword.fetch!(opts, :capacity),
      refill_rate: Keyword.fetch!(opts, :refill_rate),
      last_refill: System.monotonic_time(:millisecond)
    }

    {:ok, state}
  end

  def handle_call({:check, cost}, _from, state) do
    state = refill_tokens(state)

    if state.tokens >= cost do
      new_state = %{state | tokens: state.tokens - cost}
      {:reply, {:ok, new_state.tokens}, new_state}
    else
      {:reply, {:error, :rate_limited, state.tokens}, state}
    end
  end

  defp refill_tokens(state) do
    now = System.monotonic_time(:millisecond)
    time_passed = now - state.last_refill

    tokens_to_add = (time_passed / 1000) * state.refill_rate
    new_tokens = min(state.capacity, state.tokens + tokens_to_add)

    %{state |
      tokens: new_tokens,
      last_refill: now
    }
  end
end
```

---

## Project 5: Real-Time Metrics Collector

**Difficulty:** Advanced
**Concepts:** GenStage/Broadway, Time-Series Data, Phoenix LiveView
**Time:** 5-7 days

### Architecture

```
[MetricsApp]
├── [Collectors] - Gather metrics
│   ├── System metrics
│   ├── Application metrics
│   └── Custom metrics
├── [Aggregator] - Process and aggregate
│   ├── Counters
│   ├── Gauges
│   ├── Histograms
│   └── Timers
├── [Storage] - Time-series database
│   └── ETS/PostgreSQL/InfluxDB
└── [Dashboard] - Phoenix LiveView
    ├── Real-time charts
    ├── Alerts
    └── Query interface
```

### Features
- Collect system metrics (CPU, memory, network)
- Collect application metrics (requests, errors, latency)
- Aggregate metrics (sum, avg, min, max, percentiles)
- Store time-series data
- Real-time dashboard with Phoenix LiveView
- Alerting on thresholds
- Query API

### Key Components

#### Metric Types
```elixir
defmodule Metrics.Types do
  defmodule Counter do
    defstruct [:name, :value, :timestamp]
  end

  defmodule Gauge do
    defstruct [:name, :value, :timestamp]
  end

  defmodule Histogram do
    defstruct [:name, :values, :timestamp]

    def percentile(histogram, p) do
      # Calculate percentile
    end
  end

  defmodule Timer do
    defstruct [:name, :duration, :timestamp]
  end
end
```

#### Collector GenStage
```elixir
defmodule Metrics.Collector do
  use GenStage

  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def emit(metric) do
    GenStage.cast(__MODULE__, {:emit, metric})
  end

  def init(_opts) do
    {:producer, {:queue.new(), 0}}
  end

  def handle_cast({:emit, metric}, {queue, pending}) do
    new_queue = :queue.in(metric, queue)
    dispatch_metrics(new_queue, pending, [])
  end

  def handle_demand(demand, {queue, pending}) do
    dispatch_metrics(queue, demand + pending, [])
  end

  defp dispatch_metrics(queue, 0, metrics) do
    {:noreply, Enum.reverse(metrics), {queue, 0}}
  end

  defp dispatch_metrics(queue, demand, metrics) do
    case :queue.out(queue) do
      {{:value, metric}, new_queue} ->
        dispatch_metrics(new_queue, demand - 1, [metric | metrics])

      {:empty, queue} ->
        {:noreply, Enum.reverse(metrics), {queue, demand}}
    end
  end
end
```

---

## Common Patterns & Best Practices

### 1. GenServer Template
```elixir
defmodule MyApp.Server do
  use GenServer
  require Logger

  # Client API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def get_state do
    GenServer.call(__MODULE__, :get_state)
  end

  # Server Callbacks
  def init(opts) do
    # Perform initialization
    # Use Process.send_after for periodic tasks
    {:ok, initial_state(opts)}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_cast({:async_operation, data}, state) do
    # Handle async operation
    {:noreply, new_state}
  end

  def handle_info(:periodic_task, state) do
    # Handle periodic work
    schedule_periodic_task()
    {:noreply, state}
  end

  defp schedule_periodic_task do
    Process.send_after(self(), :periodic_task, 5_000)
  end

  defp initial_state(_opts) do
    %{}
  end
end
```

### 2. Dynamic Supervisor Pattern
```elixir
defmodule MyApp.DynamicSupervisor do
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_child(child_spec) do
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
```

### 3. Registry Pattern for Named Processes
```elixir
# In application.ex
{Registry, keys: :unique, name: MyApp.Registry}

# In GenServer
defp via_tuple(id) do
  {:via, Registry, {MyApp.Registry, id}}
end

def start_link(id) do
  GenServer.start_link(__MODULE__, id, name: via_tuple(id))
end
```

### 4. Testing Concurrent Code
```elixir
defmodule MyApp.ServerTest do
  use ExUnit.Case

  test "concurrent operations" do
    {:ok, pid} = MyApp.Server.start_link([])

    # Spawn multiple processes
    tasks =
      for i <- 1..100 do
        Task.async(fn ->
          MyApp.Server.increment(pid)
        end)
      end

    # Wait for completion
    Task.await_many(tasks)

    # Assert final state
    assert MyApp.Server.get_count(pid) == 100
  end
end
```

---

## Next Steps

1. **Choose a project** based on your skill level
2. **Follow the implementation steps** provided
3. **Test thoroughly** - especially concurrent behavior
4. **Add extensions** to deepen your understanding
5. **Share your work** with the community
6. **Move to the next project**

---

## Additional Resources

### Books
- "Designing Elixir Systems with OTP" - Worker pools and supervision
- "Concurrent Data Processing in Elixir" - GenStage and Flow

### Libraries to Study
- **Poolboy** - Worker pool implementation
- **Horde** - Distributed supervisor and registry
- **Cachex** - Cache implementation
- **ExRated** - Rate limiting library
- **Broadway** - Data ingestion and processing

### Study Real Projects
- **Phoenix Framework** - Web framework architecture
- **Ecto** - Database wrapper and connection pooling
- **Quantum** - Job scheduling
- **Oban** - Background job processing

---

*Happy building! Remember: start simple, test thoroughly, and iterate.*
