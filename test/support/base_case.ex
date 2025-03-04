defmodule Box.BaseCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Box.Support.Timer
    end
  end
end
