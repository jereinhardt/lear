defmodule Lear.Plug.TrackSesssionTest do
  use Lear.ConnCase

  alias Lear.Plug.TrackSession
  alias Plug.Conn

  describe "call/2" do
    test "saves the session id as a cookie" do
      cookie =
        %Conn{}
        |> TrackSession.call(module: Lear.TestModule)
        |> Conn.fetch_cookies()
        |> Map.get(:resp_cookies, %{})
        |> Map.get("_lear_session_")

      assert !is_nil(cookie)
    end

    test "updates the session with the user id if it is newly present" do
      user_id = 1
      conn = build_conn() |> Conn.assign(:user_id, user_id)

      session =
        conn
        |> TrackSession.call(module: Lear.TestModule)
        |> Conn.fetch_cookies()
        |> Map.get(:cookies)
        |> Map.get("_lear_session_")
        |> Lear.TestStore.get_session()

      assert session.user_id == user_id
    end
  end
end