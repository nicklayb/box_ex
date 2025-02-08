defmodule Box.Generator do
  @moduledoc """
  Behaviour for generating random values. Generators needs to implement
  this behaviour.
  """

  @callback generate(Keyword.t()) :: String.t()

  @typedoc "Module implementing the Galerie.Generator behaviour"
  @type generator :: {module(), Keyword.t()}

  @type generate_option ::
          {:max_tries, non_neg_integer()}
          | {:exists?, (any() -> boolean())}
  @doc """
  Generates a unique value using the provided generator. Option `:schema`
  is required to validate the presence of the value.

  ## Example

      iex> genereate(Alphanumerical, exists?: fn value -> Repo.exists?(where(Book, [book], book.code == ^value)) end)

  The above example will validate that the generated value doesn't exist as
  a `:reset_password_token` in the `User` scheme
  """
  @spec unique(generator(), [generate_option() | {atom(), any()}]) :: String.t()
  def unique(generator, options) do
    exists? = Keyword.fetch!(options, :exists?)
    max_tries = Keyword.get(options, :max_tries, 5)

    unique(generator, exists?, {0, max_tries})
  end

  defp unique(generator, exists?, {tries, max_tries}) when tries < max_tries do
    value = generate(generator)

    if exists?.(value) do
      unique(generator, exists?, {tries + 1, max_tries})
    else
      value
    end
  end

  defp unique(generator, _, {_, max_tries}) do
    raise RuntimeError,
      message:
        "Max tries reached after #{max_tries} attempt to generate using #{inspect(generator)}"
  end

  def generate({generator, options}) do
    generate(generator, options)
  end

  def generate(generator, options) do
    generator.generate(options)
  end
end
