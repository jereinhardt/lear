defmodule Lear do
  @moduledoc """
  Lear provides a singular interface for saving and interacting with tracking 
  data in Elixir applications.

  When using Lear, an implementation module is required:

  ```elixir
  defmodule MyApp.Lear do
    use Lear, store: MyApp.LearStore

    def current_user_resource(conn) do
      case conn.assigns do
        %{current_user: user} -> {:ok, user.id}
        _ -> {:error, nil}
      end
    end
  end
  ```

  This module will serve as the public API for saving and retrieving tracking 
  data.  Tracking data is split into two categories: Sessions and Events.

  Events are defined as:

  * Generic instances of data that can be tracked
  * Have a `name` to distinguish what type of event it is
  * Have a map of `properties` to define event details
  * Are associated with a corresponding Session

  Sessions are defined as:

  * A persistent set of interactions made by a single user
  * Has many associated Events
  * Has an associated `user` (optional)

  Many other properties can be associated with Events and Sessions, but in 
  general, Sessions are long-term chains of interactions, while Events are the 
  individual interactions themselves.

  ## Generated Functions

  ### track_request(conn)

  Saves data related to an HTTP request.

  A Request is a specific type of Event that Lear saves under the name 
  `request`.  This event is saved automatically when a connection goes through
  `Lear.Plug.Pipeline`.  The properties related to a Request are derived from
  the function `request_properties/1`.

  ### track_session(conn)

  Saves data related to a Session.

  Extra properties related to a Session are derived from the function 
  `session_properties/1`

  ### track(conn, name, properties \\\\ %{})

  Saves a generic Event.

  Arguments:
  * `conn` - The `%Plug.Conn{}` connection
  * `name` - The name of the event
  * `properties` - The properties related to the event

  ### config/1

  Returns the value of the module's configuration based on the given key.

  ### request_properties(conn)

  Overridable.

  Returns a map of the properties that are to be saved with a Request event.  By
  default, this function takes the following properties from the connection: 
  `params, host, method, request_path`.

  ### session_properties(conn)

  Overridable.

  Returns a map of properties that are to be saved with a Session.  By default, 
  this returns an empty map.

  ### current_session_resource(conn)

  Returns the identifier used to retrieve the current session from the Store.
  In database-backed stores, this will likely be an id or uuid.

  ### current_user_resource(conn)

  Overridable.

  Returns the identifier for the current user.  By default, this will return
  `{:error, nil}`.
  """

  @type id :: String.t() | integer
  @type response :: { :ok | :error, any }

  @doc """
  Returns the identifier for the current user present within the connection.
  """
  @callback current_user_resource(Plug.Conn.t()) :: { :ok, id } | { :error, any }

  @doc """
  Returns a map of properties that are meant to be saved with a session
  when it is tracked.
  """
  @callback session_properties(Plug.Conn.t()) :: map

  @doc """
  Returns a map of properties that are meant to be saved with a request
  when it is tracked.
  """
  @callback request_properties(Plug.Conn.t()) :: map

  @optional_callbacks current_user_resource: 1,
    session_properties: 1,
    request_properties: 1

  defmacro __using__(opts) do
    default_opts = [session_cookie_name: "_lear_session_"]
    final_opts = Keyword.merge(default_opts, opts)

    quote do
      @behaviour Lear

      @type id :: String.t() | integer
      @type response :: {:ok | :error, any}

      @config unquote(final_opts)

      @doc """
      Retrieves the configuration for this module.
      """

      @spec config(atom | String.t()) :: any
      def config(key), do: Keyword.get(@config, key)

      @doc """
      Saves data for the current request.

      See `Lear.track_request/2` for more information.
      """

      @spec track_request(Plug.Conn.t()) :: response
      def track_request(conn) do
        Lear.track_request(__MODULE__, conn)
      end

      @doc """
      Saves data for the current session.

      See `Lear.track_session/2` for more information.
      """

      @spec track_session(Plug.Conn.t()) :: response
      def track_session(conn) do
        Lear.track_session(__MODULE__, conn)
      end

      @doc """
      Saves data for an event.

      See `Lear.track/4` for more information.
      """

      @spec track(Plug.Conn.t(), String.t(), map) :: response
      def track(conn, name, properties \\ %{}) do
        Lear.track(__MODULE__, conn, name, properties)
      end

      @doc """
      Returns the identifier for the current session present within the
      connection.
      """

      @spec current_session_resource(Plug.Conn.t()) :: { :ok, id } | { :error, any }
      def current_session_resource(conn) do
        conn = Plug.Conn.fetch_cookies(conn)
        cookie_name = config(:session_cookie_name)
        
        case conn.cookies do
          %{^cookie_name => resource} -> {:ok, resource}
          _ -> {:error, nil}
        end
      end

      @doc """
      Returns the identifier for the current user present within the connection.
      """

      @spec current_user_resource(Plug.Conn.t()) :: { :ok, id } | { :error, any }
      def current_user_resource(conn), do: {:error, nil}

      @doc """
      Extracts properties that will be saved for a request from the connection.
      """

      @spec request_properties(Plug.Conn.t()) :: map
      def request_properties(conn) do
        Map.take(conn, [:params, :host, :method, :request_path])
      end

      @doc """
      Extracts properties that will be saved for a session from the connection.
      """

      @spec session_properties(Plug.Conn.t()) :: map
      def session_properties(conn), do: %{}

      defoverridable request_properties: 1,
        session_properties: 1,
        current_user_resource: 1
    end
  end

  alias Lear.SessionData

  @doc """
  Saves data related to an HTTP request.

  A Request is a specific type of Event that Lear saves under the name 
  `request`.  This event is saved automatically when a connection goes through
  `Lear.Plug.Pipeline`.  The properties related to a Request are derived from
  the function `request_properties/1`.  
  """
  @spec track_request(module, Plug.Conn.t()) :: response
  def track_request(mod, conn) do
    properties = apply(mod, :request_properties, [conn])

    apply(mod, :track, [conn, "request", properties])
  end

  @doc """
  Saves data related to a Session.

  The properties related to a Session are derived from the function 
  `session_properties/1`.
  """
  @spec track_session(module, Plug.Conn.t()) :: response
  def track_session(mod, conn) do
    properties = apply(mod, :session_properties, [conn])
    session_data = 
      SessionData.parse(conn)
      |> Map.put(:properites, properties)
    user_id = current_user_id(mod, conn)
    store = store_module(mod)

    apply(store, :save_session, [user_id, session_data])
  end

  @doc """
  Saves a generic Event.

  Arguments:
  * `mod` - A Lear implementation module
  * `conn` - The `%Plug.Conn{}` connection
  * `name` - The name of the event
  * `properties` - The properties related to the event
  """
  @spec track(module, Plug.Conn.t(), String.t(), map) :: response
  def track(mod, conn, name, properties \\ %{}) do
    store = store_module(mod)
    {_, session_id} = apply(mod, :current_session_resource, [conn])

    apply(store, :save_event, [session_id, name, properties])
  end

  @doc """
  Returns the store related to the given module.
  """
  @spec store_module(module) :: module
  def store_module(mod) do
    apply(mod, :config, [:store])
  end

  defp current_user_id(mod, conn) do
    case apply(mod, :current_user_resource, [conn]) do
      {:ok, user_id} -> user_id
      {:error, _} -> nil
    end
  end
end
