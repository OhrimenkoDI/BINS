[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param()

$projectRoot = $PSScriptRoot

$buildDirectories = @(
    'Win32',
    'Win64',
    'OSX32',
    'OSX64',
    'Android',
    '__history',
    '__recovery'
)

$generatedExtensions = @(
    '.dcu',
    '.exe',
    '.dll',
    '.bpl',
    '.dcp',
    '.map',
    '.tds',
    '.rsm',
    '.identcache',
    '.dsk',
    '.ddp',
    '.stat',
    '.bak'
)

$removedCount = 0

foreach ($directoryName in $buildDirectories) {
    $directoryPath = Join-Path -Path $projectRoot -ChildPath $directoryName

    if ((Test-Path -LiteralPath $directoryPath -PathType Container) -and
        $PSCmdlet.ShouldProcess($directoryPath, 'Remove build directory')) {
        Remove-Item -LiteralPath $directoryPath -Recurse -Force
        $removedCount++
    }
}

$generatedDirectories = Get-ChildItem -LiteralPath $projectRoot -Directory -Force |
    Where-Object { $_.Name -like 'iOSDevice*' -or $_.Name -like 'iOSSimulator*' }

foreach ($directory in $generatedDirectories) {
    if ($PSCmdlet.ShouldProcess($directory.FullName, 'Remove build directory')) {
        Remove-Item -LiteralPath $directory.FullName -Recurse -Force
        $removedCount++
    }
}

$generatedFiles = Get-ChildItem -LiteralPath $projectRoot -File -Force |
    Where-Object {
        $_.Name -like '*.~*' -or
        $_.Name -like '*.dproj.local' -or
        $generatedExtensions -contains $_.Extension.ToLowerInvariant()
    }

foreach ($file in $generatedFiles) {
    if ($PSCmdlet.ShouldProcess($file.FullName, 'Remove generated file')) {
        Remove-Item -LiteralPath $file.FullName -Force
        $removedCount++
    }
}

if ($WhatIfPreference) {
    Write-Host 'Preview complete. No files were removed.'
} else {
    Write-Host "Project cleanup complete. Removed items: $removedCount"
}
