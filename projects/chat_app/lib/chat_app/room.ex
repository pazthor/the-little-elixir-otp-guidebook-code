defmodule ChatApp.Room do
  use GenServer
  require Logger

  @moduledoc """
  A GenServer representing a chat room.

  Manages users in the room, broadcasts messages to all users,
  and maintains message history.
  """

  # Client API

  @doc """
  Starts a new chat room with the given name.
  """
  def start_link(room_name) do
    GenServer.start_link(__MODULE__, room_name, name: via_tuple(room_name))
  end

  @doc """
  Adds a user to the room.
  """
  def join(room_name, username) do
    GenServer.call(via_tuple(room_name), {:join, username})
  end

  @doc """
  Removes a user from the room.
  """
  def leave(room_name, username) do
    GenServer.call(via_tuple(room_name), {:leave, username})
  end

  @doc """
  Broadcasts a message to all users in the room.
  """
  def broadcast(room_name, username, message) do
    GenServer.cast(via_tuple(room_name), {:broadcast, username, message})
  end

  @doc """
  Lists all users currently in the room.
  """
  def list_users(room_name) do
    GenServer.call(via_tuple(room_name), :list_users)
  end

  @doc """
  Gets the message history for the room.
  """
  def get_history(room_name) do
    GenServer.call(via_tuple(room_name), :get_history)
  end

  # Helper to create a via tuple for Registry
  defp via_tuple(room_name) do
    {:via, Registry, {ChatApp.RoomRegistry, room_name}}
  end

  # Server Callbacks

  @impl true
  def init(room_name) do
    Logger.info("Room '#{room_name}' created")
    {:ok, %{
      name: room_name,
      users: MapSet.new(),
      messages: []
    }}
  end

  @impl true
  def handle_call({:join, username}, _from, state) do
    if MapSet.member?(state.users, username) do
      {:reply, {:error, :already_in_room}, state}
    else
      new_users = MapSet.put(state.users, username)
      broadcast_system_message(new_users, "#{username} joined the room")
      Logger.info("User #{username} joined room #{state.name}")
      {:reply, :ok, %{state | users: new_users}}
    end
  end

  @impl true
  def handle_call({:leave, username}, _from, state) do
    if MapSet.member?(state.users, username) do
      new_users = MapSet.delete(state.users, username)
      broadcast_system_message(new_users, "#{username} left the room")
      Logger.info("User #{username} left room #{state.name}")
      {:reply, :ok, %{state | users: new_users}}
    else
      {:reply, {:error, :not_in_room}, state}
    end
  end

  @impl true
  def handle_call(:list_users, _from, state) do
    {:reply, MapSet.to_list(state.users), state}
  end

  @impl true
  def handle_call(:get_history, _from, state) do
    {:reply, Enum.reverse(state.messages), state}
  end

  @impl true
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

  # Private helpers

  defp broadcast_system_message(users, message) do
    Enum.each(users, fn user ->
      ChatApp.User.send_message(user, "[SYSTEM] #{message}")
    end)
  end
end
