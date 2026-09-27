if Code.ensure_loaded?(Swoosh.Adapter) do
  defmodule MailCraft.Adapters.Swoosh do
    @moduledoc """
    A [Swoosh](https://hexdocs.pm/swoosh) adapter that sends through the MailCraft API.

        # config/runtime.exs
        config :my_app, MyApp.Mailer,
          adapter: MailCraft.Adapters.Swoosh,
          api_key: System.fetch_env!("MAILCRAFT_API_KEY")

    Optional config: `:base_url` and `:req_options`, as for `MailCraft.Client.new/2`.
    Attachments aren't supported yet.
    """

    use Swoosh.Adapter, required_config: [:api_key]

    alias Swoosh.Email

    @impl true
    def deliver(%Email{} = email, config) do
      client =
        MailCraft.Client.new(config[:api_key],
          base_url: config[:base_url] || "https://api.mailcraft.host/v1",
          req_options: config[:req_options] || []
        )

      case MailCraft.Emails.send(client, params(email)) do
        {:ok, %{"data" => %{"id" => id}}} -> {:ok, %{id: id}}
        {:ok, body} -> {:ok, body}
        {:error, reason} -> {:error, reason}
      end
    end

    @doc false
    def params(%Email{} = email) do
      [
        from: address(email.from),
        to: Enum.map(email.to, &address/1),
        subject: email.subject,
        html: email.html_body,
        text: email.text_body,
        cc: addresses(email.cc),
        bcc: addresses(email.bcc),
        reply_to: email.reply_to && address(email.reply_to),
        headers: if(email.headers == %{}, do: nil, else: email.headers)
      ]
    end

    defp addresses([]), do: nil
    defp addresses(list), do: Enum.map(list, &address/1)

    defp address({name, email}) when name in [nil, ""], do: email
    defp address({name, email}), do: "#{name} <#{email}>"
    defp address(email) when is_binary(email), do: email
  end
end
