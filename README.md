# Inventaris File C:\Windows\System32\drivers

> **Halaman interaktif:** https://adyoi.github.io/drivers-inventory/ - versi lengkap dengan pencarian, filter, dan sortir. Buka juga secara lokal lewat `docs\index.html` tanpa server.
>
> Repo dokumentasi pribadi, tidak berafiliasi dengan atau didukung Microsoft.
>
> Lisensi: [MIT](LICENSE). Nama produk, file, dan merek milik Microsoft; data nama, ukuran, dan versi file adalah fakta yang dihimpun dari instalasi Windows lokal.

Inventaris lengkap file driver (.sys) dan file pendukung di C:\Windows\System32\drivers, dikelompokkan per kategori dan per nama, dengan penjelasan singkat fungsi tiap file.

- **Sistem ini:** Microsoft Windows 11 Pro, versi 10.0.28000 (build 28000)
- **Waktu generate:** 2026-10-18 23:26
- **Jumlah file:** 608 total, yaitu 461 SYS dan 147 file lain
- **Total ukuran:** 162.2 MB
- **Sumber penjelasan:** 0 file punya penjelasan kurasi manual, 589 file memakai FileDescription dari metadata versi, 19 file tidak punya metadata sehingga ditandai eksplisit.

## Daftar isi

