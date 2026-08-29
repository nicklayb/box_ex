defmodule Box.HttpTest do
  use Box.BaseCase

  alias Box.Http.Error, as: HttpError
  alias Box.Http.Request
  alias Box.Http.Response

  defmodule FakeAdapter do
    def request(%Request{}, options) do
      case Keyword.get(options, :error) do
        nil ->
          {:ok,
           %Response{
             status: Keyword.get(options, :status, 200),
             body: Keyword.get(options, :response_body, ""),
             headers: Keyword.get(options, :response_headers, [])
           }}

        error ->
          {:error, %HttpError{error: error}}
      end
    end
  end

  defmodule FakeHttp do
    use Box.Http, otp_app: :my_app
  end

  setup [:setup_fake_adapter]

  describe "request/1" do
    test "calls the adapter creating a Request struct returning the request" do
      method = :get
      url = "http://localhost"
      body = ""
      headers = []

      assert {:ok, %Request{} = request, %Response{}} =
               FakeHttp.request(
                 method: method,
                 url: url,
                 headers: headers,
                 body: body
               )

      assert request.url == url
      assert request.method == method
      assert request.headers == headers
      assert request.body == body
    end

    test "returns an error if error" do
      method = :get
      url = "http://localhost"
      body = ""
      headers = []

      assert {:error, %Request{} = request, %HttpError{error: "oh no"}} =
               FakeHttp.request(
                 method: method,
                 url: url,
                 headers: headers,
                 body: body,
                 error: "oh no"
               )

      assert request.url == url
      assert request.method == method
      assert request.headers == headers
      assert request.body == body
    end
  end

  describe "request_200" do
    test "succeeds if response is 2XX" do
      method = :get
      url = "http://localhost"
      body = ""
      headers = []

      assert {:ok, %Request{} = request, %Response{status: 201}} =
               FakeHttp.request_200(
                 method: method,
                 url: url,
                 headers: headers,
                 body: body,
                 status: 201
               )

      assert request.url == url
      assert request.method == method
      assert request.headers == headers
      assert request.body == body
    end

    test "fails if response is not 2XX" do
      method = :get
      url = "http://localhost"
      body = ""
      headers = []

      assert {:error, %Request{} = request, %Response{status: 404}} =
               FakeHttp.request_200(
                 method: method,
                 url: url,
                 headers: headers,
                 body: body,
                 status: 404
               )

      assert request.url == url
      assert request.method == method
      assert request.headers == headers
      assert request.body == body
    end
  end

  defp setup_fake_adapter(context) do
    adapter_options = Map.get(context, :adapter_options, [])
    MockConfig.mock_config(:my_app, FakeHttp, adapter: {FakeAdapter, adapter_options})
    :ok
  end
end
