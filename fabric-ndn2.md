::: {.cell .markdown}
# NDN on FABRIC
:::

::: {.cell .markdown}
## Background
Add the background here
:::

::: {.cell .markdown}
## Initial Setup
Add information about the initial setup steps
:::


::: {.cell .code}
```python
import os

# Specify your project ID
os.environ['FABRIC_PROJECT_ID']='6ce270de-788d-4e07-8bae-3206860a6387'

# Set your Bastion username and private key
os.environ['FABRIC_BASTION_USERNAME']='rjwomack_0000027821'
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
SLICENAME=os.environ['FABRIC_BASTION_USERNAME'] + "rjwomack-fabric-ndn"
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
```
:::

::: {.cell .code}
```python
if fablib.get_slice(SLICENAME):
    print("You already have a slice named %s." % SLICENAME)
    slice = fablib.get_slice(name=SLICENAME)
    print(slice)
```
:::

::: {.cell .markdown}
## Resource Reservation
Add information about the resource reservation
:::


::: {.cell .code}
```python
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
        "sudo ndndpdk-ctrl systemd start", "ndndpdk-ctrl"
    ]
    node = slice.get_node(name=name)
    try:
        for command in commands:
            print(f"Executing {command} on {name}")
            stdout, stderr = node.execute(command)
        print(f"Finished: {name}")
        if stdout == "true":
            print(f"Success on {name}")
        else:
            print(f"Failure on {name}")
        print(f"{name} done at {datetime.datetime.now()}")
    except Exception:
        print(f"Failed: {name}")

print(f"Starting: {datetime.datetime.now()}")
for node in slice.get_nodes():
    threading.Thread(target=phase1, args=(node.get_name(),)).start()
```
:::

::: {.cell .markdown}
## Phase II - Forwarder
Add information about the phase II setup
:::

::: {.cell .markdown}
## Phase III - Traffic Generator
Add information about the phase III setup
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
