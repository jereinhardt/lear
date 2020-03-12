defmodule Lear.Plug.TrackRequestTest do
  use Lear.ConnCase

  setup do
    Lear.TestStore.clear!
    {:ok, %{conn: build_conn()}}
  end

  describe "call/2" do
    test "saves a request event to the store", %{conn: conn} do
      Lear.Plug.TrackRequest.call(conn, module: Lear.TestModule)
      events = Lear.TestStore.all_events()
      {_, event} = List.first(events)

      assert Enum.count(events) == 1
      assert event.name == "request"
    end

    test "does nothing with unsupported request methods", %{conn: conn} do
      Lear.Plug.TrackRequest.call(
        conn,
        module: Lear.TestModule, track_request_methods: ["POST"]
      )
      events = Lear.TestStore.all_events()

      assert Enum.count(events) == 0
    end
  end
end