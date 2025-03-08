defmodule Box.GeneratorTest do
  use Box.BaseCase

  defmodule FixedGenerator do
    @behaviour Box.Generator

    def generate(options) do
      generate_function = Process.get(:generate)

      generate_function.(options)
    end
  end

  @values ["first", "second", "third", "fourth", "fifth", "sixth"]
  @max_tries 3
  describe "unique/2" do
    test "generates a unique value" do
      store_pid = new_store(AgentStore, [])

      Process.put(:generate, fn options ->
        options
        |> Keyword.fetch!(:source)
        |> next()
      end)

      exists? = fn value -> Agent.get(store_pid, &(value in &1)) end

      @values
      |> Enum.take(@max_tries)
      |> Enum.each(fn value ->
        source = new_store({AgentStore, value}, @values)

        assert value ==
                 Box.Generator.unique({FixedGenerator, source: source},
                   max_tries: @max_tries,
                   exists?: exists?
                 )

        Agent.cast(store_pid, &[value | &1])
        Agent.stop(source)
      end)

      source = new_store({AgentStore, :failing}, @values)

      assert_raise(RuntimeError, fn ->
        Box.Generator.unique({FixedGenerator, source: source},
          max_tries: @max_tries,
          exists?: exists?
        )
      end)
    end
  end

  describe "generate/2" do
    test "generates a value" do
      Process.put(:generate, fn _ ->
        "value"
      end)

      assert "value" == Box.Generator.generate(FixedGenerator, [])
      assert "value" == Box.Generator.generate({FixedGenerator, []})
    end
  end

  defp new_store(id, values) do
    start_supervised!(%{id: id, start: {Agent, :start_link, [fn -> values end]}})
  end

  defp next(pid) do
    Agent.get_and_update(pid, fn [head | rest] -> {head, rest} end)
  end
end
