defmodule Hedwig.Adapters.Messenger do
  use Hedwig.Adapter
  require Logger

  def init({robot, opts}) do
    HTTPoison.start
    :global.register_name({ __MODULE__, opts[:name]}, self())
    state = %{
      robot: robot
    }

    {:ok, state}
  end

  def handle_cast({_, msg}, state) do
    send_text_message(state.user_id, msg, state)
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
        msg = build_message(req_body)
        Hedwig.Robot.handle_in(robot, msg)
    end
  end

  def send_text_message(user_id, msg, state) do
    config = Application.get_env(:hedwig_messenger, __MODULE__, [])
    endpoint = "https://graph.facebook.com/v2.6/me/messages?access_token=#{Keyword.get(config, :token)}"
    body = build_body(:text, msg, state.user_id)
    Logger.info "sending #{body} to #{user_id}"

    case send_request(endpoint, user_id, body, state) do
      {:ok, %HTTPoison.Response{status_code: status_code} = response } when status_code in 200..299 ->
        Logger.info("#{inspect response}")

      {:ok, %HTTPoison.Response{status_code: status_code} = response } when status_code in 400..599 ->
        Logger.error("#{inspect response}")

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("#{inspect reason}")
    end
  end

  defp send_request(url, user_id, body, state) do
    headers = [{"Content-Type", "application/json" }]
    HTTPoison.post(url, body, headers)
  end

  defp build_body(:text, text, user_id) do
    %{
      recipient: %{
        id: user_id
      },
      message: %{
        text: text
      }
    }
  end

  defp build_message(req_body) do
    {:ok, req_body} = req_body |> Poison.decode
    %Hedwig.Message{
      ref: make_ref(),
      text: Map.get(req_body, "messaging") |> List.first |> Map.get("text"),
      type: "chat",
      user: 1 # TODO: Fix this to use real user ids
    }
  end
end
