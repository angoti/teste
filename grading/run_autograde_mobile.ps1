#!/usr/bin/env pwsh
# Runner para mobile (corrige uso de Test-Path com -or)
$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$ResultsDir = Join-Path $RepoRoot 'results'
$OutReactNative = Join-Path $ResultsDir 'react-mobile'
New-Item -ItemType Directory -Path $OutReactNative -Force | Out-Null

function Run-Mobile {
  param(
    [string]$TaskDirName = 'react-mobile'
  )

  $TaskDir = Join-Path $RepoRoot $TaskDirName
  Write-Host "==> Autograde: $TaskDirName at $TaskDir"

  if (-not (Test-Path $TaskDir)) {
    Write-Host "Mobile project directory not found: $TaskDirName. Skipping."
    @{ success = $false; note = "missing_dir" } | ConvertTo-Json -Depth 5 | Out-File -Encoding utf8 (Join-Path $OutReactNative 'summary.txt')
    return 2
  }

  Push-Location $TaskDir
  try {
    $lockA = Test-Path (Join-Path $TaskDir 'package-lock.json')
    $lockB = Test-Path (Join-Path $TaskDir 'pnpm-lock.yaml')
    $lockC = Test-Path (Join-Path $TaskDir 'yarn.lock')
    $hasLock = $lockA -or $lockB -or $lockC

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
    @{ success = $false; note = "install_failed" } | ConvertTo-Json -Depth 5 | Out-File -Encoding utf8 (Join-Path $OutReactNative 'summary.txt')
    return 3
  }

  $jsonFile = Join-Path $OutReactNative 'test-results.json'
  $jestConfig = Join-Path $TaskDir 'jest.config.cjs'
  if (Test-Path $jestConfig) {
    $cmd = "npx jest --config `"$jestConfig`" --runInBand --json --outputFile=`"$jsonFile`""
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
      $summary | ConvertTo-Json -Depth 5 | Out-File -Encoding utf8 (Join-Path $OutReactNative 'summary.txt')
      Write-Host "Wrote summary to: $OutReactNative\summary.txt"
    } catch {
      Write-Host "Failed to parse or write JSON summary: $_"
      "error_parsing_json" | Out-File -Encoding utf8 (Join-Path $OutReactNative 'summary.txt')
    }
  } else {
    Write-Host "Jest did not produce $jsonFile (rc=$rc). Creating placeholder summary."
    "NO_JSON_RC_$rc" | Out-File -Encoding utf8 (Join-Path $OutReactNative 'summary.txt')
  }

  Pop-Location
  return $rc
}

# Try standard names (react-mobile first, then react-native)
if (Test-Path (Join-Path $RepoRoot 'react-mobile')) {
  exit (Run-Mobile -TaskDirName 'react-mobile')
} elseif (Test-Path (Join-Path $RepoRoot 'react-mobile')) {
  exit (Run-Mobile -TaskDirName 'react-mobile')
} else {
  Write-Host "No mobile project detected (react-mobile/react-native). Nothing to run."
  exit 0
}