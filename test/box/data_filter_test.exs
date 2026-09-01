defmodule Box.DataFilterTest do
  use Box.BaseCase

  defmodule TestFilter do
    use Box.DataFilter,
      fields: [
        search: [],
        level: [default: :user],
        admins?: [default: false]
      ]

    @impl Box.DataFilter
    def cast(%Filter{} = filter, :admins?, "true") do
      %Filter{filter | level: :admin, admins?: true}
    end

    def cast(%Filter{} = filter, :admins?, _) do
      %Filter{filter | level: :user, admins?: false}
    end

    def cast(%Filter{}, _, nil), do: nil
    def cast(%Filter{}, :search, ""), do: nil

    def cast(%Filter{}, :search, value) do
      with "" <- String.trim(value) do
        nil
      end
    end

    @impl Box.DataFilter
    def apply(%Filter{}, accumulator, _, nil), do: accumulator

    def apply(%Filter{}, accumulator, :search, value) do
      Map.put(accumulator, :search_by, value)
    end

    def apply(%Filter{level: level}, accumulator, :admins?, true) do
      Map.put(accumulator, :with_level, level)
    end

    def apply(_, accumulator, _, _), do: accumulator

    @impl Box.DataFilter
    def to_query(%Filter{}, _, nil), do: :ignore

    def to_query(%Filter{}, :search, search), do: search

    def to_query(%Filter{}, :admins?, true), do: {"is_admin", "true"}

    def to_query(%Filter{}, :level, level), do: {:level, to_string(level)}

    def to_query(%Filter{}, _, _), do: :ignore
  end

  describe "new/0" do
    test "initializes fields with defaults" do
      assert %TestFilter{search: nil, level: :user, admins?: false} = TestFilter.new()
    end
  end

  describe "new/1" do
    test "initializes fields from params" do
      assert %TestFilter{search: "my search", level: :user, admins?: false} =
               TestFilter.new(%{search: "my search"})

      assert %TestFilter{search: "my search", level: :user, admins?: false} =
               TestFilter.new(%{"search" => "my search"})
    end
  end

  describe "set/3" do
    test "sets field casting with the right function" do
      assert %TestFilter{search: "search"} = TestFilter.set(TestFilter.new(), :search, "search")

      assert %TestFilter{search: nil} =
               TestFilter.set(TestFilter.new(), :search, "")
    end

    test "cast functions can return updated struct instead" do
      assert %TestFilter{admins?: true, level: :admin} =
               TestFilter.set(TestFilter.new(), :admins?, "true")

      assert %TestFilter{admins?: false, level: :user} =
               TestFilter.set(TestFilter.new(), :admins?, "false")
    end
  end

  describe "update/2" do
    test "updates from a params set" do
      assert %TestFilter{search: "was set before", admins?: false} =
               filter = TestFilter.new(%{search: "was set before"})

      assert %TestFilter{search: "was set before", admins?: true} =
               TestFilter.update(filter, %{admins?: "true"})
    end
  end

  describe "apply_filter/2" do
    test "applies filter on accumulator" do
      assert %{previous: "previous", search_by: "username", with_level: :admin} =
               %{search: "username", admins?: "true"}
               |> TestFilter.new()
               |> then(&TestFilter.apply_filter(%{previous: "previous"}, &1))
    end
  end

  describe "to_query_params/2" do
    test "builds query params" do
      assert %{"level" => "user"} ==
               %{}
               |> TestFilter.new()
               |> TestFilter.to_query_params()

      assert %{"level" => "admin", "is_admin" => "true", "search" => "dragons"} ==
               %{search: "dragons", admins?: "true"}
               |> TestFilter.new()
               |> TestFilter.to_query_params()
    end
  end

  describe "to_query_string/2" do
    test "builds query string" do
      assert "level=user" ==
               %{}
               |> TestFilter.new()
               |> TestFilter.to_query_string()

      assert "is_admin=true&level=admin&search=dragons" ==
               %{search: "dragons", admins?: "true"}
               |> TestFilter.new()
               |> TestFilter.to_query_string()
    end
  end
end
