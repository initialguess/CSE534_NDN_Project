::: {.cell .markdown}
# NDN on FABRIC
:::

::: {.cell .markdown}
## Background
Achieving high-speed Named Data Networking (NDN) forwarding on commodity hardware has now been shown to be possible. Meanwhile, the roll out of FABRIC, a national research infrastructure equipped with large amounts of compute and storage and interconnected by high speed optical links, makes it possible to easily recreate, and reproduce high speed NDN forwarding on commodity hardware to incrementally improve upon and continue innovation of the data structures and algorithms that make it possible. This project creates a notebook to facilitate this further development.
:::

::: {.cell .markdown}
## Initial Setup
To run this notebook, the variables with <> must be filled with your corresponding information. The bastion key and slice key must also be in the matching directories, or the directories must be changed in order to interact with the FabLib library on FABRIC.
:::


::: {.cell .code}
```python
import os

# Specify your project ID
os.environ['FABRIC_PROJECT_ID']='<project_id>'

# Set your Bastion username and private key
os.environ['FABRIC_BASTION_USERNAME']='<username>'
os.environ['FABRIC_BASTION_KEY_LOCATION']=os.environ['HOME']+'/work/fabric_config/bastion_key'

# You can leave the rest on the default settings
# Set the keypair FABRIC will install in your slice. 
os.environ['FABRIC_SLICE_PRIVATE_KEY_FILE']=os.environ['HOME']+'/work/fabric_config/slice_key'
os.environ['FABRIC_SLICE_PUBLIC_KEY_FILE']=os.environ['HOME']+'/work/fabric_config/slice_key.pub'
# Bastion IPs
os.environ['FABRIC_BASTION_HOST'] = 'bastion-1.fabric-testbed.net'

# make sure the bastion key exists in that location!
# this cell should print True
os.path.exists(os.environ['FABRIC_BASTION_KEY_LOCATION'])

# prepare to share these with Bash so we can write the SSH config file
FABRIC_BASTION_USERNAME = os.environ['FABRIC_BASTION_USERNAME']
FABRIC_BASTION_KEY_LOCATION = os.environ['FABRIC_BASTION_KEY_LOCATION']
FABRIC_SLICE_PRIVATE_KEY_FILE = os.environ['FABRIC_SLICE_PRIVATE_KEY_FILE']
FABRIC_BASTION_HOST = os.environ['FABRIC_BASTION_HOST']
```
:::

::: {.cell .code}
```bash
%%bash -s "$FABRIC_BASTION_USERNAME" "$FABRIC_BASTION_KEY_LOCATION" "$FABRIC_SLICE_PRIVATE_KEY_FILE"

chmod 600 $2
chmod 600 $3

export FABRIC_BASTION_SSH_CONFIG_FILE=${HOME}/.ssh/config

echo "Host bastion-*.fabric-testbed.net"    >  ${FABRIC_BASTION_SSH_CONFIG_FILE}
echo "     User $1"                         >> ${FABRIC_BASTION_SSH_CONFIG_FILE}
echo "     IdentityFile $2"                 >> ${FABRIC_BASTION_SSH_CONFIG_FILE}
echo "     StrictHostKeyChecking no"        >> ${FABRIC_BASTION_SSH_CONFIG_FILE}
echo "     UserKnownHostsFile /dev/null"    >> ${FABRIC_BASTION_SSH_CONFIG_FILE}

cat ${FABRIC_BASTION_SSH_CONFIG_FILE}
```
:::

::: {.cell .code}
```python
SLICENAME=os.environ['FABRIC_BASTION_USERNAME'] + "<name>-fabric-ndn"
SITE="TACC"
```
:::

::: {.cell .code}
```python
import json
import traceback
from fabrictestbed_extensions.fablib.fablib import fablib
import datetime
import threading
import json
```
:::

::: {.cell .markdown}
## Resource Reservation
Add information about the resource reservation
:::

