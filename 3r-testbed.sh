# this script is included in other testbed startup scripts
#
# topology:
#
#      +------------------+      +------------------+      +------------------+      +------------------+
#      |        r1        |      |        r2        |      |        r3        |      |        r4        |
#      |                  |      |                  |      |                  |      |                  |
#      |              i12 +------+ i21          i23 +------+ i32          i34 +------+ i43              |
#      |                  |      |                  |      |                  |      |                  |
#      |                  |      |                  |      |                  |      |                  |
#      +------------------+      +------------------+      +------------------+      +------------------+
#
# addresses:
#
# r1 i12 10.0.0.1/24 mac 00:00:00:00:01:02
#
# r2 i21 10.0.0.2/24 mac 00:00:00:00:02:01
# r2 i23 10.1.0.2/24 mac 00:00:00:00:02:03
#
# r3 i32 10.1.0.1/24 mac 00:00:00:00:03:02


# r3 i34 fc34::1/64 mac 00:00:00:00:03:04
#
# r4 i43 fc34::2/64 mac 00:00:00:00:04:03
#

TMUX=ebpf

# Kill tmux previous session
tmux kill-session -t $TMUX 2>/dev/null

# Clean up previous network namespaces
ip -all netns delete

ip netns add r1
ip netns add r2
ip netns add r3
ip netns add r4

ip -netns r1 link add i12 type veth peer name i21 netns r2
ip -netns r2 link add i23 type veth peer name i32 netns r3
ip -netns r3 link add i34 type veth peer name i43 netns r4

###################
#### Node: r1 #####
###################
echo -e "\nNode: r1"

ip -netns r1 link set dev i12 address 00:00:00:00:01:02

ip -netns r1 link set dev lo up
ip -netns r1 link set dev i12 up

ip -netns r1 addr add 10.0.0.1/24 dev i12

ip -netns r1 route add 10.1.0.0/24 via 10.0.0.2


###################
#### Node: r2 #####
###################
echo -e "\nNode: r2"

ip -netns r2 link set dev i21 address 00:00:00:00:02:01
ip -netns r2 link set dev i23 address 00:00:00:00:02:03

ip -netns r2 link set dev lo up
ip -netns r2 link set dev i21 up
ip -netns r2 link set dev i23 up

ip -netns r2 addr add 10.0.0.2/24 dev i21
ip -netns r2 addr add 10.1.0.2/24 dev i23

#ip -netns r2 route add 10.34.0.0/24 via 10.23.0.2


read -r -d '' r2_env <<-EOF
  sysctl -w net.ipv4.ip_forward=1

	/bin/bash
EOF

###################
#### Node: r3 #####
###################
echo -e "\nNode: r3"

ip -netns r3 link set dev i32 address 00:00:00:00:03:02
ip -netns r3 link set dev i34 address 00:00:00:00:03:04

ip -netns r3 link set dev lo up
ip -netns r3 link set dev i32 up
ip -netns r3 link set dev i34 up

ip -netns r3 addr add 10.1.0.1/24 dev i32

ip -netns r3 route add 10.0.0.0/24 via 10.1.0.2


read -r -d '' r3_env <<-EOF
  sysctl -w net.ipv4.ip_forward=1

	/bin/bash
EOF

###################
#### Node: r4 #####
###################
echo -e "\nNode: r4"

ip -netns r4 link set dev i43 address 00:00:00:00:04:03

ip -netns r4 link set dev lo up
ip -netns r4 link set dev i43 up



## Create a new tmux session
sleep 1

tmux new-session -d -s $TMUX -n MAIN bash
#tmux new-window -t $TMUX -n MAPS bash
#tmux new-window -t $TMUX -n DEBUG bash
tmux new-window -t $TMUX -n R1 ip netns exec r1 bash
tmux new-window -t $TMUX -n R2 ip netns exec r2 bash -c "${r2_env}"
tmux new-window -t $TMUX -n R2-BIS ip netns exec r2 bash

tmux new-window -t $TMUX -n R3 ip netns exec r3 bash -c "${r3_env}"
#tmux new-window -t $TMUX -n R4 ip netns exec r4 bash


if [[ "$R1_EXEC" == "YES" ]] ; then CM="C-m" ; else CM="" ; fi
tmux send-keys -t $TMUX:R1   "$R1_COMMAND" $CM
if [[ "$MAIN_EXEC" == "YES" ]] ; then CM="C-m" ; else CM="" ; fi
tmux send-keys -t $TMUX:MAIN   "$MAIN_COMMAND" $CM
#if [[ "$R4_EXEC" == "YES" ]] ; then CM="C-m" ; else CM="" ; fi
#tmux send-keys -t $TMUX:R4   "$R4_COMMAND" $CM

tmux select-window -t $TMUX:R1
tmux set-option -g mouse on
tmux attach -t $TMUX
