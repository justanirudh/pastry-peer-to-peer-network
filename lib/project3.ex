defmodule Pastry do
  #LEAFSET
  #[{hex_int1, hex1, <pid1>},{hex_int2,hex2,<pid2>, ....} ]
  #ROUTING TABLE
  #map of maps
  # current node: ABCDE...32 DIGITS
  # 0 -> ...
  # 1 -> %{ 0 -> {A0-KLMN, <pid2>}, 1 -> {A1-FGHI, <pid3>}, ....   }
  # 2 -> %{ 0 -> {AB0-234, <pid4>}, ...., B -> {ABB-RFGS, <PID5>}, ....., F -> {ABF-DJHGD, <PID45>}}
  # 3
  # .
  # .
  # 31
  #NEIGHBOURHOODSET
  #[{num1, hex1, <pid1>},{num2,hex2,<pid2>, ....} ]

  defp spawn_pastry(num) do
    1..num |> Enum.map(fn i -> elem(GenServer.start_link(PastryNode, :crypto.hash(:md5, Integer.to_string(i)) |> Base.encode16()), 1) end) 
  end


  defp send_msg(nodes, val) do
    pid = Enum.random(nodes)
    key = :crypto.hash(:md5, val) |> Base.encode16()
    GenServer.cast pid, {:msg, key, val, 0} #0 is number of hops till now
  end

  def main(args) do
    num = 1000
    l = 16 # 2^b in leafset, 8 nodeids less than and 8 nodeids greater than; in outing table, each row has max 15 cols
    m = 32
    msg = "hello"

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

    #check if all state fine for a ransom node
    IO.inspect GenServer.call(Enum.at(nodes, 50), :show)

    #send msg to random node of pastry
    send_msg(nodes, msg)

    #wait to receive number of hops info
    receive do
      {:num_hops, num_hops} -> IO.inspect num_hops
    end

    

  end

end