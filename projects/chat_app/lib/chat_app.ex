defmodule ChatApp do
  @moduledoc """
  ChatApp - A simple chat application built with Elixir and OTP.

  This module provides the public API for the chat application.
  Users can create rooms, join/leave rooms, and send messages.

  ## Examples

      # Start users
      ChatApp.create_user("alice")
      ChatApp.create_user("bob")

      # Create a room
      ChatApp.create_room("general")

      # Join the room
      ChatApp.join_room("general", "alice")
      ChatApp.join_room("general", "bob")

      # Send messages
      ChatApp.send_message("general", "alice", "Hello everyone!")
      ChatApp.send_message("general", "bob", "Hi Alice!")

      # List users in room
      ChatApp.list_users("general")
      #=> ["alice", "bob"]

      # Leave room
      ChatApp.leave_room("general", "bob")

  """

  @doc """
  Creates a new user process.

  Returns `{:ok, pid}` on success, or `{:error, reason}` if the user already exists.
  """
  def create_user(username) do
    DynamicSupervisor.start_child(
      ChatApp.UserSupervisor,
      {ChatApp.User, username}
    )
  end

  @doc """
  Creates a new chat room.

  Returns `{:ok, pid}` on success, or `{:error, reason}` if the room already exists.
  """
  def create_room(room_name) do
    DynamicSupervisor.start_child(
      ChatApp.RoomSupervisor,
      {ChatApp.Room, room_name}
    )
  end

  @doc """
  Adds a user to a chat room.

  Returns `:ok` on success, or `{:error, reason}` on failure.
  """
  def join_room(room_name, username) do
    ChatApp.Room.join(room_name, username)
  end

  @doc """
  Removes a user from a chat room.

  Returns `:ok` on success, or `{:error, reason}` on failure.
  """
  def leave_room(room_name, username) do
    ChatApp.Room.leave(room_name, username)
  end

  @doc """
  Sends a message from a user to all users in a room.
  """
  def send_message(room_name, username, message) do
    ChatApp.Room.broadcast(room_name, username, message)
  end

  @doc """
  Lists all users currently in a room.
  """
  def list_users(room_name) do
    ChatApp.Room.list_users(room_name)
  end

  @doc """
  Gets the message history for a room.
  """
  def room_history(room_name) do
    ChatApp.Room.get_history(room_name)
  end

  @doc """
  Gets the messages received by a user.
  """
  def user_messages(username) do
    ChatApp.User.get_messages(username)
  end
end
