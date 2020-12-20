# Пятая лабораторная работа

## Установка

```bash
git clone https://github.com/centosos/AdminLinux.git
cd 05_lvm
ansible-galaxy install -r requirements.yml
VAGRANT_EXPERIMENTAL="disks" vagrant up --provision

# Если не запустилось с первого раза:
vagrant halt
vagrant up --provision
```

## Задание

Что нужно сделать:

- Создать файловую систему на логическом томе;
- Смонтировать её;
- Создать файл, заполненный нулями на весь размер точки монтирования;
- Уменьшить файловую систему;
- Добавить несколько новых файлов и создать снимок;
- Удалить файлы и после монтирования снимка убедиться, что созданные нами файлы имеются на диске;
- Сделать слияние томов;
- Создать зеркало.

## Как работает

### 1. Создать файловую систему на логическом томе и смонтировать её

Для данной лабораторной работы был собран аналогичный предыдущену стенд - 5 виртуальных жёстких дисков по 2Гб.

Так же установим необходимый пакет командой:

```bash
$ sudo apt update && sudo apt install lvm2
Hit:1 http://security.debian.org/debian-security stretch/updates InRelease
Ign:2 http://deb.debian.org/debian stretch InRelease
Hit:3 http://deb.debian.org/debian stretch Release
Reading package lists... Done
Building dependency tree
Reading state information... Done
...
```

Проверим базовую конфигурацию командами:

```bash
$ lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0 19.8G  0 disk 
├─sda1   8:1    0 18.8G  0 part /
├─sda2   8:2    0    1K  0 part 
└─sda5   8:5    0 1021M  0 part [SWAP]
sdb      8:16   0    2G  0 disk 
sdc      8:32   0    2G  0 disk 
sdd      8:48   0    2G  0 disk 
sde      8:64   0    2G  0 disk 
sdf      8:80   0    2G  0 disk 

$ sudo lvmdiskscan
  /dev/sda1 [      18.80 GiB] 
  /dev/sda5 [    1021.00 MiB] 
  /dev/sdb  [       1.95 GiB] 
  /dev/sdc  [       1.95 GiB] 
  /dev/sdd  [       1.95 GiB] 
  /dev/sde  [       1.95 GiB] 
  /dev/sdf  [       1.95 GiB] 
  5 disks
  2 partitions
  0 LVM physical volume whole disks
  0 LVM physical volumes
```

Добавим диск b как физический том командой, проверим создание командами:

```bash
$ sudo pvcreate /dev/sdb
  Physical volume "/dev/sdb" successfully created.

$ sudo pvdisplay
  "/dev/sdb" is a new physical volume of "1.95 GiB"
  --- NEW Physical volume ---
  PV Name               /dev/sdb
  VG Name               
  PV Size               1.95 GiB
  Allocatable           NO
  PE Size               0   
  Total PE              0
  Free PE               0
  Allocated PE          0
  PV UUID               ljdRtP-8lDu-w2U5-1OPR-93QC-TWr6-EYdBm4


$ sudo pvs
  PV         VG Fmt  Attr PSize PFree
  /dev/sdb      lvm2 ---  1.95g 1.95g
```

Далее создадим виртуальную группу командой и проверим корректность создания командами

```bash
$ sudo vgcreate labgr /dev/sdb
  Volume group "labgr" successfully created

$ sudo vgdisplay -v labgr
  --- Volume group ---
  VG Name               labgr
  System ID             
  Format                lvm2
  Metadata Areas        1
  Metadata Sequence No  1
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                0
  Open LV               0
  Max PV                0
  Cur PV                1
  Act PV                1
  VG Size               1.95 GiB
  PE Size               4.00 MiB
  Total PE              499
  Alloc PE / Size       0 / 0   
  Free  PE / Size       499 / 1.95 GiB
  VG UUID               EWmUb3-cY5u-FdcJ-ADlB-WMrw-dpjn-cKA3HI
   
  --- Physical volumes ---
  PV Name               /dev/sdb     
  PV UUID               ljdRtP-8lDu-w2U5-1OPR-93QC-TWr6-EYdBm4
  PV Status             allocatable
  Total PE / Free PE    499 / 499


$ sudo vgs
  VG    #PV #LV #SN Attr   VSize VFree
  labgr   1   0   0 wz--n- 1.95g 1.95g
```

Повторим похожие действия для создания логической группы и проверяем:

```bash
$ sudo lvcreate -l+100%FREE -n first labgr
  Logical volume "first" created.

$ sudo lvdisplay
  --- Logical volume ---
  LV Path                /dev/labgr/first
  LV Name                first
  VG Name                labgr
  LV UUID                iqMWDl-QfTv-yhaS-C2Kj-v9uA-5oZG-TNXuaW
  LV Write Access        read/write
  LV Creation host, time stretch, 2020-12-20 15:07:29 +0000
  LV Status              available
  # open                 1
  LV Size                1.95 GiB
  Current LE             499
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     256
  Block device           254:0

$ sudo lvs
  LV    VG    Attr       LSize Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  first labgr -wi-a----- 1.95g                                                    
```

