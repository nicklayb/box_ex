if Code.ensure_loaded?(Ecto.Multi) do
  defmodule Box.UseCase do
    @moduledoc """
    Use cases are a way to perform mutation in the system through
    automatic transactioning. They can perform validation and side
    effects when the results is a success one.

    ## Examples

    The following use case is one that handles User creation from an admin panel.

    1. It expects an optiona `authenticated_user` to make sure that only admin users
    can actually create users
    2. It's gonna run the insertion in a transaction, if validation succeeded
    3. It's gonna broadcast a pub sub message (maybe to update a table in live) and
    send an email to the user, if the transaction succeeded
    4. Finally an `{:ok, user}` will be returned from this execution rather than the multi result.

    ```elixir
    defmodule Accounts.CreateUser do
      use Box.UseCase

      @impl Box.UseCase
      def validate(params, [authenticated_user: %User{role: "admin"}]) do
        {:ok, params}
      end

      def validate(_, _), do: {:error, :insufficient_permissions}

      @impl Box.UseCase
      def run(multi, params, _options) do
        Ecto.Multi.insert(:user, User.changeset(params))
      end

      @impl Box.UseCase
      def after_run(%{user: %User{id: user_id, email: email}}) do
        PubSub.broadcast("users", {:new_user, user_id})
        Mailer.send_welcome_email(email)
      end

      @impl Box.UseCase
      def return(%{user: %User{} = user}) do
        {:ok, user}
      end
    end
    ```
    """
    require Logger

    @type params :: any()

    @doc """
    Validates if a given use case can be run or not. This can receive options so you can ensure a user's
    presence, some sort of roles etc... If it returns an ̀`{:ok, _}` tuple, we'll move forward to the
    `run/3` callback in order to build an ecto multi.
    """
    @callback validate(params(), Keyword.t()) :: {:ok, params()} | :ignore | {:error, any()}

    @doc """
    This is where the actual transaction body happens. This receives an empty multi for the use
    to add new transaction step to it. It also receives the same options as the `validate/2` callback.
    """
    @callback run(Ecto.Multi.t(), params(), Keyword.t()) :: Ecto.Mutli.t()

    @doc """
    This callback will run some side effects post-transactions. It receives the Ecto.Multi result
    as-is so a use can can do various thing from the step. Maybe broadcast a message to a post topic
    when a new comment is created or send an email to a newly created user. Return value is ignored.
    """
    @callback after_run(params(), Keyword.t()) :: any()

    @doc """
    This callback is involved right before returning. We'll use this callback to "simplify" the return
    value. This can be used to return only a main entity from a 5-6 steps multi result and even preload
    some relations.
    """
    @callback return(params(), Keyword.t()) :: any()

    defmacro __using__(_) do
      quote do
        @behaviour Box.UseCase

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
