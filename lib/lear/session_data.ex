defmodule Lear.SessionData do
  @moduledoc """
  Defines the interface for session data that will be sent to the store to be
  saved, and provides tools for extracting data that complies the defined
  interface.
  """

  @type t :: %{
    required(:browser) => String.t() | nil,
    required(:browser_version) => String.t() | nil,
    required(:device_type) => String.t() | nil,
    required(:ip) => String.t() | nil,
    required(:landing_page) => String.t() | nil,
    required(:os) => String.t() | nil,
    required(:os_version) => String.t() | nil,
    required(:user_agent) => String.t() | nil,
    required(:utm_campaign) => String.t() | nil,
    required(:utm_content) => String.t() | nil,
    required(:utm_medium) => String.t() | nil,
    required(:utm_source) => String.t() | nil,
    required(:utm_term) => String.t() | nil,
    optional(:user_id) => integer | nil,
    optional(:properties) => map | nil,
    optional(:id) => String.t() | integer
  }

  @utm_param_keys [
    :utm_campaign,
    :utm_content,
    :utm_medium,
    :utm_source,
    :utm_term
  ]

  @doc """
  Returns a map of detailed session information based on the incoming
  connection.
  """
  @spec parse(Plug.Conn.t()) :: t()
  def parse(conn) do
    %{
      browser: Browser.name(conn),
      browser_version: Browser.version(conn),
      device_type: device_type(conn),
      ip: ip(conn),
      landing_page: conn.request_path,
      os: os(conn),
      os_version: os_version(conn),
      user_agent: user_agent(conn),
    }
    |> update_with_utm_params(conn)
  end

  defp device_type(conn), do: Browser.device_type(conn) |> string_value()

  defp os(conn), do: Browser.platform(conn) |> string_value()

  defp string_value(val) when is_atom(val), do: Atom.to_string(val)
  defp string_value(val), do: val

  defp ip(%{remote_ip: remote_ip}) when is_nil(remote_ip), do: nil
  defp ip(conn) do
    conn
    |> Map.get(:remote_ip)
    |> Tuple.to_list()
    |> Enum.join(".")
  end

  defp os_version(conn) do
    case Browser.platform(conn) do
      :mac -> Browser.mac_version(conn)
      :ios -> Browser.ios_version(conn)
      :android -> Browser.android_version(conn)
      :windows -> Browser.windows_version_name(conn)
      _ -> nil
    end
  end

  defp user_agent(conn) do
    conn
    |> Plug.Conn.get_req_header("user-agent")
    |> case do
      [] -> nil
      [user_agent | _] -> user_agent
    end
  end

  defp update_with_utm_params(params, conn) do
    conn
    |> Plug.Conn.fetch_query_params()
    |> Map.get(:query_params)
    |> Enum.map(&atomize_key/1)
    |> Map.new()
    |> Map.take(@utm_param_keys)
    |> Map.merge(params)
  end

  defp atomize_key({name, value}) when is_binary(name) do
    {String.to_atom(name), value}
  end

  defp atomize_key(item), do: item
end