1. [Cara memakai dokumen ini](#1-cara-memakai-dokumen-ini)
2. [Apa itu C:\Windows\System32\drivers](#2-apa-itu-windows-system32-drivers)
3. [Kategori file](#3-kategori-file)
4. [File inti](#4-file-inti)
5. [Catatan praktis](#5-catatan-praktis)
6. [Cara regenerate](#appendix-cara-regenerate)

---

## 1. Cara memakai dokumen ini

**Inventaris lengkapnya ada di [docs/index.html](docs/index.html)** atau online di **https://adyoi.github.io/drivers-inventory/** - satu file HTML yang bisa dibuka langsung di browser, tanpa server dan tanpa koneksi internet. README ini hanya ringkasan; daftar 608 file per kategori tidak diulang di sini.

Yang bisa dilakukan di halaman HTML:

- **Cari** nama file atau kata kunci di penjelasannya, misalnya `tcpip`, `NDIS`, `ntfs`, atau `USB`.
- **Saring** berdasarkan tipe (SYS/Other), kategori, atau tombol **Kurasi saja** untuk melihat file yang penjelasannya ditulis manual.
- **Urutkan** dengan klik header kolom File, Ukuran, Versi, atau Kategori, atau lewat dropdown pengurutan.
- **Unduh CSV** hasil filter yang sedang aktif.
- **Ganti tema** terang/gelap; di layar sempit tabel berubah menjadi kartu.
- **Baca penjelasan file inti** di blok "Penjelasan file inti (deep dive)" di bagian atas halaman.

Kolom yang dipakai di halaman HTML:

| Kolom | Arti |
|---|---|
| File | Nama file apa adanya di folder drivers, termasuk kapitalisasinya |
| Tipe | SYS untuk berkas .sys, Other untuk .inf/.cat/.dll/.exe |
| Ukuran | Ukuran file di disk dalam KB atau MB |
| Versi | Ambil dari sumber daya versi file (FileVersion), bukan versi produk |
| Kategori | Kelompok fungsi driver; urutan mengikuti urutan logis di bagian 3 |
| Penjelasan | Kurasi manual, atau FileDescription dari metadata file, atau catatan bahwa tidak terdokumentasi |

## 2. Apa itu C:\Windows\System32\drivers

C:\Windows\System32\drivers adalah direktori yang berisi semua driver kernel-mode (.sys) yang dimuat Windows berserta file pendukungnya (.inf, .cat, .dll, .exe). Driver di sini berjalan di kernel level dengan hak istimewa penuh, mengendalikan perangkat keras fisik (disk, jaringan, USB, audio, grafis), dan menjadi lapisan antara hardware dan sistem operasi.

Isi folder ini secara logis terdiri dari:

- **Driver kernel inti** - ACPI (acpi.sys), PCI bus (pci.sys), NDIS (ndis.sys), TCP/IP (tcpip.sys), filesystem (ntfs.sys), FLT Manager (fltmgr.sys), dan banyak driver lain yang harus ada agar sistem boot dan berjalan.
- **Driver perangkat keras** - kontroler grafis (dxgkrnl.sys, igdkmd64.sys), audio (portcls.sys, HdAudio.sys), USB (usbhub.sys, USBXHCI.SYS), dan storage controller vendor (storahci.sys, amdsata.sys, dll).
- **Driver keamanan** - Windows Defender (WdFilter.sys), AppID/AppLocker, BitLocker (fvevol.sys), dan WFP callout drivers.
- **Driver virtualisasi** - komponen Hyper-V (vmbus.sys, vmgs*.sys) dan Windows Sandbox.
- **File pendukung** - .inf (instalasi), .cat (fingerprint), .dll, dan utilitas kecil.

> **Penting:** folder ini dilindungi Windows Resource Protection. File di dalamnya tidak boleh dipindah, diubah nama, dihapus, atau "dibersihkan" manual. Driver yang corrupt atau tidak cocok dapat menyebabkan blue screen (BSOD), kegagalan boot, atau perangkat tidak berfungsi.

## 3. Kategori file

Jumlah file per kategori:

| # | Kategori | Jumlah |
|---:|---|---:|
| 1 | ACPI & Firmware | 30 |
| 2 | Kernel & Core System | 63 |
| 3 | Kriptografi & TPM | 4 |
| 4 | Filesystems | 22 |
| 5 | Filesystem Filter | 37 |
| 6 | Storage Controllers & Disk | 79 |
| 7 | Network Stack | 103 |
| 8 | USB Controllers | 46 |
| 9 | Grafis & Display | 10 |
| 10 | Audio & Multimedia | 17 |
| 11 | Bluetooth | 17 |
| 12 | Input, HID & Human Interface | 57 |
| 13 | Keamanan | 43 |
| 14 | Virtualisasi & Hyper-V | 40 |
| 15 | Windows Driver Framework | 13 |
| 16 | Lain-lain / Vendor Ketiga | 27 |

- **ACPI & Firmware** - Driver ACPI power management, thermal, ACPI event handlers, platform firmware, dan device enumeration pada level firmware.
- **Kernel & Core System** - Lapisan inti kernel: RPC, PCI bus, console driver, volume/mount manager, crash dump, partition manager, dan runtime boot.
- **Kriptografi & TPM** - Crypto Next Generation (CNG), kernel crypto package, TPM, AES/RSA/SHA, dan key storage provider.
- **Filesystems** - Driver sistem file: NTFS, ReFS, FAT, exFAT, UDF, CDFS, CLFS, dan recogniser filesystem boot.
- **Filesystem Filter** - Filter minifilter: EFS, WOF, luafv AppX, BitLocker, network redirector, cloud files, dan filter I/O.
- **Storage Controllers & Disk** - Storage port driver, disk device, partition manager, dan kontroler RAID/SAS/SATA/SCSI (Intel, AMD, LSI, Broadcom, Chelsio, Marvell, nvme, dsb.).
- **Network Stack** - TCP/IP, NDIS, Winsock, NetBIOS, IPNAT, WFP firewall, network virtualization, Bluetooth port, dan protocol jaringan lain.
- **USB Controllers** - USB host controller drivers (OHCI, UHCI, EHCI, XHCI), hub, port driver, device support, dan USB function.
- **Grafis & Display** - DirectX Graphics Kernel (DXGK), display management, GPU vendor drivers (Intel/NVIDIA), display port.
- **Audio & Multimedia** - PortCls audio class driver, High Definition Audio bus/function driver, DRM, dan multimedia streaming.
- **Bluetooth** - Driver radio Bluetooth: A2DP, hands-free, RFCOMM, HID enumerator, LE transport, dan protocol stack.
- **Input, HID & Human Interface** - Keyboard, mouse, touchpad, touchscreen, HID class drivers, GPIO button, serial input, dan joystick support.
- **Keamanan** - Windows Defender (MsSense), WFP callouts, AppID, AppLocker, BitLocker filter, dan driver keamanan kernel.
- **Virtualisasi & Hyper-V** - Hyper-V hypervisor, VMBus, synthetic devices, virtual storage, virtual switch, dan VM integration.
- **Windows Driver Framework** - WDF (Windows Driver Framework) runtime dan loader, KMDF/LMDF support, USB helper, dan class extension drivers.
- **Lain-lain / Vendor Ketiga** - Driver vendor tertentu, tool diagnostik, dan file non-SYS di folder drivers.

## 4. File inti

Kalau bermasalah dengan satu file, biasanya ini daftar driver yang paling sering ditanya. Penjelasan lengkapnya ada di blok deep dive di [halaman interaktif](https://adyoi.github.io/drivers-inventory/).

| File | Fungsi |
|---|---|
| `acpi.sys` | ACPI Power Management |
| `cng.sys` | Crypto Next Generation |
| `ndis.sys` | NDIS Wrapper |
| `tcpip.sys` | TCP/IP Protocol Stack |
| `ntfs.sys` | NTFS Filesystem Driver |
| `fltmgr.sys` | Filter Manager |
| `dxgkrnl.sys` | DirectX Graphics Kernel |
| `usbhub.sys` | USB Hub Driver |
| `pci.sys` | PCI Bus Driver |
| `storport.sys` | Storage Port Driver |
| `volsnap.sys` | Volume Shadow Copy |
| `wdf01000.sys` | Kernel Mode Driver Framework |
| `tpm.sys` | Trusted Platform Module |
| `WdFilter.sys` | Windows Defender Filter |
| `vmbus.sys` | Hyper-V VMBus |
| `hvsocket.sys` | Hyper-V Socket |

## 5. Catatan praktis

- **Jangan menghapus driver secara manual.** File di folder drivers dilindungi oleh Windows Resource Protection. Hapus driver hanya melalui Device Manager atau DISM.
- **Blue screen (BSOD)** biasanya disebutkan satu file driver (.sys) di akhir layar. Kolom Kategori di tabel ini membantu mengaitkan nama file itu dengan jenis drivernya.
- **Error DRIVER_IRQL_NOT_LESS_OR_EQUAL**, **DRIVER_PAGE_FAULT_IN_NONPAGED_AREA**, atau **UNEXPECTED_KERNEL_MODE_TRAP** biasanya disebabkan driver pihak ketiga yang tidak kompatibel â€” bukan file sistem core.
- **Update driver** sebaiknya lewat Windows Update, Device Manager, atau situs vendor â€” bukan dengan mengganti file .sys secara manual.
- **Perspektif keamanan** - beberapa driver di sini dapat disalahgunakan oleh malware untuk kernel hooking (misalnya menanamkan rootkit kernel). Sysinternals Sigcheck dan Sysmon membantu membedakan driver yang sah dari yang mencurigakan.
- **Dokumen ini read-only** - isinya deskripsi file, bukan daftar file yang boleh dihapus.
- **File non-SYS** (seperti .inf, .cat, .dll, .exe) juga termasuk dalam inventaris. File .inf digunakan instalasi driver, .cat berisi fingerprint keamanan, dan .dll/.exe sering terkait utility driver.

---

## Appendix: cara regenerate

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\gen_docs.ps1
```

`tools\gen_readme.ps1` mengumpulkan inventaris dari metadata versi tiap file di `C:\Windows\System32\drivers`, kemudian menulis `README.md` dan `tools\drivers_inventory.csv`. `tools\gen_docs.ps1` memakai skrip itu dan menulis halaman interaktif ke `docs\index.html`. Data inventaris diambil langsung dari metadata versi file:

```powershell
Get-ChildItem C:\Windows\System32\drivers -File | ForEach-Object {
  [PSCustomObject]@{
    Name        = $_.Name
    SizeKB      = [math]::Round($_.Length/1KB)
    FileVersion = $_.VersionInfo.FileVersion
    Description = $_.VersionInfo.FileDescription
  }
}
```

## Lisensi

Kode generator dan dokumentasi di repo ini memakai [MIT](LICENSE), hak cipta (c) 2026 adyoi.

Nama file, produk, dan merek yang disebut di sini adalah milik Microsoft; repo ini tidak berafiliasi dengan Microsoft. Data nama, ukuran, versi, dan deskripsi file merupakan fakta yang dihimpun dari instalasi Windows lokal, bukan karya cipta Microsoft.

