defmodule Lear.ConnCase do
  use ExUnit.CaseTemplate

  def build_conn(opts \\ []) do
    {session_opts, opts} = Keyword.pop(opts, :session, [])
    %{id: session_id} = build_session(session_opts)
    cookie = Plug.Conn.Cookies.encode("_lear_session_", %{value: session_id})
    attrs = Map.new(opts)

    %Plug.Conn{}
    |> Map.merge(attrs)
    |> Plug.Conn.put_req_header("cookie", cookie)
  end

  def build_session(opts \\ []) do
    {user_id, opts} = Keyword.pop(opts, :user_id)
    {:ok, session} = Lear.TestStore.save_session(user_id, Map.new(opts))
    session
  end

  using do
    quote do
      import Lear.ConnCase
    end
  end
end