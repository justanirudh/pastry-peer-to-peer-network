defmodule RoutingTables do

  defp get_right_values(map, ind, sorted, hex, l, num) do
    if ind == num || (Map.get(map, 0) != nil && Map.get(map, 0) |> Map.keys |> length == l-1)   do
      map
    else
      curr_hex = elem(Enum.at(sorted, ind), 0)
      curr_pid = elem(Enum.at(sorted, ind), 1)

      #get common prefix length
      com_prefix = Utils.lcp([hex, curr_hex]) 
      com_prefix_len = String.length(com_prefix)

      #If map does not have a map corresponding to the common prefix length
      map = if Map.get(map, com_prefix_len) == nil do
        Map.put(map, com_prefix_len, %{})#put empty map
      else
        map
      end
      
      #find first diff b/w the the node whos map is being created (hex) with the node which is 
      #being inspected (curr_hex)
      first_diff = String.at(curr_hex, com_prefix_len)
      if(first_diff == nil) do # reached end
        map
      else
        inside_map = Map.get(map, com_prefix_len)
        
        #if it already consists entry for the first_dif, NOP
        map = if Map.get(inside_map, first_diff) != nil do
          map
        else #add an entry
          Map.put(map, com_prefix_len, Map.put(inside_map, first_diff, {curr_hex,curr_pid }))
        end
  
        get_right_values(map, ind + 1, sorted, hex, l, num)
      end

    end
  end

  defp get_left_values(map, ind, sorted, hex, l, num) do
    if ind == -1  do
      map
    else
        curr_hex = elem(Enum.at(sorted, ind), 0)
        curr_pid = elem(Enum.at(sorted, ind), 1)

        #get common prefix length
        com_prefix = Utils.lcp([hex, curr_hex]) 
        com_prefix_len = String.length(com_prefix)

        if com_prefix_len == 0 && (Map.get(map, 0) != nil && Map.get(map, 0) |> Map.keys |> length == l-1) do
            #if reached values that populates 1st row && 1st row is populated to the fullest
            map
        else
            #If map does not have a map corresponding to the common prefix length
            map = if Map.get(map, com_prefix_len) == nil do
                    Map.put(map, com_prefix_len, %{})#put empty map
                else
                    map
                end
  
            #find first diff b/w the the node whos map is being created (hex) with the node which is 
            #being inspected (curr_hex)
            first_diff = String.at(curr_hex, com_prefix_len)
            if(first_diff == nil) do # reached end
                map
            else
                inside_map = Map.get(map, com_prefix_len)
    
                #if it already consists entry for the first_dif, NOP
                map = if Map.get(inside_map, first_diff) != nil do
                    map
                else #add an entry
                    Map.put(map, com_prefix_len, Map.put(inside_map, first_diff, {curr_hex,curr_pid }))
                end

                get_left_values(map, ind - 1, sorted, hex, l, num)
            end
        end
    end
  end

  defp send_aux(sorted, ind, num, l) do
    if(ind == num) do
      :ok
    else
      map = %{}

      curr_hex = elem(Enum.at(sorted, ind), 0)
      #populate with values > curr_hex
      map = get_right_values(map, ind + 1, sorted, curr_hex, l, num)
      #populate with values < curr_hex
      map = get_left_values(map, ind - 1, sorted, curr_hex, l, num)
      
      curr_pid = elem(Enum.at(sorted, ind), 1)
      :ok = GenServer.call(curr_pid, {:routing_table, map})

      send_aux(sorted, ind + 1, num, l)
    end

  end

  #32 rows (one for each letter) and 16 columns (one for each value each letter can take)
  # .... <- . -> .....
  def send(nodes, node_hexes, num, l) do
    zipped = Enum.zip([node_hexes, nodes]) #numerical value, hex value, node id
    sorted = Enum.sort(zipped, fn(i,j) -> elem(i, 0) < elem(j,0) end)
    #IO.inspect sorted
    send_aux(sorted, 0, num, l)  
  end

    
end