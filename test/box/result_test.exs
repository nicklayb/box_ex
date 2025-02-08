defmodule Box.ResultTest do
  use Box.BaseCase

  import ExUnit.CaptureLog

  describe "from_nil/2" do
    test "creates a result from a nil value with given error" do
      assert {:ok, "value"} = Box.Result.from_nil("value")
      assert {:ok, "value"} = Box.Result.from_nil("value", :oh_no)
      assert :error = Box.Result.from_nil(nil)
      assert {:error, :oh_no} = Box.Result.from_nil(nil, :oh_no)
    end
  end

  describe "succeed/1" do
    test "creates a succes result" do
      assert {:ok, "value"} = Box.Result.succeed("value")
    end
  end

  describe "fail/1" do
    test "creates a failed result" do
      assert {:error, :oh_no} = Box.Result.fail(:oh_no)
      assert :error = Box.Result.fail(nil)
    end
  end

  describe "succeeded?/1" do
    test "returns true if success" do
      assert Box.Result.succeeded?({:ok, "value"})
      refute Box.Result.succeeded?(:error)
      refute Box.Result.succeeded?({:error, :oh_no})
    end
  end

  describe "unwrap!/1" do
    test "gets inner value if succes, raises otherwise" do
      assert "value" = Box.Result.unwrap!({:ok, "value"})
      assert_raise(ArgumentError, fn -> Box.Result.unwrap!({:error, :oh_no}) end)
      assert_raise(ArgumentError, fn -> Box.Result.unwrap!(:error) end)
    end
  end

  describe "map/2" do
    test "maps inner value in case of success" do
      assert {:ok, "VALUE"} = Box.Result.map({:ok, "value"}, &String.upcase/1)
      assert {:error, :oh_no} = Box.Result.map({:error, :oh_no}, &String.upcase/1)
    end
  end

  describe "and_then/2" do
    test "applies function in case of result" do
      assert "VALUE" = Box.Result.and_then({:ok, "value"}, &String.upcase/1)
      assert {:error, :oh_no} = Box.Result.and_then({:error, :oh_no}, &String.upcase/1)
    end
  end

  describe "log/3" do
    test "log a message in case of either success or error" do
      call_log = fn value -> Box.Result.log(value, &("Yes " <> &1), &("No " <> to_string(&1))) end

      assert capture_log(fn ->
               call_log.({:ok, "value"})
             end) =~
               "Yes value"

      assert capture_log(fn ->
               call_log.({:error, :oh_no})
             end) =~ "No oh_no"

      assert capture_log(fn ->
               call_log.(:error)
             end) =~ "No "
    end
  end

  describe "tap/3" do
    test "tap a funcation in case of either success or error" do
      call_tap = fn value ->
        Box.Result.tap(
          value,
          &send(self(), {:yes, &1}),
          &send(self(), {:no, &1})
        )
      end

      call_tap.({:ok, "value"})
      assert_receive {:yes, "value"}
      call_tap.({:error, :oh_no})
      assert_receive {:no, :oh_no}
      call_tap.(:error)
      assert_receive {:no, nil}
    end

    test "defaults to identity" do
      call_tap = fn value ->
        Box.Result.tap(value, &send(self(), {:yes, &1}))
      end

      call_tap.({:ok, "value"})
      assert_receive {:yes, "value"}
      call_tap.({:error, :oh_no})
      refute_receive {:no, :oh_no}
      call_tap.(:error)
      refute_receive {:no, nil}
    end
  end

  describe "with_default/2" do
    test "returns success value or default if failed" do
      assert "value" = Box.Result.with_default({:ok, "value"}, "all good")
      assert "all good" = Box.Result.with_default({:error, :oh_no}, "all good")
      assert "all good" = Box.Result.with_default(:error, "all good")
      assert "oh_no" = Box.Result.with_default({:error, :oh_no}, fn error -> to_string(error) end)
      assert "nil" = Box.Result.with_default(:error, fn error -> inspect(error) end)
      assert "oh_no" = Box.Result.with_default({:error, :oh_no}, fn -> "oh_no" end)
    end
  end

  describe "from_boolean/3" do
    test "gets success if true, error if false" do
      assert {:ok, "value"} = Box.Result.from_boolean(true, "value", :oh_no)
      assert {:error, :oh_no} = Box.Result.from_boolean(false, "value", :oh_no)
      assert :error = Box.Result.from_boolean(false, "value", nil)
    end
  end
end
