defmodule RoutingUtils do
    
    def get_min_dist(leafset, key_int, ind, dist_pid, min_diff, leafset_size) do
        if ind == leafset_size do
            dist_pid
        else
            tup = Enum.at(leafset, ind)
            curr_int = elem(tup, 0)
            diff = abs(curr_int - key_int)
            if diff < min_diff do
                get_min_dist(leafset, key_int, ind + 1,  elem(tup, 2), diff, leafset_size)
            else
                get_min_dist(leafset, key_int, ind + 1,  dist_pid, min_diff, leafset_size)
            end
        end
    end

    #TODO: implement this
    #returns list of {hex, pid}
    defp get_union_all(state) do
        leafset = elem(state, 1)
        routing_table = elem(state, 2)
        neighset = elem(state, 3)
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

    defp search_entire_state(state, key, key_int, min_com_prefix_len) do
        curr_hex = elem(state, 0)
        min_num_diff = abs(key_int - elem(Integer.parse( curr_hex, 16), 0))
        union_all = get_union_all(state)
        #find the first guy who's (com_prefix_len >= min_com_prefix_len) && (num_diff < min_num_diff)
        find_next_node(union_all, length(union_all), min_com_prefix_len, min_num_diff, key, key_int, 0)
    end

    def is_send(state, key, key_int, com_prefix_len, val, num_hops) do
        res = search_entire_state(state, key, key_int, com_prefix_len)
        case res do
            {:success, pid} -> 
                GenServer.cast pid, {:msg, key, val, num_hops + 1} 
                :sent
            :failure -> :current
        end
    end

end