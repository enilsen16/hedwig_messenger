defmodule Hedwig.Adapters.Messenger do
  use Hedwig.Adapter
  require Logger

  def init({robot, opts}) do
    HTTPoison.start
    :global.register_name({ __MODULE__, opts[:name]}, self())
    state = %{
      robot: robot,
      token: Keyword.get(opts, :token)
    }

    {:ok, state}
  end

  def handle_cast({_, msg}, state) do
    send_text_message(msg, state)
    {:noreply, state}
  end

  def handle_call(:robot, _, %{robot: robot} = state) do
    {:reply, robot, state}
  end

  def handle_in(robot_name, req_body) do
    case :global.whereis_name({__MODULE__, robot_name}) do
      :undefined ->
        Logger.error("#{{__MODULE__, robot_name}} not found")
        { :error, :not_found }

      adapter ->
        robot = GenServer.call(adapter, :robot)
        msg = send_messages(req_body) |> Map.put(:robot, robot)

        Hedwig.Robot.handle_in(robot, msg)
    end
  end

  def send_text_message(msg, state) do
    endpoint = "https://graph.facebook.com/v2.6/me/messages?access_token=#{Map.get(state, :token)}"
    body = build_body(:text, msg)
    Logger.info "sending #{body.message.text} to #{msg.user}"

    case send_request(endpoint, msg.user, body, state) do
      {:ok, %HTTPoison.Response{status_code: status_code} = response } when status_code in 200..299 ->
        Logger.info("#{inspect response}")

      {:ok, %HTTPoison.Response{status_code: status_code} = response } when status_code in 400..599 ->
        Logger.error("#{inspect response}")

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("#{inspect reason}")
    end
  end

  defp send_request(url, user_id, body, state) do
    {:ok, body} = body |> Poison.encode
    headers = [{"Content-Type", "application/json"}]
    HTTPoison.post(url, body, headers)
  end

  defp build_body(:text, msg) do
    %{
      recipient: %{
        id: Map.get(msg, :user)
      },
      message: %{
        text: Map.get(msg, :text)
      }
    }
  end

  defp send_messages(req_body) do
    {:ok, req_body} = req_body |> Poison.decode

    Map.get(req_body, "entry")
    |> List.first()
    |> build_message()
  end

  defp build_message(entry) do
      {text, user_id} = parse_req_body(entry)

      %Hedwig.Message{
        ref: make_ref(),
        text: text,
        type: "chat",
        user: user_id
      }
  end

  defp parse_req_body(entry) do
    body = Map.get(entry, "messaging") |> List.first()
    {get_in(body, ["message", "text"]), get_in(body, ["sender", "id"])}
  end
end
