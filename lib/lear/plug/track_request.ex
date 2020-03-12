defmodule Lear.Plug.TrackRequest do
  @moduledoc """
  Saves data for each request made to the server.  By default, only `GET` 
  requests are tracked.  In order to associate each request with a session, this
  plug must be called after `Lear.Plug.TrackSession` in the pipeline.

  ### Options:

  * `:module` - The application's Lear implementation module.
  * `:detect_bots` - Stops the plug from tracking data if the request is coming 
  from a bot.  Defaults to `true`.
  * `:track_request_methods` - A list of HTTP request methods that should be 
  tracked.  By default, data will only be saved for `GET` requests.
  """

  import Lear.Plug.Helper

  @behaviour Plug

  @methods ["GET"]

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, opts) do
    with true <- safe_conn?(conn, opts),
      true <- trackable_method?(conn, opts),
      mod <- fetch_module!(conn, opts)
    do
      apply(mod, :track_request, [conn])
    end

    conn
  end

  defp trackable_method?(conn, opts) do
    methods = Keyword.get(opts, :track_request_methods, @methods)
    Enum.member?(methods, conn.method)
  end
end