# Regenerate everything: CSV + README + docs
$here = $PSScriptRoot
Write-Host "Starting full regeneration..."
. (Join-Path $here 'gen_readme.ps1')
. (Join-Path $here 'gen_docs.ps1')
Write-Host "Done. Check README.md, docs/index.html, and tools/drivers_inventory.csv."
