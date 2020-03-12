defmodule Lear.Plug.HelperTest do
  use ExUnit.Case

  alias Plug.Conn

  describe "fetch_module!/2" do
    test "returns the specified module if there is one given" do
      module = Lear.TestModule
      result =
        %Conn{private: %{lear_module: FakeModule}}
        |> Lear.Plug.Helper.fetch_module!(module: module)

      assert result == module
    end

    test "defaults to returning the module stored privately in the conn" do
      module = Lear.TestModule
      result =
        %Conn{private: %{lear_module: module}}
        |> Lear.Plug.Helper.fetch_module!()

      assert result == module
    end

    test "raises an error if no module is specified" do
      assert_raise RuntimeError, fn ->
        Lear.Plug.Helper.fetch_module!(%Conn{})
      end
    end
  end

  describe "safe_conn?/2" do
    test "returns true when no bots are detected" do
      result = Lear.Plug.Helper.safe_conn?(%Conn{})

      assert result ==  true
    end

    test "returns false when bots are detected" do
      result =
        %Conn{req_headers: [{"user-agent", "abot"}]}
        |> Lear.Plug.Helper.safe_conn?()

      assert result == false
    end

    test "returns true when bots are ignored" do
      result =
        %Conn{req_headers: [{"user-agent", "abot"}]}
        |> Lear.Plug.Helper.safe_conn?(detect_bots: false)

      assert result == true
    end
  end
end