# Pastry

Team members: Anirudh Pathak, Vaibhav Yenamandra
What is working: network join and routing
What is the largest network you managed to deal with: 10000 nodes

Note: The messages are NOT being sent per second.

##Output explaination
new node id hex: ABC.. // New nodes being added to the pastry, one by one (network join)
new node(s) added // All nodes added to the pastry
peers activated. //All peers have started sending messages to each other
Counting avg number of hops //now counting hops
Msg num. [msgid]: num_hops = NUM // Ms number 0 took 2 hops to reach its destination
Average number of hops is [NUM] //calculated average number of hops

##Data structures used:

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
