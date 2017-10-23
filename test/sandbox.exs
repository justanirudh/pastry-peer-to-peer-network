#msg routing algorithm
def handle_cast({:msg, key, val, num_hops}, map) do
  curr_nodeid = Map.get(map, :nodeid)
  # IO.puts "msg reached #{curr_nodeid}" 
  key_int = elem(Integer.parse(key, 16), 0)
  leaf_set =  Map.get(map, :leaf_set)
  leaf_set_size = length(leaf_set)
  leaf_set_min = elem(Enum.at(leaf_set, 0), 0)
  leaf_set_max = elem(Enum.at(leaf_set, leaf_set_size - 1), 0)
  status = if key_int >= leaf_set_min && key_int <= leaf_set_max do
      #TODO: compare between ((msg - curr_node) and min(msg - leaf_set)). if former, GAMEOVER, else forward
      #GAME OVER (for now. change in TODO)
      # IO.puts "in leaf_set table of #{curr_nodeid}"
      #setting first guy as solution
      dist_pid = elem(Enum.at(leaf_set, 0), 2) 
      min_diff = abs(leaf_set_min - key_int)
      #finding actual guy
      dist_pid = RoutingUtils.get_min_dist(leaf_set, key_int, 1, dist_pid, min_diff, leaf_set_size)
      # GenServer.cast dist_pid, {:msg, key, val, num_hops + 1} #can lead to infinite loops
      GenServer.cast dist_pid, {:stop, key, val, num_hops + 1}
      :sent
  else
      com_prefix_len = Utils.lcp([key, curr_nodeid]) |> String.length
      routing_table =  Map.get(map, :routing_table)
      internal_map = Map.get(routing_table, com_prefix_len)
      if(internal_map != nil) do
          first_diff = String.at(key, com_prefix_len)
          internal_tup = Map.get(internal_map, first_diff)
          if internal_tup != nil do
              # IO.puts "in routing table of #{curr_nodeid}"
              dist_pid = elem(internal_tup, 1)
              GenServer.cast dist_pid, {:msg, key, val, num_hops + 1}
          else
              RoutingUtils.is_send(map, key, key_int, com_prefix_len,val, num_hops)
          end
      else
          RoutingUtils.is_send(map, key, key_int, com_prefix_len,val, num_hops)
      end
  end

  if status == :current do
      #TODO: save key, val in current node
      # IO.puts "terminal nodeid is #{elem(map, 0)}"
      send :master, {:num_hops, num_hops}
  end
  {:noreply, map}
end