if Code.ensure_loaded?(Ecto.Schema) do
  defmodule Box.Ecto.Schema do
    defmacro flag(setter, options \\ []) do
      quote do
        field(:"#{unquote(setter)}", :boolean, virtual: true)
        setter_field = Keyword.get(unquote(options), :key, "#{unquote(setter)}_at")
        field(:"#{setter_field}", :naive_datetime)
      end
    end
  end
end
