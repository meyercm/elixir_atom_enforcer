defmodule AtomEnforcer.MixProject do
  use Mix.Project

  @version "0.1.0"
  @repo_url "https://github.com/meyercm/elixir_atom_enforcer"

  def project do
    [
      app: :atom_enforcer,
      version: @version,
      elixir: "~> 1.6",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      # Hex
      package: hex_package(),
      description: "Compile-time checking of atoms",
      # Docs
      name: "AtomEnforcer",
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp hex_package do
    [maintainers: ["Chris Meyer"],
     licenses: ["MIT"],
     links: %{"GitHub" => @repo_url}]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:shorter_maps, "~> 2.2"},
      {:predicate_sigil,"~> 0.1"},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:earmark, ">= 0.0.0", only: :dev},
    ]
  end
end
