defmodule Box.MixProject do
  use Mix.Project

  def project do
    [
      app: :box,
      version: "0.1.0",
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
      {:assertions, "~> 0.20.1", only: :test},
      {:ecto, "~> 3.5.0", only: :test}
    ]
  end
end
