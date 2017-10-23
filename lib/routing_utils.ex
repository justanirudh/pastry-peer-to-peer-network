defmodule RoutingUtils do
    @range 10
    #TODO: change it back to 1000000
    @sleep_time 1 # in microseconds
    
    def get_min_dist(leaf_set, key_int, ind, dist_pid, min_diff, leaf_set_size) do
        if ind == leaf_set_size do
            dist_pid
        else
            tup = Enum.at(leaf_set, ind)
            curr_int = elem(tup, 0)
            diff = abs(curr_int - key_int)
            if diff < min_diff do
                get_min_dist(leaf_set, key_int, ind + 1,  elem(tup, 2), diff, leaf_set_size)
            else
                get_min_dist(leaf_set, key_int, ind + 1,  dist_pid, min_diff, leaf_set_size)
            end
        end
    end

    #returns list of {hex, pid}
    def get_union_all(map) do
        leaf_set =  Map.get(map, :leaf_set)
        leaf_set_res = Enum.map(leaf_set, fn {_, h, p} -> {h,p} end) #1
        
        routing_table =  Map.get(map, :routing_table)
        rt_vals = Map.values routing_table
        routing_table_res = Enum.map(rt_vals, fn map -> Map.values map end) |> List.flatten #2
        
        neighset = Map.get(map, :neigh_set)
        neighset_res =  Enum.map(neighset, fn {_, h, p} -> {h,p} end) #3

        (leaf_set_res ++ routing_table_res ++ neighset_res) |> Enum.uniq

    end

    defp find_next_node(union_all, len, min_com_prefix_len, min_num_diff, key,key_int,ind) do
        if ind == len do
            :failure
        else
            {hex, pid} = Enum.at(union_all, ind)
            com_prefix_len = Utils.lcp([key, hex]) |> String.length
            num_diff = key_int - ( hex |> Integer.parse(16)  |> elem(0)) |> abs
            if com_prefix_len >= min_com_prefix_len && num_diff < min_num_diff do
                {:success, pid}
            else
                find_next_node(union_all, len, min_com_prefix_len, min_num_diff, key,key_int,ind + 1)
            end          
        end
    end

    defp search_entire_state(map, key, key_int, min_com_prefix_len) do
        curr_hex = Map.get(map, :nodeid)
        min_num_diff = abs(key_int - elem(Integer.parse( curr_hex, 16), 0))
        union_all = get_union_all(map)
        #find the first guy who's (com_prefix_len >= min_com_prefix_len) && (num_diff < min_num_diff)
        find_next_node(union_all, length(union_all), min_com_prefix_len, min_num_diff, key, key_int, 0)
    end

    def is_send(map, key, key_int, com_prefix_len, val, num_hops) do
        res = search_entire_state(map, key, key_int, com_prefix_len)
        case res do
            {:success, pid} -> 
                GenServer.cast pid, {:msg, key, val, num_hops + 1} 
                :sent
            :failure -> :current
        end
    end

    def is_nodeid_send(map, new_nodeid, new_nodeid_int, com_prefix_len, num_hops, new_pid, curr_nodeid, curr_pid) do
        res = search_entire_state(map, new_nodeid, new_nodeid_int, com_prefix_len)
        case res do
            {:success, pid} -> 
                #send routing table to new node
                routing_row = Map.get(map, :routing_table) |> Map.get(num_hops)
                if routing_row == nil do
                    routing_row = %{}
                end
                IO.inspect "routing row:"
                IO.inspect routing_row
                GenServer.cast new_pid, {:routing_table, routing_row, num_hops, curr_nodeid, curr_pid, :not_last}
                #forward to next pid
                GenServer.cast pid, {:add_node, new_nodeid, new_pid, num_hops + 1}
                :sent
            :failure -> :current
        end
    end


    def send_messages(nodes, num_reqs, ind) do
        if(ind == num_reqs) do
            :ok
        else
            pid = Enum.random nodes
            val = :rand.uniform(@range) |> :crypto.strong_rand_bytes |> Base.encode64
            key = :crypto.hash(:md5, val) |> Base.encode16()
            GenServer.cast pid, {:msg, key, val, 0} #0 is number of hops till now
            :timer.sleep(@sleep_time)
            send_messages(nodes, num_reqs, ind + 1)
        end
    end

        
    defp insert_sortedly_aux(leaf_set, sender_nodeid_int, ind, len) do
        if ind == len do
            -1
        else
            {hex_int, _, _} = Enum.at(leaf_set, ind)
            if hex_int > sender_nodeid_int do
                ind
            else
                insert_sortedly_aux(leaf_set, sender_nodeid_int, ind + 1, len)
            end
        end
    end

    def insert_sortedly(leaf_set, {sender_nodeid_int, sender_nodeid, sender_pid}, leaf_set_len) do
        if length(leaf_set) == 0 do
            [{sender_nodeid_int, sender_nodeid, sender_pid}]
        else
            index = insert_sortedly_aux(leaf_set, sender_nodeid_int, 0, leaf_set_len)
            List.insert_at(leaf_set, index, {sender_nodeid_int, sender_nodeid, sender_pid})
        end
        
    end


    def add_in_leaf_set(leaf_set, set_size, sender_nodeid_int, sender_nodeid, sender_pid) do
        leaf_set_len = length(leaf_set)
        if(leaf_set_len < set_size) do
            #insert {sender_nodeid_int, sender_nodeid, sender_pid} in leaf_set sortedly
            leaf_set = insert_sortedly(leaf_set, {sender_nodeid_int, sender_nodeid, sender_pid}, leaf_set_len)   
        else
            leaf_set_min = elem(Enum.at(leaf_set, 0), 0)
            leaf_set_max = elem(Enum.at(leaf_set, leaf_set_len - 1), 0)
            if sender_nodeid_int > leaf_set_min && sender_nodeid_int < leaf_set_max do
                #insert and delete from edge
                leaf_set = RoutingUtils.insert_sortedly(leaf_set, {sender_nodeid_int, sender_nodeid, sender_pid}, leaf_set_len)
                leaf_set = List.delete_at(leaf_set, leaf_set_len)
            end
        end
        leaf_set
    end

end