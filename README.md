# Lear

Lear is an automated data-tracking library for plug-based Elixir applications.

Lear tracks user sessions, server requests, and other events and saves that
information in a persistent data store of your choosing.

## What Gets Tracked

Lear breaks tracking data down into two categories: Sessions and Events. Events
are individual actions taken by users. Sessions are a persistent chain of 
interactions made by a single user in a single sitting, and are made up of many
events.

Lear automatically tracks certain data related to Sessions.  Session
details are automatically parsed from the connection.  While that data cannot be
overwritten, you can track additional properties from the connection (see
[configuration](#configuration) for more details.)

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `lear` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:lear, "~> 0.1.0"}
  ]
end
```

In order to use Lear, you must first create an implementation module that will 
include Lear's functionality and act as your main API for saving data.  To do 
this, create a module that uses `Lear` and implements any functions necessary 
for data tracking within your application (see [configuration](#configuration) 
for more details).  At the very least, you should implement a 
`current_user_resource/1` function.

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

Once you've defined your implementation module, you will need to include Lear's
plugs within your pipeline.  There are two ways to accomplish this.

The easiest way is to include Lear's default plug within your pipeline:

```elixir
plug Lear.Plug.Pipeline, module: MyApp.Lear
```

This will automatically track sessions and server requests within the plug 
pipeline.

You can also define your own Lear plug for more control over tracking data.  To
accomplish this, you must create a module that uses `Lear.Plug.Pipeline`, and 
include any necessary options as arguments.

```elixir
defmodule MyApp.Lear.Pipeline do
  use Lear.Plug.Pipeline, module: MyApp.Lear

  plug Lear.Plug.TrackSession
  plug Lear.Plug.TrackRequest
  plug :track_utm_requests

  def track_utm_requests(conn, _opts) do
    utm_params =
      conn.query_params
      |> Enum.filter(fn {k, _} -> String.starts_with?(k, "utm") end)
      |> Map.new()
    if Map.keys(utm_params) |> Enum.any?() do
      MyApp.Lear.track(conn, "utm request", utm_params)
    end

    conn
  end
end
```

You can then include your custom module within your pipeline.

```elixir
plug MayApp.Lear.Pipeline
```

## Configuration

### Configuring your Implementation Module

When creating your implementation module, you can provide options to `use Lear` 
to configure it's behaviour.

* `:store` - the module that acts as the main API for interacting with your 
application's persistent data store.  See [stores](#stores) for more details.
* `:session_cookie_name` - (optional) the name of the cookie that will hold the
current session id.

You can further configure your implementation module by defining optional 
callbacks to control what details are tracked.

`current_user_resource/1` - Returns a tuple with the id of the current user, or
{:error, nil} if no id is present.

`request_properties/1` - returns a map of properties for each request that will 
be saved.

`session_properties/1` - returns a map of properties that will be saved as
additional session details.

### Configuring your Pipeline

Whether you are using Lear's default pipeline, it's individual plugs, or 
creating your own pipeline, all of Lear's plug's require a `:module` option to
be given to point to your application's implementation module.

Lear's individual plugs may accept other options as well for further 
customization.  See their documentation for further details.

## Stores

A Store is a module that acts as an API for persisting tracking data.  For most
cases, you will want to save data to the database.  If you application uses
Ecto, like most Phoenix applications, it is recommended that you use [LearEcto](https://github.com/jereinhardt/lear_ecto) 
as your store.

## Documentation

Documentation can be found at [https://hexdocs.pm/lear](https://hexdocs.pm/lear).

