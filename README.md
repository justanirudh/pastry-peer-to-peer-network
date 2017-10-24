# Pastry

Team members: Anirudh Pathak, Vaibhav Yenamandra
What is working: network join and routing (everything is working)
What is the largest network you managed to deal with: 100,000 nodes (can handle more nodes but just takes more time)

Note: The messages are NOT being sent per second.

##Output explanation
new node id hex: ABC.. // New nodes being added to the pastry, one by one (network join)
new node(s) added // All nodes added to the pastry
peers activated. //All peers have started sending messages to each other (routing)
Counting avg number of hops //now counting hops
Msg num. [msgid]: num_hops = NUM // Msgs number msgid took NUM hops to reach its destination
Average number of hops is [NUM] //calculated average number of hops
