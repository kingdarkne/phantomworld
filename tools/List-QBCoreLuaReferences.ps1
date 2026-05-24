<#
.SYNOPSIS
  Lists .lua files under resources/ that reference qb-core / GetCoreObject (conversion candidates).

.DESCRIPTION
  Excludes qbx_core bridge implementation and legacy qb-core resource folder by default.
  Use -ExcludeVehiclePack to skip huge vehicle asset trees.
#>
param(
    [string]$Root = (Split-Path -Parent $PSScriptRoot),
    [switch]$ExcludeVehiclePack
)

$pattern = "GetCoreObject|exports\['qb-core'\]|exports\[""qb-core""\]"

Get-ChildItem -LiteralPath (Join-Path $Root 'resources') -Filter *.lua -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object {
        $p = $_.FullName
        # e.g. resources\[qb]\qb-core\... (legacy core; not a conversion target)
        if ($p -match '\\qb-core\\') { return $false }
        if ($p -match '\\qbx_core\\bridge\\') { return $false }
        if ($ExcludeVehiclePack -and $p -match 'FiveM Vehicle Pack') { return $false }
        $true
    } |
    Select-String -Pattern $pattern -List |
    ForEach-Object { $_.Path } |
    Sort-Object -Unique
