defmodule Box.Keyword do
  def rename(keyword, from_key, to_key) do
    case Keyword.pop(keyword, from_key) do
      {nil, unchanged} -> unchanged
      {value, rest_keyword} -> Keyword.put(rest_keyword, to_key, value)
    end
  end
end
