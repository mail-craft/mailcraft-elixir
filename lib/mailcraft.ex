defmodule MailCraft do
  @moduledoc """
  Official Elixir SDK for the [MailCraft](https://mailcraft.host) email API.

      client = MailCraft.Client.new(System.fetch_env!("MAILCRAFT_API_KEY"))

      {:ok, %{"data" => email}} =
        MailCraft.Emails.send(client,
          from: "hello@yourdomain.com",
          to: ["person@example.com"],
          subject: "Welcome!",
          html: "<p>Thanks for signing up.</p>"
        )

  Every function takes the client first and returns `{:ok, body}` with the API's
  decoded JSON, or `{:error, reason}`: a `MailCraft.Error` for API errors, or the
  transport exception for network failures. Deletes return `:ok`.

  For Phoenix apps sending through Swoosh, see `MailCraft.Adapters.Swoosh`.
  """

  @version Mix.Project.config()[:version]

  @doc false
  def version, do: @version
end
