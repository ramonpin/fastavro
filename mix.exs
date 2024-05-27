defmodule FastAvro.MixProject do
  use Mix.Project

  def project do
    [
      app: :fastavro,
      version: "0.4.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Docs
      source_url: "https://github.com/ramonpin/fastavro",
      homepage_url: "http://github.com/ramonpin/fastavro",
      docs: [
        main: "FastAvro"
        # logo: "path/to/logo.png",
        # extras: ["README.md"]
      ],
      description: description(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:rustler, "~> 0.32.1"},
      {:jason, "~> 1.4"},
      {:benchee, "~> 1.1.0", only: :dev, runtime: false},
      {:ex_doc, "~> 0.29.1", only: [:dev, :test], runtime: false}
    ]
  end

  defp description do
    """
    This library implements some fast avro access functions using a wrapper
    over the apache_avro rust library. Is not a generic use avro library it
    just fulfills some use cases.
    """
  end

  defp package do
    [
      files: [
        "lib",
        "mix.exs",
        "README*",
        "LICENSE*",
        "native"
      ],
      maintainers: ["Ramón Pin"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/ramonpin/fastavro"}
    ]
  end
end
