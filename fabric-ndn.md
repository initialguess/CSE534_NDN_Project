::: {.cell .markdown}


##  Named Data Networking on Farbic

This experiment explores using NDN Data Plane Development on Fabric.  The DPDK was developed at NIST and designed to work on commodity hardware...

This experiment runs on the [FABRIC JupyterHub server](https://jupyter.fabric-testbed.net/). You will need an account on FABRIC, and you will need to have set up bastion keys, to run it.

It should take about 60-120 minutes to run this experiment.

:::

## Run my experiment

:::

::: {.cell .markdown}

### Set up bastion keys

In the next step, we will set up personal variables before attempting to reserve resources. It's important that you get the variables right *before* you import the `fablib` library, because `fablib` loads these once when imported and they can't be changed afterwards.

The important details to get right are the bastion username and the bastion key pair:

* project ID: in the FABRIC portal, click on User Profile > My Roles and Projects > and click on your project name. Then copy the Project ID string.
* bastion username: look for the string after "Bastion login" on [the SSH Keys page in the FABRIC portal](https://portal.fabric-testbed.net/experiments#sshKeys)
* bastion key pair: if you haven't yet set up bastion keys in your notebook environment (for example, in a previous session), complete the steps described in the [bastion keypair](https://github.com/fabric-testbed/jupyter-examples/blob/master//fabric_examples/fablib_api/bastion_setup.ipynb) notebook. Then, the key location you specify below should be the path to the private key file.


We also need to create an SSH config file, with settings for accessing the bastion gateway.

:::


::: {.cell .code}

```python
import os

# Specify your project ID
os.environ['FABRIC_PROJECT_ID']='XXXXXXXXXXXX'

# Set your Bastion username and private key
os.environ['FABRIC_BASTION_USERNAME']='ffund_0041777137'
os.environ['FABRIC_BASTION_KEY_LOCATION']=os.environ['HOME']+'/work/bastion-notebook'

# You can leave the rest on the default settings
# Set the keypair FABRIC will install in your slice. 
os.environ['FABRIC_SLICE_PRIVATE_KEY_FILE']=os.environ['HOME']+'/.ssh/id_rsa'
os.environ['FABRIC_SLICE_PUBLIC_KEY_FILE']=os.environ['HOME']+'/.ssh/id_rsa.pub'
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
%%bash -s "$FABRIC_BASTION_USERNAME" "$FABRIC_BASTION_KEY_LOCATION"

chmod 600 $2

export FABRIC_BASTION_SSH_CONFIG_FILE=${HOME}/.ssh/config

echo "Host bastion-*.fabric-testbed.net"    >  ${FABRIC_BASTION_SSH_CONFIG_FILE}
echo "     User $1"                         >> ${FABRIC_BASTION_SSH_CONFIG_FILE}
echo "     IdentityFile $2"                 >> ${FABRIC_BASTION_SSH_CONFIG_FILE}
echo "     StrictHostKeyChecking no"        >> ${FABRIC_BASTION_SSH_CONFIG_FILE}
echo "     UserKnownHostsFile /dev/null"    >> ${FABRIC_BASTION_SSH_CONFIG_FILE}

cat ${FABRIC_BASTION_SSH_CONFIG_FILE}
```
:::


::: {.cell .markdown}