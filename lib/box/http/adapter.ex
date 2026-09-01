defmodule Box.Http.Adapter do
  @moduledoc """
  Behaviour for implementing HTTP adapters
  """
  @type request :: Box.Http.Request.t()
  @type response :: Box.Http.Response.t()
  @type error :: Box.Http.Error.t()

  @type result :: {:ok, response()} | {:error, error()}

  @callback request(request(), Keyword.t()) :: result()
end
