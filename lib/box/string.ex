defmodule Box.String do
  @default_separator "-"

  @type to_slug_option :: {:incrementer, integer() | nil} | {:separator, String.t()}

  @doc """
  Slugifies a string
  """
  @spec to_slug(String.t(), [to_slug_option()]) :: String.t()
  def to_slug(string, options \\ []) do
    incrementer = Keyword.get(options, :incrementer)
    separator = Keyword.get(options, :separator, @default_separator)

    string
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s]+/, "")
    |> String.replace(~r/\s+/, separator)
    |> put_incrementer(incrementer, separator)
  end

  defp put_incrementer(string, nil, _), do: string

  defp put_incrementer(string, incrementer, separator),
    do: string <> separator <> to_string(incrementer)
end
