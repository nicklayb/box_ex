defmodule Box.Http do
  @moduledoc """
  Generic HTTP client dependency free. It needs to be provided
  an adapter in configuration to use.

  ## Example

  Create your local implementation specifying your OTP App name for the configuration.

  ```elixir
  defmodule MyApp.Http do
    use Box.Http, otp_app: :my_app
  end
  ```

  Configure the adapter (like Req, for instance)

  ```elixir
  config(:my_app, MyApp.Http, adapter: Box.Http.Adapter.Req)
  # or, with options
  config(:my_app, MyApp.Http, adapter: {Box.Http.Adapter.Req, [some_option: true]})
  ```

  Then call it

  ```elixir
  MyApp.Http.request(url: "http://google.com")
  ```

  **Note**: Calling the client with the adapter explicitely is discourage as it
  removes the capabailities to override it in tests.
  """
  alias Box.Http.Error
  alias Box.Http.Request
  alias Box.Http.Response

  defmacro __using__(options) do
    quote do
      @otp_app Keyword.fetch!(unquote(options), :otp_app)
      def request(options) do
        Box.Http.request(adapter(), options)
      end

      def request_200(options) do
        Box.Http.request_200(adapter(), options)
      end

      def adapter do
        @otp_app
        |> Application.fetch_env!(__MODULE__)
        |> Keyword.fetch!(:adapter)
      end
    end
  end

  @type header :: {String.t(), String.t()}

  @type option ::
          {:method, Request.method()}
          | {:header, [header()]}
          | {:body, any()}
          | {:url, URI.t()}
          | {atom(), any()}

  @type adapter :: {module(), Keyword.t()} | module()
  @request_options ~w(method url body headers)a

  @doc "Performs a HTTP request with configured adapter"
  @spec request(adapter(), [option()]) :: {:ok, Request.t(), Response.t()} | {:error, Error.t()}
  def request(adapter, options) do
    {request_options, options} = Keyword.split(options, @request_options)

    request = %Request{
      method: Keyword.get(request_options, :method, :get),
      body: Keyword.get(request_options, :body),
      headers: Keyword.get(request_options, :headers, []),
      url: Keyword.fetch!(request_options, :url)
    }

    {adapter, adapter_options} =
      case adapter do
        {_, _} = adapter_with_options -> adapter_with_options
        adapter -> {adapter, []}
      end

    case adapter.request(request, Keyword.merge(adapter_options, options)) do
      {:ok, %Response{} = response} ->
        {:ok, request, response}

      {:error, error} ->
        {:error, request, error}
    end
  end

  @doc "Performs an HTTP request expecting a 2XX response, returning error otherwise"
  @spec request_200(adapter(), [option()]) ::
          {:ok, Request.t(), Response.t()}
          | {:error, Request.t(), Response.t()}
          | {:error, Request.t(), Error.t()}
  def request_200(adapter, options) do
    with {:ok, request, %Response{status: status} = response} when status not in 200..299 <-
           request(adapter, options) do
      {:error, request, response}
    end
  end
end
