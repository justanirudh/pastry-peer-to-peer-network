defmodule Pastry do
  @moduledoc """
  Documentation for Pastry.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Pastry.hello
      :world

  """
  def hello do
    :world
  end

  def main(args) do
    num = 1000
    self() |> Process.register(:master) #register master
    #list of all pids
    list = 1..num |> Enum.map(fn i -> elem(GenServer.start_link(PastryNode, :crypto.hash(:md5, Integer.to_string(i)) |> Base.encode16()), 1) end) 
    #send entire list to all nodes to construct leaf set and routing table 
    #TODO: need to change this after implementing the 'join' functionality
    Enum.each(list, fn(pid) -> GenServer.call(pid, {:all_nodes, list, num})  end)
    IO.inspect GenServer.call(Enum.at(list, 0), :show)

  end

end
