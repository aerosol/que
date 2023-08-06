defmodule Que do
  defmacro __using__(using_opts) do
    quote do
      defmacro que(subject, opts \\ []) do
        repo = Keyword.get(unquote(using_opts), :repo, __MODULE__)
        caller = __CALLER__
        {f, a} = caller.function

        quote do
          opts =
            Keyword.merge(unquote(opts),
              location: unquote(caller.file <> ":#{caller.line}"),
              module: unquote(inspect(caller.module)),
              function: unquote("#{f}/#{a}"),
              hash: Hahash.name(binding()),
              repo: unquote(repo)
            )

          Que.pp(unquote(subject), opts)
        end
      end
    end
  end

  def pp(subject, opts \\ [])

  def pp(%Ecto.Query{} = query, opts) do
    pp(opts[:repo].to_sql(:all, query), opts)
    query
  end

  def pp({sql, bindings}, opts) when is_binary(sql) do
    pp(sql, Keyword.merge(opts, bindings: bindings))
    {sql, bindings}
  end

  def pp([m | _] = t, opts) when is_map(m) do
    banner(opts)
    Tabula.print_table(t)
    t
  end

  def pp(no_results, opts) when no_results in [[], nil] do
    banner(opts)
    print("No results.", opts)
    no_results
  end

  def pp(m, opts) when is_map(m) do
    banner(opts)
    Tabula.print_table([m])
    m
  end

  def pp(sql, opts) when is_binary(sql) do
    print(banner(opts), opts)

    sql
    |> Que.SQL.parse()
    |> print(opts)

    bindings = opts[:bindings]

    if bindings do
      print(
        [
          ?\n,
          IO.ANSI.bright(),
          "Bindings:",
          ?\n,
          IO.ANSI.reset(),
          ?\n
          | Enum.with_index(bindings, fn el, i ->
              [
                String.pad_leading(IO.ANSI.yellow() <> "$#{i + 1}: " <> IO.ANSI.reset(), 15, [" "]),
                "#{inspect(el)}",
                ?\n
              ]
            end)
        ],
        opts
      )
    end
  end

  defp banner(opts) do
    [
      ?\n,
      "Input hash: ",
      IO.ANSI.bright(),
      to_string(opts[:hash]),
      IO.ANSI.reset(),
      ?\n,
      "Label: ",
      opts[:label] || "(no label)",
      ?\n,
      "Repo: ",
      inspect(opts[:repo] || "(unknown repo)"),
      ?\n,
      "Location: ",
      opts[:location] || "(unknown location)",
      ?\n,
      "Function: ",
      opts[:module] || "(unknown module)",
      ?.,
      opts[:function] || "(unknown function)"
    ]
  end

  defp print(iolist, opts) do
    device = Keyword.get(opts, :device, :stdio)
    IO.puts(device, iolist)
  end
end
