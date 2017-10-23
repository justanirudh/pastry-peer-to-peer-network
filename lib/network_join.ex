defmodule NetworkJoin do
 
    def add_node(nodes, num) do
        hex = :crypto.hash(:md5, Integer.to_string(num)) |> Base.encode16()
        {:ok, pid} = elem(GenServer.start_link(PastryNode, %{:nodeid => hex, :leaf_set => nil, :routing_table => nil, :neigh_set => nil}), 1)
        GenServer.cast pid, {:join, nodes}
    end

end