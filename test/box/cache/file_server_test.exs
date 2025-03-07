defmodule Box.Cache.FileServerTest do
  use Box.BaseCase, async: false

  defmodule CountryDecoder do
    @behaviour Box.Cache.FileServer

    def decode(string, options) do
      string
      |> Jason.decode!()
      |> Enum.map(fn json ->
        code = Map.fetch!(json, "code")

        key =
          if Keyword.get(options, :lowercase, false) do
            String.downcase(code)
          else
            code
          end

        {key, json}
      end)
      |> Box.Result.succeed()
    end
  end

  @name CountriesCache
  @fixture_file "./test/support/fixtures/countries.json"

  setup context do
    decoder =
      case Map.get(context, :decoder_options) do
        nil -> CountryDecoder
        options -> {CountryDecoder, options}
      end

    start_supervised!({Box.Cache.FileServer, name: @name, file: @fixture_file, decoder: decoder})

    :ok
  end

  describe "start_link/1" do
    test "starts server and allows query" do
      assert {:ok, %{"code" => "CA", "name" => "Canada", "dial_code" => "+1"}} ==
               Box.Cache.get(@name, "CA")
    end

    @tag decoder_options: [lowercase: true]
    test "starts server and pass options to the decoder" do
      assert {:ok, %{"code" => "CA", "name" => "Canada", "dial_code" => "+1"}} ==
               Box.Cache.get(@name, "ca")
    end
  end
end
