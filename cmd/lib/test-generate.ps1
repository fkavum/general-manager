<#
.SYNOPSIS
  Golden test for what the Windows launcher GENERATES - not for what it launches.

.DESCRIPTION
  test-panes.cmd proves the panes open and run; nothing proved what was IN them.
  That gap shipped a real bug on the shell side: run.sh kept its --app-env value
  in a variable called APP_ENV and wrote it into the pane environment, and docker
  compose resolves a variable from the environment BEFORE --env-file - so the
  client image baked appsettings..env.local.json and the build died. run.cmd had
  the identical bug in env.cmd. Against a golden file that is a one-line diff.

  Runs the real run.cmd --dry-run against a throwaway fixture project, with stub
  docker/dotnet/flutter on PATH, so it needs no daemon, no SDKs, and touches
  nothing outside its temp folder. Then it diffs .run\env.cmd and every generated
  pane script against testdata\golden\, and enforces the env.cmd set contract.

  Windows half of ..\..\bash\lib\test-generate.sh, with the same fixture, the
  same three cases and the same contract - but its OWN goldens, because the two
  halves generate batch and shell respectively.

  PowerShell rather than batch because batch cannot diff text, and this lib
  already leans on PowerShell for waitport, tailer and the port checks.
  test-generate.cmd is the entry point; it maps --update onto -Update.

.EXAMPLE
  .\test-generate.cmd
  .\test-generate.cmd --update
#>
[CmdletBinding()]
param(
  [switch]$Update,
  [switch]$Keep,
  [switch]$Help
)

$ErrorActionPreference = 'Stop'

if ($Help) {
  Get-Help -Full $MyInvocation.MyCommand.Path | Out-String | Write-Host
  exit 0
}

$Lib    = Split-Path -Parent $MyInvocation.MyCommand.Path
$Golden = Join-Path $Lib 'testdata\golden'

$script:Passed = 0
$script:Failed = 0
function Ok  ([string]$m) { Write-Host ('ok   ' + $m) -ForegroundColor Green; $script:Passed++ }
function Bad ([string]$m) { Write-Host ('FAIL ' + $m) -ForegroundColor Red;   $script:Failed++ }