Создадим файловую систему и смонтируем её:

```bash
$ sudo mkfs.ext4 /dev/labgr/first
mke2fs 1.43.4 (31-Jan-2017)
Creating filesystem with 510976 4k blocks and 127744 inodes
Filesystem UUID: 23aba7b8-3788-486f-b6b2-3894e3082581
Superblock backups stored on blocks: 
	32768, 98304, 163840, 229376, 294912

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (8192 blocks): done
Writing superblocks and filesystem accounting information: done 

$ sudo mount /dev/labgr/first /mnt
$ sudo mount | grep labgr
/dev/mapper/labgr-first on /mnt type ext4 (rw,relatime,data=ordered)
```

### 2. Создать файл, заполенный нулями на весь размер точки монтирования

Для этого просто выполним команду, чтобы побайтово скопировать в файл 4500 чанков по 1М, после чего проверим состояние

```bash
$ sudo dd if=/dev/zero of=/mnt/mock.file bs=1M count=4500 status=progress
1999634432 bytes (2.0 GB, 1.9 GiB) copied, 2.00119 s, 999 MB/s
dd: error writing '/mnt/mock.file': No space left on device
1911+0 records in
1910+0 records out
2003595264 bytes (2.0 GB, 1.9 GiB) copied, 2.0115 s, 996 MB/s

$ df -h
Filesystem               Size  Used Avail Use% Mounted on
udev                     488M     0  488M   0% /dev
tmpfs                    100M  4.4M   96M   5% /run
/dev/sda1                 19G  1.1G   17G   7% /
tmpfs                    499M     0  499M   0% /dev/shm
tmpfs                    5.0M     0  5.0M   0% /run/lock
tmpfs                    499M     0  499M   0% /sys/fs/cgroup
tmpfs                    100M     0  100M   0% /run/user/1000
/dev/mapper/labgr-first  1.9G  1.9G     0 100% /mnt
```

### 3. Расширить vg, lv и файловую систему

Введём команды:

```bash
$ sudo pvcreate /dev/sdc
  Physical volume "/dev/sdc" successfully created.

$ sudo vgextend labgr /dev/sdc
  Volume group "labgr" successfully extended

$ sudo lvextend -l+100%FREE /dev/labgr/first
  Size of logical volume labgr/first changed from 1.95 GiB (499 extents) to 3.90 GiB (998 extents).
  Logical volume labgr/first successfully resized.

$ sudo lvdisplay
  --- Logical volume ---
  LV Path                /dev/labgr/first
  LV Name                first
  VG Name                labgr
  LV UUID                iqMWDl-QfTv-yhaS-C2Kj-v9uA-5oZG-TNXuaW
  LV Write Access        read/write
  LV Creation host, time stretch, 2020-12-20 15:07:29 +0000
  LV Status              available
  # open                 1
  LV Size                3.90 GiB
  Current LE             998
  Segments               2
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     256
  Block device           254:0

$ sudo lvs
  LV    VG    Attr       LSize Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  first labgr -wi-ao---- 3.90g                                                    

$ sudo df -h
Filesystem               Size  Used Avail Use% Mounted on
udev                     488M     0  488M   0% /dev
tmpfs                    100M  4.4M   96M   5% /run
/dev/sda1                 19G  1.1G   17G   7% /
tmpfs                    499M     0  499M   0% /dev/shm
tmpfs                    5.0M     0  5.0M   0% /run/lock
tmpfs                    499M     0  499M   0% /sys/fs/cgroup
tmpfs                    100M     0  100M   0% /run/user/1000
/dev/mapper/labgr-first  1.9G  1.9G     0 100% /mnt
```

Теперь произведём расширение файловой системы:

```bash
$ sudo resize2fs /dev/labgr/first
resize2fs 1.43.4 (31-Jan-2017)
Filesystem at /dev/labgr/first is mounted on /mnt; on-line resizing required
old_desc_blocks = 1, new_desc_blocks = 1
The filesystem on /dev/labgr/first is now 1021952 (4k) blocks long.

$ sudo df -h
Filesystem               Size  Used Avail Use% Mounted on
udev                     488M     0  488M   0% /dev
tmpfs                    100M  4.4M   96M   5% /run
/dev/sda1                 19G  1.1G   17G   7% /
tmpfs                    499M     0  499M   0% /dev/shm
tmpfs                    5.0M     0  5.0M   0% /run/lock
tmpfs                    499M     0  499M   0% /sys/fs/cgroup
tmpfs                    100M     0  100M   0% /run/user/1000
/dev/mapper/labgr-first  3.9G  1.9G  1.8G  52% /mnt
```

### 4. Уменьшить файловую систему

Для уменьшения ФС отмонтируем её, после чего пересоберём том и систему. При уменьшении размеров системы необходимо учитывать минимальное пространство, которое ей необходимо, чтобы не обрезать нужные файлы, поэтому был оставлен небольшой запас:

