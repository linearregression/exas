# --------------------
# Tideland Elixir Application Support - Identifier
# Copyright (C) 2014-2015 Frank Mueller / Tideland / Oldenburg / Germany
# --------------------

defmodule EXAS.Identifier do
  use Bitwise, only_operators: true

  @moduledoc """
  Identifier provides a way to generate identifiers and UUIDs.
  """

  # --------------------
  # PUBLIC API
  # --------------------

  @doc """
  Create a new identifier out of the strings, atoms, and integers in the list 'parts'.
  The optional 'joiner' specifies the joining sting for the parts, default is a dash.
  The optional mapper allows to post-process the parts, e.g. downcase strings or remove
  spaces.
  """
  def new(parts, joiner \\ "-", mapper \\ fn p -> p end) when 
    is_list(parts) and is_binary(joiner) and is_function(mapper, 1) do
    valid? = Enum.all?(parts, fn(part) -> is_atom(part) or is_binary(part) or is_integer(part) end)
    if valid? do
      id_mapper = fn
        part when is_atom(part) ->
          mapper.(Atom.to_string(part))
        part when is_integer(part) ->
          mapper.(Integer.to_string(part))
        part ->
          mapper.(part)
      end
      Enum.map_join(parts, joiner, id_mapper)
    else
      raise ArgumentError, message: "parts have to be atoms, strings, or integers"
    end
  end

  @uuid_v1 1
  @uuid_v3 3
  @uuid_v4 4
  @uuid_v5 5

  @uuid_variant10 2

  @uuid_namespace_dns "6ba7b8109dad11d180b400c04fd430c8"
  @uuid_namespace_url "6ba7b8119dad11d180b400c04fd430c8"
  @uuid_namespace_oid "6ba7b8129dad11d180b400c04fd430c8"
  @uuid_namespace_x500 "6ba7b8149dad11d180b400c04fd430c8"

  @doc """
  Generate a new UUID based on version 1 (timestamp plus node). The format
  can be specified as :default, :binary, :hex, and :urn.
  See http://en.wikipedia.org/wiki/Universally_unique_identifier.
  """
  def new_uuid_v1(format \\ :default) do
    <<t_hi :: 12, t_mid :: 16, t_lo :: 32>> = uuid_time()
    <<cs_hi :: 6, cs_lo :: 8>> = uuid_random(14)
    <<node ::48>> = uuid_node()
    bin = <<t_lo :: 32, t_mid :: 16, @uuid_v1 :: 4, t_hi :: 12, @uuid_variant10 :: 2, cs_hi :: 6, cs_lo :: 8, node :: 48>>
    format_uuid(bin, format)
  end

  @doc """
  Generate a new UUID based on version 3 (namespace and MD5). Valid types are
  :dns, :url, :oid, :x500, :nil, or another UUID. The format can be
  specified as :default, :binary, :hex, and :urn. See
  http://en.wikipedia.org/wiki/Universally_unique_identifier.
  """
  def new_uuid_v3(type, name, format \\ :default)

  def new_uuid_v3(:dns, <<name :: binary>>, format) do
    bin = uuid_namespace_hash(:md5, <<@uuid_namespace_dns, name :: binary>>)
    format_uuid(bin, format)
  end
  def new_uuid_v3(:url, <<name :: binary>>, format) do
    bin = uuid_namespace_hash(:md5, <<@uuid_namespace_url, name :: binary>>)
    format_uuid(bin, format)
  end
  def new_uuid_v3(:oid, <<name :: binary>>, format) do
    bin = uuid_namespace_hash(:md5, <<@uuid_namespace_oid, name :: binary>>)
    format_uuid(bin, format)
  end
  def new_uuid_v3(:x500, <<name :: binary>>, format) do
    bin = uuid_namespace_hash(:md5, <<@uuid_namespace_x500, name :: binary>>)
    format_uuid(bin, format)
  end
  def new_uuid_v3(:nil, <<name :: binary>>, format) do
    bin = uuid_namespace_hash(:md5, <<0 :: 128, name :: binary>>)
    format_uuid(bin, format)
  end
  def new_uuid_v3(<<uuid :: binary>>, <<name :: binary>>, format) do
    {:ok, uuid_bin, _version, _variant} = parse_uuid(uuid)
    uuid_hex = format_uuid(uuid_bin, :hex)
    new_uuid_bin = uuid_namespace_hash(:md5, <<uuid_hex :: binary, name :: binary>>)
    format_uuid(new_uuid_bin, format)
  end

  @doc """
  Generate a new UUID based on version 4 (strong random number). The format
  can be specified as :default, :binary, :hex, and :urn.
  See http://en.wikipedia.org/wiki/Universally_unique_identifier.
  """
  def new_uuid_v4(format \\ :default) do
    <<p1 :: 48, p2 :: 12>> = uuid_random(60)
    <<p3 :: 32, p4 :: 30>> = uuid_random(62)
    bin = <<p1 :: 48, @uuid_v4 :: 4, p2 :: 12, @uuid_variant10 :: 2, p3 :: 32, p4 :: 30>>
    format_uuid(bin, format)
  end

  @doc """
  Generate a new UUID based on version 5 (namespace and SHA1). Valid types are
  :dns, :url, :oid, :x500, :nil, or another UUID. The format can be
  specified as :default, :binary, :hex, and :urn. See
  http://en.wikipedia.org/wiki/Universally_unique_identifier.
  """
  def new_uuid_v5(type, name, format \\ :default)

  def new_uuid_v5(:dns, <<name :: binary>>, format) do
    bin = uuid_namespace_hash(:sha1, <<@uuid_namespace_dns, name :: binary>>)
    format_uuid(bin, format)
  end
  def new_uuid_v5(:url, <<name :: binary>>, format) do
    bin = uuid_namespace_hash(:sha1, <<@uuid_namespace_url, name :: binary>>)
    format_uuid(bin, format)
  end
  def new_uuid_v5(:oid, <<name :: binary>>, format) do
    bin = uuid_namespace_hash(:sha1, <<@uuid_namespace_oid, name :: binary>>)
    format_uuid(bin, format)
  end
  def new_uuid_v5(:x500, <<name :: binary>>, format) do
    bin = uuid_namespace_hash(:sha1, <<@uuid_namespace_x500, name :: binary>>)
    format_uuid(bin, format)
  end
  def new_uuid_v5(:nil, <<name :: binary>>, format) do
    bin = uuid_namespace_hash(:sha1, <<0 :: 128, name :: binary>>)
    format_uuid(bin, format)
  end
  def new_uuid_v5(<<uuid :: binary>>, <<name :: binary>>, format) do
    {:ok, uuid_bin, _version, _variant} = parse_uuid(uuid)
    uuid_hex = format_uuid(uuid_bin, :hex)
    new_uuid_bin = uuid_namespace_hash(:sha1, <<uuid_hex :: binary, name :: binary>>)
    format_uuid(new_uuid_bin, format)
  end

  @doc """
  Parse a UUID and return the UUID as 128-bit binary, the version, and the variant.
  """
  def parse_uuid(<<u1 :: 64, "-", u2 :: 32, "-", u3 :: 32, "-", u4 :: 32, "-", u5 :: 96>>) do
    hex = <<u1 :: 64, u2 :: 32, u3 :: 32, u4 :: 32, u5 :: 96>>
    {:ok, bin} = Base.decode16(hex, case: :lower)
    parse_uuid(bin)
  end
  def parse_uuid(<<"urn:uuid:", u1 :: 64, "-", u2 :: 32, "-", u3 :: 32, "-", u4 :: 32, "-", u5 :: 96>>) do
    hex = <<u1 :: 64, u2 :: 32, u3 :: 32, u4 :: 32, u5 :: 96>>
    {:ok, bin} = Base.decode16(hex, case: :lower)
    parse_uuid(bin)
  end
  def parse_uuid(<<hex :: 256>>) do
    {:ok, bin} = Base.decode16(<<hex :: 256>>, case: :lower)
    parse_uuid(bin)
  end
  def parse_uuid(<<bin :: 128>>) do
    {:ok, version, variant} = uuid_version_variant(<<bin :: 128>>)
    {:ok, <<bin :: 128>>, version, variant}
  end
  def parse_uuid(_) do
    raise ArgumentError, message: "Invalid UUID"
  end

  # --------------------
  # PRIVATE
  # --------------------

  @time_nanosec_intervals_offset 122192928000000000
  @time_nanosec_intervals_factor 10

  # Get the time as 60-bit-binary.
  defp uuid_time() do
    {mega_secs, secs, micro_secs} = :os.timestamp
    epoch = (mega_secs * 1000000000000 + secs * 1000000 + micro_secs)
    timestamp = @time_nanosec_intervals_offset + @time_nanosec_intervals_factor * epoch
    <<timestamp :: 60>>
  end

  # Generate a random number of the given size.
  defp uuid_random(rnd_size) do
    pid_sum = :erlang.phash2(self())
    <<n0 :: 32, n1 :: 32, n2 :: 32>> = :crypto.rand_bytes(12)
    now_xor_pid = {n0 ^^^ pid_sum, n1 ^^^ pid_sum, n2 ^^^ pid_sum}
    :random.seed(now_xor_pid)
    rnd = :random.uniform(2 <<< rnd_size - 1)
    <<rnd :: size(rnd_size)>>
  end

  # Get MAC address or random fallback.
  defp uuid_node() do
    {:ok, ifcs} = :inet.getifaddrs()
    uuid_node(ifcs)
  end
  defp uuid_node([{"lo", _} | rest]) do
    # Not the loopback interface.
    uuid_node(rest)
  end
  defp uuid_node([{_, if_config} | rest]) do
    case :lists.keyfind(:hwaddr, 1, if_config) do
      {:hwaddr, hw_addr} ->
        :erlang.list_to_binary(hw_addr)
      :false ->
        uuid_node(rest)
    end
  end
  defp uuid_node(_) do
    # Fallback.
    <<rnd_hi :: 7, _ :: 1, rnd_lo :: 40>> = uuid_random(48)
    <<rnd_hi :: 7, 1 :: 1, rnd_lo :: 40>>
  end

  # Calculate namespace hash for a UUID.
  defp uuid_namespace_hash(hash, namespace_name) do
    uuid = fn(version, <<t_lo :: 32, t_mid :: 16, _ :: 4, t_hi :: 12, _ :: 2, cs_hi :: 6, cs_lo :: 8, node :: 48>>) ->
      <<t_lo :: 32, t_mid :: 16, version :: 4, t_hi :: 12, @uuid_variant10 :: 2, cs_hi :: 6, cs_lo :: 8, node :: 48>>
    end
    case hash do
      :md5 ->
        md5 = :crypto.hash(:md5, namespace_name)
        uuid.(@uuid_v3, md5)
      :sha1 ->
        <<sha1 :: 128, _ :: 32>> = :crypto.hash(:sha, namespace_name)
        uuid.(@uuid_v5, <<sha1 :: 128>>)
    end
  end

  # Format a UUID.
  defp format_uuid(uuid_bin, :binary) do
    uuid_bin
  end
  defp format_uuid(uuid_bin, :hex) do
    Base.encode16(uuid_bin, case: :lower)
  end
  defp format_uuid(uuid_bin, :urn) do
    "urn:uuid:" <> format_uuid(uuid_bin, :default)
  end
  defp format_uuid(<<s1 :: 32, s2 :: 16, s3 :: 16, s4 :: 8, s5 :: 8, s6 :: 48>>, _) do
    List.flatten(:io_lib.format("~8.16.0b-~4.16.0b-~4.16.0b-~2.16.0b~2.16.0b-~12.16.0b", [s1, s2, s3, s4, s5, s6])) |> to_string()
  end

  # Return version and variant of a binary UUID.
  defp uuid_version_variant(<<_ :: 48, version :: 4, _ :: 12, variant0 :: 1, variant1 :: 1, variant2 :: 1, _ :: 61>>) do
    variant = case {variant0, variant1, variant2} do
      {1, 1, 1} -> :reserved_future
      {1, 1, _} -> :reserved_microsoft
      {1, 0, _} -> :rfc4122
      _         -> :unknown
    end
    {:ok, version, variant}
  end
  defp uuid_version_variant(_) do
    raise ArgumentError, message: "Invalid UUID"
  end
  
end

# --------------------
# EOF
# --------------------
