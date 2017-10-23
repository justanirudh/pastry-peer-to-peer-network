defmodule NetworkJoin do
 
    def add_node(nodes, num) do
        hex = :crypto.hash(:md5, Integer.to_string(num + 5)) |> Base.encode16()
        IO.puts "new node id hex: #{hex}"
        {:ok, pid} = GenServer.start_link(PastryNode, %{:nodeid => hex, :proxid => num, :leaf_set => [], :routing_table => %{}, :neigh_set => []})
        GenServer.cast pid, {:join, nodes}
        receive do
            :node_added -> :ok
        end
        pid
    end

end