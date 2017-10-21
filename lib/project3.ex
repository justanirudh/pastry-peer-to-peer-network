defmodule Pastry do


  defp spawn_pastry(num) do
    1..num |> Enum.map(fn i -> elem(GenServer.start_link(PastryNode, :crypto.hash(:md5, Integer.to_string(i)) |> Base.encode16()), 1) end) 
  end


  defp send_leafsets_aux(sorted, ind, num, l) do
    if(ind == num) do
      :ok
    else
      #TODO: implement wraparound
      num_start = ind + 1
      num_end = num_start + div(l,2) - 1
      list_right = Enum.slice(sorted, num_start..num_end)
      
      num_start = ind - div(l,2)
      num_end = ind - 1
      list_left = Enum.slice(sorted, num_start..num_end)
      
      combined = list_left ++ list_right
      
      curr = elem(Enum.at(sorted, ind), 2)
      :ok = GenServer.call(curr, {:leafset, combined})

      send_leafsets_aux(sorted, ind + 1, num, l)
    end
  end

  defp send_leafsets(nodes, l, num, node_hexes) do
    #nodes is a list of pids
    #node_hexes is a list of nodeIds
    #node_ints is a list of nodeIds in int form
    node_ints = Enum.map( node_hexes, fn i -> elem(Integer.parse(i, 16),0) end)
    zipped = Enum.zip([node_ints, node_hexes, nodes]) #numerical value, hex value, node id
    sorted = Enum.sort(zipped, fn(i,j) -> elem(i, 0) < elem(j,0) end)
    :ok = send_leafsets_aux(sorted, 0, num, l)
  end

  defp get_right_values(map, ind, sorted, hex, l, num) do
    if ind == num do
      map
    else
      curr_hex = elem(Enum.at(sorted, ind), 0)
      com_prefix = Utils.lcp([hex, curr_hex])
      com_prefix_len = String.length(com_prefix) # TODO: if got 1 39, dont add any more 39s
      map = if Map.get(map, com_prefix_len) == nil do
        Map.put(map, com_prefix_len, [curr_hex])#TODO: also put pids in map
      else
        Map.put(map, com_prefix_len, Map.get(map, com_prefix_len) ++ [curr_hex])
      end
      first_row = Map.get(map, 0)
      if(first_row == nil) do
        get_right_values(map, ind + 1, sorted, hex, l, num)  
      else
        len = length first_row
        if len == l - 1 do
          map
        else
          get_right_values(map, ind + 1, sorted, hex, l, num)  
        end
      end
    end
  end

  defp send_routing_tables_aux(sorted, ind, num, l) do
    if(ind == num) do
      :ok
    else
      map = %{}

      curr_hex = elem(Enum.at(sorted, ind), 0)
      map = get_right_values(map, ind + 1, sorted, curr_hex, l, num)
      # map = get_left_values(map, ind - 1, sorted)
      
      curr_pid = elem(Enum.at(sorted, ind), 1)
      :ok = GenServer.call(curr_pid, {:routing_table, map})

      send_routing_tables_aux(sorted, ind + 1, num, l)
    end

  end

  defp send_routing_tables(nodes, node_hexes, num, l) do
    zipped = Enum.zip([node_hexes, nodes]) #numerical value, hex value, node id
    sorted = Enum.sort(zipped, fn(i,j) -> elem(i, 0) < elem(j,0) end)
    send_routing_tables_aux(sorted, 0, num, l) 
    
  end

  def main(args) do
    num = 1000
    l = 16 # 2^b in leafset, 8 nodeids less than and 8 nodeids greater than; in outing table, each row has max 15 cols
    self() |> Process.register(:master) #register master
    #list of all pids
    nodes = spawn_pastry(num)
    node_hexes = 1..num |> Enum.map(fn i -> (:crypto.hash(:md5, Integer.to_string(i)) |> Base.encode16()) end)
    #send entire list to all nodes to construct leaf set and routing table 
    #TODO: need to change this after implementing the 'join' functionality
    send_leafsets(nodes, l, num, node_hexes)
    send_routing_tables(nodes, node_hexes, num ,l)

    # Enum.each(nodes, fn(pid) -> GenServer.call(pid, {:all_nodes, nodes, num})  end)
    IO.inspect GenServer.call(Enum.at(nodes, 100), :show)

  end

end
