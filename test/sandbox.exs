defmodule RC do
    def lcp([]), do: ""
    def lcp(strs) do
      min = Enum.min(strs)
      max = Enum.max(strs)
      index = Enum.find_index(0..String.length(min), fn i -> String.at(min,i) != String.at(max,i) end)
      if index, do: String.slice(min, 0, index), else: min
    end
  end
   
  data = [
    ["interspecies","interstellar","interstate"],
    ["throne","throne"],
    ["throne","dungeon"],
    ["throne","","throne"],
    ["cheese"],
    [""],
    [],
    ["prefix","suffix"],
    ["foo","foobar"]
  ]
   
  Enum.each(data, fn strs ->
    IO.puts "lcp(#{inspect strs}) = #{inspect RC.lcp(strs)}"
  end)
  
