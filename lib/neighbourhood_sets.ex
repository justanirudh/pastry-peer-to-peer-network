defmodule NeighbourhoodSets do
    
    defp send_aux(sorted, ind, num, m) do
        if(ind == num) do
          :ok
        else
          # num_start = ind + 1
          # num_end = num_start + div(l,2) - 1
          # list_right = Enum.slice(sorted, num_start..num_end)
          num_start = ind + 1
          amt = div(m,2)
          list_right = Enum.slice(sorted, num_start, amt)
          
          # num_start = ind - div(l,2)
          # num_end = ind - 1
          # list_left = Enum.slice(sorted, num_start..num_end)
          num_start =
            if ind - div(m,2) < 0 do
              0
            else
              ind - div(m,2)
            end
          amt = div(m,2)
          list_left = Enum.slice(sorted, num_start, amt)
          
          combined = list_left ++ list_right
          
          curr = elem(Enum.at(sorted, ind), 2)
          :ok = GenServer.call(curr, {:neigh_set, combined}, :infinity)
    
          send_aux(sorted, ind + 1, num, m)
        end
      end
    
      def send(nodes, m, num, node_hexes) do
        #nodes is a list of pids
        #node_hexes is a list of nodeIds
        #1..num to simulate proximity/neighbourhood
        zipped = Enum.zip([1..num, node_hexes, nodes]) #numerical value, hex value, node id
        :ok = send_aux(zipped, 0, num, m)
      end

end