defmodule Box.ConfigTest do
  use Box.BaseCase

  setup [:setup_env]

  describe "get/2" do
    @tag env: %{
           "STAGE" => "staging"
         }
    test "gets string value" do
      assert "staging" == Box.Config.get("STAGE", default: "Default", test: "test")

      assert_raise(RuntimeError, fn ->
        Box.Config.get("STAGE", default: :not_a_string, required: true)
      end)

      assert_raise(RuntimeError, fn ->
        Box.Config.get("STAGE", default: :not_a_string, test: "test")
      end)

      with_config_env(:test, fn ->
        assert "test" == Box.Config.get("STAGE", default: "Default", test: "test")
      end)

      assert "Default" == Box.Config.get("XANADU", default: "Default", test: "test")
      assert nil == Box.Config.get("XANADU")

      assert_raise(System.EnvError, fn ->
        Box.Config.get!("XANADU")
      end)

      assert_raise(System.EnvError, fn ->
        Box.Config.get("XANADU", required: true)
      end)
    end
  end

  describe "list/2" do
    @tag env: %{
           "ROLES" => "admin,user",
           "HOSTS" => "http://google.com|http://yahoo.com"
         }
    test "gets list value" do
      assert ["admin", "user"] = Box.Config.list("ROLES", default: "", test: "test")

      with_config_env(:test, fn ->
        assert "test" == Box.Config.get("ROLES", default: "admin", test: "test")
      end)

      assert ["http://google.com", "http://yahoo.com"] =
               Box.Config.list("HOSTS", separator: "|", default: "", test: "localhost")

      assert ["localhost"] =
               Box.Config.list("OTHER_HOSTS",
                 separator: "|",
                 default: "localhost",
                 test: "localhost"
               )
    end
  end

  describe "atom/2" do
    @tag env: %{
           "LOG_LEVEL" => "info",
           "DONT_EXIST" => "potato",
           "DONT_EXIST_EITHER" => "tomato"
         }
    test "converts to known atoms" do
      assert :info == Box.Config.atom("LOG_LEVEL", default: "error", test: :debug)

      with_config_env(:test, fn ->
        assert :debug == Box.Config.atom("LOG_LEVEL", default: "error", test: :debug)
      end)

      assert :error == Box.Config.atom("LOGGY_LEVEL", default: "error", test: :debug)

      assert_raise(ArgumentError, fn ->
        Box.Config.atom("DONT_EXIST", required: true)
      end)

      assert :tomato == Box.Config.unsafe_atom("DONT_EXIST_EITHER", required: true)

      assert :info == Box.Config.unsafe_atom("LOG_LEVEL", required: true)
    end
  end

  describe "int/2" do
    @tag env: %{
           "SOME_PORT" => "2112",
           "INVALID_PORT" => "twenty one twelve"
         }
    test "gets int value" do
      assert 2112 == Box.Config.int("SOME_PORT", default: "9001", test: "1001")

      with_config_env(:test, fn ->
        assert 1001 == Box.Config.int("SOME_PORT", default: "9001", test: 1001)
      end)

      assert 9001 == Box.Config.int("POME_SORT", default: "9001", test: "1001")
      assert nil == Box.Config.int("POME_SORT")

      assert_raise(System.EnvError, fn ->
        Box.Config.int!("POME_SORT")
      end)

      assert_raise(System.EnvError, fn ->
        Box.Config.int("POME_SORT", required: true)
      end)
    end
  end

  describe "uri/2" do
    @tag env: %{
           "TEST_HOST" => "https://xanadu.com:2112"
         }
    test "gets uri value" do
      assert %URI{scheme: "https", host: "xanadu.com", path: nil, port: 2112} =
               Box.Config.uri("TEST_HOST",
                 default: "http://localhost:4001",
                 test: "http://test:1001"
               )

      with_config_env(:test, fn ->
        assert %URI{scheme: "http", host: "test", path: nil, port: 1001} =
                 Box.Config.uri("BAD_HOST",
                   default: "http://localhost:4001",
                   test: URI.parse("http://test:1001")
                 )
      end)

      assert %URI{scheme: "http", host: "localhost", path: nil, port: 4001} =
               Box.Config.uri("BAD_HOST",
                 default: "http://localhost:4001",
                 test: "http://test:1001"
               )

      assert nil == Box.Config.uri("BAD_HOST")

      assert_raise(System.EnvError, fn ->
        Box.Config.uri!("BAD_HOST")
      end)

      assert_raise(System.EnvError, fn ->
        Box.Config.uri("BAD_HOST", required: true)
      end)
    end
  end

  describe "bool/2" do
    @tag env: %{
           "IS_ACTIVE" => "true",
           "IS_INACTIVE" => "false",
           "IS_INVALID" => "vrai"
         }
    test "gets bool value" do
      assert true == Box.Config.bool("IS_ACTIVE", default: "true", test: false)
      assert false == Box.Config.bool("IS_INACTIVE", default: "true", test: false)

      with_config_env(:test, fn ->
        assert false == Box.Config.bool("IS_ACTIVE", default: "true", test: false)
      end)

      assert true == Box.Config.bool("EST_ACTIF", default: "true", test: false)
      assert nil == Box.Config.bool("EST_ACTIVE")

      assert_raise(System.EnvError, fn ->
        Box.Config.bool!("EST_ACTIF")
      end)

      assert_raise(System.EnvError, fn ->
        Box.Config.bool("EST_ACTIF", required: true)
      end)
    end
  end

  defp with_config_env(env, function) do
    Process.put(:current_env, env)
    function.()
    Process.delete(:current_env)
  end

  defp setup_env(context) do
    context
    |> Map.get(:env, %{})
    |> Enum.each(fn {key, value} ->
      put_env(key, value)
    end)
  end

  defp put_env(key, value) do
    old_value = System.get_env(key)
    System.put_env(key, value)

    on_exit(fn ->
      if old_value do
        System.put_env(key, old_value)
      else
        System.delete_env(key)
      end
    end)
  end
end
