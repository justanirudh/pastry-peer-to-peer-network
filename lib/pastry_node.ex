defmodule PastryNode do
    use GenServer
    @b 4
    @l 16
    @m 32
    #state manual_pastry: nodeid, leaf_set, routing_table, neighbourhoodset
    #map bootstrap pastry: %{:nodeid => hex, :proxid => num,  :leaf_set => nil, :routing_table => nil, :neigh_set => nil}
    
    #leaf_set needs to remain sorted, neighbourhood set might not remain sorted

    #AddNode functions call
    #------------------------------------------------------------


    #------------------------------------------------------------
    #All these will go

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
    
    #start the process of joining to pastry network
    def handle_cast({:join, nodes}, map) do
        rec_pid = Enum.random nodes
        curr = self()
        nodeid = Map.get(map, :nodeid)
        GenServer.cast rec_pid, {:add_node, nodeid, curr, 0} # 0 is num_hops till now
        {:noreply, map}
    end


    def handle_cast({:add_me, sender_nodeid, sender_pid}, map) do
        #add in leafset
        leaf_set = Map.get(map, :leaf_set)
        sender_nodeid_int = Integer.parse(sender_nodeid, 16) |> elem(0)
        leaf_set = RoutingUtils.add_in_leaf_set(leaf_set, @l, sender_nodeid_int, sender_nodeid, sender_pid)
        map = Map.put(map, :leaf_set, leaf_set)
        #add in routing table

        #add in neighset
        
        {:noreply, map}
    end

    #propgate yourself to all nodes in state
    def handle_cast(:propagate, map) do
        curr_pid = self()
        if(Map.get(map, :leaf_set) != [] && Map.get(map, :neigh_set) != []) do
            all_nodes = RoutingUtils.get_union_all(map)
            hex = Map.get(map, :nodeid)
            Enum.each(all_nodes, fn {_, pid} -> GenServer.cast pid, {:add_me, hex, curr_pid}  end)
        else
            IO.puts "Either leaf set or neighbourhood set are not populated. Waiting for them..."
            :timer.sleep(1000)
            GenServer.cast curr_pid, :propagate
        end
    end

    #received neighbourhood set
    def handle_cast({:neigh_set, neigh_set, {sender_proxid, sender_nodeid, sender_pid}}, map) do
        #Does not matter. at worst, the set will have random elements
        neigh_set_len = length(neigh_set)
        if(neigh_set_len < @m) do
            #insert {sender_proxid, sender_nodeid, sender_pid} in neigh_set sortedly
            neigh_set = RoutingUtils.insert_sortedly(neigh_set, {sender_proxid, sender_nodeid, sender_pid}, neigh_set_len)
        else
            neigh_set_min = elem(Enum.at(neigh_set, 0), 0)
            neigh_set_max = elem(Enum.at(neigh_set, neigh_set_len - 1), 0)
            if sender_proxid > neigh_set_min && sender_proxid < neigh_set_max do
                #insert and delete from edge
                neigh_set = RoutingUtils.insert_sortedly(neigh_set, {sender_proxid, sender_nodeid, sender_pid}, neigh_set_len)
                neigh_set = List.delete_at(neigh_set, neigh_set_len)
            end    
        end
        {:noreply, Map.put(map, :neigh_set, neigh_set)}
    end

    #received leaf set
    def handle_cast({:leaf_set, leaf_set, {sender_nodeid_int, sender_nodeid, sender_pid}}, map) do
        #receiver's leaf_set is empty
        leaf_set = RoutingUtils.add_in_leaf_set(leaf_set, @l, sender_nodeid_int, sender_nodeid, sender_pid)
        {:noreply, Map.put(map, :leaf_set, leaf_set)}
    end

    #received routing table
    def handle_cast({:routing_table, routing_row, row_num, sender_nodeid, sender_pid, is_last}, map) do
        #1. add sender's info to routing table, will go in the row that just got added
        com_prefix_len = Utils.lcp([Map.get(map, :nodeid), sender_nodeid]) |> String.length
        first_diff = String.at(sender_nodeid, com_prefix_len)
        routing_row = Map.put(routing_row, first_diff, {sender_nodeid, sender_pid})
        #2. add row to routing table
        routing_table = Map.get(map, :routing_table)
        routing_table = Map.put(routing_table, row_num, routing_row)
        map = Map.put(map, :routing_table, routing_table)
        curr_pid = self()
        if is_last == :last do
            GenServer.cast curr_pid, :propagate
        end
        {:noreply, map}
    end

    #ROUTING
    #stop and send leaf_set and routing table
    def handle_cast({:stop_nodeid, new_nodeid, new_pid, num_hops}, map) do
        curr_pid = self()
        curr_nodeid = Map.get(map, :nodeid)
        nodeid_int = Integer.parse(curr_nodeid, 16) |> elem(0)
        leaf_set = Map.get(map, :leaf_set)
        #send leaf_set
        GenServer.cast new_pid, {:leaf_set, leaf_set, {nodeid_int, curr_nodeid, curr_pid}}
        #send routing table
        routing_row = Map.get(map, :routing_table) |> Map.get(num_hops)
        GenServer.cast  new_pid,  {:routing_table, routing_row, num_hops, curr_nodeid, curr_pid, :last}
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
        leaf_set =  Map.get(map, :leaf_set)
        leaf_set_size = length(leaf_set)
        leaf_set_min = elem(Enum.at(leaf_set, 0), 0)
        leaf_set_max = elem(Enum.at(leaf_set, leaf_set_size - 1), 0)
        status = if new_nodeid_int >= leaf_set_min && new_nodeid_int <= leaf_set_max do
            dist_pid = elem(Enum.at(leaf_set, 0), 2) 
            min_diff = abs(leaf_set_min - new_nodeid_int)
            dist_pid = RoutingUtils.get_min_dist(leaf_set, new_nodeid_int, 1, dist_pid, min_diff, leaf_set_size)
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
                    #send routing table to new node
                    routing_row = Map.get(routing_table, num_hops)
                    GenServer.cast new_pid, {:routing_table, routing_row, num_hops, curr_nodeid, curr_pid, :not_last}
                    #forward the nodeid to next node
                    GenServer.cast dist_pid, {:add_node, new_nodeid, new_pid, num_hops + 1}
                else
                    RoutingUtils.is_nodeid_send(map, new_nodeid, new_nodeid_int, com_prefix_len,num_hops, new_pid, curr_nodeid, curr_pid )
                end
            else
                RoutingUtils.is_nodeid_send(map, new_nodeid, new_nodeid_int, com_prefix_len,num_hops, new_pid, curr_nodeid, curr_pid )
            end
        end

        if status == :current do
            #sending to self to send leaf_set and routing table to new node
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

end