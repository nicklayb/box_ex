if Code.ensure_loaded?(Ecto.Multi) do
  defmodule Box.UseCase do
    require Logger

    @type params :: any()

    @callback validate(params(), Keyword.t()) :: {:ok, params()} | :ignore | {:error, any()}
    @callback run(Ecto.Multi.t(), params(), Keyword.t()) :: Ecto.Mutli.t()
    @callback after_run(params(), Keyword.t()) :: any()
    @callback return(params(), Keyword.t()) :: any()

    defmacro __using__(_) do
      quote do
        @behaviour Box.UseCase

        def execute!(params, options \\ []) do
          Box.UseCase.execute!(__MODULE__, params, options)
        end

        def execute(params, options \\ []) do
          Box.UseCase.execute(__MODULE__, params, options)
        end

        def validate(map, _), do: {:ok, map}

        def after_run(_map, _), do: :ok

        def return(map, _), do: map

        defoverridable(validate: 2, after_run: 2, return: 2)
      end
    end

    @type run_function :: (Ecto.Multi.t(), Keyword.t() ->
                             {:ok, any()} | {:error, any()} | {:error, any(), any(), any()})
    @type input_option ::
            {:transaction, Keyword.t()}
            | {:run, run_function()}
            | {:after_run?, boolean()}
    @spec execute(module(), params(), [input_option()]) ::
            {:ok, any()} | :ignore | {:error, any()}
    def execute(module, params, input_options) do
      {transaction_options, options_without_transaction} =
        Keyword.pop(input_options, :transaction, [])

      {run, options} = Keyword.pop!(options_without_transaction, :run)

      Logger.info("[#{inspect(module)}] [execute] [#{inspect(options)}] #{inspect(params)}")
      start_time = Box.Timer.now()

      with {:ok, new_params} <- module.validate(params, options),
           {:ok, %Ecto.Multi{} = multi} <- build_multi(module, new_params, options),
           {:ok, result} <- run.(multi, transaction_options) do
        end_time = Box.Timer.now()

        Logger.info(
          "[#{inspect(module)}] [success] [#{inspect(options)}] [#{Box.Integer.to_duration_string(start_time, end_time)}] #{inspect(params)}"
        )

        options = Keyword.put(options, :params, params)

        if Keyword.get(options, :after_run?, true) do
          module.after_run(result, options)
        end

        {:ok, module.return(result, options)}
      else
        :ignore ->
          Logger.info("[#{inspect(module)}] [ignore] #{inspect(options)} [#{inspect(params)}]")

          :ignore

        error ->
          Logger.error(
            "[#{inspect(module)}] [error] #{inspect(options)} [#{inspect(params)}] #{inspect(error)}"
          )

          error
      end
    end

    def execute!(module, params, options) do
      case execute(module, params, options) do
        {:ok, result} ->
          result

        :ignore ->
          :ignore

        {:error, _} = error ->
          raise "Usecase #{module} execution failed with #{inspect(error)}"

        {:error, _, _} = error ->
          raise "Usecase #{module} execution failed with #{inspect(error)}"
      end
    end

    defp build_multi(module, params, options) do
      case module.run(Ecto.Multi.new(), params, options) do
        %Ecto.Multi{} = multi ->
          Logger.debug("[#{inspect(module)}] [mulit] #{inspect(multi)}")
          {:ok, multi}

        other ->
          raise "Expected UseCase #{inspect(module)} to return Ecto.Multi.t(), got: #{inspect(other)}"
      end
    end
  end
end
