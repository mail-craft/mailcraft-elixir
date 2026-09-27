defmodule MailCraft.Error do
  @moduledoc """
  Returned for any non-2xx response from the MailCraft API.

  Covers both error shapes the API returns: `%{"error" => %{"type", "message"}}`
  for business-rule failures (plan limits, suppressed recipients, ...), and
  `%{"message", "errors" => %{"field" => [...]}}` for validation failures (422).

    * `:status` - the HTTP status, e.g. 402 or 422
    * `:type` - the business-rule error type, e.g. `"plan_limit_reached"`; `nil` for validation errors
    * `:errors` - field errors for 422 responses
  """

  defexception [:status, :message, :type, errors: %{}]

  @type t :: %__MODULE__{
          status: pos_integer(),
          message: String.t(),
          type: String.t() | nil,
          errors: %{optional(String.t()) => [String.t()]}
        }

  @doc false
  def from_response(status, body) do
    fallback = "Request failed with status #{status}"

    case body do
      %{"error" => %{} = error} ->
        %__MODULE__{status: status, message: error["message"] || fallback, type: error["type"]}

      %{} ->
        %__MODULE__{status: status, message: body["message"] || fallback, errors: body["errors"] || %{}}

      _ ->
        %__MODULE__{status: status, message: fallback}
    end
  end
end
