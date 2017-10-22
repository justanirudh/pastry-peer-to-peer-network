# Pastry



L = 16
M = 32
num_nodes num_requests avg_hops
100          10          ~1.9
1000         10          ~2.9
1000         1000        ~2.9    

  LEAFSET
  [{hex_int1, hex1, <pid1>},{hex_int2,hex2,<pid2>, ....} ]
  ROUTING TABLE
  map of maps
  current node: ABCDE...32 DIGITS
  0 -> ...
  1 -> %{ 0 -> {A0-KLMN, <pid2>}, 1 -> {A1-FGHI, <pid3>}, ....   }
  2 -> %{ 0 -> {AB0-234, <pid4>}, ...., B -> {ABB-RFGS, <PID5>}, ....., F -> {ABF-DJHGD, <PID45>}}
  3
  .
  .
  31
  NEIGHBOURHOODSET
  [{num1, hex1, <pid1>},{num2,hex2,<pid2>, ....} ]

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `project3` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:project3, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/project3](https://hexdocs.pm/project3).