function New-Dir ([string]$p) {
  if (-not (Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
}
function Write-Lines ([string]$p, [string[]]$lines) {
  Set-Content -LiteralPath $p -Value $lines -Encoding ASCII
}

# ------------------------------------------------------------------ fixture --
# A project with every shape a real project.cmd uses: shared infra + a wait, a
# dotnet service with both a Docker stack and a local project, an opt-in
# docker-only service with no env file, and a flutter-web client. One call per
# line - no ^ continuations, so the fixture cannot fail on a batch trap of its own.
$Root = Join-Path ([System.IO.Path]::GetTempPath()) ('gm-golden-' + [System.IO.Path]::GetRandomFileName().Replace('.', ''))
New-Dir $Root
$Runner  = Join-Path $Root 'manager\tools\cmd\runner'
$Manager = Join-Path $Root 'manager'
$StubBin = Join-Path $Root 'bin'
$OriginalPath = $env:PATH

try {
  foreach ($d in @(
    $Runner, $StubBin,
    (Join-Path $Root 'infra'),
    (Join-Path $Root 'api\Docker\Main'), (Join-Path $Root 'api\Src\Main'),
    (Join-Path $Root 'extra'),
    (Join-Path $Root 'client\Docker'), (Join-Path $Root 'client\Resources\Configs')
  )) { New-Dir $d }

  Write-Lines (Join-Path $Root 'infra\.env.test') @('MYSQL_PORT=20010')
  # the variable the launcher must never shadow: a client image bakes
  # appsettings.<APP_ENV>.json in, and compose reads it from THIS file
  Write-Lines (Join-Path $Root 'client\Docker\.env.local') @('APP_ENV=local')
  Write-Lines (Join-Path $Root 'client\Docker\.env.ci')    @('APP_ENV=ci')
  Write-Lines (Join-Path $Root 'client\Resources\Configs\appsettings.local.json') `
              @('{ "API_BASE_URL": "http://localhost:20200/api" }')

  Write-Lines (Join-Path $Runner 'project.cmd') @(
    '@echo off',
    'rem Fixture project for test-generate.cmd. Not a real stack; it exists to',
    'rem pin the generated output of every service shape.',
    'set "PROJECT=fixture"',
    'call "%GM_LIB%\tools.cmd" infra dir="%MANAGER_DIR%\..\infra" label="shared mysql"',
    'call "%GM_LIB%\tools.cmd" wait mysql key=MYSQL_PORT default=20010',
    'call "%GM_LIB%\tools.cmd" service name=api container=fixture-api port=20200 waits=mysql docker="%MANAGER_DIR%\..\api\Docker\Main" project="%MANAGER_DIR%\..\api\Src\Main"',
    'call "%GM_LIB%\tools.cmd" service name=extra container=fixture-extra port=20201 optional=1 env=- docker="%MANAGER_DIR%\..\extra"',
    'call "%GM_LIB%\tools.cmd" service name=client kind=flutter-web container=fixture-client port=20221 waits=api docker="%MANAGER_DIR%\..\client\Docker" project="%MANAGER_DIR%\..\client"',
    'exit /b 0'
  )

  # Stub EXECUTABLES, not .cmd files: run.cmd runs `docker info` directly, and a
  # batch file on PATH would transfer control and never come back (batch needs
  # `call` for that), so the run would end there having written no panes.
  $stubExe = Join-Path $StubBin 'docker.exe'
  try {
    Add-Type -TypeDefinition 'public class GmStub { public static int Main(string[] args) { return 0; } }' `
             -OutputAssembly $stubExe -OutputType ConsoleApplication
  } catch {
    throw ('could not build the stub executables: ' + $_.Exception.Message + [Environment]::NewLine +
           '  This test needs Windows PowerShell 5.1 (its C# compiler). Batch stubs cannot' + [Environment]::NewLine +
           '  stand in: run.cmd runs "docker info" without "call", so a docker.cmd on PATH' + [Environment]::NewLine +
           '  would end run.cmd right there. Run it through test-generate.cmd.')
  }
  Copy-Item -LiteralPath $stubExe -Destination (Join-Path $StubBin 'dotnet.exe')
  Copy-Item -LiteralPath $stubExe -Destination (Join-Path $StubBin 'flutter.exe')

  # -------------------------------------------------------------- normalizing --
  # Absolute paths are the only thing that differs between two correct runs, so
  # they are the only thing flattened. env.cmd carries no PATH and no OS name.
  $RootForms = @($Root)
  $resolved = (Resolve-Path -LiteralPath $Root).Path
  if ($resolved -ne $Root) { $RootForms += $resolved }

  function Normalize ([string[]]$lines) {
    $out = New-Object System.Collections.Generic.List[string]
    foreach ($line in $lines) {
      $l = $line -replace ('(?i)' + [regex]::Escape($Lib)), '<LIB>'
      foreach ($form in $RootForms) { $l = $l -replace ('(?i)' + [regex]::Escape($form)), '<ROOT>' }
      $out.Add($l)
    }
    return $out.ToArray()
  }

  function Invoke-Generate {   # <mode> [extra run.cmd args] - the launcher, as a wrapper calls it
    param([string]$Mode, [string[]]$Extra = @())
    $run = Join-Path $Runner '.run'
    if (Test-Path -LiteralPath $run) { Remove-Item -LiteralPath $run -Recurse -Force }
    $env:GM_TOOLS_DIR   = $Runner
    $env:GM_MANAGER_DIR = $Manager
    $env:PATH           = $StubBin + ';' + $OriginalPath
    # 'call' first, so cmd /c does not strip the quotes around the script path
    $cmdArgs = @('/c', 'call', (Join-Path $Lib 'run.cmd'), $Mode,
                 '--dry-run', '--no-terminal', '--infra-env=.env.test') + $Extra
    # 2>&1 on a native command turns stderr into ErrorRecords, which
    # $ErrorActionPreference='Stop' would throw on before we can report it
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $out = & $env:ComSpec @cmdArgs 2>&1
    $ErrorActionPreference = $prevEap
    if ($LASTEXITCODE -ne 0) {
      throw ("run.cmd " + $Mode + " exited " + $LASTEXITCODE + [Environment]::NewLine + ($out -join [Environment]::NewLine))
    }
  }

  function Get-Capture {   # everything the run left behind, in one normalized stream
    $run = Join-Path $Runner '.run'
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('=== .run/env.cmd')
    $lines.AddRange([string[]](Get-Content -LiteralPath (Join-Path $run 'env.cmd')))
    foreach ($f in (Get-ChildItem -LiteralPath $run -Filter '*-*.cmd' | Sort-Object Name)) {
      $lines.Add('=== .run/' + $f.Name)
      $lines.AddRange([string[]](Get-Content -LiteralPath $f.FullName))
    }
    return Normalize $lines.ToArray()
  }

  function Test-Golden {   # <name> <normalized text>
    param([string]$Name, [string[]]$Actual)
    $file = Join-Path $Golden ($Name + '.txt')
    if ($Update) {
      New-Dir $Golden
      Write-Lines $file $Actual
      Ok ($Name + '.txt updated')
      return
    }
    if (-not (Test-Path -LiteralPath $file)) {
      Bad ($Name + ': no golden yet - run --update and review the diff')
      return
    }
    $expected = [string[]](Get-Content -LiteralPath $file)
    $diff = Compare-Object -ReferenceObject $expected -DifferenceObject $Actual -SyncWindow 0
    if (-not $diff) { Ok $Name; return }
    Bad ($Name + ': generated output changed')
    foreach ($d in $diff) {
      $sign = '+'
      if ($d.SideIndicator -eq '<=') { $sign = '-' }
      Write-Host ('    ' + $sign + ' ' + $d.InputObject)
    }
  }

  # ----------------------------------------------------------------- the cases --
  Invoke-Generate 'docker';  $docker = Get-Capture      # the everyday command
  Invoke-Generate 'manual';  $manual = Get-Capture      # dotnet run + flutter run bodies
  # the flags that change what is generated: opt-in service, another app env file, no --build
  Invoke-Generate 'docker' @('--with=extra', '--app-env=.env.ci', '--no-build')
  $opts = Get-Capture

  Test-Golden 'docker'      $docker
  Test-Golden 'manual'      $manual
  Test-Golden 'docker-opts' $opts

  # ------------------------------------------------- the env.cmd set contract ---
  # Every pane calls .run\env.cmd, so every name set there reaches docker compose
  # and outranks --env-file. Only the launcher's own variables belong in it, and
  # anything new must be GM_-prefixed. The bare names below are the reviewed
  # legacy exceptions - do not add to them, add a GM_ one.
  $allowed = '^(GM_[A-Z0-9_]+|PATH|TOOLS_DIR|MANAGER_DIR|RUN_DIR|PROJECT|INFRA_DIR|INFRA_ENV_FILE|INFRA_LABEL)$'
  Invoke-Generate 'docker'
  $bad = @()
  foreach ($line in (Get-Content -LiteralPath (Join-Path $Runner '.run\env.cmd'))) {
    if ($line -match '^\s*set\s+"([A-Za-z0-9_]+)=') {
      if ($Matches[1] -cnotmatch $allowed) { $bad += $Matches[1] }
    }
  }
  if ($bad.Count -eq 0) {
    Ok 'env.cmd sets only launcher-owned names'
  } else {
    Bad ('env.cmd sets names a pane must not see: ' + ($bad -join ' '))
    Write-Host '    Every pane calls env.cmd, and docker compose resolves a variable from the'
    Write-Host '    environment before --env-file - so a stack''s own variable of that name is'
    Write-Host '    silently overridden (this is exactly how APP_ENV broke the client build).'
    Write-Host '    Prefix the launcher''s variable with GM_ (see README, ''Conventions'').'
  }
}
finally {
  $env:PATH = $OriginalPath
  if ($Keep) { Write-Host ('kept: ' + $Root) }
  elseif (Test-Path -LiteralPath $Root) { Remove-Item -LiteralPath $Root -Recurse -Force -ErrorAction SilentlyContinue }
}

Write-Host ''
if ($script:Failed -eq 0) {
  Write-Host ('==> ' + $script:Passed + ' checks passed') -ForegroundColor Cyan
  exit 0
}
Write-Host ('==> ' + $script:Passed + ' passed, ' + $script:Failed + ' failed') -ForegroundColor Red
Write-Host '    Intended change? Re-run with --update and commit the golden diff.'
exit 1
