defmodule Box.UseCaseTest do
  use Box.BaseCase

  defmodule TestUseCase do
    use Box.UseCase

    @impl Box.UseCase
    def validate(%{valid?: valid?} = params, options) do
      cond do
        Keyword.get(options, :ignore?, false) ->
          :ignore

        valid? and Keyword.get(options, :valid?, true) ->
          {:ok, params}

        true ->
          {:error, :invalid}
      end
    end

    @impl Box.UseCase
    def run(%Ecto.Multi{} = multi, params, options) do
      if Keyword.get(options, :fake_bad_run?, false) do
        :bad_run
      else
        Ecto.Multi.put(multi, :step, {params, options})
      end
    end

    @impl Box.UseCase
    def after_run(params, options) do
      with pid when is_pid(pid) <- Keyword.get(options, :parent_pid) do
        send(pid, {:after_run, params, options})
      end

      :ok
    end

    @impl Box.UseCase
    def return(multi_result, options) do
      %{multi_result: multi_result, options: options}
    end
  end

  describe "execute/3" do
    test "execute a use case successfully" do
      params = %{valid?: true, key: :value}
      options = [parent_pid: self(), option: :value]

      assert {:ok,
              %{
                multi_result: %{step: {:put, {^params, _}}} = multi_result,
                options: returned_options
              }} =
               execute(TestUseCase, params, options)

      assert returned_options == [{:params, params} | options]
      assert_receive({:after_run, ^multi_result, ^returned_options})

      assert {:ok,
              %{
                multi_result: %{step: {:put, {^params, _}}},
                options: _
              }} =
               execute(TestUseCase, params, Keyword.put(options, :after_run?, false))

      refute_receive({:after_run, _, _})
    end

    test "validation can be ignored" do
      assert :ignore = execute(TestUseCase, %{valid?: true}, ignore?: true)
      refute_receive({:after_run, _, _})
    end

    test "fails when validation fails" do
      assert {:error, :invalid} = execute(TestUseCase, %{valid?: false}, [])
      assert {:error, :invalid} = execute(TestUseCase, %{valid?: true}, valid?: false)
      refute_receive({:after_run, _, _})
    end

    test "fails when transaction fails" do
      assert {:error, :broken_stuff} =
               execute(TestUseCase, %{valid?: true}, run: fn _, _ -> {:error, :broken_stuff} end)

      refute_receive({:after_run, _, _})
    end
  end

  describe "execute!/3" do
    test "execute a use case successfully" do
      params = %{valid?: true, key: :value}
      options = [parent_pid: self(), option: :value]

      assert %{
               multi_result: %{step: {:put, {^params, _}}} = multi_result,
               options: returned_options
             } =
               execute!(TestUseCase, params, options)

      assert returned_options == [{:params, params} | options]
      assert_receive({:after_run, ^multi_result, ^returned_options})
    end

    test "raises when validation fails" do
      assert_raise(RuntimeError, fn ->
        execute!(TestUseCase, %{valid?: false}, [])
      end)

      assert_raise(RuntimeError, fn ->
        execute!(TestUseCase, %{valid?: true}, valid?: false)
      end)

      refute_receive({:after_run, _, _})
    end

    test "validation can be ignored" do
      assert :ignore = execute!(TestUseCase, %{valid?: true}, ignore?: true)
      refute_receive({:after_run, _, _})
    end

    test "raises when transaction fails with a three element tuple" do
      assert_raise(RuntimeError, fn ->
        execute!(TestUseCase, %{valid?: true},
          run: fn _, _ -> {:error, :oh_no, :broken_stuff} end
        )
      end)

      refute_receive({:after_run, _, _})
    end

    test "raises when transaction fails" do
      assert_raise(RuntimeError, fn ->
        execute!(TestUseCase, %{valid?: true}, run: fn _, _ -> {:error, :broken_stuff} end)
      end)

      refute_receive({:after_run, _, _})
    end

    test "raises when run doesn't return an ecto.multi" do
      assert_raise(RuntimeError, fn ->
        execute!(TestUseCase, %{valid?: true},
          fake_bad_run?: true,
          run: fn _, _ -> {:error, :broken_stuff} end
        )
      end)

      refute_receive({:after_run, _, _})
    end
  end

  defp options(options) do
    options
    |> Keyword.put_new(:run, &fake_transaction/2)
    |> Keyword.put_new(:transaction, in_transaction?: true)
  end

  defp execute!(module, params, options) do
    options = options(options)

    Box.UseCase.execute!(module, params, options)
  end

  defp execute(module, params, options) do
    options = options(options)

    Box.UseCase.execute(module, params, options)
  end

  defp fake_transaction(multi, _) do
    multi
    |> Ecto.Multi.to_list()
    |> Enum.into(%{})
    |> Box.Result.succeed()
  end
end
