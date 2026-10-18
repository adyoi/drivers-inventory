# Shared definitions for driver inventory generators.
# Dot-source this file from gen_readme.ps1 and gen_docs.ps1.

$script:cats = @(
  @{ Key='acpi';  Title='ACPI & Firmware'; Short='ACPI';      Desc='Driver ACPI power management, thermal, ACPI event handlers, platform firmware, dan device enumeration pada level firmware.' },
  @{ Key='kernel'; Title='Kernel & Core System'; Short='Kernel';Desc='Lapisan inti kernel: RPC, PCI bus, console driver, volume/mount manager, crash dump, partition manager, dan runtime boot.' },
  @{ Key='crypto'; Title='Kriptografi & TPM'; Short='Kripto';Desc='Crypto Next Generation (CNG), kernel crypto package, TPM, AES/RSA/SHA, dan key storage provider.' },
  @{ Key='fs';     Title='Filesystems'; Short='Filesystem';  Desc='Driver sistem file: NTFS, ReFS, FAT, exFAT, UDF, CDFS, CLFS, dan recogniser filesystem boot.' },
  @{ Key='fsflt';  Title='Filesystem Filter'; Short='FS Filter'; Desc='Filter minifilter: EFS, WOF, luafv AppX, BitLocker, network redirector, cloud files, dan filter I/O.' },
  @{ Key='store';  Title='Storage Controllers & Disk'; Short='Storage'; Desc='Storage port driver, disk device, partition manager, dan kontroler RAID/SAS/SATA/SCSI (Intel, AMD, LSI, Broadcom, Chelsio, Marvell, nvme, dsb.).' },
  @{ Key='net';    Title='Network Stack'; Short='Jaringan';   Desc='TCP/IP, NDIS, Winsock, NetBIOS, IPNAT, WFP firewall, network virtualization, Bluetooth port, dan protocol jaringan lain.' },
  @{ Key='usb';    Title='USB Controllers'; Short='USB';       Desc='USB host controller drivers (OHCI, UHCI, EHCI, XHCI), hub, port driver, device support, dan USB function.' },
  @{ Key='gfx';    Title='Grafis & Display'; Short='Grafis';   Desc='DirectX Graphics Kernel (DXGK), display management, GPU vendor drivers (Intel/NVIDIA), display port.' },
  @{ Key='audio';  Title='Audio & Multimedia'; Short='Audio';  Desc='PortCls audio class driver, High Definition Audio bus/function driver, DRM, dan multimedia streaming.' },
  @{ Key='bth';    Title='Bluetooth'; Short='Bluetooth';       Desc='Driver radio Bluetooth: A2DP, hands-free, RFCOMM, HID enumerator, LE transport, dan protocol stack.' },
  @{ Key='input';  Title='Input, HID & Human Interface'; Short='Input & HID'; Desc='Keyboard, mouse, touchpad, touchscreen, HID class drivers, GPIO button, serial input, dan joystick support.' },
  @{ Key='sec';    Title='Keamanan'; Short='Keamanan';        Desc='Windows Defender (MsSense), WFP callouts, AppID, AppLocker, BitLocker filter, dan driver keamanan kernel.' },
  @{ Key='vm';     Title='Virtualisasi & Hyper-V'; Short='Virtualisasi';     Desc='Hyper-V hypervisor, VMBus, synthetic devices, virtual storage, virtual switch, dan VM integration.' },
  @{ Key='wf';     Title='Windows Driver Framework'; Short='WDF';Desc='WDF (Windows Driver Framework) runtime dan loader, KMDF/LMDF support, USB helper, dan class extension drivers.' },
  @{ Key='other';  Title='Lain-lain / Vendor Ketiga'; Short='Lain-lain'; Desc='Driver vendor tertentu, tool diagnostik, dan file non-SYS di folder drivers.' }
)

