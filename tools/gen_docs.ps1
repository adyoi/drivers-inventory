param(
    [string]$DriversDir = 'C:\Windows\System32\drivers',
    [switch]$SkipCsv
)
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

Write-Host "Scanning $DriversDir ..."
$files = Get-ChildItem -LiteralPath $DriversDir -File -Recurse -ErrorAction SilentlyContinue | Sort-Object Name
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
        Explanation = ($_.Expl -replace '<', '&lt;' -replace '>', '&gt;')
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
        N = ($_.N -replace '<', '&lt;' -replace '>', '&gt;')
        T = ($_.T -replace '<', '&lt;' -replace '>', '&gt;')
        B = ($_.B -replace '<', '&lt;' -replace '>', '&gt;')
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
<link rel="stylesheet" href="style.css">
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
