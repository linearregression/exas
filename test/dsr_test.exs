# --------------------
# Tideland Elixir Application Support - DSR - Tests
# Copyright (C) 2014-2015 Frank Mueller / Tideland / Oldenburg / Germany
# --------------------

defmodule EXAS.DSRTest do
  use ExUnit.Case, async: true

  test "only one simple retriever" do
    EXAS.DSR.start_link

		EXAS.DSR.register(:abc, &abc_retriever/0)
  
  	states = EXAS.DSR.retrieve
  	
  	assert length(states) == 1
  	assert hd(states) == {:abc, {:ok, {:a, :b, :c}}}
  
  	EXAS.DSR.stop
  end

  test "only retriever multiple times" do
    EXAS.DSR.start_link

		EXAS.DSR.register(:abc, &abc_retriever/0)
  
	  EXAS.DSR.retrieve
  	EXAS.DSR.retrieve
  	states = EXAS.DSR.retrieve
  	
  	assert length(states) == 1
  	assert hd(states) == {:abc, {:ok, {:a, :b, :c}}}
  
  	EXAS.DSR.stop
  end

  test "only one failing retriever" do
    EXAS.DSR.start_link

		EXAS.DSR.register(:fail, &fail_retriever/0)
  
  	states = EXAS.DSR.retrieve
  	
  	assert length(states) == 1
  	assert hd(states) == {:fail, {:error, :badarith}}
  
  	EXAS.DSR.stop
  end

  test "some mixed retrievers" do
    EXAS.DSR.start_link

		EXAS.DSR.register(:abc_a, &abc_retriever/0)
		EXAS.DSR.register(:abc_b, &abc_retriever/0)
		EXAS.DSR.register(:fail, &fail_retriever/0)
  	EXAS.DSR.register(:abc_c, &abc_retriever/0)
  
  	states = EXAS.DSR.retrieve
  	counters = Enum.reduce(states, {0, 0}, fn
  		({_, {:ok, _}},    {oks, errors}) -> {oks + 1, errors}
  		({_, {:error, _}}, {oks, errors}) -> {oks, errors + 1}
  	end)
  	
  	assert length(states) == 4
  	assert counters == {3, 1}
  	
  	EXAS.DSR.stop
  end

  test "some mixed retrievers filtered" do
    EXAS.DSR.start_link

		EXAS.DSR.register(:abc_a, &abc_retriever/0)
		EXAS.DSR.register(:abc_b, &abc_retriever/0)
		EXAS.DSR.register(:fail, &fail_retriever/0)
  	EXAS.DSR.register(:abc_c, &abc_retriever/0)
  
  	states = EXAS.DSR.retrieve(fn {_, {exec_rc, _}} -> exec_rc == :ok end)
  	
  	assert length(states) == 3
  	
  	EXAS.DSR.stop
  end

  test "ping the DSR" do
    EXAS.DSR.start_link

		assert {:ok, {pid, _}} = EXAS.Ping.ping(EXAS.DSR)
		assert Process.whereis(EXAS.DSR) == pid

  	EXAS.DSR.stop
  end

  # --------------------
  # HELPER
  # --------------------

	defp abc_retriever do
		{:a, :b, :c}
	end

	defp fail_retriever do
		1/0
	end

end

# --------------------
# EOF
# --------------------
