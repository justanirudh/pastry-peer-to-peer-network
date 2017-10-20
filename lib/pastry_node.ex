defmodule PastryNode do
    use GenServer
    #state: nodeid, all_nodes, length of ring

    #initialize all ndoes data into node's state
    def handle_call({:all_nodes, list, num}, _from, nodeid) do
        {:reply, :ok, {nodeid, list, num}} 
    end

    #show
    def handle_call(:show, _from, st) do
        {:reply, st, st} 
    end

end