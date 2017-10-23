# Pastry

Team members: Anirudh Pathak, Vaibhav Yenamandra
What is working: routing and network join
What is the largest network you managed to deal with: 3000 nodes

Other stats:
b = 4
L = 16
M = 32
num_nodes num_requests avg_hops
100          10          ~1.9
1000         10          ~2.9
1000         1000        ~2.9
2000         100         ~3.04
3000         10          ~3.26 

Data structures:

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
