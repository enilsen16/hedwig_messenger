defmodule Hedwig.Adapter.Messenger.Callback do
  use Plug.Builder
  require Logger

  plug Plug.Logger

  def start_link() do
    config = Application.get_env(:hedwig_messenger, __MODULE__, [])

    port = Keyword.get(config, :port, 4000)
    cowboy_options = [port: port]

    base_path = Keyword.get(config, :base_path, "/messenger")
    base_path = Path.join(["/", base_path])
    plug_options = [base_path: base_path]

    Plug.Adapters.Cowboy.https __MODULE__, plug_options, cowboy_options
  end

  def init(options) do
    options
  end

  def call(%Plug.Conn{request_path: request_path, method: "POST"} = conn, opts) do
    base_path = opts.base_path
    if String.starts_with?(request_path, base_path) do
      robot_name = List.last(Path.split(request_path))
      {:ok, body, conn} = Plug.Conn.read_body(conn)

      case Hedwig.Adapters.Messenger.handle_in(robot_name, body) do
        {:error, _} ->
          conn
          |> send_resp(404, "Not found")
          |> halt
        :ok ->
          conn
          |> send_resp(200, "ok")
          |> halt
      end

    else
      conn
      |> send_resp(404, "Not found")
      |> halt
    end
  end

  def call(conn, _opts) do
    IO.inspect conn

    conn
    |> send_resp(404, "Not found")
    |> halt
  end
end
