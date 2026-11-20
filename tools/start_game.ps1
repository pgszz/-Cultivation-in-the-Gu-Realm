[CmdletBinding()]
param(
    [string]$GodotPath,
    [string]$ProjectPath,
    [switch]$PrepareOnly
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)

function Quote-Arguments([string[]]$Values) {
    # Paths cannot contain a double quote on Windows. Pass arguments directly to
    # the executable, never through cmd.exe or a generated shell expression.
    return (($Values | ForEach-Object { '"' + $_ + '"' }) -join ' ')
}

function Read-Log([string]$Path) {
    if (Test-Path -LiteralPath $Path) {
        $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
        $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::UTF8)
        try { return $reader.ReadToEnd() }
        finally { $reader.Dispose() }
    }
    return ''
}

function Has-EngineError([string]$Text) {
    return $Text -match '(?im)SCRIPT ERROR|Parse Error:|^\s*(?:USER )?ERROR:'
}

function Invoke-EngineCheck([string]$Label, [string[]]$EngineArguments) {
    $stdout = Join-Path $logDirectory ($Label + '.stdout.log')
    $stderr = Join-Path $logDirectory ($Label + '.stderr.log')
    $process = Start-Process -FilePath $GodotPath -ArgumentList (Quote-Arguments $EngineArguments) -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    $null = $process.Handle
    if (-not $process.WaitForExit(180000)) {
        $process.Kill()
        throw "$Label timed out. Logs: $logDirectory"
    }
    $process.WaitForExit()
    $process.Refresh()
    $output = (Read-Log $stdout) + (Read-Log $stderr)
    if ($process.ExitCode -ne 0 -or (Has-EngineError $output)) {
        Write-Host $output
        throw "$Label failed. Logs: $logDirectory"
    }
    return $output
}

try {
    if (-not $ProjectPath) { $ProjectPath = Join-Path $PSScriptRoot '../godot' }
    $ProjectPath = (Resolve-Path -LiteralPath $ProjectPath).Path
    if (-not (Test-Path -LiteralPath (Join-Path $ProjectPath 'project.godot'))) {
        throw "project.godot was not found in $ProjectPath"
    }
    if (-not $GodotPath) {
        foreach ($name in @('Godot_v4.3-stable_win64_console.exe', 'Godot_v4.3-stable_win64.exe', 'godot.exe')) {
            $command = Get-Command $name -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($command) { $GodotPath = $command.Source; break }
        }
        if (-not $GodotPath -and $env:LOCALAPPDATA) {
            $candidate = Join-Path $env:LOCALAPPDATA 'Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.3-stable_win64_console.exe'
            if (Test-Path -LiteralPath $candidate) { $GodotPath = $candidate }
        }
    }
    if (-not $GodotPath) { throw 'Godot 4.3 was not found. Use -GodotPath to specify its executable.' }
    $GodotPath = (Resolve-Path -LiteralPath $GodotPath).Path
    $logDirectory = Join-Path $PSScriptRoot ('../.launch-logs/' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0, 6))
    $logDirectory = (New-Item -ItemType Directory -Path $logDirectory -Force).FullName
    $version = (Invoke-EngineCheck 'version' @('--version')).Trim()
    if ($version -notmatch '^4\.3\.stable(?:\.|$)') {
        throw "This project requires Godot 4.3 stable; found $version"
    }
    Write-Host "Godot $version"
    Write-Host 'Preparing scripts and resources...'
    $null = Invoke-EngineCheck 'import' @('--headless', '--editor', '--path', $ProjectPath, '--import')
    Write-Host "Import passed. Logs: $logDirectory"
    if ($PrepareOnly) { exit 0 }

    # Use the GUI executable when it is installed beside the console wrapper.
    $gameExecutable = $GodotPath -replace '_console\.exe$', '.exe'
    if (-not (Test-Path -LiteralPath $gameExecutable)) { $gameExecutable = $GodotPath }
    $runtimeLog = Join-Path $logDirectory 'game.log'
    $gameArguments = @('--path', $ProjectPath, '--log-file', $runtimeLog, '--', '--startup-report')
    $gameProcess = Start-Process -FilePath $gameExecutable -ArgumentList (Quote-Arguments $gameArguments) -WorkingDirectory $ProjectPath -WindowStyle Normal -PassThru
    $deadline = [DateTime]::UtcNow.AddSeconds(60)
    while ([DateTime]::UtcNow -lt $deadline) {
        Start-Sleep -Milliseconds 200
        $gameProcess.Refresh()
        $output = Read-Log $runtimeLog
        if (Has-EngineError $output) {
            # Close only this failed startup, before a character can be loaded.
            if (-not $gameProcess.HasExited) { $null = $gameProcess.CloseMainWindow() }
            Write-Host $output
            throw "Game startup failed. Log: $runtimeLog"
        }
        if ($gameProcess.HasExited) { throw "The game closed during startup. Log: $runtimeLog" }
        if ($output -match '(?m)^GUDAO_STARTUP_READY\s*$') {
            Write-Host "Character selection ready. PID=$($gameProcess.Id) Log: $runtimeLog"
            exit 0
        }
    }
    throw "Startup was not confirmed within 60 seconds. Inspect the game window and log: $runtimeLog"
} catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
}
