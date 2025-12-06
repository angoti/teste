#!/usr/bin/env pwsh
# Robust autograde runner — logs with Write-Host (não polui o pipeline) e retorna códigos numéricos limpos

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$ResultsDir = Join-Path $RepoRoot 'results'
$OutReactWeb = Join-Path $ResultsDir 'react-web'
$OutReactNative = Join-Path $ResultsDir 'react-mobile'

New-Item -ItemType Directory -Path $OutReactWeb -Force | Out-Null
New-Item -ItemType Directory -Path $OutReactNative -Force | Out-Null

function Run-Task {
  param(
    [string]$TaskRelativePath,
    [string]$OutDir,
    [string]$ConfigPath = ''
  )

  $TaskDir = Join-Path $RepoRoot $TaskRelativePath
  Write-Host "==> Running tests in: $TaskDir"
  if (-not (Test-Path $TaskDir)) {
    $obj = [ordered]@{ success = $false; note = "missing_dir" }
    $obj | ConvertTo-Json -Depth 5 | Out-File -Encoding utf8 (Join-Path $OutDir 'summary.txt')
    Write-Host "Missing directory: $TaskDir"
    return 2
  }

  Push-Location $TaskDir
  try {
    $hasLock = (Test-Path (Join-Path $TaskDir 'package-lock.json')) -or (Test-Path (Join-Path $TaskDir 'pnpm-lock.yaml')) -or (Test-Path (Join-Path $TaskDir 'yarn.lock'))
    if ($hasLock) {
      Write-Host "Installing dependencies with npm ci..."
      npm ci --silent
    } else {
      Write-Host "No lockfile found: running npm install..."
      npm install --silent
    }
  } catch {
    Write-Host "Dependency install failed: $_"
    Pop-Location
    $obj = [ordered]@{ success = $false; note = "install_failed" }
    $obj | ConvertTo-Json -Depth 5 | Out-File -Encoding utf8 (Join-Path $OutDir 'summary.txt')
    return 3
  }

  New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
  $jsonFile = Join-Path $OutDir 'test-results.json'

  if ($ConfigPath -and (Test-Path (Join-Path $RepoRoot $ConfigPath))) {
    $configFull = Join-Path $RepoRoot $ConfigPath
    $cmd = "npx jest --config `"$configFull`" --runInBand --json --outputFile=`"$jsonFile`""
  } else {
    $cmd = "npx jest --runInBand --json --outputFile=`"$jsonFile`""
  }

  Write-Host "Running: $cmd"
  Invoke-Expression $cmd
  $rc = $LASTEXITCODE

  if (Test-Path $jsonFile) {
    try {
      $j = Get-Content $jsonFile -Raw | ConvertFrom-Json
      $summary = [ordered]@{
        success = $j.success
        numTotalTests = $j.numTotalTests
        numPassedTests = $j.numPassedTests
        numFailedTests = $j.numFailedTests
        numTotalTestSuites = $j.numTotalTestSuites
        numFailedTestSuites = $j.numFailedTestSuites
        startTime = $j.startTime
        endTime = [int64]((Get-Date).ToUniversalTime() - (Get-Date '1970-01-01')).TotalMilliseconds
      }
      $summary | ConvertTo-Json -Depth 5 | Out-File -Encoding utf8 (Join-Path $OutDir 'summary.txt')
      Write-Host "Wrote summary to: $OutDir\summary.txt"
    } catch {
      Write-Host "Failed to parse or write JSON summary: $_"
      "error_parsing_json" | Out-File -Encoding utf8 (Join-Path $OutDir 'summary.txt')
    }
  } else {
    Write-Host "Jest did not produce $jsonFile (rc=$rc). Creating placeholder summary."
    "NO_JSON_RC_$rc" | Out-File -Encoding utf8 (Join-Path $OutDir 'summary.txt')
  }

  Pop-Location
  return $rc
}

# Execute tasks and capture numeric return codes
$rc_web = [int](Run-Task -TaskRelativePath 'react-web' -OutDir $OutReactWeb -ConfigPath 'react-web/jest.config.cjs')
$rc_mobile = [int](Run-Task -TaskRelativePath 'react-mobile' -OutDir $OutReactNative -ConfigPath 'react-mobile/jest.config.cjs')

Write-Host "=== Autograde finished ==="
Write-Host "react-web rc: $rc_web => results at $OutReactWeb"
Write-Host "react-mobile rc: $rc_mobile => results at $OutReactNative"

if ($rc_web -ne 0 -or $rc_mobile -ne 0) {
  Write-Host "One or more tasks failed (rc_web=$rc_web, rc_mobile=$rc_mobile)" -ForegroundColor Red
  exit 2
}

exit 0