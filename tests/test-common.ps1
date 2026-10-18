# Basic validation for common.ps1
. $PSScriptRoot/../tools/common.ps1

$tests = @(
    @{ Name='tcpip.sys';  Expected='net';    Actual=(Get-Cat 'tcpip.sys') },
    @{ Name='ntfs.sys';   Expected='fs';     Actual=(Get-Cat 'ntfs.sys') },
    @{ Name='usbhub.sys'; Expected='usb';    Actual=(Get-Cat 'usbhub.sys') },
    @{ Name='vmbus.sys';  Expected='vm';     Actual=(Get-Cat 'vmbus.sys') },
    @{ Name='wdf01000.sys'; Expected='wf';  Actual=(Get-Cat 'wdf01000.sys') },
    @{ Name='unknown.abc'; Expected='other'; Actual=(Get-Cat 'unknown.abc') }
)

$passed = 0; $failed = 0
foreach ($t in $tests) {
    if ($t.Actual -eq $t.Expected) {
        Write-Host "PASS: $($t.Name) -> $($t.Expected)"
        $passed++
    } else {
        Write-Host "FAIL: $($t.Name) expected $($t.Expected) got $($t.Actual)"
        $failed++
    }
}
Write-Host "Results: $passed passed, $failed failed"
exit ($failed -gt 0 ? 1 : 0)
