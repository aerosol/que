defmodule FakeRepo do
  use Que

  def to_sql(_operation, _query) do
    """
    SELECT * FROM foo WHERE bar = 1 AND baz = 2 GROUP BY boom
    """
  end
end

defmodule QueTest do
  use ExUnit.Case
  import Ecto.Query
  require FakeRepo

  describe "use" do
    test "FakeRepo", %{test: test} do
      {:ok, io} = StringIO.open("")
      FakeRepo.que(from(s in "foo", where: s.id == 1, select: "*"), label: "foo", device: io)

      {:ok, {"", output}} = StringIO.close(io)
      assert output =~ "SELECT"
    end
  end

  describe "pp" do
  end
end
