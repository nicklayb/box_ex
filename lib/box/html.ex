defmodule Box.Html do
  @type condition :: boolean() | (-> boolean())
  @type conditional_class :: {condition(), String.t()} | {condition(), String.t(), String.t()}

  @type class :: String.t() | conditional_class()

  @spec class(String.t(), class() | [class()] | nil) :: String.t()
  def class(initial \\ "", classes)

  def class(initial, classes) when is_list(classes) do
    Enum.reduce(classes, initial, fn class, acc ->
      class(acc, class)
    end)
  end

  def class(initial, nil), do: initial
  def class(initial, ""), do: initial

  def class(initial, {true, class}), do: class(initial, class)
  def class(initial, {true, class, _}), do: class(initial, class)
  def class(initial, {false, _, class}), do: class(initial, class)

  def class(initial, {function, class}) when is_function(function, 0),
    do: class(initial, {function.(), class})

  def class(initial, {function, if_true, if_false}) when is_function(function, 0),
    do: class(initial, {function.(), if_true, if_false})

  def class("", ""), do: ""

  def class("", class) when is_binary(class), do: class

  def class(initial, ""), do: initial

  def class(initial, class) when is_binary(class), do: initial <> " " <> class

  def class(initial, _), do: initial

  @spec titleize(atom() | String.t()) :: String.t()
  def titleize(atom) when is_atom(atom) do
    atom
    |> to_string()
    |> titleize()
  end

  def titleize(string) do
    string
    |> String.replace("_", " ")
    |> Macro.camelize()
  end
end
