defmodule ChatAppTest do
  use ExUnit.Case
  doctest ChatApp

  setup do
    # Create unique names for each test to avoid conflicts
    user1 = "alice_#{:rand.uniform(10000)}"
    user2 = "bob_#{:rand.uniform(10000)}"
    room = "room_#{:rand.uniform(10000)}"

    {:ok, user1: user1, user2: user2, room: room}
  end

  test "create and manage users", %{user1: user1} do
    assert {:ok, _pid} = ChatApp.create_user(user1)
    # Creating same user again should fail
    assert {:error, {:already_started, _pid}} = ChatApp.create_user(user1)
  end

  test "create and manage rooms", %{room: room} do
    assert {:ok, _pid} = ChatApp.create_room(room)
    # Creating same room again should fail
    assert {:error, {:already_started, _pid}} = ChatApp.create_room(room)
  end

  test "users can join and leave rooms", %{user1: user1, room: room} do
    {:ok, _} = ChatApp.create_user(user1)
    {:ok, _} = ChatApp.create_room(room)

    assert :ok = ChatApp.join_room(room, user1)
    assert [^user1] = ChatApp.list_users(room)

    assert :ok = ChatApp.leave_room(room, user1)
    assert [] = ChatApp.list_users(room)
  end

  test "messages are broadcast to all users in room", %{user1: user1, user2: user2, room: room} do
    {:ok, _} = ChatApp.create_user(user1)
    {:ok, _} = ChatApp.create_user(user2)
    {:ok, _} = ChatApp.create_room(room)

    ChatApp.join_room(room, user1)
    ChatApp.join_room(room, user2)

    ChatApp.send_message(room, user1, "Hello!")

    # Give message time to be delivered
    Process.sleep(50)

    # Both users should have received the message
    messages1 = ChatApp.user_messages(user1)
    messages2 = ChatApp.user_messages(user2)

    assert length(messages1) >= 2  # Join message + broadcast
    assert length(messages2) >= 2  # Join message + broadcast
  end

  test "room maintains message history", %{user1: user1, room: room} do
    {:ok, _} = ChatApp.create_user(user1)
    {:ok, _} = ChatApp.create_room(room)

    ChatApp.join_room(room, user1)
    ChatApp.send_message(room, user1, "Message 1")
    ChatApp.send_message(room, user1, "Message 2")
    ChatApp.send_message(room, user1, "Message 3")

    # Give messages time to be processed
    Process.sleep(50)

    history = ChatApp.room_history(room)
    assert length(history) == 3
  end

  test "system messages are sent on join/leave", %{user1: user1, user2: user2, room: room} do
    {:ok, _} = ChatApp.create_user(user1)
    {:ok, _} = ChatApp.create_user(user2)
    {:ok, _} = ChatApp.create_room(room)

    ChatApp.join_room(room, user1)
    ChatApp.join_room(room, user2)

    Process.sleep(50)

    messages = ChatApp.user_messages(user1)
    # Should have received system message about user2 joining
    assert Enum.any?(messages, fn msg -> String.contains?(msg, "#{user2} joined") end)

    ChatApp.leave_room(room, user2)
    Process.sleep(50)

    messages = ChatApp.user_messages(user1)
    # Should have received system message about user2 leaving
    assert Enum.any?(messages, fn msg -> String.contains?(msg, "#{user2} left") end)
  end
end
