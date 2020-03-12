defmodule LearTest do
  use Lear.ConnCase

  test "track_request/2" do
    conn = build_conn() |> Plug.Conn.fetch_cookies()
    session_id = conn.cookies["_lear_session_"]

    {:ok, request} = Lear.track_request(Lear.TestModule, conn)

    assert request.name == "request"
    assert request.session_id == session_id
  end

  test "track_session/2" do
    user_id = 1
    conn = %Plug.Conn{assigns: %{user_id: user_id}}

    {:ok, session} = Lear.track_session(Lear.TestModule, conn)
    assert is_map(session)
    assert Map.has_key?(session, :id)
    assert Map.has_key?(session, :user_id)
  end

  test "track/4" do
    conn = build_conn() |> Plug.Conn.fetch_cookies()
    session_id = conn.cookies["_lear_session_"]
    name = "New Event"
    props = %{}

    {:ok, event} = Lear.track(Lear.TestModule, conn, name, props)

    assert Map.has_key?(event, :id)
    assert event.session_id == session_id
    assert event.name == name
    assert event.properties == props
  end
end
