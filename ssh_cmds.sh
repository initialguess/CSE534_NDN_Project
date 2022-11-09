-----------------  ---------------------------------------------------------------------------------------------------------------------------
ID                 d2e52fee-0e16-4580-9ad0-f2ad00f23bb0
Name               ndn1
Cores              6
RAM                64
Disk               100
Image              default_ubuntu_20
Image Type         qcow2
Host               ucsd-w2.fabric-testbed.net
Site               UCSD
Management IP      132.249.252.189
Reservation State  Active
Error Message
SSH Command        ssh -i /home/fabric/work/fabric_config/slice_key -J gsinkins_0000025334@bastion-1.fabric-testbed.net ubuntu@132.249.252.189
-----------------  ---------------------------------------------------------------------------------------------------------------------------
-----------------  ---------------------------------------------------------------------------------------------------------------------------
ID                 ce0daa04-a223-4dc6-bdd6-e140133af29d
Name               ndn2
Cores              6
RAM                64
Disk               100
Image              default_ubuntu_20
Image Type         qcow2
Host               ucsd-w2.fabric-testbed.net
Site               UCSD
Management IP      132.249.252.187
Reservation State  Active
Error Message
SSH Command        ssh -i /home/fabric/work/fabric_config/slice_key -J gsinkins_0000025334@bastion-1.fabric-testbed.net ubuntu@132.249.252.187
-----------------  ---------------------------------------------------------------------------------------------------------------------------
-----------------  ---------------------------------------------------------------------------------------------------------------------------
ID                 f49c8fc1-8bec-4129-a5f2-33f7855a67a8
Name               fwdr
Cores              6
RAM                64
Disk               100
Image              default_ubuntu_20
Image Type         qcow2
Host               ucsd-w2.fabric-testbed.net
Site               UCSD
Management IP      132.249.252.183
Reservation State  Active
Error Message
SSH Command        ssh -i /home/fabric/work/fabric_config/slice_key -J gsinkins_0000025334@bastion-1.fabric-testbed.net ubuntu@132.249.252.183
-----------------  ---------------------------------------------------------------------------------------------------------------------------


%%bash -s "$FABRIC_SLICE_PRIVATE_KEY_FILE" "$FABRIC_BASTION_USERNAME" "$FABRIC_BASTION_HOST" "$ROMEO_USER" "$ROMEO_IP" "$ROMEO_IFACE_R" 
ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $FABRIC_SLICE_PRIVATE_KEY_FILE -J $2@$3 $4@$5


ssh -F fabric_config/ssh_config -i fabric_config/slice_key ubuntu@132.249.252.181