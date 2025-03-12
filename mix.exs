defmodule Box.MixProject do
  use Mix.Project

  @version File.read!("VERSION") |> String.trim()

  def project do
    [
      app: :box,
      version: @version,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:assertions, "~> 0.20", only: [:dev, :test]},
      {:credo, "~> 1.7.11", runtime: false, only: ~w(dev test)a},
      {:ecto, "~> 3.12.5", optional: true},
      {:phoenix_pubsub, "~> 2.0", optional: true},
      {:phoenix_html, "~> 4.0", optional: true},
      {:gettext, "~> 0.26.2", optional: true},
      {:phoenix_live_view, "~> 1.0.4", optional: true},
      {:ex_doc, "~> 0.37.3", runtime: false, only: ~w(dev test)a}
    ]
  end
end
