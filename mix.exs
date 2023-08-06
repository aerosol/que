defmodule Que.MixProject do
  use Mix.Project

  def project do
    [
      app: :que,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:hahash, "~> 0.1.0"},
      {:ecto, "~> 3.10.3", override: true},
      {:tabula, "~> 2.1.1"}
    ]
  end
end
