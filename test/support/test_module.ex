defmodule Lear.TestModule do
  use Lear, store: Lear.TestStore

  def current_user_resource(conn) do
    case conn.assigns do
      %{user_id: id} -> {:ok, id}
      _ -> {:error, nil}
    end
  end
end