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

  %{0 => %{"1" => {"1FF1DE774005F8DA13F42943881C655F", 1},
  "3" => {"3295C76ACBF4CAAED33C36B1B5FC2CB1", 1},
  "F" => {"F033AB37C30201F73F142449D037028D", 1}},
1 => %{"6" => {"26657D5FF9020D2ABEFE558796B99584", 1},
  "A" => {"2A38A4A9316C49E5A833517C45D31070", 1}},
2 => %{"D" => {"28DD2C7955CE926456240B2FF0100BDE", 1}},
32 => %{}
}
  
