if Code.ensure_loaded?(Ecto.Schema) do
  defmodule Box.Ecto.Schema do
    defmacro flag(setter, options \\ []) do
      quote do
        # credo:disable-for-lines:3
        field(:"#{unquote(setter)}", :boolean, virtual: true)
        setter_field = Keyword.get(unquote(options), :key, "#{unquote(setter)}_at")
        field(:"#{setter_field}", :utc_datetime)
      end
    end
  end
end
