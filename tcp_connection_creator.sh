#!/bin/bash
# Florentin Raud florentin.raud at gmail.com
# Code released under the WTFPL license

# Create a tcp connection to an ip/port couple.
# This script is mainly used to force the loadbalancer into submission.

# Usage: ./tcp_connection_creator.sh <IP> <PORT> <RETRIES> [debug:true/false]

# Why are we doing this?
# =====================
# Netscaler have a "Feature" called "Slow start"
# It doesn't actually help _if_ you have a slow start.
# The problem it tries to solve is burst connection.
# They implemented this in order to avoid calculating
# least connection on a bunch of services that just started.
# They make you use round-robin, until you are out of this 
# starting point in time, then with enough connection.
# you can have your least connection balancing...
# ... a _lot_ of connections.

# Are you kinding me ?
# ===================
# no http://support.citrix.com/article/CTX108886

# What are the parameters of the algorithm ?
# ========================================
# The "Slow start" algorithm is (re)started every:
# - time there is a service in your VIP
# - time there is a new servie added to the pool
#
# The "Slow Start" algorithm has 3 parameters:
# - The RR factor: A hardcoded value in 9.2
# It can be change after 9.3, but not 0 either.
# - The packet engines: Number of CPU cores on the box
# - The services: the number of box in your pool

# How do i calculate the "out of round robin magic number" ?
# ========================================================
# This is simple, one will need to factor all the parameters
# Formula: RR factor * packet engines * services
# Example: 100       * 8              * 10
# 

##################
### Parameters ###
##################
# Hardcoded in 9.2, can be redifined after that
# In 9.3 you can change it in the web gui/cli
# In 9.3 you cannot change it to 0
RRFACTOR=100
# Number of CPU cores
PACKETENGINES=8
# Number of instance of the service in the pool
# For us it is the numver of servers
SERVICES=9

#################
### Variables ###
#################

# Marshal our argumentsdd
IP=$1
PORT=$2
RETRIES=$3
DEBUG=$4


###################
###  Functions  ###
###################

## Generic functions

usage() {
# Display a usage summary and exit
  echo "Usage: $0 <IP> <PORT> <RETRIES>"
  echo
  echo "Create a TCP connection to provided ip and port"
  echo "The main goal is to use this script agains"

  exit 255
}

valid_ip()
{
  local  ip=$1
  local  stat=1

  if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    OIFS=$IFS
    IFS='.'
    ip=($ip)
    IFS=$OIFS
    [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
      stat=$?
  fi

  if [ $stat != 0 ]; then
    echo "The IP provided is not valid"
    echo "You provided $1, it needs to be RFC 1518 compliant"
    
    exit 1
  fi

  return 0
}

valid_port()
{
  local port=$1
  local stat=1
  
  [[ $port -le 65535 && $port -ge 1 ]]
     stat=$?

  if [ $stat != 0 ]; then
    echo "The Port provided is not in the valid range"
    echo "You provided $1"

    exit 1
  fi

  return 0
}

valid_number ()
{
  local  retries=$1
  local  stat=1

  if ! [[ $retries =~ ^[0-9]+$ ]] ; then
    echo "The number of connection retry you provided is not an number"
    echo "You provided $1"

    exit 1

  fi

  return 0
}

#############
### Debug ###
#############
debug_timestamp() {
  echo "$0: Starting at $(date)"
}

debug_verification() {
  echo "$0: Parameters verification"
}

debug_parameters() {
  echo "$0: Parameters verified"
  echo "$0: Parameters: IP=$IP"
  echo "$0: Parameters: PORT=$PORT"
  echo "$0: Parameters: RETRIES=$RETRIES"
  echo "$0: Creating TCP conenctions"
}

debug_goodbye() {
  echo "$0: Done creating TCP connections"
  echo "$0: Stopping at $(date)"
}


#######################
### Sanity Checking ###
#######################
# If debug is enabled, tell the world we started
if ! [ -z "$DEBUG" ] && DEBUG=0; then
  debug_timestamp
fi

## Perform some basic sanity checks, the IP is an IP,
## The port is in range and the retries is a positive value

# Make sure we're running as root
if [ `whoami` != "root" ]; then
    echo "ERROR: This program must be run as root."
    exit 1
fi

# Have we got the right number of options?
# XXX: Should probably use getopt?
[ $# -lt 3 ] && usage

# If debug is enabled, say that we are testing params
if ! [ -z "$DEBUG" ] && DEBUG=0; then
  debug_verification
fi

# Can we trust our user input
# If we can't we will fail at one of these
valid_ip $IP
valid_port $PORT
valid_number $RETRIES

# If debug is enabled, print the parameters
if ! [ -z "$DEBUG" ] && DEBUG=0; then
  debug_parameters
fi

#############
### Main  ###
#############
main ()
{
  local stat=1

  for i in `seq 1 $RETRIES`; do  
    exec 5<>/dev/tcp/$IP/$PORT && echo "OK" > /dev/null;
    stat=$?
    if [ $stat != 0 ]; then
      echo "The connection could not be established"
      echo "Ensure that the details are correct and that you can access it"
      echo "  EG. 'telnet $IP $PORT'"

      exit 1
    fi

    echo $i>&5 ;
  done

  return 0
}

######################
### Program Start  ###
######################

main

# If debug is enabled, say goodbye
if ! [ -z "$DEBUG" ] && DEBUG=0; then
  debug_goodbye
fi
