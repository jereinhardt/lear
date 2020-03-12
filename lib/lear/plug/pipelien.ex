defmodule Lear.Plug.Pipeline do
  @moduledoc """
  Build plug pipelines with the use of Lear's associated plugs.

  Lear's plugs take their own options, but they all require a `:module` option
  as a reference to the application's Lear implementation module.

  The easiest way to make use of Lear is to evoke the pre-built pipeline as a
  plug.

  ```elixir
  plug Lear.Plug.Pipeline, module: MyApp.Lear
  ```

  This will filter connections through `Lear.Plug.TrackSession` and 
  `Lear.Plug.TrackRequest`.

  You can also create a module to define a custom pipeline.

  ```elixir
  defmodule MyApp.Lear.Pipeline do
    use Lear.Plug.Pipeline, module: MyApp.Lear

    plug Lear.Plug.TrackSession
    plug Lear.Plug.TrackRequest
    plug :track_utm_requests

    defp track_utm_requests(conn, _opts) do
      utm_params =
        conn.query_params
        |> Enum.filter({k, _} -> String.starts_with?(k, "utm") end)
        |> Map.new()
      MyApp.Lear.track(conn, "utm request made", utm_params)

      conn
    end
  end
  ```

  You can then include your custom pipeline like a normal plug

  ```elixir
  plug MyApp.Lear.Pipeline
  ```

  ### Options

  If using Lear's default pipeline, you can provide options when you call the 
  plug.  If you are building your own pipeline, you can provide either provide 
  options when you `use Lear.Plug.Pipeline`, or when calling the plug.

  * `:module` - The application's Lear implementation module

  When using Lear's default pipeline, you can also provide options for its 
  children plugs.  Those options will be provided to those children when they 
  are called.  See the documentation for `Lear.Plug.TrackSession` and 
  `Lear.Plug.TrackRequest` for more information on their options.
  """

  defmacro __using__(config_opts) do
    quote do
      use Plug.Builder

      @impl Plug
      def init(opts) do
        Keyword.merge(unquote(config_opts), opts)
      end

      @impl Plug
      def call(conn, opts) do
        Lear.Plug.Pipeline.prepare_conn(conn, opts)
        |> super(opts)
      end
    end
  end

  use Plug.Builder

  plug Lear.Plug.TrackSession, builder_opts()
  plug Lear.Plug.TrackRequest, builder_opts()

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, opts) do
    prepare_conn(conn, opts)
    |> super(opts)
  end

  @doc """
  Prepare a connection to communicate with other Lear plugs by updating it's
  private data.
  """

  @spec prepare_conn(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def prepare_conn(conn, opts) do
    maybe_put_module(conn, opts)
  end

  defp maybe_put_module(conn, opts) do
    if Map.has_key?(conn.private, :lear_module) do
      conn
    else
      module = Keyword.get(opts, :module)
      Plug.Conn.put_private(conn, :lear_module, module)
    end
  end
end