```bash
$ sudo umount /mnt
$ sudo fsck -fy /dev/labgr/first
fsck from util-linux 2.29.2
e2fsck 1.43.4 (31-Jan-2017)
Pass 1: Checking inodes, blocks, and sizes
Pass 2: Checking directory structure
Pass 3: Checking directory connectivity
Pass 4: Checking reference counts
Pass 5: Checking group summary information
/dev/mapper/labgr-first: 12/255488 files (0.0% non-contiguous), 515398/1021952 blocks

$ sudo resize2fs /dev/labgr/first 2100M
resize2fs 1.43.4 (31-Jan-2017)
resize2fs: New size smaller than minimum (966495)

$ sudo mount /dev/labgr/first /mnt
$ sudo df -h
Filesystem               Size  Used Avail Use% Mounted on
udev                     488M     0  488M   0% /dev
tmpfs                    100M  4.4M   96M   5% /run
/dev/sda1                 19G  1.1G   17G   7% /
tmpfs                    499M     0  499M   0% /dev/shm
tmpfs                    5.0M     0  5.0M   0% /run/lock
tmpfs                    499M     0  499M   0% /sys/fs/cgroup
tmpfs                    100M     0  100M   0% /run/user/1000
/dev/mapper/labgr-first  3.9G  1.9G  1.8G  52% /mnt
```

### 5. Создать несколько новых файлов и создать снимок

Создадим несколько файлов и сделаем снимок. Для этого выполним следующую последовательность команд:

```bash
$ sudo touch /mnt/fillerfile{1..5}
$ ls /mnt
fillerfile1  fillerfile2  fillerfile3  fillerfile4  fillerfile5  lost+found

$ sudo lvcreate -L 100M -s -n log_snapsh /dev/labgr/first
  Using default stripesize 64.00 KiB.
  Logical volume "log_snapsh" created.

$ sudo lvs
  LV         VG    Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  first      labgr owi-aos---   1.00g                                                    
  log_snapsh labgr swi-a-s--- 100.00m      first  0.00                                   

$ sudo lsblk
NAME                   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                      8:0    0 19.8G  0 disk 
├─sda1                   8:1    0 18.8G  0 part /
├─sda2                   8:2    0    1K  0 part 
└─sda5                   8:5    0 1021M  0 part [SWAP]
sdb                      8:16   0    5G  0 disk 
├─labgr-first-real     254:1    0    1G  0 lvm  
│ ├─labgr-first        254:0    0    1G  0 lvm  
│ └─labgr-log_snapsh   254:3    0    1G  0 lvm  
└─labgr-log_snapsh-cow 254:2    0  100M  0 lvm  
  └─labgr-log_snapsh   254:3    0    1G  0 lvm  
sdc                      8:32   0    5G  0 disk 
sdd                      8:48   0    5G  0 disk 
sde                      8:64   0    5G  0 disk 
sdf                      8:80   0    5G  0 disk 
```

Результат - в нашей vg создан снапшот, по которому можно будет откатить систему к состоянию на момент его создания:

### 6. Удалить файлы и после монтирования снимка убедиться, что созданные нами файлы присутствуют

Удалим файлы, после чего проверим есть ли удалённые файлы на снапшоте

```bash
$ sudo rm -f /mnt/fillerfile{1..3}
$ sudo mkdir /snapsh
$ sudo mount /dev/labgr/log_snapsh /snapsh
$ ls /snapsh
fillerfile1  fillerfile2  fillerfile3  fillerfile4  fillerfile5  lost+found

$ sudo umount /snapsh
```

### 7. Сделать слияние томов

Чтобы выполнить слияние томов необходимо сначала отмонтировать систему, после ввести команды

```bash
$ sudo umount /mnt
$ sudo lvconvert --merge /dev/labgr/log_snapsh
  Merging of volume labgr/log_snapsh started.
  first: Merged: 99.94%
  first: Merged: 100.00%

$ sudo mount /dev/labgr/first /mnt
$ ls /mnt
fillerfile1  fillerfile2  fillerfile3  fillerfile4  fillerfile5  lost+found
```

### 8. Сделать зеркало

Для этого понадобится добавить еще устройств в PV, их я заготовил заранее аналогичным образом.  После создадим VG и смонтируем LV с флагом того, что она монтируется с созданием зеркала:

```bash
$ sudo vgcreate labgrMirror /dev/sd{d,e}
  Physical volume "/dev/sdd" successfully created.
  Physical volume "/dev/sde" successfully created.
  Volume group "labgrMirror" successfully created

$ sudo lvcreate -l+100%FREE -m1 -n fMirror labgrMirror
  Logical volume "fMirror" created.
$ sudo lvs
  LV      VG          Attr       LSize Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  first   labgr       -wi-ao---- 1.00g                                                    
  fMirror labgrMirror rwi-a-r--- 4.99g                                    100.00          
```

Как видно из скрина, зеркало создано и синхронизировано.
