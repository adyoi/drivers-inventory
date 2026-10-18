$ErrorActionPreference = 'Stop'

$here = $PSScriptRoot
. (Join-Path $here 'common.ps1')

$csvPath  = Join-Path $here 'drivers_inventory.csv'
$docsDir  = Join-Path (Split-Path -Parent $here) 'docs'
$htmlPath = Join-Path $docsDir 'index.html'

if (-not (Test-Path $docsDir)) { New-Item -ItemType Directory -Path $docsDir -Force | Out-Null }

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

$deep = $script:deep

$curCount  = @($rows | Where-Object { $_.Src -eq 'kurasi' }).Count
$metaCount = @($rows | Where-Object { $_.Src -eq 'metadata' }).Count
$noneCount = @($rows | Where-Object { $_.Src -eq 'kosong' }).Count
$totalSize = ($rows | Measure-Object -Property SizeBytes -Sum).Sum
$sysCount  = @($rows | Where-Object { $_.Ext -eq 'SYS' }).Count
$otherCount = $rows.Count - $sysCount

# ------------------------------------------------------------------ build JSON payload

$jsonRows = $rows | ForEach-Object {
    $catKey = $_.Cat
    $catTitle = ($script:cats | Where-Object { $_.Key -eq $catKey }).Title
    [PSCustomObject]@{
        File      = $_.Name
        Type      = $_.Ext
        SizeKB    = [math]::Round($_.SizeBytes / 1KB)
        Version   = $_.FileVersion
        CatKey    = $catKey
        CatTitle  = $catTitle
        Explanation = $_.Expl
        Src       = $_.Src
    }
}

$jsonCats = $script:cats | ForEach-Object {
    $key = $_.Key
    $count = @($rows | Where-Object { $_.Cat -eq $key }).Count
    [PSCustomObject]@{
        Key   = $_.Key
        Title = $_.Title
        Short = $_.Short
        Desc  = $_.Desc
        Count = $count
    }
}

$jsonDeep = $script:deep | ForEach-Object {
    [PSCustomObject]@{
        N = $_.N
        T = $_.T
        B = $_.B
    }
}

$payload = [PSCustomObject]@{
    rows  = $jsonRows
    cats  = $jsonCats
    deep  = $jsonDeep
    meta  = [PSCustomObject]@{
        os       = "$($os.Caption) (v$($os.Version), build $($os.BuildNumber))"
        count    = $rows.Count
        sys      = $sysCount
        other    = $otherCount
        size     = (Fmt-Size $totalSize)
        generated= $now
        kurasi   = $curCount
        metadata = $metaCount
        kosong   = $noneCount
    }
}
$jsonData = ($payload | ConvertTo-Json -Depth 5) -replace '</script>', '<\/script>'

$osCaption = $os.Caption
$osVersion = $os.Version
$osBuild   = $os.BuildNumber
$osFull    = "$osCaption (v$osVersion, build $osBuild)"

# ------------------------------------------------------------------ HTML template (data injected via placeholder)

