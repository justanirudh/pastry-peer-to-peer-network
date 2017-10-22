defmodule PastryNode do
    use GenServer
    @diff_max 3.402823669209385e38
    #state: nodeid, leafset, routing_table, neighbourhoodset
    #b = 4, L = 16, M = 32

    #add leaf set
    def handle_call({:leafset, leafset}, _from, nodeid) do
        {:reply, :ok, {nodeid, leafset}} 
    end

    #add routing table
    def handle_call({:routing_table, routing_table}, _from, state) do
        {:reply, :ok, {elem(state, 0),elem(state, 1),routing_table }} 
    end

    #add neighset set
    def handle_call({:neighset, neighset}, _from, state) do
        {:reply, :ok, {elem(state, 0),elem(state, 1), elem(state, 2),neighset }} 
    end

    #show
    def handle_call(:show, _from, st) do
        {:reply, st, st} 
    end

    defp get_min_dist(leafset, key_int, ind, dist_pid, min_diff, leafset_size) do
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

    def handle_cast({:stop, key, val, num_hops}, state) do
        #TODO: save key, val in current node
        IO.puts "terminal nodeid is #{elem(state, 0)}"
        send :master, {:num_hops, num_hops}
        {:noreply, state}
    end


    def handle_cast({:msg, key, val, num_hops}, state) do
        #routing algorithm
        curr_hex = elem(state, 0)
        IO.puts "msg reached #{curr_hex}" 
        key_int = elem(Integer.parse(key, 16), 0)
        leafset = elem(state, 1)
        leafset_size = length(leafset)
        leafset_min = elem(Enum.at(leafset, 0), 0)
        leafset_max = elem(Enum.at(leafset, leafset_size - 1), 0)
        status = if key_int >= leafset_min && key_int <= leafset_max do
            #GAME OVER (else infinte loop)
            IO.puts "in leafset table of #{curr_hex}"
            #setting first guy as solution
            dist_pid = elem(Enum.at(leafset, 0), 2) 
            min_diff = abs(leafset_min - key_int)
            #finding actual guy
            dist_pid = get_min_dist(leafset, key_int, 1, dist_pid, min_diff, leafset_size)
            # GenServer.cast dist_pid, {:msg, key, val, num_hops + 1} #can lead to infinite loops
            GenServer.cast dist_pid, {:stop, key, val, num_hops + 1}
            :sent
        else
            com_prefix_len = Utils.lcp([key, curr_hex]) |> String.length
            routing_table = elem(state, 2)
            internal_map = Map.get(routing_table, com_prefix_len)
            if(internal_map != nil) do
                first_diff = String.at(key, com_prefix_len)
                internal_tup = Map.get(internal_map, first_diff)
                if internal_tup != nil do
                    IO.puts "in routing table of #{curr_hex}"
                    dist_pid = elem(internal_tup, 1)
                    GenServer.cast dist_pid, {:msg, key, val, num_hops + 1}
                else
                   #TODO: SAME HERE - search in union
                   :current #for debugging   
                end
            else
                #TODO: SAME HERE - search in union 
                :current  #for debugging    
            end
        end

        if status == :current do
            #TODO: save key, val in current node
            IO.puts "terminal nodeid is #{elem(state, 0)}"
            send :master, {:num_hops, num_hops}
        end

        {:noreply, state}

    end

end