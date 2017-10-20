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
    list = 1..num |> Enum.map(
      fn i -> elem(GenServer.start_link(PastryNode, :crypto.hash(:md5, Integer.to_string(i)) |> Base.encode16()), 1) end) #list of all pids

  end

end
