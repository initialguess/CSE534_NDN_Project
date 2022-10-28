::: {.cell .markdown}

#  Named Data Networking on Fabric

This experiment explores using NDN Data Plane Development on Fabric.  The DPDK was developed at NIST and designed to work on commodity hardware...

This experiment runs on the [FABRIC JupyterHub server](https://jupyter.fabric-testbed.net/). You will need an account on FABRIC, and you will need to have set up bastion keys, to run it.

It should take about 60-120 minutes to run this experiment.

:::

## Run my experiment

:::

::: {.cell .markdown}

### Set up bastion keys

As a first step, set up your personal variables.  Do this before attempting to reserve resources. It's important that you get the variables right *before* you import the `fablib` library, because `fablib` loads these once when imported and they can't be changed afterwards.

* project ID: in the FABRIC portal, click on User Profile > My Roles and Projects > and click on your project name. Then copy the Project ID string.
* bastion username: look for the string after "Bastion login" on [the SSH Keys page in the FABRIC portal](https://portal.fabric-testbed.net/experiments#sshKeys)
* bastion key pair: if you haven't yet set up bastion keys in your notebook environment (for example, in a previous session), complete the steps described in the [bastion keypair](https://github.com/fabric-testbed/jupyter-examples/blob/master//fabric_examples/fablib_api/bastion_setup.ipynb) notebook. Then, the key location you specify below should be the path to the private key file.

If you have set this up, move on to the following:
:::

### Specifying Your Details
Add your unique Fabric credentials that you just set up.

::: {.cell .code}

```python
import os

# Import the python os library
import os

# Specify your project ID
os.environ['FABRIC_PROJECT_ID']='6ce270de-788d-4e07-8bae-3206860a6387'

# Set your Bastion username
os.environ['FABRIC_BASTION_USERNAME']='gsinkins_0000025334'

# Specify the path to your Bastion key, Slice private and public keys
os.environ['FABRIC_BASTION_KEY_LOCATION']=os.environ.get('HOME')+'/work/fabric_config/fabric_bastion_key'
os.environ['FABRIC_SLICE_PRIVATE_KEY_FILE']=os.environ['HOME']+'/work/fabric_config/slice_key'
os.environ['FABRIC_SLICE_PUBLIC_KEY_FILE']=os.environ['HOME']+'/work/fabric_config/slice_key.pub'

# Prepare to share these with Bash so we can write the SSH config file
os.environ['FABRIC_BASTION_HOST'] = 'bastion-1.fabric-testbed.net'
FABRIC_BASTION_USERNAME = os.environ['FABRIC_BASTION_USERNAME']
FABRIC_BASTION_KEY_LOCATION = os.environ['FABRIC_BASTION_KEY_LOCATION']
FABRIC_SLICE_PRIVATE_KEY_FILE = os.environ['FABRIC_SLICE_PRIVATE_KEY_FILE']
FABRIC_BASTION_HOST = os.environ['FABRIC_BASTION_HOST']
```
:::

::: {.cell .markdown} 
### Using the variables set above, run the following bash commands
:::

::: {.cell .code}

```bash
%%bash -s "$FABRIC_BASTION_USERNAME" "$FABRIC_BASTION_KEY_LOCATION" "$FABRIC_SLICE_PRIVATE_KEY_FILE"
# Set permissions for the key location and private slice file
chmod 600 $2 $3

export FABRIC_BASTION_SSH_CONFIG_FILE=${HOME}/work/fabric_config/ssh_config

echo "Host bastion-*.fabric-testbed.net"    >  ${FABRIC_BASTION_SSH_CONFIG_FILE}
echo "     User $1"                         >> ${FABRIC_BASTION_SSH_CONFIG_FILE}
echo "     IdentityFile $2"                 >> ${FABRIC_BASTION_SSH_CONFIG_FILE}
echo "     StrictHostKeyChecking no"        >> ${FABRIC_BASTION_SSH_CONFIG_FILE}
echo "     UserKnownHostsFile /dev/null"    >> ${FABRIC_BASTION_SSH_CONFIG_FILE}


cat ${FABRIC_BASTION_SSH_CONFIG_FILE}
```
:::

::: {.cell .markdown} 

### Setup the Experiments
Import Fabric API and slice manager

:::

::: {.cell .code}

```python
import os
from fabrictestbed.slice_manager import SliceManager, Status, SliceState
import json
```
:::


::: {.cell .markdown}
### Create the FABRIC Proxies
The FABRIC API is used via proxy objects that manage connections to the control framework.
:::


::: {.cell .code}

```python
print(f"FABRIC_ORCHESTRATOR_HOST: {os.environ['FABRIC_ORCHESTRATOR_HOST']}")
print(f"FABRIC_CREDMGR_HOST:      {os.environ['FABRIC_CREDMGR_HOST']}")
print(f"FABRIC_TOKEN_LOCATION:    {os.environ['FABRIC_TOKEN_LOCATION']}")


slice_manager = SliceManager(oc_host=os.environ['FABRIC_ORCHESTRATOR_HOST'], 
                             cm_host=os.environ['FABRIC_CREDMGR_HOST'] ,
                             project_name='ASU-CSE-534', 
                             scope='all')

# Initialize the slice manager
slice_manager.initialize()

```
:::

::: {.cell .markdown}
## Create Slice
Configure Slice Parameters
:::


::: {.cell .code}

```python
slice_name = 'fabric-ndn'
site = 'UCSD'
node1_name = 'ndn1'
node2_name = 'ndn2'
network_service_name='fwdr'
nic1_name = 'ndn1-nic'
nic2_name = 'ndn2-nic'
username = 'ubuntu'
image = 'default_ubuntu_20'
image_type = 'qcow2'
cores = 6
ram = 64
disk = 40
```
:::


::: {.cell .code}

```python
slice = fablib.new_slice(name=SLICENAME)

ndn1 = slice.add_node(name="ndn1", site=SITE, cores=6, ram=64, disk=100, image='default_ubuntu_20')
ndn2 = slice.add_node(name="ndn2", site=SITE, cores=6, ram=64, disk=100,image='default_ubuntu_20')
fwdr = slice.add_node(name="fwdr", site=SITE, cores=6, ram=64, disk=100, image='default_ubuntu_20')

ndn1_interface = ndn1.add_component(model="NIC_Basic", name="if1").get_interfaces()[0]
ndn2_interface = ndn2.add_component(model="NIC_Basic", name="if2").get_interfaces()[0]
fwdr_interface = fwdr.add_component(model="NIC_Basic", name="if1").get_interfaces()[0]
fwdr_interface2 = fwdr.add_component(model="NIC_Basic", name="if2").get_interfaces()[0]

net1 = slice.add_l2network(name='net1', type='L2Bridge', interfaces=[ndn1_interface, fwdr_interface])
net2 = slice.add_l2network(name='net2', type='L2Bridge', interfaces=[ndn2_interface, fwdr_interface2])

slice.submit()
```
:::

::: {.cell .markdown}
## Slice Status
When the slice is ready, the Slice state will be listed as StableOK
:::

::: {.cell .code}

```python
print(f"{slice}")
```
:::

::: {.cell .markdown}
## Get Login Details
To get the log in details for each node, run the following:
::: 

::: {.cell .code}

```python
for node in slice.get_nodes():
    print(f"{node}")
```
:::

::: {.cell .markdown}

## Gather ssh Details and Set Environment Variables

### variables specific to this slice
:::


::: {.cell .code}

```python
NDN1_IP = str(slice.get_node("ndn1").get_management_ip())
NDN1_USER =  str(slice.get_node("ndn1").get_username())
NDN1_if_FWDR = slice.get_node("ndn1").get_interfaces()[0].get_os_interface()

```
:::

::: {.cell .markdown}
## Delete Slice

:::

::: {.cell .code}
```python


return_status, result = slice_manager.delete(slice_object=slice)

print("Response Status {}".format(return_status))
print("Response received {}".format(result))


```

:::