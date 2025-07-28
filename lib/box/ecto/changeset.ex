if Code.ensure_loaded?(Ecto.Changeset) and Code.ensure_loaded?(Gettext) do
  defmodule Box.Ecto.Changeset do
    @moduledoc """
    Ecto changeset helper functions.
    """
    import Ecto.Changeset

    require Ecto.Query

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

    @type format_error_option :: {:gettext, module()}
    @doc "Formats a changeset error"
    @spec format_error({atom(), {String.t(), Keyword.t()}} | {String.t(), Keyword.t()}, [
            format_error_option()
          ]) ::
            String.t()
    def format_error(error, options \\ [])

    def format_error({_field_name, {_message, _options} = error}, options),
      do: format_error(error, options)

    def format_error({message, options}, format_options) do
      gettext = Keyword.fetch!(format_options, :gettext)

      case Keyword.get(options, :count) do
        nil ->
          Gettext.dgettext(gettext, "errors", message, options)

        count ->
          Gettext.dngettext(gettext, "errors", message, message, count, options)
      end
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

    @type generate_slug_option ::
            {:source, atom()}
            | {:field, atom()}
            | {:exists?, (String.t() -> boolean())}
            | {:separator, String.t()}
    @doc """
    Generates a slug from another field on the schema
    """
    @spec generate_slug(Ecto.Changeset.t(), [generate_slug_option()]) :: Ecto.Changeset.t()
    def generate_slug(%Ecto.Changeset{} = changeset, options) do
      source_field = Keyword.fetch!(options, :source)
      destination_field = Keyword.get(options, :field, :slug)

      case Ecto.Changeset.get_change(changeset, source_field) do
        nil ->
          changeset

        name ->
          slug = generate_unique_slug(name, options)

          Ecto.Changeset.put_change(changeset, destination_field, slug)
      end
    end

    defp generate_unique_slug(name, options, incrementer \\ nil) do
      new_slug = Box.String.to_slug(name, Keyword.put(options, :incrementer, incrementer))
      exists? = Keyword.fetch!(options, :exists?)

      if exists?.(new_slug) do
        generate_unique_slug(name, options, next_incrementer(incrementer))
      else
        new_slug
      end
    end

    defp next_incrementer(nil), do: 1
    defp next_incrementer(integer), do: integer + 1

    @doc "Puts a default value change if no value is provided"
    @spec put_default_change(Ecto.Changeset.t(), atom(), (-> any()) | any) ::
            Ecto.Changeset.t()
    def put_default_change(%Ecto.Changeset{} = changeset, field, value_or_function) do
      new_value =
        case {Ecto.Changeset.get_field(changeset, field), value_or_function} do
          {nil, function} when is_function(function, 0) -> function.()
          {nil, value} -> value
          {_, current_value} -> current_value
        end

      Ecto.Changeset.put_change(changeset, field, new_value)
    end
  end
end
