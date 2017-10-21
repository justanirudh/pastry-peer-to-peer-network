defmodule LeafSets do
    
    defp send_aux(sorted, ind, num, l) do
        if(ind == num) do
          :ok
        else
          #TODO: implement wraparound for edge values
          num_start = ind + 1
          num_end = num_start + div(l,2) - 1
          list_right = Enum.slice(sorted, num_start..num_end)
          
          num_start = ind - div(l,2)
          num_end = ind - 1
          list_left = Enum.slice(sorted, num_start..num_end)
          
          combined = list_left ++ list_right
          
          curr = elem(Enum.at(sorted, ind), 2)
          :ok = GenServer.call(curr, {:leafset, combined})
    
          send_aux(sorted, ind + 1, num, l)
        end
      end
    
      def send(nodes, l, num, node_hexes) do
        #nodes is a list of pids
        #node_hexes is a list of nodeIds
        #node_ints is a list of nodeIds in int form
        node_ints = Enum.map( node_hexes, fn i -> elem(Integer.parse(i, 16),0) end)
        zipped = Enum.zip([node_ints, node_hexes, nodes]) #numerical value, hex value, node id
        sorted = Enum.sort(zipped, fn(i,j) -> elem(i, 0) < elem(j,0) end)
        :ok = send_aux(sorted, 0, num, l)
      end

end