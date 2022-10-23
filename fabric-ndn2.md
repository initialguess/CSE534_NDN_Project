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

### Set Tokens and Keys
Add your unique Fabric credentials that you just set up.

::: {.cell .code}

```
%%bash
export FABRIC_BASTION_USERNAME='gsinkins_0000025334' 
export FABRIC_PROJECT_ID='6ce270de-788d-4e07-8bae-3206860a6387'
export FABRIC_BASTION_PRIVATE_KEY_LOCATION=${HOME}/work/fabric_config/fabric_bastion_key
export FABRIC_TOKEN_FILE=${HOME}'/.tokens.json'
export FABRIC_SLICE_PRIVATE_KEY_FILE=${HOME}/work/fabric_config/slice_key
export FABRIC_SLICE_PUBLIC_KEY_FILE=${FABRIC_SLICE_PRIVATE_KEY_FILE}.pub
```

:::

::: {.cell .markdown} 
### Set Permissions

:::

::: {.cell .code}
```
%%bash
chmod 600 ${FABRIC_BASTION_PRIVATE_KEY_LOCATION}
chmod 600 ${FABRIC_SLICE_PRIVATE_KEY_FILE}

```
:::

::: {.cell .markdown} 
### Create the FABRIC config file

:::

::: {.cell .code}

```
%%bash
export FABRIC_RC_FILE=${HOME}'/work/fabric_config/fabric_rc'

cat <<EOF > ${FABRIC_RC_FILE}
export FABRIC_CREDMGR_HOST=cm.fabric-testbed.net
export FABRIC_ORCHESTRATOR_HOST=orchestrator.fabric-testbed.net

export FABRIC_PROJECT_ID=${FABRIC_PROJECT_ID}
export FABRIC_TOKEN_LOCATION=${FABRIC_TOKEN_FILE}

export FABRIC_BASTION_HOST=bastion-1.fabric-testbed.net
export FABRIC_BASTION_USERNAME=${FABRIC_BASTION_USERNAME}

export FABRIC_BASTION_KEY_LOCATION=${FABRIC_BASTION_PRIVATE_KEY_LOCATION}
#export FABRIC_BASTION_KEY_PASSPHRASE=

export FABRIC_SLICE_PRIVATE_KEY_FILE=${FABRIC_SLICE_PRIVATE_KEY_FILE}
export FABRIC_SLICE_PUBLIC_KEY_FILE=${FABRIC_SLICE_PUBLIC_KEY_FILE} 
#export FABRIC_SLICE_PRIVATE_KEY_PASSPHRASE=

export FABRIC_LOG_FILE=/tmp/fablib/fablib.log
export FABRIC_LOG_LEVEL=INFO 
EOF
```

:::

::: {.cell .markdown} 
### Create the SSH config file

:::

::: {.cell .code}

```
%%bash
export FABRIC_BASTION_SSH_CONFIG_FILE=${HOME}'/work/fabric_config/ssh_config'

cat <<EOF > ${FABRIC_BASTION_SSH_CONFIG_FILE}
UserKnownHostsFile /dev/null
StrictHostKeyChecking no
ServerAliveInterval 120 

Host bastion-?.fabric-testbed.net
     User ${FABRIC_BASTION_USERNAME}
     ForwardAgent yes
     Hostname %h
     IdentityFile ${FABRIC_BASTION_PRIVATE_KEY_LOCATION}
     IdentitiesOnly yes

Host * !bastion-?.fabric-testbed.net
     ProxyJump ${FABRIC_BASTION_USERNAME}@bastion-1.fabric-testbed.net:22
EOF
```

:::

### Using the variables set above, run the following bash commands
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
Import Fabric API from

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
                             project_name='all', 
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
node2_name = 'ndn22'
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


from fabrictestbed.slice_editor import ExperimentTopology, Capacities, ComponentType, ComponentModelType, ServiceType
# Create topology
t = ExperimentTopology()

# Add node
n1 = t.add_node(name=node1_name, site=site)

# Set capacities
cap = Capacities()
cap.set_fields(core=cores, ram=ram, disk=disk)

# Set Properties
n1.set_properties(capacities=cap, image_type=image_type, image_ref=image)

# Add node
n2 = t.add_node(name=node2_name, site=site)

# Set properties
n2.set_properties(capacities=cap, image_type=image_type, image_ref=image)

# Shared Cards
n1.add_component(model_type=ComponentModelType.SharedNIC_ConnectX_6, name=nic1_name)
n2.add_component(model_type=ComponentModelType.SharedNIC_ConnectX_6, name=nic2_name)

# L2Bridge Service
t.add_network_service(name=network_service_name, nstype=ServiceType.L2Bridge, interfaces=t.interface_list)

# Generate Slice Graph
slice_graph = t.serialize()

# Request slice from Orchestrator
return_status, slice_reservations = slice_manager.create(slice_name=slice_name, 
                                            slice_graph=slice_graph, 
                                            ssh_key=slice_public_key)

if return_status == Status.OK:
    slice_id = slice_reservations[0].get_slice_id()
    print("Submitted slice creation request. Slice ID: {}".format(slice_id))
else:
    print(f"Failure: {slice_reservations}")


```

::: {.cell .markdown}
## Get the Slice

:::

::: {.cell .code}

```python


import time
def wait_for_slice(slice,timeout=180,interval=10,progress=False):
    timeout_start = time.time()

    if progress: print("Waiting for slice .", end = '')
    while time.time() < timeout_start + timeout:
        return_status, slices = slice_manager.slices(excludes=[SliceState.Dead,SliceState.Closing])

        if return_status == Status.OK:
            slice = list(filter(lambda x: x.slice_name == slice_name, slices))[0]
            if slice.slice_state == "StableOK":
                if progress: print(" Slice state: {}".format(slice.slice_state))
                return slice
            if slice.slice_state == "Closing" or slice.slice_state == "Dead":
                if progress: print(" Slice state: {}".format(slice.slice_state))
                return slice    
        else:
            print(f"Failure: {slices}")
        
        if progress: print(".", end = '')
        time.sleep(interval)
    
    if time.time() >= timeout_start + timeout:
        if progress: print(" Timeout exceeded ({} sec). Slice: {} ({})".format(timeout,slice.slice_name,slice.slice_state))
        return slice    


return_status, slices = slice_manager.slices(excludes=[SliceState.Dead,SliceState.Closing])

if return_status == Status.OK:
    slice = list(filter(lambda x: x.slice_name == slice_name, slices))[0]
    slice = wait_for_slice(slice, progress=True)

print()
print("Slice Name : {}".format(slice.slice_name))
print("ID         : {}".format(slice.slice_id))
print("State      : {}".format(slice.slice_state))
print("Lease End  : {}".format(slice.lease_end))


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