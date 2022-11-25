::: {.cell .markdown}

#  Named Data Networking on Fabric

This experiment explores using NDN Data Plane Development on Fabric.  The DPDK was developed at NIST and designed to work on commodity hardware...

This experiment runs on the [FABRIC JupyterHub server](https://jupyter.fabric-testbed.net/). You will need an account on FABRIC, and you will need to have set up bastion keys, to run it.

To set up your keys, open this [notebook to configure your environment](fabric-ndn/configure_environment.ipynb).  After completeing this step, return here to run the project.


This project should take about 60-120 minutes to run.



### Reserve resources
TODO: Determine the best sites, list the suggested sites for the project

:::

::: {.cell .code}

```python
SLICENAME='fabric-ndn'
SITE1='UCSD'
SITE2='SALT'
```

:::

::: {.cell .markdown}
Now we are ready to import fablib! And we'll use it to see what resources are available at FABRIC sites.
:::


::: {.cell .code}

```python
import json
import traceback
from fabrictestbed_extensions.fablib.fablib import fablib
```
:::

::: {.cell .code}

```python
try:
    slice = fablib.new_slice(SLICENAME)

    # ndn1
    ndn1 = slice.add_node(name="ndn1", site=SITE1, cores=6, ram=128, disk=100, image='default_ubuntu_20')
    ndn1_interface = ndn1.add_component(model="NIC_Basic", name='nic').get_interfaces()[0]

    # ndn2 (will eventually be on a separate site)
    ndn2 = slice.add_node(name="ndn2", site=SITE2, cores=6, ram=128, disk=100,image='default_ubuntu_20')
    ndn2_interface = ndn2.add_component(model="NIC_Basic", name='nic').get_interfaces()[0]

    # Forwarder
    fwdr = slice.add_node(name="fwdr", site=SITE1, cores=6, ram=128, disk=100, image='default_ubuntu_20')
    fwdr_if1 = fwdr.add_component(model="NIC_Basic", name='if1').get_interfaces()[0]
    fwdr_if2 = fwdr.add_component(model="NIC_Basic", name='if2').get_interfaces()[0]

    # Networks
    net1 = slice.add_l3network(name='net1', type='L2Bridge', interfaces=[ndn1_interface,fwdr_if1])
    net2 = slice.add_l3network(name='net2', type='L2Bridge', interfaces=[ndn2_interface,fwdr_if2])

    slice.submit()

except Exception as e:
    print(f"Exception: {e}")
```
:::

::: {.cell .markdown}
## Slice Status
When the slice is ready, the Slice state will be listed as StableOK; be patient this can take some time.  If a Management IP is not listed for the slice, it means the site was busy, and you need to now retrive the IP before proceeding.
:::

::: {.cell .code}

```python
try:
    # Ensure slice details are retrieved
    slice = fablib.get_slice(SLICENAME)

    # Print the node details
    for node in slice.get_nodes():
        print(f"{node}")
except Exception as e:
    print(f"Exception: {e}")
```
:::


::: {.cell .markdown}

## Delete slice
When you are finished, delete your slice to free resources for other experimenters.

:::


::: {.cell .code}

```python
fablib.delete_slice(SLICENAME)
```

:::