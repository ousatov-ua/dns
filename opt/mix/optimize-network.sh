sudo ethtool -K enp1s0 rx off tx off
sudo ip link set enp1s0 txqueuelen 50
