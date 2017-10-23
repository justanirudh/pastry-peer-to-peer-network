defmodule PastryNode do
    use GenServer
    @b 4
    @l 16
    @m 3
    @max 3.402823669209385e38
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

    # propagation, addme to your states
    def handle_cast({:add_me, sender_nodeid, sender_pid, proxid}, map) do
        if sender_nodeid != Map.get(map, :nodeid) do
            #add in leafset
            leaf_set = Map.get(map, :leaf_set)
            sender_nodeid_int = Integer.parse(sender_nodeid, 16) |> elem(0)
            leaf_set = RoutingUtils.add_in_leaf_set(leaf_set, @l, sender_nodeid_int, sender_nodeid, sender_pid)
            map = Map.put(map, :leaf_set, leaf_set)
            #add in routing table
            curr_nodeid = Map.get(map, :nodeid)
            row_num = Utils.lcp([curr_nodeid, sender_nodeid]) |> String.length
            first_diff = String.at(sender_nodeid, row_num)
            routing_table = Map.get(map, :routing_table)
            routing_row = Map.get(routing_table, row_num)
            if routing_row == nil do
            routing_table = Map.put(routing_table, row_num, %{})
            routing_row = Map.get(routing_table, row_num)
            end
            routing_row = Map.put(routing_row, first_diff, {sender_nodeid, sender_pid})
            map = Map.put(map, row_num, routing_row)
            #add in neighset
            neigh_set = Map.get(map, :neigh_set)
            neigh_set = RoutingUtils.add_in_leaf_set(neigh_set, @l, proxid, sender_nodeid, sender_pid)
            map = Map.put(map, :neigh_set, neigh_set)
            send sender_pid, :added
        end
        
        {:noreply, map}
    end

    def handle_info(:added, map) do
        num_added = Map.get(map, :all_nodes_added)
        num_added = num_added - 1
        if num_added == 0 do
            send :master, :node_added
        end
        {:noreply, Map.put(map, :all_nodes_added, num_added)}
    end

    #propagate yourself to all nodes in state
    def handle_cast(:propagate, map) do
        curr_pid = self()
        if(Map.get(map, :leaf_set) != [] && Map.get(map, :neigh_set) != []) do
            all_nodes = RoutingUtils.get_union_all(map)
            hex = Map.get(map, :nodeid)
            proxid = Map.get(map, :proxid)
            Enum.each(all_nodes, fn {_, pid} -> GenServer.cast pid, {:add_me, hex, curr_pid, proxid}  end)
            {:noreply, Map.put(map, :all_nodes_added, length(all_nodes))}
        else
            IO.puts "Either leaf set or neighbourhood set are not populated. Waiting for them..."
            :timer.sleep(1000)
            GenServer.cast curr_pid, :propagate
            {:noreply, map}
        end
        
    end

    #received neighbourhood set: from first node to new node
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

    #received leaf set: from terminal node to new node
    def handle_cast({:leaf_set, leaf_set, {sender_nodeid_int, sender_nodeid, sender_pid}}, map) do
        #receiver's leaf_set is empty
        leaf_set = RoutingUtils.add_in_leaf_set(leaf_set, @l, sender_nodeid_int, sender_nodeid, sender_pid)
        #just to be safe
        curr_pid = self()
        curr_nodeid = Map.get(map, :nodeid)
        curr_nodeid_int = Integer.parse(curr_nodeid, 16) |> elem(0)
        leaf_set = List.delete(leaf_set, {curr_nodeid_int , curr_nodeid, curr_pid})
        {:noreply, Map.put(map, :leaf_set, leaf_set)}
    end

    #received routing table:from nodes in path to new node
    def handle_cast({:routing_table, routing_row, row_num, sender_nodeid, sender_pid, is_last}, map) do
        #1. add sender's info to routing table, will go in the row that just got added
        curr_hex = Map.get(map, :nodeid)
        com_prefix_len = Utils.lcp([curr_hex, sender_nodeid]) |> String.length
        first_diff = String.at(sender_nodeid, com_prefix_len)
        if routing_row == nil do
            routing_row = %{}
        end
        routing_row = Map.put(routing_row, first_diff, {sender_nodeid, sender_pid})
        #2. add row to routing table
        #TODO: this check should not be required
        routing_row = RoutingUtils.verify_row(routing_row, row_num, curr_hex)
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
        IO.puts "Num_hops (stop node): #{Integer.to_string(num_hops)}"
        curr_pid = self()
        curr_nodeid = Map.get(map, :nodeid)
        nodeid_int = Integer.parse(curr_nodeid, 16) |> elem(0)
        leaf_set = Map.get(map, :leaf_set)
        #send leaf_set
        IO.puts "leafset of #{curr_nodeid}"
        IO.inspect leaf_set
        GenServer.cast new_pid, {:leaf_set, leaf_set, {nodeid_int, curr_nodeid, curr_pid}}
        #send routing table
        com_prefix_len = Utils.lcp([new_nodeid, curr_nodeid]) |> String.length
        routing_row = Map.get(map, :routing_table) |> Map.get(com_prefix_len)
        if routing_row == nil do
            routing_row = %{}
        end
        IO.inspect "routing table of #{curr_nodeid}"
        IO.inspect Map.get(map, :routing_table)
        IO.inspect "routing row:"
        IO.inspect routing_row
        GenServer.cast  new_pid,  {:routing_table, routing_row, num_hops, curr_nodeid, curr_pid, :last}
        {:noreply, map}
    end

    #TODO: When changing routing algo, change both algos: for routing msgs and routing nodeids
    #nodeid routing algorithm
    def handle_cast({:add_node, new_nodeid, new_pid, num_hops}, map) do
        # IO.puts "Num_hops (add_node): #{Integer.to_string(num_hops)}"
        curr_nodeid = Map.get(map, :nodeid)
        IO.puts "path: #{curr_nodeid}"
        curr_proxid = Map.get(map, :proxid)
        routing_table =  Map.get(map, :routing_table)
        curr_pid = self()
        if num_hops == 0 do #curr ndoe is first used by new node to enter pastry
            # send neigh set to new_pid    
            neigh_set = Map.get(map, :neigh_set)
            GenServer.cast new_pid, {:neigh_set, neigh_set, {curr_proxid, curr_nodeid, curr_pid}}
        end
        new_nodeid_int = elem(Integer.parse(new_nodeid, 16), 0)
        leaf_set =  Map.get(map, :leaf_set)
        if leaf_set == nil do
            IO.puts "leafset is nil"
        end
        leaf_set_size = length(leaf_set)
        if leaf_set_size < @l do
            # If leafset not completely full ,current node is terminal node
            GenServer.cast curr_pid, {:stop_nodeid, new_nodeid, new_pid, num_hops}
        else
            leaf_set_min = elem(Enum.at(leaf_set, 0), 0)
            leaf_set_max = elem(Enum.at(leaf_set, leaf_set_size - 1), 0)
    
            com_prefix_len = Utils.lcp([new_nodeid, curr_nodeid]) |> String.length
            status = if new_nodeid_int >= leaf_set_min && new_nodeid_int <= leaf_set_max do
                #leafset
                dist_pid = elem(Enum.at(leaf_set, 0), 2) 
                min_diff = abs(leaf_set_min - new_nodeid_int)
                {dist_pid, min_diff} = RoutingUtils.get_min_dist(leaf_set, new_nodeid_int, 1, dist_pid, min_diff, leaf_set_size)
                curr_diff = abs(new_nodeid_int - elem(Integer.parse(Map.get(map, :nodeid), 16), 0))
                if curr_diff < min_diff do
                    :current
                else
                    routing_row = Map.get(routing_table, num_hops)
                    if routing_row == nil do
                        routing_row = %{}
                    end
                    IO.inspect routing_row
                    #send routing row
                    GenServer.cast new_pid, {:routing_table, routing_row, com_prefix_len , curr_nodeid, curr_pid, :not_last}
                    #forward the message
                    GenServer.cast dist_pid, {:add_node, new_nodeid, new_pid, num_hops + 1}
                    :sent
                end
            else         
                internal_map = Map.get(routing_table, com_prefix_len)
                if(internal_map != nil) do
                    first_diff = String.at(new_nodeid, com_prefix_len)
                    internal_tup = Map.get(internal_map, first_diff)
                    if internal_tup != nil do
                        dist_pid = elem(internal_tup, 1)
                        #send routing table to new node
                        routing_row = Map.get(routing_table, num_hops)
                        if routing_row == nil do
                            routing_row = %{}
                        end
                        IO.inspect "routing row:"
                        IO.inspect routing_row
                        GenServer.cast new_pid, {:routing_table, routing_row, com_prefix_len, curr_nodeid, curr_pid, :not_last}
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
        # IO.puts "#{key} msg reached #{curr_nodeid}" 
        # IO.inspect Map.get(map, :routing_table)
        key_int = elem(Integer.parse(key, 16), 0)
        leaf_set =  Map.get(map, :leaf_set)
        leaf_set_size = length(leaf_set)
        leaf_set_min = elem(Enum.at(leaf_set, 0), 0)
        leaf_set_max = elem(Enum.at(leaf_set, leaf_set_size - 1), 0)
        status = if key_int >= leaf_set_min && key_int <= leaf_set_max do
            dist_pid = elem(Enum.at(leaf_set, 0), 2) 
            min_diff = abs(leaf_set_min - key_int)
            {dist_pid, min_diff} = RoutingUtils.get_min_dist(leaf_set, key_int, 1, dist_pid, min_diff, leaf_set_size)
            curr_diff = abs(key_int - elem(Integer.parse(Map.get(map, :nodeid), 16), 0))
            if curr_diff < min_diff do
                :current
            else
                GenServer.cast dist_pid, {:msg, key, val, num_hops + 1}
                :sent
            end
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