defmodule Box.BaseCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Box.Support.Timer
      alias Box.Test.MockConfig
    end
  end
end
