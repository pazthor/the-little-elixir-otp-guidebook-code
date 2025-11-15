defmodule ChatApp.User do
  use GenServer
  require Logger

  @moduledoc """
  A GenServer representing a chat user.

  Each user has a username and stores received messages.
  Messages are printed to the console when received.
  """

  # Client API

  @doc """
  Starts a new user process with the given username.
  """
  def start_link(username) do
    GenServer.start_link(__MODULE__, username, name: via_tuple(username))
  end

  @doc """
  Sends a message to a user.
  """
  def send_message(username, message) do
    GenServer.cast(via_tuple(username), {:message, message})
  end

  @doc """
  Gets the message history for a user.
  """
  def get_messages(username) do
    GenServer.call(via_tuple(username), :get_messages)
  end

  # Helper to create a via tuple for Registry
  defp via_tuple(username) do
    {:via, Registry, {ChatApp.UserRegistry, username}}
  end

  # Server Callbacks

  @impl true
  def init(username) do
    Logger.info("User #{username} started")
    {:ok, %{username: username, messages: []}}
  end

  @impl true
  def handle_cast({:message, message}, state) do
    IO.puts("[#{state.username}] #{message}")
    new_messages = [message | state.messages]
    {:noreply, %{state | messages: new_messages}}
  end

  @impl true
  def handle_call(:get_messages, _from, state) do
    {:reply, Enum.reverse(state.messages), state}
  end
end
