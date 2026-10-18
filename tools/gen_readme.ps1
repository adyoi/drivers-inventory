$ErrorActionPreference = 'Stop'

$here = $PSScriptRoot
. (Join-Path $here 'common.ps1')

$csvPath  = Join-Path $here 'drivers_inventory.csv'
$outPath  = Join-Path (Split-Path -Parent $here) 'README.md'
$projectRoot = Split-Path -Parent $outPath
$docsDir = Join-Path $projectRoot 'docs'

$os  = Get-CimInstance Win32_OperatingSystem
$now = Get-Date -Format 'yyyy-MM-dd HH:mm'

# ------------------------------------------------------------------ collect data

$driversDir = 'C:\Windows\System32\drivers'
Write-Host "Scanning $driversDir ..."
$files = Get-ChildItem -LiteralPath $driversDir -File -Recurse -ErrorAction SilentlyContinue | Sort-Object Name
$csvRows = foreach ($f in $files) {
    $vi = $f.VersionInfo
    [PSCustomObject]@{
        Name        = $f.Name
        Ext         = $f.Extension
        SizeKB      = [math]::Round($f.Length / 1KB)
        FileVersion = $vi.FileVersion
        Description = $vi.FileDescription
    }
}
$csvRows | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8
Write-Host "Wrote $($csvRows.Count) entries to drivers_inventory.csv"

# ------------------------------------------------------------------ load data

$list = New-Object System.Collections.Generic.List[object]
foreach ($r in $csvRows) {
    $dc = Clean-Desc $r.Description $r.Name
    $ext = if ($r.Name -match '\.sys$') { 'SYS' } else { 'Other' }
    if ($script:curated.ContainsKey($r.Name)) { $ex = $script:curated[$r.Name]; $sc = 'kurasi' }
    elseif ($dc) { $ex = $dc; $sc = 'metadata' }
    else { $ex = 'Komponen internal tanpa metadata versi; fungsi spesifiknya tidak terdokumentasi publik.'; $sc = 'kosong' }
    $list.Add([PSCustomObject]@{
        Name        = $r.Name
        Ext         = $ext
        SizeBytes   = [double]($r.SizeKB) * 1KB
        FileVersion = (Clean-Ver $r.FileVersion)
        Cat         = (Get-Cat $r.Name)
        Expl        = $ex
        Src         = $sc
    })
}
$rows = $list.ToArray()

$sys = @($rows | Where-Object { $_.Ext -eq 'SYS' } | Sort-Object Name)
$other = @($rows | Where-Object { $_.Ext -ne 'SYS' } | Sort-Object Name)

$totalSize = ($rows | Measure-Object -Property SizeBytes -Sum).Sum
$curCount  = @($rows | Where-Object { $_.Src -eq 'kurasi' }).Count
$metaCount = @($rows | Where-Object { $_.Src -eq 'metadata' }).Count
$noneCount = @($rows | Where-Object { $_.Src -eq 'kosong' }).Count

$deep = $script:deep

# ------------------------------------------------------------------ README

$md = New-Object System.Collections.Generic.List[string]
function A([string]$s) { $md.Add($s) }