# Rules ordered: most specific first. PowerShell -match is case-insensitive.
$script:rules = @(
  @{ Key='bth';   P='^bluetooth|^microsoft.*bluetooth|^bth|^bta|^btfp|^btflt|^rfcomm|^bluet' },
  @{ Key='usb';   P='^usb|^ucm|^ucx|^udecx|^ucpd|^ufx|^uasp|^winusb|^usb8023|^mausb|^tsusb' },
  @{ Key='gfx';   P='^dxg|^igdkmd|^vid\.|^videoprt|^indirect|^hsp\.|^cea\.|^cea' },
  @{ Key='audio'; P='^acx01000|^portcls|^drmk|^hdaud|^hdudio|^mstee|^qwavedrv|^ksthunk|^kst\.|^ksld|^mmcss|^mskssrv|^mspc|^mspq|^streaming|^usbaudio|^audio|^stream\.sys' },
  @{ Key='input'; P='^kbd|^mou|^hid|^i8042|^buttonconv|^apfiltr|^terminpt|^teedriver|^xbox|^xinput|^kbldfltr|^wacom|^parport|^par1|^serenum|^serial|^sermouse|^sfloppy|^game|^joystick|^mtconfig|^monitor|^hidbth|^mshid|^mshwnclx|^hyperkbd|^vhf|^winaccel|^bcmfn2|^circlass|^cir|^bttflt|^hiddrv' },
  @{ Key='vm';    P='^vmbus|^vmbkm|^vmg|^vmgenc|^vmgid|^vms3|^vmstor|^vmswi|^vmsvc|^vmsvce|^vpci|^winhv|^winhvr|^vhdmp|^vhdparser|^pvhd|^dmvsc|^vpciv|^hyper|^hv|^vmsproxy|^rdp' },
  @{ Key='wf';    P='^wdf01000|^wdfldr|^ksthunk|^kst\.|^spbcx|^msgpio|^msgpiowin32|^msgpioclx|^hidspicx|^urscx|^mbbcx|^ucx01000|^ucmucsi|^ucp|^ucx0|^ufx|^udec|^wdmcomp|^wud' },
  @{ Key='sec';   P='^wdb|^wdn|^wdde|^wdfilt|^mssec|^msseccore|^peauth|^bindflt|^verifier|^kerb3961|^tbs\.|^ksec|^cng\.|^cnghw|^devauthe|^wfp|^fwp|^appid|^applocker|^appv|^proc|^proclaunch|^wdag|^mssecl|^werkern|^werke|^bam|^scfilter|^uev|^windowstrusted|^wtd' },
  @{ Key='store'; P='^stor|^disk|^nvme|^nvstor|^nvraid|^sbp2|^sdb|^sdport|^sdstor|^scsiport|^atapi|^ataport|^partmgr|^spaceport|^spaces|^intel|^lsi|^mega|^percsas|^smartsam|^stex|^arcsas|^chel|^cht4|^marv|^broad|^qlog|^qla|^mcd\.|^mpi3|^mvumis|^sisraid|^hpsamd|^diskdump|^dump|^3ware|^adp|^apple|^classpnp|^ehstor|^fdc|^lun|^nvdimm|^st_accel|^vst|^vsmraid|^itsas|^cdrom|^mlx|^msiscsi' },
  @{ Key='fs';    P='^ntfs|^exfat|^fastfat|^udfs|^cdfs|^clfs|^refs|^refsv1|^cimfs|^fs_rec|^fse\.|^kernelfs|^ext|^ramdisk|^ramparser|^flpydisk|^fat|^tape|^unionfs|^wim|^wimmount' },
  @{ Key='fsflt'; P='^fltmgr|^luafv|^wof|^filecrypt|^fileinfo|^filetrace|^flpydisk|^fvevol|^csc\.|^mrx|^bowser|^netbios|^cldflt|^wcifs|^windp|^storqosflt|^storufs|^mup|^dfs|^dfsc|^rdbss|^srv2|^srvnet|^bfs|^ahcache|^fsdep|^rdyboost|^dmpusb|^wpdupfltr|^smc|^appv' },
  @{ Key='net';   P='^tcpip|^netio|^ndis|^ndiscap|^ndistapi|^ndisuio|^ndisv|^ndiswan|^ndproxy|^ndu|^netadapter|^netbt|^netvsc|^nwifi|^wifi|^wdi|^idmwfp|^ipflt|^ipnat|^ipt\.|^ipt\b|^wanarp|^bridge|^nsiproxy|^npcap|^rndis|^rt|^evb|^asyncmac|^agilevpn|^afunix|^afd\.|^afd\b|^lltd|^rspndr|^rmcast|^mpsdrv|^iphtt|^routep|^rhproxy|^l2bridge|^l1vhl|^hnswfp|^mslldp|^smbdirect|^ztdns|^p9rdr|^pacer|^ppp|^ras|^rasacd|^rasl2tp|^raspppoe|^raspptp|^rassstp|^wfplwfs|^winmad|^winverbs|^winnat|^ws2ifsl|^http\.|^htt|^b57|^mlx|^ndfltr|^ndk|^modem|^kdnic|^knet|^ibbus|^vfp|^vwifi|^tun|^tunnel|^msquic|^pkt|^wintun|^bxv' },
  @{ Key='acpi';  P='^acpi|^acpiex|^acpitime|^acpdev|^acx01000|^hwpolicy|^mssmbios|^wmiacpi|^buttonconverter|^amdgpio|^amdi2c|^iagpio|^iai2c|^iaLPSS|^intcdaud|^iaStor|^apfiltr|^amdwps|^battc|^AMD|^amd' },
  @{ Key='kernel';P='^msrpc|^msisadrv|^pcw|^pdc|^pci\.|^pcip|^pciide|^pciidex|^isapnp|^condrv|^volmgr|^volsnap|^mountmgr|^volume\.|^null\.|^msfs|^npfs|^beep|^crashdmp|^dmvsc|^errdev|^dam\.|^passthruparser|^dumpar|^um\.|^ums\.|^partmgr|^npsvctrig|^werkernel|^smc|^smclib|^watchdog|^dbg|^devau|^devauthe|^exec|^iorate|^ipmidrv|^passthru|^pnp|^pnpmem|^pmem|^portcfg|^pcmcia|^pvsc|^scsiport|^sd\.|^sdport|^sdstor|^sercx|^serial|^serenu|^sermou|^sdbus|^space|^spacepar|^spaceport|^spb|^srv|^srvnet|^stex|^tape|^tdi|^tdx|^vdrvroot|^vid|^videoprt|^wpp|^xboxgip|^xinputhid|^ztdns|^loop\.|^loop|^rootmdm|^clipsp|^1394|^kmpdc|^glob|^st_accel|^tm\.sys|^lx|^ks\.sys|^ndk|^ntosext|^smb|^vfp|^wmilib' },
  @{ Key='crypto';P='^cng\.|^ksec|^ksecdd|^ksecpkg|^tbs\.|^kerb3961|^cmimcext|^cnghw|^msseccore|^hwpolicy|^tpm\.|^tbs\b' },
  @{ Key='other'; P='.*' }
)

