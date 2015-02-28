defmodule Hubsolution.Mixfile do
  use Mix.Project

  def project do
    [ app: :hubsolution,
      version: "0.0.1",
      deps: deps ]
  end

  # Configuration for the OTP application
  def application do
    []
  end

  # Returns the list of dependencies in the format:
  # { :foobar, "~> 0.1", git: "https://github.com/elixir-lang/foobar.git" }
  defp deps do
    [{:httpotion, "~> 2.0.0", git: "https://github.com/myfreeweb/httpotion.git"},
    { :json,   github: "cblage/elixir-json"}]
  end
end
