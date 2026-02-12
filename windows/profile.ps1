$script:debug_Override = $false
function Get-Theme_Override {
    $ompConfigPath = Join-Path (Split-Path $PROFILE) "my_layout.omp.json"
    if (-not (Test-Path $ompConfigPath)) {
        Write-Warning "Oh My Posh configuration file not found at $ompConfigPath."
        return
    }

    $ompInit = oh-my-posh init pwsh --config $ompConfigPath
    Invoke-Expression $ompInit
}
