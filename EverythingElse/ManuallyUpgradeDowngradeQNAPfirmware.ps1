<# 
Manually Upgrade/Downgrade firmware by SSH

NAS Model Number
QNAP TS-873-8G

#>

# 1. Upload the firmware img file to Public folder  by File station.
#Here I take TS-X53A_20190704-4.3.6.0993.img as example

#2. SSH access to the NAS

# 3. Run
ln -sf /mnt/HDA_ROOT/update /mnt/update

# 4.Run
/etc/init.d/update.sh /share/Public/TS-X53A_20190704-4.3.6.0993.img
 
# 5.Run
reboot -r


<#
Example Output
[~] # ln -sf /mnt/HDA_ROOT/update /mnt/update
[~] # /etc/init.d/update.sh /share/Public/TS-X53A_20190704-4.3.6.0993.img
cksum=2235270506
Check RAM space available for FW update: OK.
Using 120-bit encryption - (QNAPNASVERSION4)

#>
