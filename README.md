# HedwigMessenger

An in-progress alpha...

## Configuration

Below is an example configuration

```elixir
use Mix.Config

config :alfred, Alfred.Robot,
  adapter: Hedwig.Adapters.Messenger,
  name: "alfred",
  token: "", #Your Page Access Token
  responders: [
    {Hedwig.Responders.Help, []},
    {Hedwig.Responders.Ping, []},
  ]
```

## Facebook Callback
Messages are received from Facebook using an HTTP callback. You can use the included `Hedwig.Adapters.Messenger.Callback` module or define one yourself
as long as it calls `Hedwig.Adapters.Messenger.handle_in/2` to send the message to the robot.

### Using the included server

To use the included callback with your robot, update your dependencies by including `plug` and `cowboy`:

```elixir
  defp deps do
    [
      {:cowboy, "~> 1.0"},
      {:plug, "~> 1.1"}
    ]
  end
```

Finally, add `Hedwig.Adapters.Messenger.Callback` to your supervision tree alongside your robot

```elixir
    children = [
      worker(Alfred.Robot, []),
      worker(Hedwig.Adapters.Messenger.Callback, [])
    ]
```

The parameters are:
* `cowboy_options` - a keyword list of options to pass to cowboy (optional)

### Defining your own callback

If you are defining your own callback (for instance in a phoenix app), just make sure to call `Hedwig.Adapters.Messenger.handle_in/2`

```elixir
    def my_twilio_callback(conn, params) do
        case Hedwig.Adapters.Messenger.handle_in(robot_name, params) do
            {:error, reason} ->
                # Handle robot not found
            :ok ->
                # Message sent to robot.
       end
    end
```

## What's Supported

| Send API  | Supported?  |
|---|---|
|Text Messages   | ✓  |
|Audio Messages   |   |    
|File Messages   |   |
|Image Messages   |   |
|Video Messages   |   |
|Typing Indicators   |   |
|Quick Replies   |   |
|Buttons   |   |
|Templates   |   |    |

|  Webhook Reference   | Supported?    |
| --- | --- |
| Message Received    |  ✓ |
| Message Delivered    |    |
| Message Read    |    |
| Message Echo    |    |
| Postback    |    |
| Plugin Opt-in    |    |
| Referral    |    |
| Payment    |    |
| Checkout Update    |    |
| Account Linking    |    |   |
