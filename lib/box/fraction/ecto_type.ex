if Code.ensure_loaded?(Ecto.Type) do
  defmodule Box.Fraction.EctoType do
    @moduledoc """
    Ecto type for Fraction. The Fraction type is expected to 
    be stored as a `fraction` type which is a composite Postgres
    type.
    """
    use Ecto.Type

    alias Box.Fraction

    @spec type() :: :fraction
    def type, do: :fraction

    @spec load({integer(), integer()}) :: {:ok, Fraction.t()}
    def load({numerator, denominator}) when is_integer(numerator) and is_integer(denominator) do
      {:ok, Fraction.new({numerator, denominator})}
    end

    @spec dump(any()) :: :error | {:ok, {integer(), String.t()}}
    def dump(%Fraction{} = fraction) do
      {:ok, Fraction.to_tuple(fraction)}
    end

    def dump(_), do: :error

    @spec cast(Fraction.t() | {integer(), integer()} | {String.t(), String.t()}) ::
            :error | {:ok, Fraction.t()}
    def cast(%Fraction{} = fraction) do
      {:ok, fraction}
    end

    def cast({numerator, denominator} = tuple)
        when is_integer(numerator) and is_integer(denominator) do
      {:ok, Fraction.new(tuple)}
    end

    def cast({numerator, denominator}) when is_binary(numerator) and is_binary(denominator) do
      cast({String.to_integer(numerator), String.to_integer(denominator)})
    end

    def cast(string) when is_binary(string) do
      string
      |> Fraction.parse()
      |> cast()
    rescue
      _ ->
        :error
    end

    def cast(_), do: :error
  end
end
