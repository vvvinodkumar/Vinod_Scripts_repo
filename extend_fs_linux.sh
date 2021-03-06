###This script is used to extend the filesystem in RHEL 3,4,5,6 servers.
[root@rhel5_64bit ~]# cat extend_fs_linux.sh
#!/bin/bash
############################################################################
#                                                                          #
#                                   STARWOOD HOTELS                        #
#                                                                          #
#      FILE CODE  : extend_fs_linux.sh                                     #
#                                                                          #
#      DESCRIPTION: interactive script to extend linux lvm filesystem      #
#                                                                          #
#  DATE                  Developed by                                      #
#  ========            =============                                       #
#10July                 V.V.Vinod Kumar                                    #
############################################################################
echo -e "\n\t\t\t\e[1;32;40m ***** This script is used to extend linux lvm filesystem - online ****\t\033[0m"
if [[ $EUID -ne 0 ]]; then
  echo -e "\n\n\e[1;31m WARNING.... You must be a root user to execute this script... Please switch to root user and execute the script again... \e[0m " 2>&1
  exit 1
else
h_name=`uname -n`
rhel_vers=`lsb_release -r |awk '{ print $2 }' | cut -d. -f1`
echo -n -e  "\n\nPlease enter the \e[1;31m filesystem name\e[0m to extend the filesystem: " ;read fs_name
#varia=`df -h -P -T $fs_name | tail -n1|sed "s/^ *//;s/ *$//;s/ \{1,\}/ /g"`
df -h -P -T $fs_name | tail -n1 >/var/tmp/filelist.txt
#set stdin to the file listing we jsut made
#exec 0<filelist
#ifs_old=$IFS

#Resize commands changes for legacy and new versions of Redhat linux

if  [[ $rhel_vers = 6 || $rhel_vers = 5 ]]
then
RESIZE=resize2fs
elif [[ $rhel_vers = 3 || $rhel_vers = 4 ]]
then
RESIZE=ext2online
fi

while IFS=" " read arg1 arg2 arg3 arg4 arg5 arg6 arg7
do
volume_info=$arg1
fs_type=$arg2
total_size=$arg3
used_size=$arg4
avail_size=$arg5
per_value=$arg6
fsys_name=$arg7
vg_name=`echo $volume_info | awk -F"/" '{ print $4 }' | awk -F"-" '{ print $1 }'`
lv_name=`echo $volume_info | awk -F"/" '{ print $4 }' | awk -F"-" '{ print $2}'`
echo -e "========================================================================="
echo -e "\e[1;32;40mBelow is the information for the filesystem \e[1;31m$fsys_name \e[0m\e[1;32;40myou entered\033[0m"
echo -e "=========================================================================\n"
echo -e "Filesystem  \"$fsys_name\" Properties"
echo -e "\n$fsys_name    vg name\t\t: $vg_name"
echo -e "$fsys_name    lv name\t\t: $lv_name"
echo -e "$fsys_name   vol info\t\t: $volume_info"
echo -e "$fsys_name    fs type\t\t: $fs_type"
echo -e "$fsys_name total size\t\t: $total_size"
echo -e "$fsys_name  used size\t\t: $used_size"
echo -e "$fsys_name avail size\t\t: $avail_size"
echo -e "$fsys_name usage in %\t\t: $per_value"
echo -e "\n\e[1;32;40mVolume Group size information\033[0m\n"
#vg_tot=`vgs | grep -i $vg_name|awk '{print $6}'`
#vg_free=`vgs | grep -i $vg_name|awk '{print $7}'`
#vg_tot_kb=`vgs --units k| grep -i $vg_name|awk '{print $6}'|cut -d. -f1`

vg_tot=`vgdisplay vg00 |grep -i "VG Size"|awk '{ print $3,$4 }'`
vg_free=`vgdisplay vg00 |grep -i "Free  PE"|awk '{ print $7,$8 }'`
vg_tot_kb=`vgdisplay vg00 --units k|grep -i "VG Size"|awk '{ print $3 }'|cut -d. -f1`
vg_free_kb=`vgdisplay vg00 --units k|grep -i "Free  PE"|awk '{ print $7 }'|cut -d. -f1`

#echo "total vg space in KB   :$vg_tot_kb"
#echo "Free space in vg in KB :$vg_free_kb"
vg_free_kb=`vgs --units k| grep -i $vg_name|awk '{print $7}'|cut -d. -f1`
echo -e "$fsys_name  VG name is  \"$vg_name\" \n"
echo -e "\n$vg_name total size \t\t: $vg_tot ( $vg_tot_kb KB )"
echo -e "$vg_name free space \t\t: $vg_free ( $vg_free_kb KB ) \n"
done</var/tmp/filelist.txt

