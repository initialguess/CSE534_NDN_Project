# NDN on FABRIC

Achieving high-speed Named Data Networking (NDN) forwarding on commodity hardware has now been shown to be possible. Meanwhile, the roll out of FABRIC, a national research infrastructure equipped with large amounts of compute and storage and interconnected by high speed optical links, makes it possible to easily recreate, and reproduce high speed NDN forwarding on commodity hardware to incrementally improve upon and continue innovation of the data structures and algorithms that make it possible. This project creates a notebook to facilitate this further development. More background in our [report](https://github.com/initialguess/fabric-ndn/blob/main/NDN%20on%20FABRIC.pdf).

## Usage

To use this notebook on FABRIC:

* clone the repository: git clone https://github.com/initialguess/fabric-ndn
* navigate to the repo directory: cd fabric-ndn
* make the notebooks: make notebooks
* open the fabric-ndn notebook, follow the steps to conifgure your environment, the proceed with the project
* *fabric-ndn.ipynb* contains all of the necessary steps to achieve each component offered by the NDN-DPDK package on FABRIC
## References

[NDN-DPDK GitHub](https://github.com/usnistgov/ndn-dpdk)

[DPDK GitHub](https://github.com/DPDK/dpdk)

[NVIDIA MLX OFED](https://docs.nvidia.com/networking/display/MLNXOFEDv531001/Downloading+Mellanox+OFED)

