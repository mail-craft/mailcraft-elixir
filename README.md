# mailcraft-elixir

Official Elixir SDK for the [MailCraft](https://mailcraft.host) email API: transactional email, contacts, lists, segments, templates, campaigns, webhooks and more. Includes a [Swoosh](https://hexdocs.pm/swoosh) adapter for Phoenix apps.

Requires Elixir 1.15+. Built on [Req](https://hexdocs.pm/req).

## Install

```elixir
def deps do
  [
    {:mailcraft, "~> 0.1"}
  ]
end
```

## Quick start

```elixir
client = MailCraft.Client.new(System.fetch_env!("MAILCRAFT_API_KEY"))

{:ok, %{"data" => email}} =
  MailCraft.Emails.send(client,
    from: "hello@yourdomain.com",
    to: ["person@example.com"],   # a string or a list of addresses
    subject: "Welcome!",
    html: "<p>Thanks for signing up.</p>"
  )

email["id"]
```

Create an API key under **Settings → API keys** in your MailCraft dashboard.

Every function takes the client first and returns `{:ok, body}` with the API's decoded JSON, or `{:error, reason}`. Deletes return `:ok`. Options set to `nil` are left out of the request.

## Swoosh (Phoenix)

```elixir
# config/runtime.exs
config :my_app, MyApp.Mailer,
  adapter: MailCraft.Adapters.Swoosh,
  api_key: System.fetch_env!("MAILCRAFT_API_KEY")
```

Then send with `MyApp.Mailer.deliver(email)` as usual. `deliver/1` returns `{:ok, %{id: email_id}}`. The adapter sends through Req, so Swoosh's own HTTP client isn't needed (`config :swoosh, :api_client, false`). Attachments aren't supported yet.

## Resources

Every MailCraft SDK has the same resources and functions:

| Module | Functions |
| --- | --- |
| `MailCraft.Emails` | `send`, `list`, `get`, `validate` |
| `MailCraft.Domains` | `create`, `list`, `get`, `verify`, `delete` |
| `MailCraft.Senders` | `create`, `list`, `get`, `delete` |
| `MailCraft.Contacts` | `upsert`, `list`, `get`, `delete`, `unsubscribe`, `add_to_lists`, `lists`, `remove_from_list` |
| `MailCraft.Lists` | `create`, `list`, `get`, `delete` |
| `MailCraft.Segments` | `create`, `list`, `get`, `delete` |
| `MailCraft.Properties` | `create`, `list`, `delete` |
| `MailCraft.Templates` | `create`, `list`, `get`, `update`, `delete` |
| `MailCraft.TemplateFolders` | `create`, `list`, `delete` |
| `MailCraft.Campaigns` | `create`, `list`, `get`, `send`, `delete` |
| `MailCraft.Webhooks` | `create`, `list`, `delete` |
| `MailCraft.Suppressions` | `add`, `list`, `delete` |
| `MailCraft.Metrics` | `get`, `reputation` |

See the [API reference](https://docs.mailcraft.host/api-reference) for every field.

## Errors

Non-2xx responses return `{:error, %MailCraft.Error{}}`. Network failures return the transport exception.

```elixir
case MailCraft.Domains.create(client, name: "acme.com") do
  {:ok, %{"data" => domain}} ->
    domain

  {:error, %MailCraft.Error{status: status, type: type, errors: errors}} ->
    # status: e.g. 402
    # type: e.g. "plan_limit_reached" (business-rule errors)
    # errors: field errors for 422 validation failures
    {:error, status}
end
```

## Options

```elixir
MailCraft.Client.new(api_key,
  base_url: "https://api.mailcraft.host/v1", # override for staging or self-hosting
  receive_timeout: 30_000,                   # milliseconds
  req_options: []                            # merged into the underlying Req request
)
```

## Development

```bash
mix deps.get
mix test
```

The tests run the real client with only Req's HTTP adapter swapped out, so request building, encoding and error handling all run as they would for a user.

## License

MIT
