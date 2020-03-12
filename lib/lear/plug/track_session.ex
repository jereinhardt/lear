defmodule Lear.Plug.TrackSession do
  @moduledoc """
  Saves session data for any new sessions and stores the session id in a cookie.

  ### Options

  * `:module` - The application's Lear implementation module.
  * `:detect_bots` - Stops the plug from tracking data if the request is coming 
  from a bot.  Defaults to `true`.
  """

  import Lear.Plug.Helper

  @behaviour Plug

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, opts) do
    with true <- safe_conn?(conn, opts),
      mod <- fetch_module!(conn, opts),
      session_id <- find_session_cookie(mod, conn),
      {:ok, session} <- save_or_update_session(session_id, mod, conn),
      updated_conn <- add_session_cookie(mod, conn, session)
    do
      updated_conn
    else
      _ -> conn
    end
  end

  defp find_session_cookie(mod, conn) do
    cookie_name = session_cookie_name(mod)
    conn
    |> Plug.Conn.fetch_cookies()
    |> Map.get(:cookies)
    |> Map.get(cookie_name)
  end

  defp session_cookie_name(mod) do
    apply(mod, :config, [:session_cookie_name])
  end

  defp add_session_cookie(mod, conn, %{id: session_id} = session) when is_integer(session_id) do
    session = Map.update!(session, :id, &Integer.to_string/1)
    add_session_cookie(mod, conn, session)
  end

  defp add_session_cookie(mod, conn, session) do
    cookie_name = session_cookie_name(mod)
    Plug.Conn.put_resp_cookie(conn, cookie_name, session.id)
  end

  defp save_or_update_session(session_id, mod, conn) when is_nil(session_id) do
    apply(mod, :track_session, [conn])
  end

  defp save_or_update_session(session_id, mod, conn) do
    store = Lear.store_module(mod)
    session = apply(store, :get_session, [session_id])
    if session.user_id do
      {:ok, session }
    else
      update_session_if_user_is_present(session, mod, store, conn)
    end
  end

  defp update_session_if_user_is_present(session, mod, store, conn) do
    with {:ok, user_id} <- apply(mod, :current_user_resource, [conn]),
      false <- is_nil(user_id)
    do
      apply(store, :update_session, [session, %{user_id: user_id}])
    else
      _ -> {:ok, session}
    end
  end
end