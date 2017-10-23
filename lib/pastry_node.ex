defmodule PastryNode do
    use GenServer
    @b 4
    @l 16
    @m 32
    #state manual_pastry: nodeid, leafset, routing_table, neighbourhoodset
    #map bootstrap pastry: %{:nodeid => hex, :proxid => num,  :leaf_set => nil, :routing_table => nil, :neigh_set => nil}
    
    #Leafset needs to remain sorted, neighbourhood set might noe remain sorted

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


    def handle_cast({:neigh_set, neigh_set, {sender_proxid, sender_nodeid, sender_pid}}, map) do
        
    end

    def handle_cast({:leaf_set, leaf_set, {nodeid_int, sender_nodeid, sender_pid}}, map) do
        
    end

    def handle_cast({:routing_table, routing_row, row_num}, map) do
        
    end

    def handle_cast({:stop_nodeid, new_nodeid, new_pid, num_hops}, map) do
        curr_pid = self()
        curr_nodeid = Map.get(map, :nodeid)
        nodeid_int = Integer.parse(curr_nodeid, 16) |> elem(0)
        leaf_set = Map.get(map, :leaf_set)
        send new_pid, {:leaf_set, leaf_set, {nodeid_int, curr_nodeid, curr_pid}}
        #num_hops will be required to find out which row of routing table to send
        {:noreply, map}
    end

    #TODO: When changing routing algo, change both algos: for routing msgs and routing nodeids
    #nodeid routing algorithm
    def handle_cast({:add_node, new_nodeid, new_pid, num_hops}, map) do
        curr_nodeid = Map.get(map, :nodeid)
        curr_proxid = Map.get(map, :proxid)
        curr_pid = self()
        if num_hops == 0 do #curr ndoe is first used by new node to enter pastry
            # send neigh set to new_pid    
            neigh_set = Map.get(map, :neigh_set)
            GenServer.cast new_pid, {:neigh_set, neigh_set, {curr_proxid, curr_nodeid, curr_pid}}
        end
        new_nodeid_int = elem(Integer.parse(new_nodeid, 16), 0)
        leafset =  Map.get(map, :leaf_set)
        leafset_size = length(leafset)
        leafset_min = elem(Enum.at(leafset, 0), 0)
        leafset_max = elem(Enum.at(leafset, leafset_size - 1), 0)
        status = if new_nodeid_int >= leafset_min && new_nodeid_int <= leafset_max do
            dist_pid = elem(Enum.at(leafset, 0), 2) 
            min_diff = abs(leafset_min - new_nodeid_int)
            dist_pid = RoutingUtils.get_min_dist(leafset, new_nodeid_int, 1, dist_pid, min_diff, leafset_size)
            GenServer.cast dist_pid, {:stop_nodeid, new_nodeid, new_pid, num_hops + 1}
            :sent
        else
            com_prefix_len = Utils.lcp([new_nodeid, curr_nodeid]) |> String.length
            routing_table =  Map.get(map, :routing_table)
            internal_map = Map.get(routing_table, com_prefix_len)
            if(internal_map != nil) do
                first_diff = String.at(new_nodeid, com_prefix_len)
                internal_tup = Map.get(internal_map, first_diff)
                if internal_tup != nil do
                    dist_pid = elem(internal_tup, 1)
                    GenServer.cast dist_pid, {:add_node, new_nodeid, new_pid, num_hops + 1}
                else
                    RoutingUtils.is_nodeid_send(map, new_nodeid, new_nodeid_int, com_prefix_len,num_hops, new_pid)
                end
            else
                RoutingUtils.is_nodeid_send(map, new_nodeid, new_nodeid_int, com_prefix_len,num_hops, new_pid)
            end
        end

        if status == :current do
            #sending to self to send leafset to new node
            GenServer.cast curr_pid, {:stop_nodeid, new_nodeid, new_pid, num_hops}
        end
        {:noreply, map}
    end


    #----------------------------------------------------------------------------

    def handle_cast({:stop, key, val, num_hops}, map) do
        #TODO: save key, val in current node, if needed
        # IO.puts "terminal nodeid is #{elem(map, 0)}"
        send :master, {:num_hops, num_hops}
        {:noreply, map}
    end

    #msg routing algorithm
    def handle_cast({:msg, key, val, num_hops}, map) do
        curr_nodeid = Map.get(map, :nodeid)
        # IO.puts "msg reached #{curr_nodeid}" 
        key_int = elem(Integer.parse(key, 16), 0)
        leafset =  Map.get(map, :leaf_set)
        leafset_size = length(leafset)
        leafset_min = elem(Enum.at(leafset, 0), 0)
        leafset_max = elem(Enum.at(leafset, leafset_size - 1), 0)
        status = if key_int >= leafset_min && key_int <= leafset_max do
            #TODO: compare between ((msg - curr_node) and min(msg - leafset)). if former, GAMEOVER, else forward
            #GAME OVER (for now. change in TODO)
            # IO.puts "in leafset table of #{curr_nodeid}"
            #setting first guy as solution
            dist_pid = elem(Enum.at(leafset, 0), 2) 
            min_diff = abs(leafset_min - key_int)
            #finding actual guy
            dist_pid = RoutingUtils.get_min_dist(leafset, key_int, 1, dist_pid, min_diff, leafset_size)
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

end