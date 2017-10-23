defmodule Pastry do
  @range 100
  # LEAFSET
  # [{hex_int1, hex1, <pid1>},{hex_int2,hex2,<pid2>, ....} ]
  # ROUTING TABLE
  # map of maps
  # current node: ABCDE...32 DIGITS
  # 0 -> ...
  # 1 -> %{ 0 -> {A0-KLMN, <pid2>}, 1 -> {A1-FGHI, <pid3>}, ....   }
  # 2 -> %{ 0 -> {AB0-234, <pid4>}, ...., B -> {ABB-RFGS, <PID5>}, ....., F -> {ABF-DJHGD, <PID45>}}
  # 3
  # .
  # .
  # 31
  # NEIGHBOURHOODSET
  # [{num1, hex1, <pid1>},{num2,hex2,<pid2>, ....} ]

  defp spawn_pastry(num) do
    1..num |> Enum.map(fn i ->
      hex = :crypto.hash(:md5, Integer.to_string(i)) |> Base.encode16()
      elem(GenServer.start_link(PastryNode, %{:nodeid => hex, :proxid => i, :leaf_set => nil, :routing_table => nil, :neigh_set => nil}), 1) end) 
  end

defp activate_peers(nodes, ind, len, num_reqs) do
  if ind == len do
    :ok
  else
    :ok = GenServer.call Enum.at(nodes, ind), {:activate, nodes, num_reqs}  
    activate_peers(nodes, ind + 1, len, num_reqs)
  end
end


defp get_avg_num_hops(total_reqs, ind, sum) do
  if ind == total_reqs do
    sum/total_reqs
  else
    num_hops = receive do
      {:num_hops, num_hops} -> num_hops 
    end
    get_avg_num_hops(total_reqs, ind + 1, sum + num_hops)
  end
end

  def main(args) do
    #1k nodes ~ 15s, 10k nodes > 2hrs
    
    num = Enum.at(args, 0) |> String.to_integer #number of peers
    num_reqs = Enum.at(args, 1) |> String.to_integer #number of requests each peer needs to make
    l = 16 # 2^b in leafset, 8 nodeids less than and 8 nodeids greater than; in outing table, each row has max 15 cols
    m = 32
    msg = "is anybody in there"

    self() |> Process.register(:master) #register master
    
    #list of all pids
    nodes = spawn_pastry(num)

    #Pastry setup
    #TODO: need to change this after implementing the 'join' functionality?
    node_hexes = 1..num |> Enum.map(fn i -> (:crypto.hash(:md5, Integer.to_string(i)) |> Base.encode16()) end)
    IO.inspect "creating leafsets..."
    LeafSets.send(nodes, l, num, node_hexes)
    IO.inspect "creating routing tables..."
    RoutingTables.send(nodes, node_hexes, num ,l)
    #Neighbourhood set: M = 32. similar to leafset but with 32 neighbours and with num indices.
    IO.inspect "creating neighbourhoodsets..."
    NeighbourhoodSets.send(nodes, m, num, node_hexes)

    #check if all state fine for a random node
    IO.inspect GenServer.call(Enum.at(nodes, 50), :show)

    #add 1 node
    # NetworkJoin.add_node(nodes, num)

    #activate nodes to start sending messages to each other
    activate_peers(nodes, 0, num, num_reqs)

    avg_num_hops = get_avg_num_hops(num_reqs * num, 0, 0)

    IO.puts "Average number of hops is #{avg_num_hops}"
    

  end

end