$script:deep = @(
  @{ N='acpi.sys';       T='ACPI Power Management';       B='Driver ACPI utama: power state S0-S5, thermal zones, wake alarms, device enumeration, dan ACPI _INI/_STA methods. Wajib ada untuk boot; corrupt bisa menyebabkan BSOD IRQL_NOT_LESS_OR_EQUAL atau ACPI_BIOS_ERROR.' },
  @{ N='cng.sys';        T='Crypto Next Generation';      B='Implementasi kernel CNG: AES, SHA-2/3, RSA, ECC, HMAC. Semua enkripsi modern (BitLocker, TLS, SMB) melewati cng.sys. Salah satu driver paling sering dimuat proses keamanan.' },
  @{ N='ndis.sys';       T='NDIS Wrapper';                B='Network Driver Interface Specification wrapper: antarmuka antara driver jaringan (miniport) dan protocol stack (tcpip.sys). Semua network adapter driver melewati ndis.sys; sering jadi target hooking malware.' },
  @{ N='tcpip.sys';      T='TCP/IP Protocol Stack';       B='Implementasi TCP/IP kernel: IPv4/IPv6, UDP, ICMP, routing table, socket buffer. Menerima paket dari ndis.sys lalu memproses. Error sering muncul sebagai TCP checksum error atau connection timeout.' },
  @{ N='ntfs.sys';       T='NTFS Filesystem Driver';      B='Driver NTFS: MFT read/write, cluster mapping, journaling, kompresi, EFS. Driver filesystem paling penting untuk boot. Corruption bisa menyebabkan STOP 0x000000ED (UNMOUNTABLE_BOOT_VOLUME).' },
  @{ N='fltmgr.sys';     T='Filter Manager';              B='Framework untuk minifilter drivers: menerima I/O file operations, mendistribusikan ke registered minifilters (luafv, wcifs, windp, filecrypt). Titik penting untuk filesystem filter debugging.' },
  @{ N='dxgkrnl.sys';    T='DirectX Graphics Kernel';     B='DXGK: interface antara user-mode (D3D, OpenGL, Vulkan) dan GPU hardware. GPU scheduling, memory allocation, mode setting, display ports. Kunci untuk gaming, rendering, multi-monitor.' },
  @{ N='usbhub.sys';     T='USB Hub Driver';              B='Mengelola hubungan parent-child antar USB devices, port status changes, interrupt/isochronous transfers. Jika gagal, USB devices tidak terdeteksi.' },
  @{ N='pci.sys';        T='PCI Bus Driver';              B='Enumerates semua PCI/PCIe devices, assigns IRQ/resources, memuat child drivers. Salah satu driver pertama saat boot. BSOD di fase ini sering terkait acpi.sys.' },
  @{ N='storport.sys';   T='Storage Port Driver';         B='Interface generik antara storage controller drivers dan kernel I/O manager. Semua storage miniport (storahci, stornvme) melewati storport.' },
  @{ N='volsnap.sys';    T='Volume Shadow Copy';          B='Snapshot NTFS untuk backup, System Restore, VSS. Read-only point-in-time copies untuk Windows Backup. Wajib untuk System Restore.' },
  @{ N='wdf01000.sys';   T='Kernel Mode Driver Framework';B='WDF runtime: abstraksi untuk kernel-mode driver. Driver WDF bergantung pada file ini. Queue management, power management, synchronization.' },
  @{ N='tpm.sys';        T='Trusted Platform Module';    B='Interface antara Windows Measured Boot, BitLocker, dan TPM chip. PCR, sealing/unsealing keys, measured launch environment. Kunci untuk Secure Boot.' },
  @{ N='WdFilter.sys';   T='Windows Defender Filter';     B='Windows Defender minifilter: memindai file real-time protection. Berhubungan dengan fltMgr.sys. Sering satu-satunya driver terlihat di Procexp saat Defender scanning.' },
  @{ N='vmbus.sys';      T='Hyper-V VMBus';               B='Protokol komunikasi antara parent partition (hypervisor) dan guest VM untuk paravirtualized drivers. Kritis untuk Hyper-V integration services.' },
  @{ N='hvsocket.sys';   T='Hyper-V Socket';              B='Komunikasi antar VM menggunakan AF_HYPERV. Digunakan oleh PowerShell Direct, HVCI, container networking.' }
)

