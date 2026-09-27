defmodule MailCraftTest do
  use ExUnit.Case, async: true

  # Replaces Req's HTTP adapter: records the request and replies with the
  # response the test set up, while everything else runs for real. Req calls
  # the adapter in the calling process, so the test process is self().
  defmodule FakeAdapter do
    def run(request) do
      send(self(), {:request, request})
      {status, body} = Process.get(:mailcraft_response)
      {request, Req.Response.new(status: status, body: body, headers: %{"content-type" => ["application/json"]})}
    end
  end

  defp client_with(status, body) do
    Process.put(:mailcraft_response, {status, body})
    MailCraft.Client.new("mc_test_key", base_url: "https://api.test/v1/", req_options: [adapter: FakeAdapter])
  end

  defp last_request do
    assert_received {:request, request}
    request
  end

  defp json_body(request), do: request.body |> IO.iodata_to_binary() |> Jason.decode!()

  test "sends an email" do
    client = client_with(202, ~s({"data":{"id":"em_1","status":"queued"}}))

    assert {:ok, %{"data" => %{"id" => "em_1"}}} =
             MailCraft.Emails.send(client,
               from: "hello@yourdomain.com",
               to: "person@example.com",
               subject: "Welcome!",
               html: "<p>Hi</p>",
               text: nil
             )

    request = last_request()
    assert request.method == :post
    assert URI.to_string(request.url) == "https://api.test/v1/emails"
    assert Req.Request.get_header(request, "authorization") == ["Bearer mc_test_key"]
    assert Req.Request.get_header(request, "user-agent") == ["mailcraft-elixir/#{MailCraft.version()}"]

    body = json_body(request)
    assert body["to"] == ["person@example.com"]
    refute Map.has_key?(body, "text")
  end

  test "list sends the limit and skips it when missing" do
    client = client_with(200, ~s({"data":[]}))

    MailCraft.Contacts.list(client, limit: 5)
    assert last_request().url.query == "limit=5"

    MailCraft.Contacts.list(client)
    assert last_request().url.query in [nil, ""]
  end

  test "validate escapes the email" do
    client = client_with(200, ~s({"valid":true}))

    MailCraft.Emails.validate(client, "a+b@example.com")

    request = last_request()
    assert request.url.path == "/v1/emails/validate"
    assert request.url.query == "email=a%2Bb%40example.com"
  end

  test "template update uses PATCH with only the given fields" do
    client = client_with(200, ~s({"data":{"id":3}}))

    MailCraft.Templates.update(client, 3, subject: "New")

    request = last_request()
    assert request.method == :patch
    assert request.url.path == "/v1/templates/3"
    assert json_body(request) == %{"subject" => "New"}
  end

  test "manages contact list membership" do
    client = client_with(204, "")

    MailCraft.Contacts.add_to_lists(client, "c_1", [1, 2])
    request = last_request()
    assert request.url.path == "/v1/contacts/c_1/lists"
    assert json_body(request) == %{"list_ids" => [1, 2]}

    assert :ok = MailCraft.Contacts.remove_from_list(client, "c 1", 2)
    request = last_request()
    assert request.method == :delete
    assert request.url.path == "/v1/contacts/c%201/lists/2"
  end

  test "metrics and reputation" do
    client = client_with(200, ~s({"data":[]}))

    MailCraft.Metrics.get(client, start_date: "2026-01-01")
    assert last_request().url.query == "start_date=2026-01-01"

    MailCraft.Metrics.reputation(client)
    assert last_request().url.path == "/v1/reputation"
  end

  test "template folders use the hyphenated path" do
    client = client_with(201, ~s({"data":{"id":1}}))

    MailCraft.TemplateFolders.create(client, "Onboarding")

    request = last_request()
    assert request.url.path == "/v1/template-folders"
    assert json_body(request) == %{"name" => "Onboarding"}
  end

  test "business-rule errors" do
    client = client_with(402, ~s({"error":{"type":"plan_limit_reached","message":"Monthly limit reached."}}))

    assert {:error, %MailCraft.Error{status: 402, type: "plan_limit_reached", message: "Monthly limit reached."}} =
             MailCraft.Campaigns.send(client, 4)
  end

  test "validation errors" do
    client =
      client_with(
        422,
        ~s({"message":"The email field is required.","errors":{"email":["The email field is required."]}})
      )

    assert {:error, %MailCraft.Error{status: 422, type: nil, errors: %{"email" => ["The email field is required."]}}} =
             MailCraft.Contacts.upsert(client, email: "")
  end

  test "unparseable error bodies fall back to the status" do
    client = client_with(502, "<html>Bad gateway</html>")

    assert {:error, %MailCraft.Error{status: 502, message: "Request failed with status 502"}} =
             MailCraft.Lists.list(client)
  end

  test "requires an API key" do
    assert_raise ArgumentError, fn -> MailCraft.Client.new("") end
  end

  describe "Swoosh adapter" do
    import Swoosh.Email

    test "delivers through the API" do
      Process.put(:mailcraft_response, {202, ~s({"data":{"id":"em_9"}})})

      email =
        new()
        |> from({"Acme", "hello@acme.com"})
        |> to({"", "ada@example.com"})
        |> cc("ops@acme.com")
        |> subject("Hi")
        |> html_body("<p>Hi</p>")

      assert {:ok, %{id: "em_9"}} =
               MailCraft.Adapters.Swoosh.deliver(email,
                 api_key: "mc_test_key",
                 base_url: "https://api.test/v1",
                 req_options: [adapter: FakeAdapter]
               )

      body = json_body(last_request())
      assert body["from"] == "Acme <hello@acme.com>"
      assert body["to"] == ["ada@example.com"]
      assert body["cc"] == ["ops@acme.com"]
      refute Map.has_key?(body, "bcc")
      refute Map.has_key?(body, "text")
    end
  end
end
