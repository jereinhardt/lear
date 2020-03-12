defmodule Lear.TestStore do
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

  def all_events do
    GenServer.call(__MODULE__, :all_events)
  end

  def clear! do
    GenServer.call(__MODULE__, :clear)
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
  def handle_call(:clear, _from, state) do
    :ets.delete_all_objects(@sessions_table)
    :ets.delete_all_objects(@events_table)

    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:all_events, _from, state) do
    events = :ets.tab2list(@events_table)

    {:reply, events, state}
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