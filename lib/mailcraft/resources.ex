# One module per API section. Every function takes a MailCraft.Client first.
# Optional fields that are nil are left out of the request.

defmodule MailCraft.Emails do
  @moduledoc "Transactional email."
  alias MailCraft.Client

  @doc """
  Sends a transactional email.

  Options: `:from`, `:to` (a string or a list), `:subject`, `:html`, `:text`,
  `:cc`, `:bcc`, `:reply_to`, `:headers`, `:tags`.
  """
  def send(client, opts) do
    body = opts |> Map.new() |> Map.update(:to, [], &List.wrap/1)
    Client.post(client, "/emails", body)
  end

  def list(client, opts \\ []), do: Client.get(client, "/emails", limit: opts[:limit])
  def get(client, id), do: Client.get(client, "/emails/#{Client.segment(id)}")

  @doc "Checks an address's format, MX records and disposable domain, without sending."
  def validate(client, email), do: Client.get(client, "/emails/validate", email: email)
end

defmodule MailCraft.Domains do
  @moduledoc "Sending domains."
  alias MailCraft.Client

  @doc "Options: `:name`, `:region`."
  def create(client, opts), do: Client.post(client, "/domains", opts)
  def list(client), do: Client.get(client, "/domains")
  def get(client, id), do: Client.get(client, "/domains/#{id}")
  def verify(client, id), do: Client.post(client, "/domains/#{id}/verify")
  def delete(client, id), do: Client.delete(client, "/domains/#{id}")
end

defmodule MailCraft.Senders do
  @moduledoc "Sender identities."
  alias MailCraft.Client

  @doc "Options: `:domain_id`, `:email`, `:name`, `:reply_to`."
  def create(client, opts), do: Client.post(client, "/senders", opts)
  def list(client), do: Client.get(client, "/senders")
  def get(client, id), do: Client.get(client, "/senders/#{id}")
  def delete(client, id), do: Client.delete(client, "/senders/#{id}")
end

defmodule MailCraft.Contacts do
  @moduledoc "Contacts and their list memberships."
  alias MailCraft.Client

  @doc """
  Creates a contact, or updates it if one exists for this email.

  Options: `:email`, `:first_name`, `:last_name`, `:status`, `:properties`.
  """
  def upsert(client, opts), do: Client.post(client, "/contacts", opts)
  def list(client, opts \\ []), do: Client.get(client, "/contacts", limit: opts[:limit])
  def get(client, id), do: Client.get(client, "/contacts/#{Client.segment(id)}")
  def delete(client, id), do: Client.delete(client, "/contacts/#{Client.segment(id)}")
  def unsubscribe(client, id), do: Client.post(client, "/contacts/#{Client.segment(id)}/unsubscribe")

  def add_to_lists(client, id, list_ids),
    do: Client.post(client, "/contacts/#{Client.segment(id)}/lists", list_ids: list_ids)

  def lists(client, id), do: Client.get(client, "/contacts/#{Client.segment(id)}/lists")

  def remove_from_list(client, id, list_id),
    do: Client.delete(client, "/contacts/#{Client.segment(id)}/lists/#{list_id}")
end

defmodule MailCraft.Lists do
  @moduledoc "Mailing lists."
  alias MailCraft.Client

  @doc "Options: `:name`, `:description`, `:type` (`\"static\"` or `\"dynamic\"`), `:segment_id`."
  def create(client, opts), do: Client.post(client, "/lists", opts)
  def list(client), do: Client.get(client, "/lists")
  def get(client, id), do: Client.get(client, "/lists/#{id}")
  def delete(client, id), do: Client.delete(client, "/lists/#{id}")
end

defmodule MailCraft.Segments do
  @moduledoc "Segments."
  alias MailCraft.Client

  @doc """
  Options: `:name`, `:description`, `:filters`, e.g.
  `%{operator: "and", conditions: [%{field: "plan", operator: "eq", value: "pro"}]}`.
  """
  def create(client, opts), do: Client.post(client, "/segments", opts)
  def list(client), do: Client.get(client, "/segments")
  def get(client, id), do: Client.get(client, "/segments/#{id}")
  def delete(client, id), do: Client.delete(client, "/segments/#{id}")
end

defmodule MailCraft.Properties do
  @moduledoc "Custom contact properties."
  alias MailCraft.Client

  @doc "Options: `:key`, `:label`, `:type` (text, number, boolean, date or list), `:default_value`."
  def create(client, opts), do: Client.post(client, "/properties", opts)
  def list(client), do: Client.get(client, "/properties")
  def delete(client, id), do: Client.delete(client, "/properties/#{id}")
end

defmodule MailCraft.Templates do
  @moduledoc "Versioned templates."
  alias MailCraft.Client

  @doc "Options: `:name`, `:subject`, `:html_body`, `:text_body`, `:template_folder_id`, `:variables`."
  def create(client, opts), do: Client.post(client, "/templates", opts)
  def list(client), do: Client.get(client, "/templates")
  def get(client, id), do: Client.get(client, "/templates/#{id}")

  @doc "Each save becomes a new version. Pass only the fields to change."
  def update(client, id, opts), do: Client.patch(client, "/templates/#{id}", opts)
  def delete(client, id), do: Client.delete(client, "/templates/#{id}")
end

defmodule MailCraft.TemplateFolders do
  @moduledoc "Template folders."
  alias MailCraft.Client

  def create(client, name), do: Client.post(client, "/template-folders", name: name)
  def list(client), do: Client.get(client, "/template-folders")
  def delete(client, id), do: Client.delete(client, "/template-folders/#{id}")
end

defmodule MailCraft.Campaigns do
  @moduledoc "Marketing campaigns."
  alias MailCraft.Client

  @doc "Options: `:name`, `:subject`, `:template_id`, `:sender_id`, `:list_id` or `:segment_id`."
  def create(client, opts), do: Client.post(client, "/campaigns", opts)
  def list(client), do: Client.get(client, "/campaigns")
  def get(client, id), do: Client.get(client, "/campaigns/#{id}")
  def send(client, id), do: Client.post(client, "/campaigns/#{id}/send")
  def delete(client, id), do: Client.delete(client, "/campaigns/#{id}")
end

defmodule MailCraft.Webhooks do
  @moduledoc "Webhook endpoints."
  alias MailCraft.Client

  @doc "Options: `:url`, `:events`, `:description`."
  def create(client, opts), do: Client.post(client, "/webhooks", opts)
  def list(client), do: Client.get(client, "/webhooks")
  def delete(client, id), do: Client.delete(client, "/webhooks/#{id}")
end

defmodule MailCraft.Suppressions do
  @moduledoc "The suppression list."
  alias MailCraft.Client

  @doc "Options: `:email`, `:reason`."
  def add(client, opts), do: Client.post(client, "/suppressions", opts)
  def list(client, opts \\ []), do: Client.get(client, "/suppressions", limit: opts[:limit])
  def delete(client, id), do: Client.delete(client, "/suppressions/#{id}")
end

defmodule MailCraft.Metrics do
  @moduledoc "Sending metrics and reputation."
  alias MailCraft.Client

  @doc "Options: `:start_date`, `:end_date` (`\"YYYY-MM-DD\"`)."
  def get(client, opts \\ []),
    do: Client.get(client, "/metrics", start_date: opts[:start_date], end_date: opts[:end_date])

  def reputation(client), do: Client.get(client, "/reputation")
end
