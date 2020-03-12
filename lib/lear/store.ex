defmodule Lear.Store do
  @moduledoc """
  Defines the behaviour of any module that is meant to act as the
  API for the persistent data store where tracking information is saved.

  A store can accomplish this in one of two ways:

    1. Act directly as the persistent data store
    2. Act as a line of communication between the main application and the 
       persistent data store.

  For any applications that use Ecto, such as most Phoenix applications, you
  will want to use `Lear.Ecto` as your store in order to save tracking data to
  your database.

  It is also possible to define your own store that implements the behavior of
  `Lear.Store`.

  ## Example Store

  One example of this implementation is to use ETS tables managed by a 
  Genserver:
  
  ```elixir
  defmodule MyApp.Lear.Store do
    use GenServer

    @behaviour Lear.Store

    @sessions_table :sessions
    @events_table :events

    def start_link(_) do
      GenServer.start_link(__MODULE__, [], name: __MODULE__)
    end

    @impl true
    def init(_) do
      :ets.new(@sessions_table, [:set, :named_table])
      :ets.new(@events_table, [:set, :named_table])
      {:ok, nil}
    end

    @impl Lear.Store
    def save_event(session_id, name, properties) do
      id = UUID.uuid4()
      event = %{
        id: id,
        name: name,
        session_id: session_id,
        properties: properties
      }

      GenServer.call(__MODULE__, {:save_event, id, event})
      |> respond_to_save(event)
    end

    @impl Lear.Store
    def save_session(user_id, properties) do
      id = UUID.uuid4()
      session = %{
        id: id,
        user_id: user_id,
        properties: properties
      }
      
      GenServer.call(__MODULE__, {:save_session, id, session})
      |> respond_to_save(session)
    end

    @impl Lear.Store
    def get_event(id) do
      GenServer.call(__MODULE__, {:get_event, id})
    end

    @impl Lear.Store
    def get_session(id) do
      GenServer.call(__MODULE__, {:get_session, id})
    end

    @impl Lear.Store
    def update_session(session, attrs) do
      updated_session = Map.merge(session, attrs)
      GenServer.call(__MODULE__, {:update_session, session.id, updated_session})
      |> respond_to_save(updated_session)
    end
  
    # GenServer Callbacks

    @impl true
    def handle_call({:save_event, id, event}, _from, state) do
      result = :ets.insert(@events_table, {id, event})

      {:reply, result, state}
    end

    @impl true
    def handle_call({:save_session, id, session}, _from, state) do
      result = :ets.insert(@sessions_table, {id, session})

      {:reply, result, state}
    end

    @impl true
    def handle_call({:get_event, id}, _from, state) do
      event = lookup_from_table(@events_table, id)

      {:reply, event, state}
    end

    @impl true
    def handle_call({:get_session, id}, _from, state) do
      session = lookup_from_table(@sessions_table, id)

      {:reply, session, state}
    end

    @impl true
    def handle_call({:update_session, session_id, updated_session}, _from, state) do
      result =
        :ets.update_element(@sessions_table, session_id, {2, updated_session})
      {:reply, result, state}
    end

    # Private Functions

    defp respond_to_save(result, record) do
      case result do
        true -> {:ok, record}
        _ -> {:error, nil}
      end
    end

    defp lookup_from_table(table, id) do
      case :ets.lookup(table, id) do
        [{^id, record}] -> record
        _ -> nil
      end
    end
  end
  ```  
  """

  alias Lear.SessionData

  @type id :: String.t() | integer
  @type record :: %{required(:id) => id, optional(any) => any}
  @type response :: { :ok, record } | { :error, any }

  @doc """
  Saves an event to the store with the given properties.  Should recieve the id
  of the associated session as the first argument, the name of the event as the
  second argument, and the event properties as the third argument.  

  Returns `{:ok, record}` if the save is successful.  A `record` is a 
  representation of the event that was just saved, and must include an `:id` 
  field.

  Returns `{:error, any}` if the event was unable to be saved.
  """
  @callback save_event(id, String.t(), map) :: response

  @doc """
  Saves a session to the store with the given properties.  Should recieve the id
  of the associated user or `nil` as the first argument, and the session  properties
  as the second argument.

  Returns `{:ok, record}` if the save is successful.  A `record` is a 
  representation of the session that was just saved, and must include an `:id` 
  field.

  Returns `{:error, any}` if the session was unable to be saved.
  """
  @callback save_session(id | nil, SessionData.t()) :: response

  @doc """
  Updates a session in the store with the given properties.
  """
  @callback update_session(record, map) :: response

  @doc """
  Returns the event saved in the store with the associated id.
  """
  @callback get_event(id) :: nil | any

  @doc """
  Returns the session saved in the store with the associated id.
  """
  @callback get_session(id) :: nil | any
end