defmodule Pastry do


  defp spawn_pastry(num) do
    1..num |> Enum.map(fn i -> elem(GenServer.start_link(PastryNode, :crypto.hash(:md5, Integer.to_string(i)) |> Base.encode16()), 1) end) 
  end


  defp send_leafsets_aux(sorted, ind, num, l) do
    if(ind == num) do
      :ok
    else
      num_start = ind + 1
      num_end = num_start + div(l,2) - 1
      list_right = Enum.slice(sorted, num_start..num_end)
      
      num_start = ind - div(l,2)
      num_end = ind - 1
      list_left = Enum.slice(sorted, num_start..num_end)
      
      combined = list_left ++ list_right
      curr = elem(Enum.at(sorted, ind), 2)   
      :ok = GenServer.call(curr, {:leafset, combined})
      send_leafsets_aux(sorted, ind + 1, num, l)
    end
  end

  defp send_leafsets(nodes, l, num) do
    #nodes is a list of pids
    #node_hexes is a list of nodeIds
    #node_ints is a list of nodeIds in int form
    node_hexes = 1..num |> Enum.map(fn i -> (:crypto.hash(:md5, Integer.to_string(i)) |> Base.encode16()) end)
    node_ints = Enum.map( node_hexes, fn i -> elem(Integer.parse(i, 16),0) end)
    zipped = Enum.zip([node_ints, node_hexes, nodes]) #numerical value, hex value, node id
    sorted = Enum.sort(zipped, fn(i,j) -> elem(i, 0) < elem(j,0) end)
    :ok = send_leafsets_aux(sorted, 0, num, l)
  end

  def main(args) do
    num = 1000
    l = 16 # in leafset, 8 nodeids less than and 8 nodeids greater than
    self() |> Process.register(:master) #register master
    #list of all pids
    nodes = spawn_pastry(num)
    #send entire list to all nodes to construct leaf set and routing table 
    #TODO: need to change this after implementing the 'join' functionality
    send_leafsets(nodes, l, num)

    # Enum.each(nodes, fn(pid) -> GenServer.call(pid, {:all_nodes, nodes, num})  end)
    IO.inspect GenServer.call(Enum.at(nodes, 100), :show)

  end

end
