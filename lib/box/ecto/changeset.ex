defmodule Box.Ecto.Changeset do
  @moduledoc """
  Ecto changeset helper functions.
  """
  import Ecto.Changeset

  @type touch_timestamp_option :: {:key, atom()} | {:setter, atom()}

  @doc """
  Updates a schema's timestamp from a boolean field. The schema
  needs to have a virtual field to check if it should update the
  timestamp or not.

  By default, the function infers the timestamp field's name from
  the virtual field's name.

  ## Example

  Calling `touch_timestamp(changeset, setter: :inverted)` will
  attempt to update the `inverted_at` timestamp. This can be
  overriden with thie `:key` option
  """
  @spec touch_timestamp(Ecto.Changeset.t(), [touch_timestamp_option()]) :: Ecto.Changeset.t()
  def touch_timestamp(%Ecto.Changeset{} = changeset, options) do
    Box.Ecto.Changeset.update_valid(changeset, fn changeset ->
      setter = Keyword.fetch!(options, :setter)
      key = Keyword.get_lazy(options, :key, fn -> String.to_existing_atom("#{setter}_at") end)

      case get_change(changeset, setter) do
        true -> put_change(changeset, key, DateTime.truncate(DateTime.utc_now(), :second))
        false -> put_change(changeset, key, nil)
        _ -> changeset
      end
    end)
  end

  @doc "Hashes a value using Argon2"
  @spec hash(Ecto.Changeset.t(), atom()) :: Ecto.Changeset.t()
  def hash(%Ecto.Changeset{} = changeset, field, options \\ []) do
    hash_function = Keyword.fetch!(options, :hash_function)

    Box.Ecto.Changeset.update_valid(changeset, fn changeset ->
      update_change(changeset, field, hash_function)
    end)
  end

  @doc "Trims fields values in changeset"
  @spec trim(Ecto.Changeset.t(), [atom()] | atom()) :: Ecto.Changeset.t()
  def trim(%Ecto.Changeset{} = changeset, field_or_fields) do
    field_or_fields
    |> List.wrap()
    |> Enum.reduce(changeset, fn field, changeset ->
      Ecto.Changeset.update_change(changeset, field, &String.trim/1)
    end)
  end

  @doc """
  Generates a unique value. Requires at least a generator and a length

  ## Examples

      iex> generate_unique(changeset, :code, generator: Box.Generator.Base64, length: 12)

  The above generates a 12 char long base 64 encoded string as ̀`:code`
  """
  @spec generate_unique(Ecto.Changeset.t(), atom(), Keyword.t()) :: Ecto.Changeset.t()
  def generate_unique(%Ecto.Changeset{} = changeset, field, options) do
    {generator, options} = Keyword.pop!(options, :generator)
    value = Box.Generator.unique(generator, options)
    Ecto.Changeset.put_change(changeset, field, value)
  end

  @doc "Applies a given function a valid changeset"
  @spec update_valid(Ecto.Changeset.t(), (Ecto.Changeset.t() -> Ecto.Changeset.t())) ::
          Ecto.Changeset.t()
  def update_valid(%Ecto.Changeset{valid?: true} = changeset, function) do
    function.(changeset)
  end

  def update_valid(changeset, _), do: changeset
end
