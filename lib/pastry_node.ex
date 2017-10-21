defmodule PastryNode do
    use GenServer
    #state: nodeid, leafset[numerical value, hex value, node id], routing_table
    #b = 4, L = 16, M = 32

    #add leaf set
    def handle_call({:leafset, leafset}, _from, nodeid) do
        {:reply, :ok, {nodeid, leafset}} 
    end

    #add routing table
    def handle_call({:routing_table, routing_table}, _from, state) do
        {:reply, :ok, {elem(state, 0),elem(state, 1),routing_table }} 
    end

    # #initialize all nodes data into node's state
    # def handle_call({:all_nodes, list, num}, _from, nodeid) do
    #     #initialize routing table
    #     {:reply, :ok, {nodeid, list, num}} 
    # end

    #show
    def handle_call(:show, _from, st) do
        {:reply, st, st} 
    end

end