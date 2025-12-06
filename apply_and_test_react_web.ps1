#!/usr/bin/env pwsh
<#
  apply_and_test_react_web.ps1

  Cria/atualiza arquivos mínimos em react-web (babel/jest/mocks/App/App.test)
  instala dependências e executa jest gerando:
    - results/react-web/test-results.json
    - results/react-web/summary.txt

  Uso (na raiz do repo, ex.: E:\template-autenticacao):
    PowerShell -ExecutionPolicy Bypass -File .\apply_and_test_react_web.ps1

  Observações:
  - Não altera react-web/package.json existente.
  - Faz backup de arquivos que já existirem (sufixo .bak).
  - Requer Node/npm disponíveis no PATH.
#>

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ReactDir = Join-Path $RepoRoot 'react-web'
$SrcDir = Join-Path $ReactDir 'src'
$MocksDir = Join-Path $ReactDir '__mocks__'
$ResultsDir = Join-Path $RepoRoot 'results\react-web'
$RunShPath = Join-Path $RepoRoot 'grading\run_autograde.ps1'

# Helpers
function Backup-IfExists {
  param($path)
  if (Test-Path $path) {
    $bak = "$path.bak"
    Write-Output "Backup existing: $path -> $bak"
    Copy-Item -Force $path $bak
  }
}

function Write-File {
  param($path, $content)
  $dir = Split-Path -Parent $path
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  Backup-IfExists $path
  $content | Out-File -Encoding utf8 -FilePath $path -Force
  Write-Output "Wrote: $path"
}

# Create dirs
New-Item -ItemType Directory -Path $SrcDir -Force | Out-Null
New-Item -ItemType Directory -Path $MocksDir -Force | Out-Null
New-Item -ItemType Directory -Path (Split-Path -Parent $RunShPath) -Force | Out-Null
New-Item -ItemType Directory -Path $ResultsDir -Force | Out-Null

# Files to add/update (won't touch package.json)
$babelCfg = @'
module.exports = {
  presets: [
    ['@babel/preset-env', { targets: { node: 'current' } }],
    ['@babel/preset-react', { runtime: 'automatic' }]
  ]
};
'@

$jestCfg = @'
module.exports = {
  testEnvironment: "jest-environment-jsdom",
  testEnvironmentOptions: { resources: "usable" },
  transform: {
    "^.+\\.[tj]sx?$": ["babel-jest", { configFile: "<rootDir>/babel.config.cjs" }]
  },
  setupFilesAfterEnv: ["<rootDir>/src/setupTests.js"],
  transformIgnorePatterns: ["/node_modules/"],
  moduleFileExtensions: ["js","jsx","ts","tsx","json","node"],
  moduleNameMapper: {
    "\\.(css|less|scss|sass)$": "<rootDir>/__mocks__/styleMock.js",
    "\\.(gif|ttf|eot|svg|png|jpg|jpeg)$": "<rootDir>/__mocks__/fileMock.js"
  }
};
'@

$appJsx = @'
import React from "react";

export default function App() {
  return (
    <div>
      <h1>Hello React Assignment</h1>
      <p>Implemente sua tarefa aqui.</p>
    </div>
  );
}
'@

$appTest = @'
import React from "react";
import { render, screen } from "@testing-library/react";
import "@testing-library/jest-dom";
import App from "./App.jsx";

test("renders heading", () => {
  render(<App />);
  expect(screen.getByText(/Hello React Assignment|Hello React/i)).toBeInTheDocument();
});
'@

$setupTests = @'
import "@testing-library/jest-dom";
'@

$styleMock = "module.exports = {};"
$fileMock = "module.exports = 'test-file-stub';"

# Write files
Write-File -path (Join-Path $ReactDir 'babel.config.cjs') -content $babelCfg
Write-File -path (Join-Path $ReactDir 'jest.config.cjs') -content $jestCfg
Write-File -path (Join-Path $SrcDir 'App.jsx') -content $appJsx
Write-File -path (Join-Path $SrcDir 'App.test.js') -content $appTest
Write-File -path (Join-Path $SrcDir 'setupTests.js') -content $setupTests
Write-File -path (Join-Path $MocksDir 'styleMock.js') -content $styleMock
Write-File -path (Join-Path $MocksDir 'fileMock.js') -content $fileMock

# Optional runner (PowerShell) — overwrite safe
$runner = @'
#!/usr/bin/env pwsh
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$ResultsDir = Join-Path $RepoRoot "results\react-web"
New-Item -ItemType Directory -Path $ResultsDir -Force | Out-Null

Push-Location (Join-Path $RepoRoot "react-web")
if (Test-Path package-lock.json -or Test-Path pnpm-lock.yaml -or Test-Path yarn.lock) {
  npm ci --silent
} else {
  npm install --silent
}
$npxCmd = "npx jest --config ./jest.config.cjs --runInBand --json --outputFile=../results/react-web/test-results.json"
Write-Output "Running: $npxCmd"
Invoke-Expression $npxCmd
Pop-Location

# create summary.txt from json
$json = Join-Path $RepoRoot "results\react-web\test-results.json"
if (Test-Path $json) {
  $j = Get-Content $json -Raw | ConvertFrom-Json
  $summary = [ordered]@{
    success = $j.success
    numTotalTests = $j.numTotalTests
    numPassedTests = $j.numPassedTests
    numFailedTests = $j.numFailedTests
    numTotalTestSuites = $j.numTotalTestSuites
    numFailedTestSuites = $j.numFailedTestSuites
    startTime = $j.startTime
    endTime = [int64]((Get-Date).ToUniversalTime() - (Get-Date "1970-01-01")).TotalMilliseconds
  }
  $summary | ConvertTo-Json -Depth 5 | Out-File -Encoding utf8 (Join-Path $RepoRoot "results\react-web\summary.txt")
  Write-Output "Wrote summary: results\react-web\summary.txt"
} else {
  Write-Output "No test-results.json found."
}
'@

Write-File -path $RunShPath -content $runner

# Install dependencies and run tests
Write-Output "`n==> Installing dependencies in react-web (npm install)..."
Push-Location $ReactDir
npm install
Pop-Location

Write-Output "`n==> Running jest (this may install jest transiently via npx)..."
try {
  npx jest --config "$ReactDir/jest.config.cjs" --runInBand --json --outputFile="$ResultsDir/test-results.json"
  $rc = $LASTEXITCODE
} catch {
  Write-Output "Jest execution failed: $_"
  $rc = 1
}

# Generate summary if not already generated by runner
if (Test-Path (Join-Path $ResultsDir 'test-results.json')) {
  try {
    $j = Get-Content (Join-Path $ResultsDir 'test-results.json') -Raw | ConvertFrom-Json
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
    $summary | ConvertTo-Json -Depth 5 | Out-File -Encoding utf8 (Join-Path $ResultsDir 'summary.txt')
    Write-Output "Summary written to: $ResultsDir\summary.txt"
  } catch {
    Write-Output "Failed to write summary: $_"
  }
} else {
  Write-Output "test-results.json not found in $ResultsDir (jest may have errored)."
}

if ($rc -ne 0) {
  Write-Output "Finished with non-zero exit code: $rc"
  exit $rc
}
Write-Output "All done. Results in: $ResultsDir"
exit 0