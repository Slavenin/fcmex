defmodule Fcmex.Request do
  @moduledoc ~S"
    Perform request to FCM
  "

  use Retry
  alias Fcmex.{Util, Config, Payload}

  @fcm_endpoint "https://fcm.googleapis.com/v1/projects/myproject-b5ae1/messages:send"

  def perform(to, opts) do
    with payload <- Payload.create(to, opts),
         result <- post(payload, opts) do
      Util.parse_result(result)
    end
  end

  defp post(%Payload{} = payload, opts) do
    endpoint = Keyword.get(opts, :endpoint, @fcm_endpoint)

    retry with: exponential_backoff() |> randomize |> expiry(10_000) do
      HTTPoison.post(
        endpoint,
        %{
          "message" => payload
        }
        |> Config.json_library().encode!(),
        Config.new(),
        Config.httpoison_options()
      )
    after
      result -> result
    else
      error -> error
    end
  end
end
