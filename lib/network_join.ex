defmodule NetworkJoin do
 
    def add_node(nodes, num) do
        hex = :crypto.hash(:md5, Integer.to_string(num)) |> Base.encode16()
        {:ok, pid} = elem(GenServer.start_link(PastryNode, %{:nodeid => hex, :proxid => num, :leaf_set => [], :routing_table => %{}, :neigh_set => []}), 1)
        GenServer.cast pid, {:join, nodes}
    end

end