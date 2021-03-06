#!powershell

#Requires -Module Ansible.ModuleUtils.Legacy
#Requires -Module Ansible.ModuleUtils.FileUtil

$ErrorActionPreference = "Stop"

$result = @{
    changed = $false
}

Function Assert-Equals($actual, $expected) {
    if ($actual -cne $expected) {
        $call_stack = (Get-PSCallStack)[1]
        $error_msg = "AssertionError:`r`nActual: `"$actual`" != Expected: `"$expected`"`r`nLine: $($call_stack.ScriptLineNumber), Method: $($call_stack.Position.Text)"
        Fail-Json -obj $result -message $error_msg
    }
}

# Test-AnsiblePath Hidden system file
$actual = Test-AnsiblePath -Path C:\pagefile.sys
Assert-Equals -actual $actual -expected $true

# Test-AnsiblePath File that doesn't exist
$actual = Test-AnsiblePath -Path C:\fakefile
Assert-Equals -actual $actual -expected $false

# Test-AnsiblePath Normal directory
$actual = Test-AnsiblePath -Path C:\Windows
Assert-Equals -actual $actual -expected $true

# Test-AnsiblePath Normal file
$actual = Test-AnsiblePath -Path C:\Windows\System32\kernel32.dll

# Test-AnsiblePath fails with wildcard
$failed = $false
try {
    Test-AnsiblePath -Path C:\Windows\*.exe
} catch {
    $failed = $true
    Assert-Equals -actual $_.Exception.Message -expected "Exception calling `"GetAttributes`" with `"1`" argument(s): `"Illegal characters in path.`""
}
Assert-Equals -actual $failed -expected $true

# Get-AnsibleItem doesn't exist with -ErrorAction SilentlyContinue param
$actual = Get-AnsibleItem -Path C:\fakefile -ErrorAction SilentlyContinue
Assert-Equals -actual $actual -expected $null


# Get-AnsibleItem file
$actual = Get-AnsibleItem -Path C:\pagefile.sys
Assert-Equals -actual $actual.FullName -expected C:\pagefile.sys
Assert-Equals -actual $actual.Attributes.HasFlag([System.IO.FileAttributes]::Directory) -expected $false
Assert-Equals -actual $actual.Exists -expected $true

# Get-AnsibleItem directory
$actual = Get-AnsibleItem -Path C:\Windows
Assert-Equals -actual $actual.FullName -expected C:\Windows
Assert-Equals -actual $actual.Attributes.HasFlag([System.IO.FileAttributes]::Directory) -expected $true
Assert-Equals -actual $actual.Exists -expected $true

$result.data = "success"
Exit-Json -obj $result
