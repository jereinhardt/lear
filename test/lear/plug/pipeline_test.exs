defmodule Lear.Plug.PipelineTest do
  use ExUnit.Case

  describe "prepare_conn/2" do
    test "sets the private key for :lear_module" do
      module = Lear.TestModule
      private = 
        %Plug.Conn{}
        |> Lear.Plug.Pipeline.prepare_conn(module: module)
        |> Map.get(:private)

      assert Map.has_key?(private, :lear_module)
      assert Map.get(private, :lear_module) == module
    end

    test "does nothing if a private key for :lear_module exists" do
      module = Lear.TestModule
      result =
        %Plug.Conn{private: %{lear_module: module}}
        |> Lear.Plug.Pipeline.prepare_conn(module: FakeModule)
        |> Map.get(:private)
        |> Map.get(:lear_module)

      assert result == module
    end
  end
end