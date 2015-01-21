# --------------------
# Tideland Elixir Application Support - Identifier - Tests
# Copyright (C) 2014-2015 Frank Mueller / Tideland / Oldenburg / Germany
# --------------------

defmodule EXAS.IdentifierTest do
  use ExUnit.Case, async: true

  test "correct identifier, no joiner, no mapper" do
    assert EXAS.Identifier.new([]) == ""
    assert EXAS.Identifier.new([true, false]) == "true-false"
    assert EXAS.Identifier.new([:a, :b, :c]) == "a-b-c"
    assert EXAS.Identifier.new([1, 2, 3]) == "1-2-3"
    assert EXAS.Identifier.new(["A", "B", "C"]) == "A-B-C"
    assert EXAS.Identifier.new([:a, 2, "C"]) == "a-2-C"
  end

  test "correct identifier, different joiner, no mapper" do
    assert EXAS.Identifier.new([:a, :b, :c], "/") == "a/b/c"
    assert EXAS.Identifier.new([:a, :b, :c], "") == "abc"
    assert EXAS.Identifier.new([:a, :b, :c], " :: ") == "a :: b :: c"
  end

  test "correct identifier, different joiner, different mapper" do
    assert EXAS.Identifier.new(["A", 4711, :c], "-", &String.downcase/1) == "a-4711-c"
    assert EXAS.Identifier.new(["A", 4711, :c], "/", &String.upcase/1) == "A/4711/C"
  end

  test "illegal part list, so raised argument error" do
    assert_raise ArgumentError, fn ->
      EXAS.Identifier.new([1.1])
    end
    assert_raise ArgumentError, fn ->
      EXAS.Identifier.new(['foo'])
    end
    assert_raise ArgumentError, fn ->
      EXAS.Identifier.new([fn x -> x end])
    end
  end

  test "UUID v1" do
    test_uuid_generator(&EXAS.Identifier.new_uuid_v1/1, 1)
  end

  test "UUID v3" do
      test_uuid_generator(fn(format) -> EXAS.Identifier.new_uuid_v3(:dns, "www.tideland.biz", format) end, 3)
      test_uuid_generator(fn(format) -> EXAS.Identifier.new_uuid_v3(:url, "www.tideland.biz", format) end, 3)
      test_uuid_generator(fn(format) -> EXAS.Identifier.new_uuid_v3(:oid, "www.tideland.biz", format) end, 3)
      test_uuid_generator(fn(format) -> EXAS.Identifier.new_uuid_v3(:x500, "www.tideland.biz", format) end, 3)
      test_uuid_generator(fn(format) -> EXAS.Identifier.new_uuid_v3(:nil, "www.tideland.biz", format) end, 3)
      uuid = EXAS.Identifier.new_uuid_v4()
      test_uuid_generator(fn(format) -> EXAS.Identifier.new_uuid_v3(uuid, "www.tideland.biz", format) end, 3)
  end

  test "UUID v4" do
    test_uuid_generator(&EXAS.Identifier.new_uuid_v4/1, 4)
  end

  test "UUID v5" do
      test_uuid_generator(fn(format) -> EXAS.Identifier.new_uuid_v5(:dns, "www.tideland.biz", format) end, 5)
      test_uuid_generator(fn(format) -> EXAS.Identifier.new_uuid_v5(:url, "www.tideland.biz", format) end, 5)
      test_uuid_generator(fn(format) -> EXAS.Identifier.new_uuid_v5(:oid, "www.tideland.biz", format) end, 5)
      test_uuid_generator(fn(format) -> EXAS.Identifier.new_uuid_v5(:x500, "www.tideland.biz", format) end, 5)
      test_uuid_generator(fn(format) -> EXAS.Identifier.new_uuid_v5(:nil, "www.tideland.biz", format) end, 5)
      uuid = EXAS.Identifier.new_uuid_v4()
      test_uuid_generator(fn(format) -> EXAS.Identifier.new_uuid_v5(uuid, "www.tideland.biz", format) end, 5)
  end

  # --------------------
  # HELPER
  # --------------------

  def test_uuid_generator(uuid_generator, wanted_version) do
    # Test the generator for a given version.
    uuid_default = uuid_generator.(:default)
    {:ok, <<_ :: 128>>, version, variant} = EXAS.Identifier.parse_uuid(uuid_default)

    assert String.length(uuid_default) == 36
    assert Regex.match?(~r/[a-z0-9]{8}\-[a-z0-9]{4}\-[a-z0-9]{4}\-[a-z0-9]{4}\-[a-z0-9]{12}/, uuid_default)
    assert version == wanted_version
    assert variant == :rfc4122

    uuid_urn = uuid_generator.(:urn)
    {:ok, <<_ :: 128>>, version, variant} = EXAS.Identifier.parse_uuid(uuid_urn)

    assert String.length(uuid_urn) == 45
    assert Regex.match?(~r/urn:uuid:[a-z0-9]{8}\-[a-z0-9]{4}\-[a-z0-9]{4}\-[a-z0-9]{4}\-[a-z0-9]{12}/, uuid_urn)
    assert version == wanted_version
    assert variant == :rfc4122

    uuid_bin = uuid_generator.(:binary)
    {:ok, <<_ :: 128>>, version, variant} = EXAS.Identifier.parse_uuid(uuid_bin)

    assert byte_size(uuid_bin) == 16
    assert version == wanted_version
    assert variant == :rfc4122

    uuid_hex = uuid_generator.(:hex)
    {:ok, <<_ :: 128>>, version, variant} = EXAS.Identifier.parse_uuid(uuid_hex)

    assert String.length(uuid_hex) == 32
    assert Regex.match?(~r/[a-z0-9]{32}/, uuid_hex)
    assert version == wanted_version
    assert variant == :rfc4122
  end

end

# --------------------
# EOF
# --------------------