function Get-Cat {
    param([string]$Name)
    foreach ($r in $script:rules) { if ($Name -match $r.P) { return $r.Key } }
    return 'other'
}

function Clean-Desc {
    param([string]$D, [string]$Name)
    if ([string]::IsNullOrWhiteSpace($D)) { return $null }
    $s = ($D -replace '[^\x20-\x7E]', '') -replace '\s+', ' '
    $s = $s -replace '\s*\(.*\)\s*$', ''
    $s = $s -replace '\s*[-]\s*(64|32)-bit.*$', ''
    $s = $s -replace '\s*[-]\s*Windows.*$', ''
    $s = ($s.Trim() -replace '[\s\-\.]+$', '')
    if ($s.Length -gt 180) { $s = $s.Substring(0,177) + '...' }
    if ($s.Length -lt 3) { return $null }
    $bare = [IO.Path]::GetFileNameWithoutExtension($Name)
    if ($s -ieq $bare -or $s -ieq $Name) { return $null }
    return $s
}

function Clean-Ver {
    param([string]$V)
    if ([string]::IsNullOrWhiteSpace($V)) { return '-' }
    return ($V -replace '\s*\(.*\)\s*$', '').Trim()
}

function Fmt-Size {
    param([double]$Bytes)
    if ($Bytes -ge 1MB) { return ('{0:0.0} MB' -f ($Bytes/1MB)) }
    if ($Bytes -ge 1KB) { return ('{0} KB' -f [math]::Round($Bytes/1KB)) }
    return ('{0} B' -f [math]::Round($Bytes))
}

# Curated manual descriptions (keyed by filename). Populate to enable 'kurasi' source.
$script:curated = @{}
