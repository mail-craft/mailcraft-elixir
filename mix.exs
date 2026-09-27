defmodule MailCraft.MixProject do
  use Mix.Project

  @version "1.0.0"
  @source_url "https://github.com/mail-craft/mailcraft-elixir"

  def project do
    [
      app: :mailcraft,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      description: "Official Elixir SDK for the MailCraft email API, with a Swoosh adapter.",
      package: [
        licenses: ["MIT"],
        links: %{"GitHub" => @source_url}
      ],
      docs: [main: "readme", extras: ["README.md"], source_ref: "v#{@version}", source_url: @source_url],
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:req, "~> 0.7"},
      {:jason, "~> 1.4"},
      {:swoosh, "~> 1.16", optional: true}
    ]
  end
end
