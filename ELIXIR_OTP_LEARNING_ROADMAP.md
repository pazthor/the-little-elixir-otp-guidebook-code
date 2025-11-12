# Elixir OTP Learning Roadmap

> A comprehensive guide to mastering Elixir and OTP based on "The Little Elixir & OTP Guidebook"

## Table of Contents
- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Learning Path](#learning-path)
- [Hands-On Projects](#hands-on-projects)
- [Where Elixir Shines](#where-elixir-shines)
- [Real-World Project Ideas](#real-world-project-ideas)
- [Resources](#resources)

---

## Introduction

This roadmap guides you through learning Elixir and OTP (Open Telecom Platform) from fundamentals to advanced distributed systems. Elixir is a functional, concurrent language built on the Erlang VM (BEAM), designed for building scalable and maintainable applications.

**Why Elixir?**
- Built for concurrency and fault tolerance
- Lightweight processes (not OS threads)
- "Let it crash" philosophy with supervisors
- Real-time capabilities
- Distributed by default
- Hot code swapping

---

## Prerequisites

Before starting this roadmap:

**Required:**
- Basic programming experience (any language)
- Understanding of terminal/command line
- Text editor or IDE

**Helpful but not required:**
- Functional programming concepts
- Understanding of concurrent programming
- Basic networking knowledge

**Installation:**
```bash
# Install Elixir (includes Erlang)
# macOS
brew install elixir

# Ubuntu/Debian
sudo apt install elixir

# Verify installation
elixir --version
iex --version
```

---

## Learning Path

### Phase 1: Foundations (Weeks 1-2)

#### Chapter 1: Recursion & Functional Thinking
**Location:** `chapter_1/`

**Concepts:**
- Recursion as the primary loop mechanism
- Pattern matching in function definitions
- Tail call optimization
- Comparing Elixir to Erlang

**Exercise:**
```bash
cd chapter_1
iex recursive.ex
```

**Practice Tasks:**
1. Implement recursive sum, product, and reverse functions
2. Write a recursive Fibonacci function
3. Convert iterative algorithms to recursive ones
4. Understand base cases and recursive cases

**Key Takeaway:** In functional programming, recursion replaces loops.

---

#### Chapter 2: Elixir Fundamentals
**Location:** `chapter_2/`

**Concepts:**
- Pattern matching
- Immutable data structures
- Lists and tuples
- Maps and keyword lists
- Pipe operator (|>)
- Modules and functions

**Exercises:**
```bash
cd chapter_2/2_1
iex length_converter.ex

cd ../2_2
iex length_converter.ex
```

**Practice Tasks:**
1. Build a temperature converter (Celsius/Fahrenheit/Kelvin)
2. Implement list operations (filter, map, reduce) from scratch
3. Work with nested data structures
4. Use the pipe operator for data transformations
5. Study `id3.ex` and `my_list.ex` in `2_4/`

**Key Takeaway:** Pattern matching is the foundation of Elixir code.

---

### Phase 2: Concurrency Basics (Weeks 3-4)

#### Chapter 3: Processes & Message Passing
**Location:** `chapter_3/metex/`

**Concepts:**
- Lightweight processes (not OS threads)
- Spawning processes with `spawn/1`
- Message passing with `send/2` and `receive`
- Process mailboxes
- Parallel execution
- Coordinating multiple processes

**Project: Metex (Weather Service)**
```bash
cd chapter_3/metex
mix deps.get
iex -S mix

# In IEx:
Metex.temperatures_of(["Singapore", "Tokyo", "London"])
```

**Practice Tasks:**
1. Spawn 1000 processes and measure memory usage
2. Build a ping-pong process example
3. Create a message broadcasting system
4. Implement a simple calculator with separate processes for operations
5. Measure performance differences between sequential and concurrent execution

**Key Concepts:**
- `spawn/1` - Create new process
- `send/2` - Send message to process
- `receive do` - Pattern match on messages
- `self/0` - Get current process PID

**Key Takeaway:** Processes are cheap. Spawn millions!

---

### Phase 3: GenServer Pattern (Week 5)

#### Chapter 4: GenServer Abstraction
**Location:** `chapter_4/metex/`

**Concepts:**
- GenServer behavior
- Client/Server architecture
- Synchronous calls (`call`)
- Asynchronous casts (`cast`)
- State management
- Callbacks: `init/1`, `handle_call/3`, `handle_cast/2`, `handle_info/2`

**Project: Metex Refined**
```bash
cd chapter_4/metex
mix deps.get
iex -S mix

# In IEx:
{:ok, pid} = Metex.Worker.start_link
Metex.Worker.get_temperature(pid, "Singapore")
```

**Practice Tasks:**
1. Build a counter GenServer with increment/decrement
2. Create a key-value store GenServer
3. Implement a stack GenServer (push/pop)
4. Build a queue GenServer with timeout
5. Create a rate limiter GenServer

**GenServer Template:**
```elixir
defmodule MyServer do
  use GenServer

  # Client API
  def start_link(initial_state) do
    GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
  end

  def get_state do
    GenServer.call(__MODULE__, :get_state)
  end

  # Server Callbacks
  def init(initial_state) do
    {:ok, initial_state}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end
end
```

**Key Takeaway:** GenServer abstracts process boilerplate and provides structure.

---

### Phase 4: Supervision & Fault Tolerance (Weeks 6-7)

#### Chapter 5: Building Supervisors
**Location:** `chapter_5/thy_supervisor/`

**Concepts:**
- Supervisor behavior
- Supervision strategies:
  - `:one_for_one` - Restart only failed child
  - `:one_for_all` - Restart all children
  - `:rest_for_one` - Restart failed child and those started after it
- Child specifications
- Restart strategies: `:permanent`, `:temporary`, `:transient`
- "Let it crash" philosophy
- Linking and monitoring

**Project: Custom Supervisor**
```bash
cd chapter_5/thy_supervisor
mix deps.get
iex -S mix

# Experiment with crashes
```

**Practice Tasks:**
1. Build a supervisor for multiple workers
2. Test different supervision strategies
3. Implement max_restarts and max_seconds
4. Create a supervision tree with multiple levels
5. Monitor process crashes and restarts

**Supervision Tree Example:**
```
[Application]
└── [Supervisor]
    ├── [Worker1]
    ├── [Worker2]
    └── [Worker3]
```

**Key Takeaway:** Supervisors make your system self-healing.

---

### Phase 5: Advanced Architecture (Weeks 8-10)

#### Chapter 7: Pooly - Worker Pool Management
**Location:** `chapter_7/pooly/`

**This is the most important chapter for understanding real-world Elixir architecture.**

##### Version 1: Basic Pool
```bash
cd chapter_7/pooly/version_1
iex -S mix
```

**Concepts:**
- Worker pool pattern
- Resource management
- Checkout/checkin pattern
- Basic supervision tree

**Practice:** Implement a database connection pool

---

##### Version 2: Fault Tolerance
```bash
cd chapter_7/pooly/version_2
iex -S mix
```

**Concepts:**
- Recovery from worker crashes
- Consumer monitoring
- Process linking
- Handling unexpected failures

**Practice:** Add monitoring to your connection pool

---

##### Version 3: Multiple Pools
```bash
cd chapter_7/pooly/version_3
iex -S mix
```

**Concepts:**
- Multiple isolated pools
- Advanced supervision trees
- Error isolation
- Scalability patterns

**Supervision Tree:**
```
[Pooly.Supervisor]
├── [Pooly.PoolStarter]
└── [Pooly.PoolsSupervisor]
    └── [Pooly.PoolSupervisor] (per pool)
        ├── [Pooly.Server]
        └── [Pooly.WorkerSupervisor]
```

**Practice:** Create a multi-tenant connection pool system

---

##### Version 4: Advanced Features
```bash
cd chapter_7/pooly/version_4
iex -S mix
```

**Concepts:**
- Blocking and queuing
- Worker overflow (dynamic scaling)
- Transaction-based checkout
- Advanced resource management

**Practice:** Build a scalable HTTP client pool with overflow

---

**Key Pooly Takeaways:**
- Pool pattern is crucial for resource management
- Supervision trees can be complex and hierarchical
- Isolation prevents cascading failures
- Dynamic worker creation handles traffic spikes

---

### Phase 6: Distribution (Weeks 11-12)

#### Chapter 8: Blitzy - Distributed Load Testing
**Location:** `chapter_8/blitzy/`

**Concepts:**
- Distributed Elixir nodes
- Node naming and connection
- Remote process spawning
- Distributed supervision
- Cookie-based authentication
- Load distribution

**Project: HTTP Load Tester**
```bash
cd chapter_8/blitzy
mix deps.get
mix escript.build

# Start multiple nodes
iex --sname node1 -S mix
iex --sname node2 -S mix

# In node1:
Node.connect(:node2@hostname)
Blitzy.run(1000, "http://example.com")
```

**Practice Tasks:**
1. Build a distributed chat system
2. Create a distributed task queue
3. Implement distributed map-reduce
4. Build a distributed key-value store
5. Create a cluster of nodes with automatic discovery

**Distribution Commands:**
```elixir
# Connect nodes
Node.connect(:"node@host")

# List connected nodes
Node.list()

# Spawn on remote node
Node.spawn(node, fn -> IO.puts("Hello from remote") end)

# RPC call
:rpc.call(node, Module, :function, [args])
```

**Key Takeaway:** Distribution is built into the BEAM. Scaling horizontally is natural.

---

#### Chapter 9: Chucky - Failover & Takeover
**Location:** `chapter_9/chucky/`

**Concepts:**
- Distributed applications
- Failover mechanisms
- Takeover when primary returns
- Application configuration
- Node roles (primary/backup)
- High availability patterns

**Project: Distributed Chuck Norris Facts Service**
```bash
cd chapter_9/chucky
mix deps.get

# Terminal 1 (primary)
iex --sname primary -S mix

# Terminal 2 (backup)
iex --sname backup -S mix

# Test failover by killing primary
```

**Practice Tasks:**
1. Build a distributed counter with failover
2. Create a leader election system
3. Implement distributed locks
4. Build a replicated state machine
5. Create an active-passive cluster

**Key Takeaway:** Elixir makes highly available systems achievable.

---

### Phase 7: Testing & Verification (Week 13)

#### Chapter 11: Advanced Testing
**Location:** `chapter_11/`

##### Concurrency Testing with Concuerror
```bash
cd chapter_11/concuerror_playground
mix deps.get
```

**Concepts:**
- Race condition detection
- Systematic concurrency testing
- Process interleaving exploration
- State space exploration

**Practice:** Test your concurrent modules for race conditions

---

##### Property-Based Testing with QuickCheck
```bash
cd chapter_11/quickcheck_playground
mix test
```

**Concepts:**
- Property-based testing
- Generative testing
- Shrinking failing cases
- Testing invariants

**Practice Tasks:**
1. Write properties for your GenServers
2. Test list operations properties
3. Generate random test cases
4. Find edge cases automatically

**Key Takeaway:** Proper testing of concurrent systems requires special tools.

---

## Hands-On Projects

### Project 1: Chat Server (Beginner)
**Skills:** GenServer, supervision, message passing

Build a chat server where multiple clients can:
- Connect to the server
- Send messages to all users
- Send private messages
- List online users

**Architecture:**
- ChatServer GenServer
- Room GenServer (per room)
- User process (per user)
- Supervisor for rooms

---

### Project 2: URL Shortener (Intermediate)
**Skills:** GenServer, persistence, web interface

Build a URL shortener service:
- Shorten long URLs
- Redirect to original URL
- Track click statistics
- Expire old links

**Tech Stack:**
- Phoenix web framework
- GenServer for state
- ETS for fast lookups
- PostgreSQL for persistence

---

### Project 3: Job Queue (Intermediate)
**Skills:** Worker pools, supervision, fault tolerance

Build a background job processing system:
- Enqueue jobs
- Process jobs with worker pool
- Retry failed jobs
- Job priorities
- Job scheduling

**Architecture:**
- Queue GenServer
- Worker pool (use Pooly pattern)
- Job scheduler
- Dead letter queue

---

### Project 4: Real-Time Metrics Dashboard (Advanced)
**Skills:** Concurrency, Phoenix LiveView, statistics

Build a real-time metrics collection and visualization system:
- Collect metrics from multiple sources
- Aggregate statistics
- Real-time visualization
- Alerting on thresholds

**Components:**
- Metric collector processes
- Aggregator GenServer
- Phoenix LiveView for real-time UI
- Time-series data storage

---

### Project 5: Distributed Cache (Advanced)
**Skills:** Distribution, consistent hashing, replication

Build a distributed caching system:
- Key-value storage
- Distributed across nodes
- Replication for reliability
- Consistent hashing for distribution
- Automatic node discovery

**Architecture:**
- Cache node GenServer (per node)
- Hash ring for distribution
- Replication manager
- Gossip protocol for node discovery

---

### Project 6: Game Server (Advanced)
**Skills:** All OTP concepts, soft real-time

Build a multiplayer game server:
- Player connections
- Game rooms/lobbies
- Real-time game state synchronization
- Leaderboards
- Chat

**Tech Stack:**
- Phoenix Channels for WebSocket
- GenServer for game state
- Supervision for fault tolerance
- Distribution for scaling

---

## Where Elixir Shines

### 1. Real-Time Systems
**Why Elixir:**
- Soft real-time capabilities
- Low latency message passing
- Predictable performance

**Examples:**
- Chat applications (WhatsApp was built on Erlang)
- Live dashboards
- IoT systems
- Trading platforms

---

### 2. Web Applications
**Why Elixir:**
- Phoenix framework
- Built-in WebSocket support (Phoenix Channels)
- Handle millions of connections
- LiveView for real-time UIs

**Examples:**
- Social networks
- Collaborative tools
- Live streaming platforms
- E-commerce sites

---

### 3. API Servers
**Why Elixir:**
- High concurrency
- Low memory footprint
- Built-in fault tolerance
- Easy to scale

**Examples:**
- RESTful APIs
- GraphQL servers
- Microservices
- API gateways

---

### 4. Background Job Processing
**Why Elixir:**
- Natural worker pool patterns
- Excellent for parallel processing
- Supervisors handle failures
- No need for external queue services

**Examples:**
- Email sending
- Image processing
- Data import/export
- Scheduled tasks

---

### 5. Distributed Systems
**Why Elixir:**
- Distribution built into BEAM
- Easy node communication
- Distributed supervision
- Failover support

**Examples:**
- Distributed databases
- Load balancers
- Service discovery
- Clustered applications

---

### 6. Streaming Data
**Why Elixir:**
- GenStage for backpressure
- Flow for parallel processing
- Handle high-throughput streams

**Examples:**
- Log aggregation
- Metrics collection
- Data pipelines
- Stream processing

---

### 7. Embedded Systems
**Why Elixir:**
- Nerves framework
- Small footprint
- Fault tolerance
- Hot code updates

**Examples:**
- IoT devices
- Robotics
- Smart home systems
- Industrial automation

---

## Real-World Project Ideas

### Beginner Level

1. **Todo List API**
   - CRUD operations
   - User authentication
   - Task scheduling
   - Email reminders

2. **Weather Aggregator**
   - Fetch from multiple APIs
   - Cache results
   - Serve via HTTP API
   - Historical data

3. **RSS Feed Reader**
   - Subscribe to feeds
   - Periodic updates
   - Read/unread tracking
   - Search functionality

4. **Link Shortener**
   - Generate short codes
   - Redirect service
   - Click tracking
   - Custom aliases

---

### Intermediate Level

5. **Real-Time Chat Application**
   - Multiple rooms
   - Private messaging
   - File sharing
   - User presence
   - Message history

6. **Job Queue System**
   - Background job processing
   - Scheduled jobs
   - Priority queues
   - Retry logic
   - Web dashboard

7. **Image Processing Service**
   - Upload images
   - Resize/crop/filter
   - Worker pool for processing
   - CDN integration
   - Thumbnail generation

8. **Rate Limiter as a Service**
   - Token bucket algorithm
   - Per-user limits
   - Distributed rate limiting
   - HTTP API
   - Redis-style protocol

9. **Notification System**
   - Email/SMS/Push notifications
   - Template management
   - Delivery tracking
   - Retry logic
   - Priority delivery

10. **WebSocket Proxy**
    - Connection pooling
    - Message routing
    - Load balancing
    - Authentication
    - Metrics

---

### Advanced Level

11. **Distributed Key-Value Store**
    - Consistent hashing
    - Replication
    - Automatic failover
    - Node discovery
    - Data persistence
    - Client libraries

12. **Real-Time Analytics Platform**
    - Event ingestion
    - Stream processing
    - Aggregations
    - Real-time dashboards
    - Alerting
    - Historical queries

13. **Multi-Player Game Server**
    - Game lobbies
    - Real-time gameplay
    - Player matching
    - Leaderboards
    - Spectator mode
    - Replay system

14. **Content Delivery Network (CDN)**
    - Content caching
    - Geographic distribution
    - Cache invalidation
    - Request routing
    - Analytics
    - DDoS protection

15. **IoT Platform**
    - Device management
    - Data collection
    - Rule engine
    - Alerting
    - Device control
    - Time-series database

16. **Video Streaming Platform**
    - Live streaming
    - Transcoding pipeline
    - Adaptive bitrate
    - Chat integration
    - Recording
    - Analytics

17. **Cryptocurrency Exchange**
    - Order matching engine
    - Wallet management
    - Trading API
    - WebSocket feeds
    - Settlement system
    - Risk management

18. **Distributed Task Scheduler**
    - Cron-like scheduling
    - Distributed execution
    - Dependency management
    - Retry policies
    - Monitoring
    - Web UI

---

## Resources

### Official Documentation
- [Elixir Docs](https://elixir-lang.org/docs.html)
- [Hex.pm](https://hex.pm/) - Package manager
- [Phoenix Framework](https://phoenixframework.org/)

### Books
- "The Little Elixir & OTP Guidebook" by Benjamin Tan Wei Hao (this repo!)
- "Programming Elixir" by Dave Thomas
- "Elixir in Action" by Saša Jurić
- "Designing Elixir Systems with OTP" by James Edward Gray II

### Online Courses
- [Elixir School](https://elixirschool.com/)
- [Exercism Elixir Track](https://exercism.org/tracks/elixir)
- [Pragmatic Studio Elixir Course](https://pragmaticstudio.com/elixir)

### Community
- [Elixir Forum](https://elixirforum.com/)
- [Elixir Slack](https://elixir-slackin.herokuapp.com/)
- [ElixirConf](https://elixirconf.com/)

### Tools & Libraries
- **Phoenix** - Web framework
- **Ecto** - Database wrapper and query DSL
- **Nerves** - Embedded systems framework
- **Broadway** - Data processing pipelines
- **GenStage** - Stream processing with backpressure
- **ExUnit** - Built-in testing framework
- **Dialyzer** - Static analysis tool
- **Credo** - Code analysis tool

---

## Study Schedule

### 13-Week Intensive Track

| Week | Focus | Time Investment |
|------|-------|----------------|
| 1-2 | Foundations (Ch 1-2) | 10 hrs/week |
| 3-4 | Concurrency & GenServer (Ch 3-4) | 15 hrs/week |
| 5 | GenServer Deep Dive | 15 hrs/week |
| 6-7 | Supervision & Fault Tolerance (Ch 5) | 15 hrs/week |
| 8-10 | Pooly - All Versions (Ch 7) | 20 hrs/week |
| 11-12 | Distribution (Ch 8-9) | 15 hrs/week |
| 13 | Testing & Project (Ch 11) | 15 hrs/week |

**Total:** ~200 hours

### 6-Month Part-Time Track

| Month | Focus | Time Investment |
|-------|-------|----------------|
| 1 | Foundations & Concurrency Basics | 5 hrs/week |
| 2 | GenServer & Basic Supervision | 5 hrs/week |
| 3 | Advanced Architecture (Pooly v1-2) | 8 hrs/week |
| 4 | Advanced Architecture (Pooly v3-4) | 8 hrs/week |
| 5 | Distribution & Fault Tolerance | 8 hrs/week |
| 6 | Testing & Capstone Project | 10 hrs/week |

**Total:** ~180 hours

---

## Next Steps

1. **Set up your environment**
   ```bash
   # Install Elixir
   # Clone this repo
   git clone https://github.com/yourusername/the-little-elixir-otp-guidebook-code
   cd the-little-elixir-otp-guidebook-code
   ```

2. **Start with Chapter 1**
   ```bash
   cd chapter_1
   iex recursive.ex
   ```

3. **Join the community**
   - Elixir Forum
   - Elixir Slack
   - Reddit r/elixir

4. **Build projects**
   - Start small
   - Apply concepts immediately
   - Share your work

5. **Read the book**
   - "The Little Elixir & OTP Guidebook"
   - Follow along with this repo

---

## Conclusion

Elixir and OTP provide powerful tools for building concurrent, distributed, and fault-tolerant systems. The patterns you'll learn here apply to real-world production systems handling millions of users.

**Remember:**
- Start simple
- Build incrementally
- Embrace the "let it crash" philosophy
- Test concurrent behavior
- Join the community

**The BEAM VM has been in production for 30+ years. You're learning battle-tested technology.**

Happy coding! 🚀

---

*This roadmap is based on "The Little Elixir & OTP Guidebook" by Benjamin Tan Wei Hao*