::: {.cell .code}
```python
two_node: bool = False # Select True for 2 node topology, False for 4 node
try:
    if fablib.get_slice(SLICENAME):
        print("You already have a slice named %s." % SLICENAME)
        slice = fablib.get_slice(name=SLICENAME)
        print(slice)
except Exception:
    if two_node:
        slice = fablib.new_slice(name=SLICENAME)
        node1 = slice.add_node(name="node1", site=SITE, cores=6, ram=80, disk=60, image='default_ubuntu_20')
        node2 = slice.add_node(name="node2", site=SITE, cores=6, ram=80, disk=60, image='default_ubuntu_20')
        ifacenode1 = node1.add_component(model="NIC_Basic", name="if_node_1").get_interfaces()[0]
        ifacenode2 = node2.add_component(model="NIC_Basic", name="if_node_2").get_interfaces()[0]
        net1 = slice.add_l3network(name='net_1', type='L2Bridge', interfaces=[ifacenode1, ifacenode2])
        slice.submit()
    else:
        slice = fablib.new_slice(name=SLICENAME)
        node1 = slice.add_node(name="node1", site=SITE, cores=6, ram=80, disk=60, image='default_ubuntu_20')
        node2 = slice.add_node(name="node2", site=SITE, cores=6, ram=80, disk=60, image='default_ubuntu_20')
        forward1 = slice.add_node(name="forward1", site=SITE, cores=6, ram=80, disk=60, image='default_ubuntu_20')
        forward2 = slice.add_node(name="forward2", site=SITE, cores=6, ram=80, disk=60, image='default_ubuntu_20')
        ifaceforward1 = forward1.add_component(model="NIC_Basic", name="if_forward_1").get_interfaces()[0]
        ifaceforward2 = forward2.add_component(model="NIC_Basic", name="if_forward_2").get_interfaces()[0]
        ifaceforward11 = forward1.add_component(model="NIC_Basic", name="if_forward_11").get_interfaces()[0]
        ifaceforward22 = forward2.add_component(model="NIC_Basic", name="if_forward_22").get_interfaces()[0]
        ifacenode1 = node1.add_component(model="NIC_Basic", name="if_node_1").get_interfaces()[0]
        ifacenode2 = node2.add_component(model="NIC_Basic", name="if_node_2").get_interfaces()[0]
        net1 = slice.add_l3network(name='net_1', type='L2Bridge', interfaces=[ifaceforward1, ifaceforward2])
        net2 = slice.add_l3network(name='net_2', type='L2Bridge', interfaces=[ifacenode1, ifaceforward11])
        net3 = slice.add_l3network(name='net_3', type='L2Bridge', interfaces=[ifacenode2, ifaceforward22])
        slice.submit()
```
:::

::: {.cell .code}
```python
for node in slice.get_nodes():
    print(node.get_name())
    print(node.get_ssh_command())
```
:::

