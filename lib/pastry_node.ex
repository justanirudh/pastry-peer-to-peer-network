defmodule PastryNode do
    use GenServer
    #map manual_pastry: nodeid, leafset, routing_table, neighbourhoodset
    #map bootstrap pastry: %{:nodeid => hex, :leaf_set => nil, :routing_table => nil, :neigh_set => nil}
    #b = 4, L = 16, M = 32
    #TODO: change usage of set to usage of map

    #AddNode functions call
    #------------------------------------------------------------


    #------------------------------------------------------------
    
    #add leaf set
    def handle_call({:leaf_set, leaf_set}, _from, map) do
        {:reply, :ok,  Map.put(map, :leaf_set, leaf_set)} 
    end

    #add routing table
    def handle_call({:routing_table, routing_table}, _from, map) do
        {:reply, :ok,  Map.put(map, :routing_table, routing_table)} 
    end

    #add neighset set
    def handle_call({:neigh_set, neigh_set}, _from, map) do
        {:reply, :ok, Map.put(map, :neigh_set, neigh_set) } 
    end

    #show
    def handle_call(:show, _from, st) do
        {:reply, st, st} 
    end

    #activate to send messages to other peers
    def handle_call({:activate, nodes, num_reqs}, _from, st) do
        {:ok, _} = Task.start_link fn -> RoutingUtils.send_messages(nodes, num_reqs, 0) end
        {:reply, :ok, st} 
    end


    #Add node functions cast
    #----------------------------------------------------------------------------
    
    def handle_cast({:join, nodes}, map) do
        rec_pid = Enum.random nodes
        curr = self()
        nodeid = Map.get(map, :nodeid)
        GenServer.cast rec_pid, {:add_node, nodeid, curr, 0} # 0 is num_hops till now
        {:noreply, map}
    end


    def handle_cast({:neigh_set, neigh_set}, map) do
        
    end

    def handle_cast({:leaf_set, leaf_set}, map) do
        
    end

    def handle_cast({:routing_table, routing_table}, map) do
        
    end

    #----------------------------------------------------------------------------

    def handle_cast({:stop, key, val, num_hops}, map) do
        #TODO: save key, val in current node
        # IO.puts "terminal nodeid is #{elem(map, 0)}"
        send :master, {:num_hops, num_hops}
        {:noreply, map}
    end

    #msg routing algorithm
    def handle_cast({:msg, key, val, num_hops}, map) do
        curr_hex = Map.get(map, :nodeid)
        # IO.puts "msg reached #{curr_hex}" 
        key_int = elem(Integer.parse(key, 16), 0)
        leafset =  Map.get(map, :leaf_set)
        leafset_size = length(leafset)
        leafset_min = elem(Enum.at(leafset, 0), 0)
        leafset_max = elem(Enum.at(leafset, leafset_size - 1), 0)
        status = if key_int >= leafset_min && key_int <= leafset_max do
            #TODO: compare between ((msg - curr_node) and min(msg - leafset)). if former, GAMEOVER, else forward
            #GAME OVER (for now. change in TODO)
            # IO.puts "in leafset table of #{curr_hex}"
            #setting first guy as solution
            dist_pid = elem(Enum.at(leafset, 0), 2) 
            min_diff = abs(leafset_min - key_int)
            #finding actual guy
            dist_pid = RoutingUtils.get_min_dist(leafset, key_int, 1, dist_pid, min_diff, leafset_size)
            # GenServer.cast dist_pid, {:msg, key, val, num_hops + 1} #can lead to infinite loops
            GenServer.cast dist_pid, {:stop, key, val, num_hops + 1}
            :sent
        else
            com_prefix_len = Utils.lcp([key, curr_hex]) |> String.length
            routing_table =  Map.get(map, :routing_table)
            internal_map = Map.get(routing_table, com_prefix_len)
            if(internal_map != nil) do
                first_diff = String.at(key, com_prefix_len)
                internal_tup = Map.get(internal_map, first_diff)
                if internal_tup != nil do
                    # IO.puts "in routing table of #{curr_hex}"
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

end