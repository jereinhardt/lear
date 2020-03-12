defmodule Lear.SessionDataTest do
  use ExUnit.Case

  test "parse/1" do
    user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.117 Safari/537.36"
    utm_term = "term"
    query_params = %{utm_term: utm_term, s: "search+term"}
    result = 
      %Plug.Conn{remote_ip: {127, 0, 0, 0}, request_path: "/"}
      |> Plug.Conn.put_req_header("user-agent", user_agent)
      |> Map.put(:query_params, query_params)
      |> Lear.SessionData.parse()

    assert Map.get(result, :browser) == "Chrome"
    assert Map.get(result, :browser_version) == "79"
    assert Map.get(result, :device_type) == "desktop"
    assert Map.get(result, :ip) == "127.0.0.0"
    assert Map.get(result, :landing_page) == "/"
    assert Map.get(result, :os) == "mac"
    assert Map.get(result, :os_version) == "10.14.6"
    assert Map.get(result, :user_agent) == user_agent
    assert Map.get(result, :utm_term) == utm_term
    assert Map.get(result, :s) == nil
  end
end