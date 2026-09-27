defmodule MailCraft.Client do
  @moduledoc """
  Holds the API key and HTTP settings. Create one with `new/2` and pass it to
  every resource function.
  """

  @default_base_url "https://api.mailcraft.host/v1"

  @enforce_keys [:req]
  defstruct [:req]

  @type t :: %__MODULE__{req: Req.Request.t()}
  @type result :: {:ok, term()} | {:error, MailCraft.Error.t() | Exception.t()}

  @doc """
  Creates a client. Create an API key under Settings > API keys.

  ## Options

    * `:base_url` - override for staging or self-hosting (default `#{@default_base_url}`)
    * `:receive_timeout` - milliseconds to wait for a response (default `30_000`)
    * `:req_options` - extra options merged into the underlying `Req` request
  """
  @spec new(String.t(), keyword()) :: t()
  def new(api_key, opts \\ [])

  def new(api_key, opts) when is_binary(api_key) and api_key != "" do
    base_url = opts |> Keyword.get(:base_url, @default_base_url) |> String.trim_trailing("/")

    req =
      Req.new(
        base_url: base_url,
        auth: {:bearer, api_key},
        headers: [
          {"accept", "application/json"},
          {"user-agent", "mailcraft-elixir/#{MailCraft.version()}"}
        ],
        receive_timeout: Keyword.get(opts, :receive_timeout, 30_000),
        retry: false,
        decode_body: false
      )
      |> Req.merge(Keyword.get(opts, :req_options, []))

    %__MODULE__{req: req}
  end

  def new(_api_key, _opts) do
    raise ArgumentError, "An API key is required. Find yours under Settings > API Keys."
  end

  @doc false
  @spec request(t(), atom(), String.t(), keyword()) :: result()
  def request(%__MODULE__{req: req}, method, path, opts \\ []) do
    opts =
      [method: method, url: path]
      |> put_if(:params, compact(Keyword.get(opts, :params, [])))
      |> put_if(:json, Keyword.get(opts, :json))

    case Req.request(req, opts) do
      {:ok, %Req.Response{status: status, body: body}} when status >= 400 ->
        {:error, MailCraft.Error.from_response(status, decode(body))}

      {:ok, %Req.Response{body: body}} ->
        {:ok, decode(body)}

      {:error, exception} ->
        {:error, exception}
    end
  end

  @doc false
  def get(client, path, params \\ []), do: request(client, :get, path, params: params)

  @doc false
  def post(client, path, body \\ nil), do: request(client, :post, path, json: body && compact(body))

  @doc false
  def patch(client, path, body), do: request(client, :patch, path, json: compact(body))

  @doc false
  def delete(client, path) do
    with {:ok, _} <- request(client, :delete, path), do: :ok
  end

  @doc false
  def segment(value), do: URI.encode(to_string(value), &URI.char_unreserved?/1)

  defp decode(""), do: nil

  defp decode(body) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, decoded} -> decoded
      {:error, _} -> body
    end
  end

  defp decode(body), do: body

  defp compact(fields) when is_list(fields) or is_map(fields) do
    for {key, value} <- fields, not is_nil(value), into: %{}, do: {key, value}
  end

  defp put_if(opts, _key, value) when value in [nil, %{}], do: opts
  defp put_if(opts, key, value), do: Keyword.put(opts, key, value)
end
