# Que

Quick and dirty, no hex package yet.

Add the following to deps:

```elixir
   {:que, github: "aerosol/que"}
```

Update your Repo (postgres, clickhouse - sql ones) with:

```elixir
defmodule MyApp.Repo do
   ...
   use Que
end
```

Update points of interests:

```elixir

defp aggregate_events(site, query, metrics) do
  from(e in base_event_query(site, query), select: %{})
  |> select_event_metrics(metrics)
  |> ClickhouseRepo.que(label: "select event metrics") # <--
  |> merge_imported(site, query, :aggregate, metrics)
  |> ClickhouseRepo.que(label: "merge imported") # <--
  |> ClickhouseRepo.one()
  |> ClickhouseRepo.que(label: "oooh, the results") # <--
end
```

Test and enjoy.

