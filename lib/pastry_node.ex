defmodule PastryNode do
    use GenServer
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



    def handle_cast({:msg, key, val}, state) do
        
    end

end