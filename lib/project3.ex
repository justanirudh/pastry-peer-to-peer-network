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
      elem(GenServer.start_link(PastryNode, %{:nodeid => hex, :proxid => i, :leaf_set => [], :routing_table => %{}, :neigh_set => []}), 1) end) 
  end

defp activate_peers(nodes, ind, len, num_reqs) do
  if ind == len do
    :ok
  else
    :ok = GenServer.call Enum.at(nodes, ind), {:activate, nodes, num_reqs}, :infinity
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
    IO.inspect "Msg num. #{ind}: num_hops = #{num_hops}"
    get_avg_num_hops(total_reqs, ind + 1, sum + num_hops)
  end
end

  def main(args) do
    
    num = (Enum.at(args, 0) |> String.to_integer) #number of peers
    num_reqs = Enum.at(args, 1) |> String.to_integer #number of requests each peer needs to make
    self() |> Process.register(:master) #register master
    #spawn 1 node
    hex = :crypto.hash(:md5, Integer.to_string(1)) |> Base.encode16()
    pid = elem(GenServer.start_link(PastryNode, %{:nodeid => hex, :proxid => 1, :leaf_set => [], :routing_table => %{}, :neigh_set => []}), 1)
    
    #add rest nodes
    nodes = NetworkJoin.add_node_many([pid], 1, num - 1)

    IO.puts "new node(s) added"

    #activate nodes to start sending messages to each other
    activate_peers(nodes, 0, num, num_reqs)

    IO.puts "peers activated.\nCounting avg number of hops "

    avg_num_hops = get_avg_num_hops(num_reqs * num, 0, 0)

    IO.puts "Average number of hops is #{avg_num_hops}"

  end

end