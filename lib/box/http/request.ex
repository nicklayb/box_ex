defmodule Box.Http.Request do
  @moduledoc """
  Generic HTTP Request structure
  """
  alias Box.Http.Request

  defstruct [:headers, :body, :method, :url]

  @type method :: :get | :post | :patch | :put | atom()

  @type t :: %Request{
          headers: [Box.Http.header()],
          body: any(),
          method: method(),
          url: URI.t()
        }
end
