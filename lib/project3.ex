defmodule Pastry do
  #routing table
  #map of maps
  # current node: ABCDE...32 DIGITS
  # 0 -> ...
  # 1 -> %{ 0 -> {A0-KLMN, <pid2>}, 1 -> {A1-FGHI, <pid3>}, ....   }
  # 2 -> %{ 0 -> {AB0-234, <pid4>}, ...., B -> {ABB-RFGS, <PID5>}, ....., F -> {ABF-DJHGD, <PID45>}}
  # 3
  # .
  # .
  # 31

  defp spawn_pastry(num) do
    1..num |> Enum.map(fn i -> elem(GenServer.start_link(PastryNode, :crypto.hash(:md5, Integer.to_string(i)) |> Base.encode16()), 1) end) 
  end

  def main(args) do
    num = 1000
    l = 16 # 2^b in leafset, 8 nodeids less than and 8 nodeids greater than; in outing table, each row has max 15 cols
    self() |> Process.register(:master) #register master
    #list of all pids
    nodes = spawn_pastry(num)
    node_hexes = 1..num |> Enum.map(fn i -> (:crypto.hash(:md5, Integer.to_string(i)) |> Base.encode16()) end)
    #send entire list to all nodes to construct leaf set and routing table 
    #TODO: need to change this after implementing the 'join' functionality?
    IO.inspect "creating leafsets..."
    LeafSets.send(nodes, l, num, node_hexes)
    IO.inspect "creating routing tables..."
    RoutingTables.send(nodes, node_hexes, num ,l)

    # Enum.each(nodes, fn(pid) -> GenServer.call(pid, {:all_nodes, nodes, num})  end)
    IO.inspect GenServer.call(Enum.at(nodes, 50), :show)

  end

end