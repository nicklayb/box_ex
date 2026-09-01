defmodule Box.Http.Response do
  @moduledoc """
  Generic HTTP Response structure
  """
  alias Box.Http.Response

  defstruct [:status, :body, :headers]

  @type t :: %Response{
          headers: [Box.Http.header()],
          body: any(),
          status: non_neg_integer()
        }
end
