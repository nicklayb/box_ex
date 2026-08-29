defmodule Box.Http.Error do
  @moduledoc """
  Generic HTTP Error structure
  """
  alias Box.Http.Error

  defstruct [:error, :detail]

  @type t :: %Error{
          error: any(),
          detail: any()
        }
end
