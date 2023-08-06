defmodule Que.SQL do
  @rainbow [
    IO.ANSI.blue(),
    IO.ANSI.green(),
    IO.ANSI.magenta(),
    IO.ANSI.cyan(),
    IO.ANSI.yellow(),
    IO.ANSI.red()
  ]

  @tokens [
    {"AND", [:newline, :tab, :bright, :token]},
    {"LIMIT", [:newline, :tab, :bright, :token]},
    {"ASC", [:bright, :token]},
    {"AS", [:bright, :token]},
    {"OFFSET", [:newline, :tab, :bright, :token]},
    {"NOT", [:bright, :token]},
    {"NULL", [:bright, :token]},
    {"IS", [:bright, :token]},
    {"DESC", [:bright, :token]},
    {"ON", [:bright, :token]},
    {"SELECT", [:newline, :tab, :bright, :token, :inc]},
    {"WHERE", [:newline, :dec, :tab, :bright, :token, :inc]},
    {"GROUP BY", [:newline, :dec, :tab, :bright, :token]},
    {"ORDER BY", [:newline, :tab, :bright, :token]},
    {"FULL OUTER JOIN", [:newline, :dec, :tab, :bright, :token, :inc]},
    {"INNER JOIN", [:newline, :dec, :tab, :bright, :token, :inc]},
    {"LEFT JOIN", [:newline, :tab, :bright, :token, :inc]},
    {"CROSS JOIN", [:newline, :tab, :bright, :token, :inc]},
    {"FROM", [:newline, :tab, :bright, :token, :inc]},
    {"(", [:rainbow_inc, :rainbow, :inc]},
    {")", [:rainbow, :rainbow_dec, :dec]},
    {"OR", [:newline, :tab, :bright, :token]},
    {",", [:token]}
    | Enum.map(1..99, &{"$#{&1}", [:accent, :token]})
  ]

  defmodule State do
    defstruct indent: 0, acc: [], log: [], rainbow_level: 0
  end

  def parse(sql) do
    parse(String.trim(sql), %State{})
  end

  def parse(<<>>, state) do
    Enum.reverse(state.acc)
  end

  for {token, ops} <- @tokens, is_binary(token) do
    def parse(<<unquote(token), rest::binary>>, state) do
      state = run(unquote(token), unquote(ops), state)
      parse(rest, state)
    end
  end

  def parse(<<" ", rest::binary>>, state) do
    if hd(state.log) in [:tab, :newline] do
      parse(rest, state)
    else
      parse(rest, %{state | acc: [[" ", IO.ANSI.reset()] | state.acc]})
    end
  end

  def parse(<<char::utf8, rest::binary>>, state) do
    parse(rest, %{state | acc: [char | state.acc], log: [:char | state.log]})
  end

  def run(token, ops, state) do
    Enum.reduce(ops, state, fn
      op, state when is_atom(op) ->
        state = apply(__MODULE__, op, [state, token])
        %{state | log: [op | state.log]}

      {op, args}, state ->
        state = apply(__MODULE__, op, [state, token | args])
        %{state | log: [op | state.log]}
    end)
  end

  def bright(state, _) do
    %{state | acc: [IO.ANSI.bright() | state.acc]}
  end

  def accent(state, _) do
    %{state | acc: [IO.ANSI.yellow(), IO.ANSI.underline() | state.acc]}
  end

  def token(state, token) do
    %{state | acc: [[token, IO.ANSI.reset()] | state.acc]}
  end

  def newline(state, _) do
    %{state | acc: [?\n | state.acc]}
  end

  def inc(state, _) do
    %{state | indent: state.indent + 2}
  end

  def dec(state, _) do
    new_indent =
      if state.indent > 0 do
        state.indent - 2
      else
        state.indent
      end

    %{state | indent: new_indent}
  end

  def rainbow_inc(state, _) do
    %{state | rainbow_level: state.rainbow_level + 1}
  end

  def rainbow_dec(state, _) do
    %{state | rainbow_level: state.rainbow_level - 1}
  end

  def rainbow(state, token) do
    sequence = @rainbow |> Stream.cycle() |> Enum.take(state.rainbow_level)
    %{state | acc: [[sequence, token, IO.ANSI.reset()] | state.acc]}
  end

  def tab(n) when is_integer(n) do
    String.duplicate(" ", n)
  end

  def tab(state, _) do
    %{state | acc: [tab(state.indent) | state.acc]}
  end
end
