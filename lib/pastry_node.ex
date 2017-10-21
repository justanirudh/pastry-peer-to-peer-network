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


    def handle_cast({:msg, key, val, num_hops}, state) do
        #routing algorithm
        key_int = elem(Integer.parse(key, 16), 0)
        leafset = elem(state, 0)
        leafset_size = length(leafset)
        leafset_min = elem(Enum.at(leafset, 0), 0)
        leafset_max = elem(Enum.at(leafset, leafset_size - 1), 0)
        if key_int >= leafset_min && key_int <= leafset_max do
            #game over
            #setting first guy as solution
            dist_pid = elem(Enum.at(leafset, 0), 2) 
            min_diff = abs(leafset_min - key_int)
            #finding actual guy
            dist_pid = get_min_dist(leafset, key_int, 1, dist_pid, min_diff, leafset_size)
            GenServer.cast dist_pid, {:end, key, val, num_hops + 1}
            {:noreply, state}
        else

        end

    end

    def handle_cast({:end, key, val, num_hops}, state) do
    
    end


end