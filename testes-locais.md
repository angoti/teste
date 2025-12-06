# CI -Comandos para testar localmente:

## A. Execução única (recomendada — usa os runners que já instalamos)

- Executa instalação e testes para ambos os pacotes e gera results/*

PowerShell:

```powershell
# Na raiz do repo
# Executa ambos os projetos separadamente
PowerShell -ExecutionPolicy Bypass -File .\grading\run_autograde.ps1        # React Web
PowerShell -ExecutionPolicy Bypass -File .\grading\run_autograde_mobile.ps1 # React Mobile

# Ou execute ambos em sequência:
.\grading\run_autograde.ps1; .\grading\run_autograde_mobile.ps1
```

**Nota:** O script `run_autograde_mobile.ps1` detecta automaticamente se a pasta é `react-mobile` ou `react-native` e ajusta o caminho de saída para `results/react-native/` (mantendo compatibilidade com o workflow do CI).

## B. Executar manualmente por pacote

1) React Web (executar a partir da raiz)

```powershell
# instalar deps (opcional se já instalou)
Set-Location .\react-web
npm install

# rodar jest a partir da pasta react-web (garante <rootDir> correto)
npx jest --config ./jest.config.cjs --runInBand --json --outputFile=../results/react-web/test-results.json

# voltar para a raiz e conferir
Set-Location ..
Get-ChildItem .\results\react-web
Get-Content .\results\react-web\test-results.json -Raw
```

2) React Mobile (executar a partir da raiz)

**Importante:** A pasta foi renomeada de `react-native` para `react-mobile`, mas os resultados ainda são salvos em `results/react-native/` para manter compatibilidade com o CI.

```powershell
# A pasta agora é "react-mobile"
Set-Location .\react-mobile

# instalar deps (se necessário)
npm install

# limpar cache do jest (recomendado após mudanças)
npx jest --clearCache

# rodar jest a partir da pasta do app (gera ../results/react-native/test-results.json)
# Nota: o caminho de saída mantém "react-native" para compatibilidade
npx jest --config ./jest.config.cjs --runInBand --json --outputFile=../results/react-native/test-results.json

# voltar para a raiz e conferir
Set-Location ..
Get-ChildItem .\results\react-native
Get-Content .\results\react-native\test-results.json -Raw
```

**Alternativa usando o runner:**

```powershell
# Na raiz do repo - usa o script que detecta automaticamente react-mobile ou react-native
PowerShell -ExecutionPolicy Bypass -File .\grading\run_autograde_mobile.ps1
```

## C. Regenerar / atualizar summary.txt a partir do test-results.json
(Roda na raiz do repo; gera/atualiza results/<pkg>/summary.txt a partir do JSON mais recente)

```powershell
# Para react-web
$pkg = 'react-web'
$jr = Join-Path (Get-Location) "results\$pkg\test-results.json"
$out = Join-Path (Get-Location) "results\$pkg\summary.txt"
if (-not (Test-Path $jr)) { Write-Error "Arquivo não encontrado: $jr"; exit 1 }
$j = Get-Content $jr -Raw | ConvertFrom-Json
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
$summary | ConvertTo-Json -Depth 5 | Out-File -Encoding utf8 $out
Write-Output "Wrote summary: $out"
Get-Content -Path $out -Raw

# Para react-mobile (resultados salvos em results/react-native/)
$pkg = 'react-native'  # Nota: caminho mantido como react-native para compatibilidade
$jr = Join-Path (Get-Location) "results\$pkg\test-results.json"
$out = Join-Path (Get-Location) "results\$pkg\summary.txt"
if (-not (Test-Path $jr)) { Write-Error "Arquivo não encontrado: $jr"; exit 1 }
$j = Get-Content $jr -Raw | ConvertFrom-Json
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
$summary | ConvertTo-Json -Depth 5 | Out-File -Encoding utf8 $out
Write-Output "Wrote summary: $out"
Get-Content -Path $out -Raw
```

## D. Comandos úteis de diagnóstico

```powershell
# Ver quais arquivos em results e timestamps
Get-ChildItem results\react-web | Select-Object Name,LastWriteTime
Get-ChildItem results\react-native | Select-Object Name,LastWriteTime

# Mostrar um resumo curto dos JSONs (na raiz)
if (Test-Path .\results\react-web\test-results.json) { 
  Write-Host "=== React Web ===" -ForegroundColor Cyan
  Get-Content .\results\react-web\test-results.json -Raw | ConvertFrom-Json | Select-Object success,numTotalTests,numPassedTests,numFailedTests 
} 
if (Test-Path .\results\react-native\test-results.json) { 
  Write-Host "=== React Mobile ===" -ForegroundColor Cyan
  Get-Content .\results\react-native\test-results.json -Raw | ConvertFrom-Json | Select-Object success,numTotalTests,numPassedTests,numFailedTests 
} 

# Limpar cache do jest (se precisar depois de alterar configs)
# Na pasta do projeto específico:
Set-Location .\react-web; npx jest --clearCache; Set-Location ..
Set-Location .\react-mobile; npx jest --clearCache; Set-Location ..
```

## GitHub Actions

### 1) Rodar o workflow manualmente (pela UI)

- Vá em GitHub → seu repositório → Actions → Autograde CI → Run workflow (ou re-run the latest run).

### 2) Rodar/re-executar o workflow pela CLI (gh)

- Listar últimos runs:
  gh run list --workflow autograde.yml --limit 10
- Executar o workflow (dispara um run no branch main):
  gh workflow run autograde.yml --ref main
- Re-executar um run existente (pega o run-id da listagem):
  gh run rerun <run-id>

### 3) Ver logs e baixar artifacts

- Ver detalhes de um run:
  gh run view <run-id> --log
- Baixar artifacts do run (substitua <run-id> e o nome do artifact conforme aparece):
  gh run download <run-id> --name autograde-results-ubuntu-latest --dir ./artifacts