::: {.cell .markdown}
## Phase I - Install NDN-DPDK
Installing the base [NDN-DPDK](https://github.com/usnistgov/ndn-dpdk) package is done automatically using the code block below.
This will set the terminal prefix to the node's name, install the NVIDIA MLX OFED drivers, clone the [NDN-DPDK](https://github.com/usnistgov/ndn-dpdk) and [DPDK](https://github.com/DPDK/dpdk) GitHub repositories, run the dependency installation, install the [NDN-DPDK](https://github.com/usnistgov/ndn-dpdk) package, and then configure hugepages to use 64 1GB hugepages (must have <80GB RAM on node).
All nodes in the slice reserved will have this installed. 
The install will be validated and a Success/Failure message will send per node.
This code block may take about an hour to run successfully, and may appear idle due to a triggered sleep.
Do not start other code blocks until a Success/Failure message is given.
:::

::: {.cell .code}
```python
def phase1(name: str):
    commands = [
        f"echo \"PS1=\'{name}:\\w\\$ \'\" >> .bashrc", "sudo apt update",
        "wget http://www.mellanox.com/downloads/ofed/MLNX_OFED-5.8-1.0.1.1/MLNX_OFED_SRC-debian-5.8-1.0.1.1.tgz",
        "tar zxvf MLNX_OFED_SRC-debian-5.8-1.0.1.1.tgz","sudo MLNX_OFED_SRC-5.8-1.0.1.1/./install.pl", "git clone https://github.com/usnistgov/ndn-dpdk",
        "git clone https://github.com/DPDK/dpdk", "sudo apt install --no-install-recommends -y ca-certificates curl jq lsb-release sudo nodejs",
        "chmod a+x ndn-dpdk/docs/ndndpdk-depends.sh", "echo | ndn-dpdk/docs/./ndndpdk-depends.sh", "sudo npm install -g pnpm", "cd ndn-dpdk/core && pnpm install",
        "cd ndn-dpdk && NDNDPDK_MK_RELEASE=1 make && sudo make install", "sudo python3 dpdk/usertools/dpdk-hugepages.py -p 1G --setup 64G",
        "sudo ndndpdk-ctrl systemd start", "ndndpdk-ctrl -v"
    ]
    node = slice.get_node(name=name)
    try:
        stdout, stderr = node.execute("ndndpdk-ctrl -v")
        if stdout.startswith("ndndpdk-ctrl version"):
            print(f"Already installed on {name}")
            return
        for command in commands:
            print(f"Executing {command} on {name}")
            stdout, stderr = node.execute(command)
        if stdout.startswith("ndndpdk-ctrl version"):
            print(f"Success on {name} at {datetime.datetime.now()}")
        else:
            print(f"Failure on {name} at {datetime.datetime.now()}")
    except Exception:
        print(f"Failed: {name} at {datetime.datetime.now()}")

print(f"Starting: {datetime.datetime.now()}")
for node in slice.get_nodes():
    threading.Thread(target=phase1, args=(node.get_name(),)).start()
```
:::

::: {.cell .markdown}
## Phase II - Forwarder
Activating the Forwarder can be done manually or by using the code block below.
Manually, the commands are as follows:
```
echo {} | sudo ndndpdk-ctrl activate-forwarder
sudo ndndpdk-ctrl create-eth-port --pci <INTERFACE INDEX>
sudo ndndpdk-ctrl create-ether-face --local <LOCAL INTERFACE MAC> --remote <OTHER NODE'S INTERFACE MAC>
```
This must be done on all nodes that are to be set up as forwarders, and the ether-face must be created for every interface that is to be used.
The code below will activate these commands for all nodes starting in "forward."
The ether-face will only be made if it is using a 2 node setup, since this indicates only one ether-face connected to itself on each of the 2 nodes.

The installation can be tested post install using *NDNping*, described in the documentation on the [NDN-DPDK GitHub](https://github.com/usnistgov/ndn-dpdk/blob/main/docs/forwarder.md).
:::

::: {.cell .code}
```python
def phase2(name: str):
    commands = [
        "sudo apt install net-tools",
        "sudo ndndpdk-ctrl systemd restart",
        "echo {} | sudo ndndpdk-ctrl activate-forwarder"
    ]
    node = slice.get_node(name=name)
    try:
        for command in commands:
            print(f"Executing {command} on {name}")
            stdout, stderr = node.execute(command)
        if stdout.startswith("true"):
            global_interfaces[f"{name}"] = finish_phase2(name)[f"{name}"]
            print(f"Success on {name} at {datetime.datetime.now()}")
        else:
            print(f"Failure on {name} with last message {stdout} {stderr} at {datetime.datetime.now()}")
    except Exception as e:
        print(f"Failed: {name} with {e.message} at {datetime.datetime.now()}")


def finish_phase2(name: str) -> dict:
    node = slice.get_node(name=name)
    interface_entry: dict = {
        f"{name}": []
    }
    try:
        stdout, stderr = node.execute("ifconfig -a | grep \"mtu 1500\"")
        interfaces = stdout.split("\n")
        for interface in interfaces:
            if interface.startswith("ens"):
                interface = interface.removeprefix("ens")
                interface = interface.removesuffix("np0: flags=4098<BROADCAST,MULTICAST>  mtu 1500")
                interface = interface.removesuffix("np0: flags=4419<UP,BROADCAST,RUNNING,PROMISC,MULTICAST>  mtu 1500")
                if interface != "" and "mtu 1500" not in interface:
                    stdout, stderr = node.execute(f"sudo ndndpdk-ctrl create-eth-port --pci 00:{interface}.0")
        stdout, stderr = node.execute("sudo ndndpdk-ctrl list-ethdev")
        interfaces = stdout.split("\n")
        for interface in interfaces:
            if interface != "":
                interface_entry[f"{name}"].append(json.loads(interface))
        return interface_entry
    except Exception as e:
        print(f"Failed: {name} with {e.message}")


print(f"Starting: {datetime.datetime.now()}")
global_interfaces: dict = {}
thread_list: list = []
for node in slice.get_nodes():
    thread_list.append(threading.Thread(target=phase2, args=(node.get_name(),)))
for node_thread in thread_list:
    node_thread.start()
for node_thread in thread_list:
    node_thread.join()
print(json.dumps(global_interfaces, indent=4))
if two_node:
    try:
        nodes = slice.get_nodes()
        node1mac = global_interfaces[nodes[0].get_name()][0]["macAddr"]
        node2mac = global_interfaces[nodes[1].get_name()][0]["macAddr"]
        nodes[0].execute(f"sudo ndndpdk-ctrl create-ether-face --local {node1mac} --remote {node2mac}")
        nodes[1].execute(f"sudo ndndpdk-ctrl create-ether-face --local {node2mac} --remote {node1mac}")
    except Exception as e:
        print(f"Failed with error {e.message}")
```
:::

::: {.cell .markdown}
## Phase III - Traffic Generator
Activating the Traffic Generator can be done manually or by using the code block below.
Manually, the commands are as follows for the producer node:
```
echo {} | sudo ndndpdk-ctrl activate-trafficgen
sudo ndndpdk-ctrl create-eth-port --pci <INTERFACE INDEX>
jq -n '{
  face: {
    scheme: "ether",
    local: "<LOCAL INTERFACE MAC>",
    remote: "<OTHER NODE'S INTERFACE MAC>",
    mtu: 1500
  },
  producer: {
    patterns: [
      {
        prefix: "/V",
        replies: [
          {
            suffix: "/V",
            payloadLen: 8000,
            weight: 6
          }
        ]
      }
    ]
  }
}' | ndndpdk-ctrl start-trafficgen

```
And for the consume node:
```
echo {} | sudo ndndpdk-ctrl activate-trafficgen
sudo ndndpdk-ctrl create-eth-port --pci <INTERFACE INDEX>
jq -n '{
  face: {
    scheme: "ether",
    local: "<LOCAL INTERFACE MAC>",
    remote: "<OTHER NODE'S INTERFACE MAC>",
    mtu: 1500
  },
  consumer: {
    patterns: [
      {
        weight: 5,
        prefix: "/V",
        canBePrefix: true
      }
    ],
    interval: "1ms"
  }
}' | ndndpdk-ctrl start-trafficgen

```
Once the two nodes have been started, the generators can be verified using the following:
```
sudo ndndpdk-ctrl get-face --id <INTERFACE ID> --cnt
```
If the transmitted/received matches the other node, it is running successfully.
:::

::: {.cell .markdown}
## Phase IV - File Server
Add information about the phase IV setup
:::


::: {.cell .markdown}
## Delete Resources
Add information about the phase I setup
:::

::: {.cell .code}
```python
fablib.delete_slice(SLICENAME)
```
:::
