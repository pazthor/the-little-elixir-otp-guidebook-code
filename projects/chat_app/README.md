# ChatApp

A simple chat application demonstrating Elixir/OTP concepts including GenServer, supervision trees, and process registries.

## Concepts Demonstrated

- **GenServer**: User and Room processes
- **Supervision**: Dynamic supervisors for managing user and room processes
- **Registry**: Named process lookup for users and rooms
- **Message Passing**: Broadcasting messages between processes
- **Fault Tolerance**: Supervised processes that can restart on failure

## Architecture

```
[ChatApp.Supervisor]
├── [Registry] - User registry for process lookup
├── [Registry] - Room registry for process lookup
├── [ChatApp.UserSupervisor] - Dynamic supervisor for users
│   └── [ChatApp.User] - GenServer per user
└── [ChatApp.RoomSupervisor] - Dynamic supervisor for rooms
    └── [ChatApp.Room] - GenServer per room
```

## Features

- Create users and chat rooms dynamically
- Users can join/leave rooms
- Broadcast messages to all users in a room
- System notifications (user join/leave)
- Message history (last 100 messages per room)
- User message inbox

## Installation

```bash
cd projects/chat_app
mix deps.get
```

## Running

```bash
iex -S mix
```

## Usage Examples

```elixir
# Create users
ChatApp.create_user("alice")
ChatApp.create_user("bob")
ChatApp.create_user("charlie")

# Create a room
ChatApp.create_room("general")

# Join the room
ChatApp.join_room("general", "alice")
ChatApp.join_room("general", "bob")
ChatApp.join_room("general", "charlie")

# Send messages
ChatApp.send_message("general", "alice", "Hello everyone!")
ChatApp.send_message("general", "bob", "Hi Alice!")
ChatApp.send_message("general", "charlie", "Hey folks!")

# List users in room
ChatApp.list_users("general")
#=> ["alice", "bob", "charlie"]

# Get room message history
ChatApp.room_history("general")

# Get user's messages
ChatApp.user_messages("alice")

# Leave room
ChatApp.leave_room("general", "bob")

# Multiple rooms
ChatApp.create_room("elixir-help")
ChatApp.join_room("elixir-help", "alice")
ChatApp.send_message("elixir-help", "alice", "How do I use GenServer?")
```

## Testing

```bash
mix test
```

## Extensions to Try

1. **Private Messaging**: Add direct user-to-user messaging
2. **Persistence**: Store messages in a database (PostgreSQL/ETS)
3. **Web Interface**: Add Phoenix web interface with LiveView
4. **WebSockets**: Use Phoenix Channels for real-time web chat
5. **Authentication**: Add user authentication and authorization
6. **Moderation**: Add room moderators and kick/ban functionality
7. **Encryption**: Add end-to-end encryption for messages
8. **Presence**: Track online/offline status
9. **Read Receipts**: Track which messages users have read
10. **File Sharing**: Allow file uploads and sharing

## Learning Points

This project demonstrates several important OTP patterns:

1. **Process per entity**: Each user and room is a separate process
2. **Dynamic supervision**: Processes are created and destroyed dynamically
3. **Process registry**: Using Registry for named process lookup (vs global names)
4. **Async message passing**: Messages are delivered asynchronously
5. **State management**: Each GenServer maintains its own state
6. **Supervision strategies**: Using `:one_for_one` strategy
7. **Process isolation**: Failures in one user/room don't affect others

## Common Patterns Used

### Via Tuples for Registry

```elixir
defp via_tuple(name) do
  {:via, Registry, {ChatApp.UserRegistry, name}}
end
```

This pattern allows you to name processes dynamically without global name conflicts.

### Dynamic Supervisor

```elixir
DynamicSupervisor.start_child(
  ChatApp.UserSupervisor,
  {ChatApp.User, username}
)
```

This allows processes to be started dynamically at runtime.

### GenServer Callbacks

```elixir
def handle_cast({:broadcast, username, message}, state) do
  # Process async message
  {:noreply, new_state}
end

def handle_call(:list_users, _from, state) do
  # Process sync message
  {:reply, users, state}
end
```

Understanding when to use `cast` (async) vs `call` (sync) is crucial.

## Next Steps

After mastering this project, try:

1. Building the Job Queue project for worker pool patterns
2. Adding Phoenix web framework for a web interface
3. Implementing a distributed version across multiple nodes
4. Adding persistence with Ecto and PostgreSQL
5. Building more complex features like threads, reactions, etc.