#IFS=$ifs_old
echo -n -e  "\e[1;32;40mDo you want to extend the filesystem \e[1;31m$fsys_name \e[0m\e[1;32;40mnow .....press [yes/no]\033[0m: " ;read in_put
#typeset -l in_put
#typeset -u type
in_put=$(echo $in_put | tr '[A-Z]' '[a-z]')
#type=$(echo $type | tr '[a-z]' '[A-Z]')
if [ $in_put = yes ]
then
echo -n -e  "Please enter the size in MB/GB ... \e[1;32;40mPress [MB/GB] \033[0m: "; read type

type=$(echo $type | tr '[a-z]' '[A-Z]')

if [ $type = GB ]
then
echo -n -e  "Please enter the size to be extended(only in numbers) in terms of $type\e[0m: ";read exten_size
echo "Size to be extended is : +$exten_size $type"
req_size_kbs=$(expr $exten_size \* 1024 \* 1024)
req_size_mb=$(expr $exten_size \* 1024)
#echo "Size to be extended is : +$req_size_kbs KB"
echo "Size to be extended is : +$req_size_mb MB ( +$req_size_kbs KB )"
fi


if [ $type = MB ]
then
echo -n -e  "Please enter the size to be extended(only in numbers) in terms of $type\e[0m: ";read req_size_mb
req_size_kbs=$(expr $req_size_mb \* 1024)
echo "Size to be extended is : +$req_size_mb $type ( +$req_size_kbs KB )"
#echo "Size to be extended is : +$req_size_kbs KB"
fi

MB=M
if [ $req_size_kbs -gt $vg_free_kb ]
then
echo -e "\e[1;31mRequired space is not available in VG... Please add a sufficient space to VG to extend...\033[0m\n"
echo -n -e  "\e[1;32;40mDo you have a disk/lun to extend the VG $vg_name now ....press [yes/no]\033[0m:";read in_put1
if [ $in_put1 = yes ]
then
echo -n " Please enter the disk partition name as ex: /dev/sdb1 etc to extend VG size::" ;read disk_info
echo -e "\nBelow commands will be executed on your confirmation ....."
echo "******************************************"
echo "   pvcreate $disk_info"
echo "   vgextend $vg_name $disk_info"
echo "   lvextend -L +$req_size_mb$MB /dev/$vg_name/$lv_name"
echo "   $RESIZE /dev/$vg_name/$lv_name"
echo -n -e  "\e[1;32;40mDo you want to proceed with above commands \e[1;31m$fsys_name \e[0m\e[1;32;40mnow .....press [yes/no]\033[0m: " ;read in_put3

if [ $in_put3 = yes ]
then
echo -n -e  "\e[1;32;40m Are you sure .....press [yes/no]\033[0m: " ;read in_put4
if [ $in_put4 = yes ]
then

echo -e "\n\e[1;31m==================================="
echo -e "\t\tBEFORE EXTENSION"
echo -e "===================================\033[0m"

echo -e "\e[1;32;40m"
df -h $fs_name
echo -e "\033[0m"
echo -e "\e[1;31m===================================\033[0m\n"

pvcreate $disk_info
vgextend $vg_name $disk_info
lvextend -L +$req_size_mb$MB /dev/$vg_name/$lv_name
$RESIZE /dev/$vg_name/$lv_name
echo -e "\n\e[1;31m==================================="
echo -e "\t\tAFTER EXTENSION"
echo -e "===================================\033[0m"

echo -e "\e[1;32;40m"
df -h $fs_name
echo -e "\033[0m"
echo -e "\e[1;31m===================================\033[0m\n"


fi
fi

fi
else
echo -e "\e[1;32;40mRequired space is  available in the VG $vg_name... Therefore proceeding with filesystem extension now...\033[0m\n"
echo "   lvextend -L +$req_size_mb$MB /dev/$vg_name/$lv_name"
echo "   $RESIZE /dev/$vg_name/$lv_name"

echo -n -e  "\e[1;32;40mDo you want to proceed with above commands \e[1;31m$fsys_name \e[0m\e[1;32;40mnow .....press [yes/no]\033[0m: " ;read in_put3

if [ $in_put3 = yes ]
then
echo -n -e  "\e[1;32;40m Are you sure .....press [yes/no]\033[0m: " ;read in_put4
if [ $in_put4 = yes ]
then
echo -e "\n\e[1;31m==================================="
echo -e "\t\tBEFORE EXTENSION"
echo -e "===================================\033[0m"

echo -e "\e[1;32;40m"
df -h $fs_name
echo -e "\033[0m"
echo -e "\e[1;31m===================================\033[0m\n"
lvextend -L +$req_size_mb$MB /dev/$vg_name/$lv_name
$RESIZE /dev/$vg_name/$lv_name
echo -e "\n\e[1;31m==================================="
echo -e "\t\tAFTER EXTENSION"
echo -e "===================================\033[0m"

echo -e "\e[1;32;40m"
df -h $fs_name
echo -e "\033[0m"
echo -e "\e[1;31m===================================\033[0m\n"
fi
fi

fi

fi
fi

[root@rhel5_64bit ~]#
