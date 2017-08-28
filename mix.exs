defmodule UtilFS.Mixfile do
  use Mix.Project

  @version "0.0.1"

  def project do
    [app: :util_fs,
     version: @version,
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     description: description()
    ]
  end

  def application do
    [applications: [:logger, :ex_aws, :hackney],
     mod: {UtilFS, []}]
  end

  defp deps do
    [
      {:sweet_xml, "~> 0.6.5"},
      {:httpoison, "~> 0.11.0"},
      {:poison, "~> 2.0"},
      {:hackney, "~> 1.6"},
      {:ex_aws, "~> 1.1.2"}
    ]
  end

  defp description do
    """
    UTIL_FS модуль для elixir приложений
    """
  end

end
