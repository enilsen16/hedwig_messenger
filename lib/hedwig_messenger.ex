defmodule Hedwig.Adapters.Messenger do
  use Hedwig.Adapter
  require Logger

  def init({robot, opts}) do
    HTTPoison.start
    :global.register_name({__MODULE__}, opts[:name], self())
    Hedwig.Robot.handle_connect(robot)

    state = %{
      robot: robot
    }

    {:ok, robot}
  end

  def handle_cast({_, msg}, state) do
    send_text_message(state.user_id, msg, state)
    {:noreply, state}
  end

  def handle_call(:robot, _, %{robot: robot} = state) do
    {:reply, robot, state}
  end

  def send_text_message(user_id, msg, state) do
    endpoint = "https://graph.facebook.com/v2.6/me/messages?access_token=#{Application.get_env("PAGE_ACCESS_TOKEN")}"
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
end