A '# Inventaris File C:\Windows\System32\drivers'
A ''
A '> **Halaman interaktif:** https://adyoi.github.io/drivers-inventory/ - versi lengkap dengan pencarian, filter, dan sortir. Buka juga secara lokal lewat `docs\index.html` tanpa server.'
A '>'
A '> Repo dokumentasi pribadi, tidak berafiliasi dengan atau didukung Microsoft.'
A '>'
A '> Lisensi: [MIT](LICENSE). Nama produk, file, dan merek milik Microsoft; data nama, ukuran, dan versi file adalah fakta yang dihimpun dari instalasi Windows lokal.'
A ''
A 'Inventaris lengkap file driver (.sys) dan file pendukung di C:\Windows\System32\drivers, dikelompokkan per kategori dan per nama, dengan penjelasan singkat fungsi tiap file.'
A ''
A ("- **Sistem ini:** $($os.Caption), versi $($os.Version) (build $($os.BuildNumber))")
A ("- **Waktu generate:** $now")
A ("- **Jumlah file:** $($rows.Count) total, yaitu $($sys.Count) SYS dan $($other.Count) file lain")
A ("- **Total ukuran:** $(Fmt-Size $totalSize)")
A ("- **Sumber penjelasan:** $curCount file punya penjelasan kurasi manual, $metaCount file memakai FileDescription dari metadata versi, $noneCount file tidak punya metadata sehingga ditandai eksplisit.")
A ''
A '## Daftar isi'
A ''
A '1. [Cara memakai dokumen ini](#1-cara-memakai-dokumen-ini)'
A '2. [Apa itu C:\Windows\System32\drivers](#2-apa-itu-windows-system32-drivers)'
A '3. [Kategori file](#3-kategori-file)'
A '4. [File inti](#4-file-inti)'
A '5. [Catatan praktis](#5-catatan-praktis)'
A '6. [Cara regenerate](#appendix-cara-regenerate)'
A ''
A '---'
A ''
A '## 1. Cara memakai dokumen ini'
A ''
A "**Inventaris lengkapnya ada di [docs/index.html](docs/index.html)** atau online di **https://adyoi.github.io/drivers-inventory/** - satu file HTML yang bisa dibuka langsung di browser, tanpa server dan tanpa koneksi internet. README ini hanya ringkasan; daftar $($rows.Count) file per kategori tidak diulang di sini."
A ''
A 'Yang bisa dilakukan di halaman HTML:'
A ''
A '- **Cari** nama file atau kata kunci di penjelasannya, misalnya `tcpip`, `NDIS`, `ntfs`, atau `USB`.'
A '- **Saring** berdasarkan tipe (SYS/Other), kategori, atau tombol **Kurasi saja** untuk melihat file yang penjelasannya ditulis manual.'
A '- **Urutkan** dengan klik header kolom File, Ukuran, Versi, atau Kategori, atau lewat dropdown pengurutan.'
A '- **Unduh CSV** hasil filter yang sedang aktif.'
A '- **Ganti tema** terang/gelap; di layar sempit tabel berubah menjadi kartu.'
A '- **Baca penjelasan file inti** di blok "Penjelasan file inti (deep dive)" di bagian atas halaman.'
A ''
A 'Kolom yang dipakai di halaman HTML:'
A ''
A '| Kolom | Arti |'
A '|---|---|'
A '| File | Nama file apa adanya di folder drivers, termasuk kapitalisasinya |'
A '| Tipe | SYS untuk berkas .sys, Other untuk .inf/.cat/.dll/.exe |'
A '| Ukuran | Ukuran file di disk dalam KB atau MB |'
A '| Versi | Ambil dari sumber daya versi file (FileVersion), bukan versi produk |'
A '| Kategori | Kelompok fungsi driver; urutan mengikuti urutan logis di bagian 3 |'
A '| Penjelasan | Kurasi manual, atau FileDescription dari metadata file, atau catatan bahwa tidak terdokumentasi |'
A ''
A '## 2. Apa itu C:\Windows\System32\drivers'
A ''
A 'C:\Windows\System32\drivers adalah direktori yang berisi semua driver kernel-mode (.sys) yang dimuat Windows berserta file pendukungnya (.inf, .cat, .dll, .exe). Driver di sini berjalan di kernel level dengan hak istimewa penuh, mengendalikan perangkat keras fisik (disk, jaringan, USB, audio, grafis), dan menjadi lapisan antara hardware dan sistem operasi.'
A ''
A 'Isi folder ini secara logis terdiri dari:'
A ''
A '- **Driver kernel inti** - ACPI (acpi.sys), PCI bus (pci.sys), NDIS (ndis.sys), TCP/IP (tcpip.sys), filesystem (ntfs.sys), FLT Manager (fltmgr.sys), dan banyak driver lain yang harus ada agar sistem boot dan berjalan.'
A '- **Driver perangkat keras** - kontroler grafis (dxgkrnl.sys, igdkmd64.sys), audio (portcls.sys, HdAudio.sys), USB (usbhub.sys, USBXHCI.SYS), dan storage controller vendor (storahci.sys, amdsata.sys, dll).'
A '- **Driver keamanan** - Windows Defender (WdFilter.sys), AppID/AppLocker, BitLocker (fvevol.sys), dan WFP callout drivers.'
A '- **Driver virtualisasi** - komponen Hyper-V (vmbus.sys, vmgs*.sys) dan Windows Sandbox.'
A '- **File pendukung** - .inf (instalasi), .cat (fingerprint), .dll, dan utilitas kecil.'
A ''
A '> **Penting:** folder ini dilindungi Windows Resource Protection. File di dalamnya tidak boleh dipindah, diubah nama, dihapus, atau "dibersihkan" manual. Driver yang corrupt atau tidak cocok dapat menyebabkan blue screen (BSOD), kegagalan boot, atau perangkat tidak berfungsi.'
A ''
A '## 3. Kategori file'
A ''
A 'Jumlah file per kategori:'
A ''
A '| # | Kategori | Jumlah |'
A '|---:|---|---:|'
$ci = 0
foreach ($c in $script:cats) {
    $ci++
    A "| $ci | $($c.Title) | $(@($rows | Where-Object { $_.Cat -eq $c.Key }).Count) |"
}
A ''
foreach ($c in $script:cats) {
    A "- **$($c.Title)** - $($c.Desc)"
}
A ''
A '## 4. File inti'
A ''
A 'Kalau bermasalah dengan satu file, biasanya ini daftar driver yang paling sering ditanya. Penjelasan lengkapnya ada di blok deep dive di [halaman interaktif](https://adyoi.github.io/drivers-inventory/).'
A ''
A '| File | Fungsi |'
A '|---|---|'
foreach ($d in $deep) {
    A "| ``$($d.N)`` | $($d.T) |"
}
A ''
A '## 5. Catatan praktis'
A ''
A '- **Jangan menghapus driver secara manual.** File di folder drivers dilindungi oleh Windows Resource Protection. Hapus driver hanya melalui Device Manager atau DISM.'
A '- **Blue screen (BSOD)** biasanya disebutkan satu file driver (.sys) di akhir layar. Kolom Kategori di tabel ini membantu mengaitkan nama file itu dengan jenis drivernya.'
A '- **Error DRIVER_IRQL_NOT_LESS_OR_EQUAL**, **DRIVER_PAGE_FAULT_IN_NONPAGED_AREA**, atau **UNEXPECTED_KERNEL_MODE_TRAP** biasanya disebabkan driver pihak ketiga yang tidak kompatibel — bukan file sistem core.'
A '- **Update driver** sebaiknya lewat Windows Update, Device Manager, atau situs vendor — bukan dengan mengganti file .sys secara manual.'
A '- **Perspektif keamanan** - beberapa driver di sini dapat disalahgunakan oleh malware untuk kernel hooking (misalnya menanamkan rootkit kernel). Sysinternals Sigcheck dan Sysmon membantu membedakan driver yang sah dari yang mencurigakan.'
A '- **Dokumen ini read-only** - isinya deskripsi file, bukan daftar file yang boleh dihapus.'
A '- **File non-SYS** (seperti .inf, .cat, .dll, .exe) juga termasuk dalam inventaris. File .inf digunakan instalasi driver, .cat berisi fingerprint keamanan, dan .dll/.exe sering terkait utility driver.'
A ''
A '---'
A ''
A '## Appendix: cara regenerate'
A ''
A '```powershell'
A 'powershell -NoProfile -ExecutionPolicy Bypass -File tools\gen_docs.ps1'
A '```'
A ''
A '`tools\gen_readme.ps1` mengumpulkan inventaris dari metadata versi tiap file di `C:\Windows\System32\drivers`, kemudian menulis `README.md` dan `tools\drivers_inventory.csv`. `tools\gen_docs.ps1` memakai skrip itu dan menulis halaman interaktif ke `docs\index.html`. Data inventaris diambil langsung dari metadata versi file:'
A ''
A '```powershell'
A 'Get-ChildItem C:\Windows\System32\drivers -File | ForEach-Object {'
A '  [PSCustomObject]@{'
A '    Name        = $_.Name'
A '    SizeKB      = [math]::Round($_.Length/1KB)'
A '    FileVersion = $_.VersionInfo.FileVersion'
A '    Description = $_.VersionInfo.FileDescription'
A '  }'
A '}'
A '```'
A ''
A '## Lisensi'
A ''
A 'Kode generator dan dokumentasi di repo ini memakai [MIT](LICENSE), hak cipta (c) 2026 adyoi.'
A ''
A 'Nama file, produk, dan merek yang disebut di sini adalah milik Microsoft; repo ini tidak berafiliasi dengan Microsoft. Data nama, ukuran, versi, dan deskripsi file merupakan fakta yang dihimpun dari instalasi Windows lokal, bukan karya cipta Microsoft.'
A ''

[IO.File]::WriteAllLines($outPath, $md, (New-Object System.Text.UTF8Encoding($false)))

"OK -> $outPath"
"lines : $($md.Count)"
"rows  : $($rows.Count) (SYS $($sys.Count) / Other $($other.Count))"
"explain       : kurasi $curCount / metadata $metaCount / kosong $noneCount"
foreach ($c in $script:cats) { $n = @($rows | Where-Object { $_.Cat -eq $c.Key }).Count; "  $($c.Key): $n" }