$html = @"
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="description" content="Inventaris lengkap file driver di C:\Windows\System32\drivers, dikelompokkan per kategori.">
<title>Inventaris Driver Windows - System32\drivers</title>
<style>
:root {
  --bg:#0b1021; --bg2:#12192e; --bg3:#1c2746; --card:#16203a; --card2:#1f2a4c;
  --text:#e2e8f0; --text2:#94a3b8; --accent:#22d3ee; --accent2:#0891b2;
  --border:#273554; --border2:#1e2a47; --code:#0f172a; --codebg:#0b1021;
  --bth:#f472b6; --usb:#22d3ee; --gfx:#a78bfa; --audio:#fbbf24; --input:#34d399;
  --vm:#f472b6; --wf:#eab308; --sec:#f87171; --store:#818cf8; --fs:#4ade80;
  --fsflt:#22d3ee; --net:#60a5fa; --acpi:#f87171; --kernel:#34d399; --crypto:#a3e635; --other:#94a3b8;
}
body.dark {
  --bg:#000000; --bg2:#0a0a0a; --bg3:#121212; --card:#0a0a0a; --card2:#121212;
  --text:#e2e8f0; --text2:#94a3b8; --accent:#00cc44; --accent2:#00b300;
  --border:#1a1a1a; --border2:#2a2a2a; --code:#000000; --codebg:#000000;
}
body.light {
  --bg:#f8fafc; --bg2:#ffffff; --bg3:#f1f5f9; --card:#ffffff; --card2:#f8fafc;
  --text:#0f172a; --text2:#475569; --accent:#0ea5e9; --accent2:#0369a1;
  --border:#e2e8f0; --border2:#cbd5e1; --code:#1e1b4b; --codebg:#f1f5f9;
  --bth:#be185d; --usb:#0891b2; --gfx:#6d28d9; --audio:#b45309; --input:#059669;
  --vm:#be185d; --wf:#b45309; --sec:#dc2626; --store:#4f46e5; --fs:#16a34a;
  --fsflt:#0891b2; --net:#2563eb; --acpi:#dc2626; --kernel:#16a34a; --crypto:#65a30d; --other:#64748b;
}
* { margin:0; padding:0; box-sizing:border-box; }
html { scroll-behavior:smooth; }
body {
  font-family:'Inter','Segoe UI',system-ui,-apple-system,BlinkMacSystemFont,sans-serif;
  background:var(--bg); color:var(--text);
  padding:24px; max-width:1400px; margin:0 auto; line-height:1.55;
  letter-spacing:-0.01em;
}
.container { position:relative; }
h1 { font-size:1.75rem; font-weight:700; margin-bottom:6px; letter-spacing:-0.02em; }
h2 { font-size:1.15rem; font-weight:600; margin:26px 0 10px; border-bottom:1px solid var(--border); padding-bottom:8px; color:var(--text); }
.subtitle { color:var(--text2); font-size:0.9rem; margin-bottom:18px; font-weight:400; }
.meta { display:flex; gap:10px; flex-wrap:wrap; margin-bottom:20px; }
.meta span { background:var(--bg2); padding:6px 14px; border-radius:999px; border:1px solid var(--border); font-size:0.8rem; color:var(--text2); }
.toolbar { display:flex; gap:10px; flex-wrap:wrap; margin:0 0 20px 0; align-items:center; }
.toolbar input, .toolbar select, .toolbar button {
  padding:8px 14px; border:1px solid var(--border); border-radius:10px;
  background:var(--bg2); color:var(--text); font-size:0.875rem; outline:none; transition:all .18s ease;
}
.toolbar input { flex:1; min-width:200px; }
.toolbar input:focus { border-color:var(--accent); box-shadow:0 0 0 3px rgba(0,204,68,0.15); }
.toolbar select { cursor:pointer; }
.toolbar button { cursor:pointer; background:linear-gradient(135deg,var(--accent),var(--accent2)); color:#020617; border:none; font-weight:600; font-size:0.85rem; transition:all .2s ease; box-shadow:0 1px 3px rgba(0,0,0,0.35); }
.toolbar button:hover { transform:translateY(-1px); box-shadow:0 4px 12px rgba(0,0,0,0.4); filter:brightness(1.08); }
table { width:100%; border-collapse:separate; border-spacing:0; background:var(--card); border:1px solid var(--border); border-radius:12px; overflow:hidden; }
th, td { padding:10px 14px; text-align:left; border-bottom:1px solid var(--border2); font-size:0.82em; }
th { background:var(--bg2); font-weight:600; color:var(--text2); position:sticky; top:0; z-index:2; cursor:pointer; user-select:none; letter-spacing:0.04em; text-transform:uppercase; font-size:0.72em; }
th:hover { background:var(--bg3); }
.sort-icon { margin-left:6px; transition:transform 0.2s ease; flex-shrink:0; }
tbody tr { transition:background 0.12s ease; }
tbody tr:hover td { background:var(--bg3); }
td code { font-family:'Cascadia Code','Fira Code',monospace; font-size:0.8em; background:rgba(0,0,0,0.2); padding:1px 6px; border-radius:4px; color:var(--accent); border:1px solid var(--border2); }
td a { color:var(--accent); text-decoration:none; }
td a:hover { text-decoration:underline; text-decoration-thickness:2px; text-underline-offset:3px; }
.badge { display:inline-flex; align-items:center; gap:6px; padding:2px 10px; border-radius:999px; font-size:0.7em; font-weight:700; text-transform:uppercase; letter-spacing:0.06em; border:1px solid; }
.badge-bth { background:rgba(244,114,182,0.12); color:var(--bth); border-color:rgba(244,114,182,0.35); }
.badge-usb { background:rgba(34,211,238,0.12); color:var(--usb); border-color:rgba(34,211,238,0.35); }
.badge-gfx { background:rgba(167,139,250,0.12); color:var(--gfx); border-color:rgba(167,139,250,0.35); }
.badge-audio { background:rgba(251,191,36,0.12); color:var(--audio); border-color:rgba(251,191,36,0.35); }
.badge-input { background:rgba(52,211,153,0.12); color:var(--input); border-color:rgba(52,211,153,0.35); }
.badge-vm { background:rgba(244,114,182,0.12); color:var(--vm); border-color:rgba(244,114,182,0.35); }
.badge-wf { background:rgba(234,179,8,0.12); color:var(--wf); border-color:rgba(234,179,8,0.35); }
.badge-sec { background:rgba(248,113,113,0.12); color:var(--sec); border-color:rgba(248,113,113,0.35); }
.badge-store { background:rgba(129,140,248,0.12); color:var(--store); border-color:rgba(129,140,248,0.35); }
.badge-fs { background:rgba(74,222,128,0.12); color:var(--fs); border-color:rgba(74,222,128,0.35); }
.badge-fsflt { background:rgba(34,211,238,0.12); color:var(--fsflt); border-color:rgba(34,211,238,0.35); }
.badge-net { background:rgba(96,165,250,0.12); color:var(--net); border-color:rgba(96,165,250,0.35); }
.badge-acpi { background:rgba(248,113,113,0.12); color:var(--acpi); border-color:rgba(248,113,113,0.35); }
.badge-kernel { background:rgba(52,211,153,0.12); color:var(--kernel); border-color:rgba(52,211,153,0.35); }
.badge-crypto { background:rgba(163,230,53,0.12); color:var(--crypto); border-color:rgba(163,230,53,0.35); }
.badge-other { background:rgba(148,163,184,0.12); color:var(--other); border-color:rgba(148,163,184,0.35); }
.category-grid { display:grid; grid-template-columns:repeat(auto-fill,minmax(210px,1fr)); gap:16px; margin-bottom:26px; }
.category-card { background:var(--card); border:1px solid var(--border); border-radius:16px; padding:20px; cursor:pointer; transition:all .25s ease; position:relative; overflow:hidden; }
.category-card::before { content:''; position:absolute; inset:0 0 auto 0; height:3px; background:linear-gradient(90deg,var(--accent),var(--accent2)); opacity:0.9; }
.category-card:hover { transform:translateY(-4px); border-color:var(--accent); box-shadow:0 12px 32px -10px rgba(0,0,0,0.5); }
.category-card .cat-title { font-weight:700; font-size:0.95rem; margin-bottom:8px; color:var(--text); letter-spacing:-0.01em; }
.category-card .cat-count { font-size:2.6rem; font-weight:800; color:var(--accent); line-height:1; margin-bottom:8px; }
.category-card .cat-desc { font-size:0.72rem; color:var(--text2); line-height:1.5; display:-webkit-box; -webkit-line-clamp:3; -webkit-box-orient:vertical; overflow:hidden; }
.deep-grid { display:grid; grid-template-columns:repeat(auto-fill,minmax(300px,1fr)); gap:16px; margin-bottom:26px; }
.deep-card { background:var(--card); border:1px solid var(--border); border-radius:14px; padding:20px; position:relative; overflow:hidden; }
.deep-card::before { content:''; position:absolute; top:0; left:0; width:4px; height:100%; background:var(--accent); }
.deep-card h3 { color:var(--accent); font-size:0.95rem; margin-bottom:8px; font-weight:700; letter-spacing:-0.01em; }
.deep-card p { font-size:0.8rem; color:var(--text2); line-height:1.55; }
.code-block { background:var(--codebg); border:1px solid var(--border); border-radius:10px; padding:14px; font-size:0.75rem; font-family:'Cascadia Code','Fira Code',monospace; overflow-x:auto; margin:10px 0; }
.footer { margin-top:34px; padding-top:20px; border-top:1px solid var(--border); font-size:0.78rem; color:var(--text2); line-height:1.5; }
.hidden { display:none; }
.accordion-item { margin-bottom:12px; border:1px solid var(--border); border-radius:12px; overflow:hidden; background:var(--card); }
.accordion-header {
  display:flex; align-items:center; justify-content:space-between;
  padding:14px 18px; background:var(--bg2); cursor:pointer; font-size:0.95rem; font-weight:600;
  transition:background 0.18s ease;
}
.accordion-header:hover { background:var(--bg3); }
.accordion-toggle { margin-left:10px; width:18px; height:18px; flex-shrink:0; transition:transform 0.3s ease; }
.accordion-toggle.open { transform: rotate(180deg); }
.accordion-content { max-height:0; overflow:hidden; transition:max-height 0.35s ease, padding 0.35s ease; border-top:1px solid var(--border); padding:10px 18px 16px 18px; }
.accordion-content.collapsed { max-height:0; padding:0 18px 0 18px; }
.card-view td { display:block; padding:6px 0; font-size:0.82em; }
.card-view td::before { content:attr(data-label); font-weight:600; color:var(--text2); font-size:0.68em; text-transform:uppercase; letter-spacing:0.06em; display:block; margin-bottom:3px; }
@media (max-width:768px) {
  body { padding:14px; }
  table { font-size:0.78em; }
  .category-grid, .deep-grid { grid-template-columns:1fr; }
  .toolbar { flex-direction:column; align-items:stretch; }
  .toolbar input { min-width:auto; }
}
</style>
</head>
<body class="dark">
<div class="container">
  <h1>Inventaris Driver Windows &mdash; System32\drivers</h1>
  <div class="subtitle">Inventaris lengkap $($rows.Count) file driver di C:\Windows\System32\drivers, dikelompokkan per kategori dengan penjelasan.</div>

   <div class="meta">
     <span>Sistem: $($osFull)</span>
     <span>Total: $($rows.Count) file ($sysCount SYS + $otherCount lain)</span>
     <span>Berukuran: $(Fmt-Size $totalSize)</span>
     <span>Generate: $now</span>
    </div>

   <div class="accordion-item">
     <div class="accordion-header" id="deepHeader">
       File Inti (Deep Dive)
        <svg class="accordion-toggle" id="deepToggle" viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 12 15 18 9"></polyline></svg>
     </div>
     <div class="accordion-content collapsed" id="deepContent">
       <div class="deep-grid" id="deepGrid"></div>
     </div>
   </div>

   <div class="accordion-item">
     <div class="accordion-header" id="catHeader">
       Kategori File (Card Filter)
        <svg class="accordion-toggle" id="catToggle" viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 12 15 18 9"></polyline></svg>
     </div>
     <div class="accordion-content collapsed" id="catContent">
       <div class="category-grid" id="catGrid"></div>
     </div>
   </div>

   <div class="toolbar">
     <input type="text" id="search" placeholder="Cari nama file atau kata kunci (misal: tcpip, ntfs, NDIS)..." />
    <select id="filterType">
      <option value="">Semua tipe</option>
      <option value="SYS">SYS</option>
      <option value="Other">Non-SYS</option>
    </select>
    <select id="filterCat">
      <option value="">Semua kategori</option>
    </select>
    <select id="sort">
      <option value="name|asc">Urutkan: Nama (A-Z)</option>
      <option value="name|desc">Urutkan: Nama (Z-A)</option>
      <option value="size|desc">Urutkan: Ukuran (Terbesar)</option>
      <option value="size|asc">Urutkan: Ukuran (Terkecil)</option>
      <option value="cat|asc">Urutkan: Kategori</option>
    </select>
    <button id="toggleKurasi">Kurasi saja</button>
    <button id="downloadCsv">Unduh CSV</button>
    <button id="themeToggle">Terang</button>
   </div>

   <div id="tableWrapper">
   <table>
     <thead>
       <tr>
        <th data-key="name">File<svg class="sort-icon" id="sort-icon-name" viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 12 15 18 9"></polyline></svg></th>
        <th data-key="ext">Tipe<svg class="sort-icon" id="sort-icon-ext" viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 12 15 18 9"></polyline></svg></th>
        <th data-key="sizeKB">Ukuran<svg class="sort-icon" id="sort-icon-sizeKB" viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 12 15 18 9"></polyline></svg></th>
        <th data-key="ver">Versi<svg class="sort-icon" id="sort-icon-ver" viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 12 15 18 9"></polyline></svg></th>
        <th data-key="cat">Kategori<svg class="sort-icon" id="sort-icon-cat" viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 12 15 18 9"></polyline></svg></th>
        <th data-key="expl">Deskripsi<svg class="sort-icon" id="sort-icon-expl" viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 12 15 18 9"></polyline></svg></th>
       </tr>
     </thead>
     <tbody id="tbody"></tbody>
   </table>
   </div>

   <div class="footer">
     <p><strong>Catatan:</strong> File di folder ini dilindungi Windows Resource Protection. Jangan hapus atau ganti driver secara manual &mdash; gunakan Device Manager atau DISM.</p>
     <p>Generator: <code>tools/gen_docs.ps1</code> &mdash; satu berkas HTML, tidak butuh server, tidak butuh internet.</p>
     <p>Repo ini tidak berafiliasi dengan Microsoft. Nama file dan merek adalah milik pemiliknya masing-masing.</p>
   </div>
</div>

<script>
var DATA = __DATA_JSON__;

var sortField = 'name', sortDir = 'asc', filterType = '', filterCat = '', searchTerm = '', kurasiOnly = false;

function fmtSize(kb) {
  if (kb >= 1024) return (kb/1024).toFixed(1) + ' MB';
  return Math.round(kb) + ' KB';
}

function catBadge(key, title) {
  return '<span class="badge badge-' + key + '">' + title + '</span>';
}

function renderRows() {
  var rows = DATA.rows.filter(function(r) {
    if (filterType && r.Type !== filterType) return false;
    if (filterCat && r.CatKey !== filterCat) return false;
    if (kurasiOnly && r.Src !== 'kurasi') return false;
    if (searchTerm) {
      var hay = (r.File + ' ' + r.Explanation + ' ' + r.CatTitle).toLowerCase();
      if (hay.indexOf(searchTerm.toLowerCase()) === -1) return false;
    }
    return true;
  });
  rows.sort(function(a, b) {
    var av, bv;
    if (sortField === 'name') { av = a.File.toLowerCase(), bv = b.File.toLowerCase(); }
    else if (sortField === 'sizeKB') { av = a.SizeKB, bv = b.SizeKB; }
    else if (sortField === 'cat') { av = a.CatKey.toLowerCase(), bv = b.CatKey.toLowerCase(); }
    else if (sortField === 'ext') { av = a.Type.toLowerCase(), bv = b.Type.toLowerCase(); }
    else if (sortField === 'ver') { av = a.Version, bv = b.Version; }
    else if (sortField === 'expl') { av = a.Explanation.toLowerCase(), bv = b.Explanation.toLowerCase(); }
    if (av < bv) return sortDir === 'asc' ? -1 : 1;
    if (av > bv) return sortDir === 'asc' ? 1 : -1;
    return 0;
  });

  var tbody = document.getElementById('tbody');
  tbody.innerHTML = '';
  if (rows.length === 0) {
    tbody.innerHTML = '<tr><td colspan="7" style="text-align:center;padding:24px;color:var(--text2)">Tidak ada file yang cocok.</td></tr>';
    return;
  }
  rows.forEach(function(r) {
    var tr = document.createElement('tr');
    tr.innerHTML = '<td data-label="File"><code>' + r.File + '</code></td>' +
      '<td data-label="Tipe">' + r.Type + '</td>' +
      '<td data-label="Ukuran">' + fmtSize(r.SizeKB) + '</td>' +
      '<td data-label="Versi">' + r.Version + '</td>' +
      '<td data-label="Kategori">' + catBadge(r.CatKey, r.CatTitle) + '</td>' +
      '<td data-label="Deskripsi">' + r.Explanation + '</td>';
    tbody.appendChild(tr);
  });

  document.querySelectorAll('th[data-key]').forEach(function(th) {
    var icon = th.querySelector('.sort-icon');
    if (th.getAttribute('data-key') === sortField) {
      icon.style.transform = sortDir === 'asc' ? 'rotate(0deg)' : 'rotate(180deg)';
    } else {
      icon.style.transform = 'rotate(0deg)';
    }
  });
}

function renderCats() {
  var grid = document.getElementById('catGrid');
  grid.innerHTML = '';
  DATA.cats.forEach(function(c) {
    var card = document.createElement('div');
    card.className = 'category-card';
    card.innerHTML = '<div class="cat-title">' + c.Title + '</div>' +
      '<div class="cat-count">' + c.Count + '</div>' +
      '<div class="cat-desc">' + c.Desc + '</div>';
    card.addEventListener('click', function() { filterCat = c.Key; document.getElementById('filterCat').value = c.Key; renderRows(); });
    grid.appendChild(card);
  });
}

function renderDeep() {
  var grid = document.getElementById('deepGrid');
  grid.innerHTML = '';
  DATA.deep.forEach(function(d) {
    var card = document.createElement('div');
    card.className = 'deep-card';
    card.innerHTML = '<h3>' + d.N + '</h3><p><strong>' + d.T + '</strong></p><p>' + d.B + '</p>';
    grid.appendChild(card);
  });
}

function downloadCsv() {
  var rows = DATA.rows.filter(function(r) {
    if (filterType && r.Type !== filterType) return false;
    if (filterCat && r.CatKey !== filterCat) return false;
    if (kurasiOnly && r.Src !== 'kurasi') return false;
    if (searchTerm) {
      var hay = (r.File + ' ' + r.Explanation + ' ' + r.CatTitle).toLowerCase();
      if (hay.indexOf(searchTerm.toLowerCase()) === -1) return false;
    }
    return true;
  });
  var header = 'File,Tipe,Ukuran,Kategori,Versi,Deskripsi';
  var lines = [header];
  rows.forEach(function(r) {
    var sz = Math.round(r.SizeKB) + ' KB';
    var fields = [r.File, r.Type, sz, r.CatTitle, r.Version, r.Explanation];
    var escaped = fields.map(function(f) {
      if (f.indexOf(',') !== -1 || f.indexOf('"') !== -1) return '"' + f.replace(/"/g, '""') + '"';
      return f;
    });
    lines.push(escaped.join(','));
  });
  var blob = new Blob([lines.join('\n')], {type: 'text/csv'});
  var url = URL.createObjectURL(blob);
  var a = document.createElement('a');
  a.href = url; a.download = 'drivers_inventory.csv';
  a.click(); URL.revokeObjectURL(url);
}

document.getElementById('search').addEventListener('input', function(e) { searchTerm = e.target.value; renderRows(); });
document.getElementById('filterType').addEventListener('change', function(e) { filterType = e.target.value; renderRows(); });
document.getElementById('filterCat').addEventListener('change', function(e) { filterCat = e.target.value; renderRows(); });

function toggleAccordion(headerId, contentId, toggleId) {
  var header = document.getElementById(headerId);
  var content = document.getElementById(contentId);
  var toggle = document.getElementById(toggleId);
  var isCollapsed = content.classList.contains('collapsed');

  document.querySelectorAll('.accordion-content').forEach(function(c) {
    if (c.id !== contentId) { c.classList.add('collapsed'); c.style.maxHeight = '0'; }
    var cid = c.id.replace('Content', 'Toggle');
    var t = document.getElementById(cid);
    if (t) { t.classList.remove('open'); }
  });

  if (isCollapsed) {
    content.classList.remove('collapsed');
    content.style.maxHeight = content.scrollHeight + 'px';
    toggle.classList.add('open');
    setTimeout(function() { content.style.maxHeight = 'none'; }, 300);
  } else {
    content.classList.add('collapsed');
    content.style.maxHeight = '0';
    toggle.classList.remove('open');
  }
}

document.getElementById('deepHeader').addEventListener('click', function() {
  toggleAccordion('deepHeader', 'deepContent', 'deepToggle');
});

document.getElementById('catHeader').addEventListener('click', function() {
  toggleAccordion('catHeader', 'catContent', 'catToggle');
});
document.getElementById('sort').addEventListener('change', function(e) {
  var parts = e.target.value.split('|');
  sortField = parts[0]; sortDir = parts[1];
  renderRows();
});
document.getElementById('toggleKurasi').addEventListener('click', function() {
  kurasiOnly = !kurasiOnly;
  this.style.background = kurasiOnly ? 'var(--sec)' : 'var(--accent)';
  this.textContent = kurasiOnly ? 'Tampilkan semua' : 'Kurasi saja';
  renderRows();
});
document.getElementById('downloadCsv').addEventListener('click', downloadCsv);
document.getElementById('themeToggle').addEventListener('click', function() {
  var body = document.body;
  var btn = document.getElementById('themeToggle');
  if (body.classList.contains('dark')) { body.classList.remove('dark'); body.classList.add('light'); btn.textContent = 'Gelap'; }
  else { body.classList.remove('light'); body.classList.add('dark'); btn.textContent = 'Terang'; }
});
document.querySelectorAll('th[data-key]').forEach(function(th) {
  th.addEventListener('click', function() {
    if (sortField === th.getAttribute('data-key')) { sortDir = sortDir === 'asc' ? 'desc' : 'asc'; }
    else { sortField = th.getAttribute('data-key'); sortDir = 'asc'; }
    document.getElementById('sort').selectedIndex = -1;
    renderRows();
  });
});

DATA.cats.forEach(function(c, i) {
  var opt = document.createElement('option');
  opt.value = c.Key; opt.textContent = c.Title + ' (' + c.Count + ')';
  document.getElementById('filterCat').appendChild(opt);
});

renderCats();
renderDeep();
renderRows();
</script>
</body>
</html>
"@

$html = $html -replace '__DATA_JSON__', $jsonData

[IO.File]::WriteAllLines($htmlPath, @($html), (New-Object System.Text.UTF8Encoding($false)))

$nojekyll = Join-Path $docsDir '.nojekyll'
if (-not (Test-Path $nojekyll)) { Set-Content -Path $nojekyll -Value '' -Encoding UTF8 }

"OK -> $htmlPath"
"rows  : $($rows.Count) (SYS $($sysCount) / Other $($otherCount))"
"explain       : kurasi $curCount / metadata $metaCount / kosong $noneCount"
"  docs/.nojekyll created"
