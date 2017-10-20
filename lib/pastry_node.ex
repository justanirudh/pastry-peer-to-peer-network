defmodule PastryNode do
    use GenServer
    #state: nodeid, leafset
    #b = 4, L = 16, M = 32

    #add leaf set
    def handle_call({:leafset, leafset}, _from, nodeid) do
        #initialize routing table
        {:reply, :ok, {nodeid, leafset}} 
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