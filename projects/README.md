# Elixir OTP Projects

This directory contains fully-implemented Elixir OTP projects for hands-on learning. Each project demonstrates real-world patterns and best practices for building concurrent, fault-tolerant applications.

## Projects

### 1. ChatApp - Multi-User Chat Server

**Difficulty:** Beginner
**Location:** `chat_app/`

A complete chat application demonstrating:
- GenServer for user and room management
- Dynamic supervision for process lifecycle
- Registry for named process lookup
- Message broadcasting between processes
- State management and message history

**Quick Start:**
```bash
cd chat_app
mix deps.get
iex -S mix

# Try it out
ChatApp.create_user("alice")
ChatApp.create_room("general")
ChatApp.join_room("general", "alice")
ChatApp.send_message("general", "alice", "Hello!")
```

**What You'll Learn:**
- Process per entity pattern
- Dynamic supervisors
- Registry-based naming
- Async message passing
- GenServer callbacks

---

### 2. JobQueue - Background Job Processor

**Difficulty:** Intermediate
**Location:** `job_queue/`

A background job processing system with:
- Priority-based job queue
- Worker pool (5 workers by default)
- Automatic retry with exponential backoff
- Job scheduling for future execution
- ETS-based storage
- Comprehensive statistics

**Quick Start:**
```bash
cd job_queue
mix deps.get
iex -S mix

# Define a worker
defmodule EmailWorker do
  def send_email(to, subject) do
    IO.puts("Sending email to #{to}: #{subject}")
    :ok
  end
end

# Enqueue jobs
JobQueue.enqueue(EmailWorker, :send_email, ["user@example.com", "Hello"])
JobQueue.stats()
```

**What You'll Learn:**
- Worker pool pattern
- Priority queues with ETS
- Retry logic and exponential backoff
- Job scheduling
- Performance monitoring
- Fault tolerance

---

## Prerequisites

Before running these projects, ensure you have:

1. **Elixir** installed (version 1.14 or later)
   ```bash
   # macOS
   brew install elixir

   # Ubuntu/Debian
   sudo apt install elixir

   # Verify
   elixir --version
   ```

2. **Basic Elixir knowledge**
   - Complete chapters 1-5 of the guidebook first
   - Understand GenServer, supervision, and processes

## Running the Projects

Each project follows the standard Mix project structure:

```bash
# Navigate to project directory
cd chat_app  # or job_queue

# Install dependencies
mix deps.get

# Compile the project
mix compile

# Run tests
mix test

# Start interactive shell
iex -S mix
```

## Project Structure

Both projects follow this structure:

```
project_name/
├── lib/
│   ├── project_name.ex           # Public API
│   └── project_name/
│       ├── application.ex         # Supervision tree
│       └── *.ex                   # Core modules
├── test/
│   ├── test_helper.exs
│   └── project_name_test.exs     # Tests
├── mix.exs                        # Project configuration
└── README.md                      # Project documentation
```

## Learning Path

We recommend studying the projects in this order:

1. **Start with ChatApp** (Beginner)
   - Simpler architecture
   - Fewer moving parts
   - Great introduction to GenServer and supervision
   - Run the examples in the README
   - Read through the code
   - Modify and experiment

2. **Move to JobQueue** (Intermediate)
   - More complex architecture
   - Introduces worker pools
   - ETS storage patterns
   - Retry logic and scheduling
   - Study the tests to understand behavior

3. **Extend the Projects**
   - Try the suggested extensions in each README
   - Add new features
   - Combine concepts from both projects

## Testing

Both projects include comprehensive test suites:

```bash
# Run all tests
mix test

# Run specific test file
mix test test/chat_app_test.exs

# Run with coverage
mix test --cover

# Run in verbose mode
mix test --trace
```

## Common Patterns

### 1. Via Tuples for Registry

Both projects use Registry with via tuples:

```elixir
defp via_tuple(name) do
  {:via, Registry, {MyApp.Registry, name}}
end

def start_link(name) do
  GenServer.start_link(__MODULE__, name, name: via_tuple(name))
end
```

**Benefits:**
- No global name conflicts
- Can have multiple instances with different names
- Process discovery by name

### 2. Dynamic Supervisors

Creating processes on-demand:

```elixir
DynamicSupervisor.start_child(
  MyApp.DynamicSupervisor,
  {MyApp.Worker, args}
)
```

**Benefits:**
- Processes created as needed
- Automatic restart on crash
- Process cleanup on termination

### 3. GenServer State Management

```elixir
def handle_call(:get_state, _from, state) do
  {:reply, state, state}
end

def handle_cast({:update, new_data}, state) do
  {:noreply, Map.put(state, :data, new_data)}
end
```

**Benefits:**
- Encapsulated state
- Process isolation
- Concurrent access without locks

## Troubleshooting

### Port Already in Use
If you see "address already in use" errors:
```bash
# Kill any running beam processes
pkill -9 beam
```

### Tests Timing Out
Some tests use `Process.sleep` for async operations:
- This is normal for testing async systems
- Tests may take several seconds
- Increase timeout if needed: `assert_receive :msg, 5000`

### Registry Conflicts
If you get "already started" errors:
```bash
# Restart your iex session
Ctrl+C, Ctrl+C  # or
System.halt()
```

## Extensions and Challenges

### ChatApp Extensions

1. **Private Messaging**: Add user-to-user messaging
2. **Persistence**: Store messages in PostgreSQL
3. **Web UI**: Add Phoenix with WebSockets
4. **Presence**: Track online/offline status
5. **Authentication**: Add user auth

### JobQueue Extensions

1. **Persistence**: Use PostgreSQL instead of ETS
2. **Dashboard**: Phoenix LiveView monitoring
3. **Dependencies**: Implement job dependencies (DAG)
4. **Distributed**: Run across multiple nodes
5. **Cancellation**: Cancel pending jobs

## Additional Resources

### Documentation
- Each project has a detailed README
- Code is documented with @moduledoc and @doc
- Run `mix docs` to generate HTML documentation

### Related Chapters
- **Chapter 3**: Process basics (Metex)
- **Chapter 4**: GenServer pattern
- **Chapter 5**: Supervision
- **Chapter 7**: Worker pools (Pooly)

### Further Reading
- [GenServer Guide](https://elixir-lang.org/getting-started/mix-otp/genserver.html)
- [Supervisor and Application](https://elixir-lang.org/getting-started/mix-otp/supervisor-and-application.html)
- [Registry Documentation](https://hexdocs.pm/elixir/Registry.html)
- [ETS Documentation](https://www.erlang.org/doc/man/ets.html)

## Getting Help

If you run into issues:

1. **Read the error message carefully** - Elixir errors are descriptive
2. **Check the project README** - Contains usage examples
3. **Run the tests** - See working examples
4. **Study the code** - Well-commented and documented
5. **Experiment in IEx** - Try things interactively

## Next Steps

After completing these projects:

1. **Study Production Libraries**
   - Phoenix Framework (web)
   - Oban (job queue)
   - Horde (distributed processes)

2. **Build Your Own Project**
   - Apply the patterns learned
   - Start small, iterate
   - Share with the community

3. **Advanced Topics**
   - Distribution (Chapter 8-9)
   - Testing (Chapter 11)
   - Production deployment

## Contributing

Found an issue or want to improve a project?

1. Fix the issue
2. Add tests if applicable
3. Update documentation
4. Submit your changes

## License

These projects are provided as educational examples to accompany "The Little Elixir & OTP Guidebook".

---

**Happy Learning!** 🚀

Remember: The best way to learn is by doing. Run the code, break it, fix it, and extend it. Don't just read - experiment!
