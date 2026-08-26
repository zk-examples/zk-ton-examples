$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$compilerVersion = '2.2.3'
$compilerSha256 = 'e43f132ee6f0aa79b705beceb59c2a7e6a54d7bdeab917ca34e9fc1951d185e1'
$compilerUrl = 'https://github.com/iden3/circom/releases/download/v2.2.3/circom-windows-amd64.exe'
$expectedSourceSha256 = 'b5593cb4ee3d75bcfbd47490680c1a1143843e3bd69490d9e4caaccc0182aef7'
$expectedWasmSha256 = '091863c47764a6607d66938711ecadd8003508715a7878ab65ed962425cdcc2a'
$compilerCacheDirectory = Join-Path $repositoryRoot ".cache\circom\v$compilerVersion"
$cachedCompilerPath = Join-Path $compilerCacheDirectory 'circom-windows-amd64.exe'
$compilerPath = if ($env:CIRCOM_BIN) { $env:CIRCOM_BIN } else { $cachedCompilerPath }
$circuitDirectory = Join-Path $repositoryRoot 'circuits\Multiplier'
$sourcePath = Join-Path $circuitDirectory 'Multiplier.circom'
$r1csPath = Join-Path $circuitDirectory 'Multiplier.r1cs'
$symPath = Join-Path $circuitDirectory 'Multiplier.sym'
$wasmPath = Join-Path $circuitDirectory 'Multiplier_js\Multiplier.wasm'
$temporaryBase = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
$temporaryRoot = Join-Path $temporaryBase ("zk-ton-examples-circom-" + [System.Guid]::NewGuid().ToString('N'))

function Get-Sha256([string] $path) {
    $stream = [System.IO.File]::OpenRead($path)
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        return ([System.BitConverter]::ToString($sha256.ComputeHash($stream))).Replace('-', '').ToLowerInvariant()
    }
    finally {
        $sha256.Dispose()
        $stream.Dispose()
    }
}

if ((Get-Sha256 $sourcePath) -ne $expectedSourceSha256) {
    throw 'Multiplier.circom changed; review the circuit and update the expected artifact hashes.'
}

if (-not (Test-Path -LiteralPath $compilerPath -PathType Leaf)) {
    if ($env:CIRCOM_BIN) {
        throw "CIRCOM_BIN does not point to a file: $compilerPath"
    }

    New-Item -ItemType Directory -Path $compilerCacheDirectory -Force | Out-Null
    $downloadPath = [System.IO.Path]::GetTempFileName()
    try {
        Write-Host "Downloading official Circom $compilerVersion release..."
        Invoke-WebRequest -Uri $compilerUrl -OutFile $downloadPath
        $downloadHash = Get-Sha256 $downloadPath
        if ($downloadHash -ne $compilerSha256) {
            throw "Downloaded Circom SHA-256 mismatch: $downloadHash"
        }
        Move-Item -LiteralPath $downloadPath -Destination $cachedCompilerPath
    }
    finally {
        Remove-Item -LiteralPath $downloadPath -Force -ErrorAction SilentlyContinue
    }
}

$actualCompilerHash = Get-Sha256 $compilerPath
if ($actualCompilerHash -ne $compilerSha256) {
    throw "Circom SHA-256 mismatch: expected $compilerSha256, got $actualCompilerHash"
}
$actualCompilerVersion = (& $compilerPath --version 2>&1 | Out-String).Trim()
if ($actualCompilerVersion -ne "circom compiler $compilerVersion") {
    throw "Circom version mismatch: expected $compilerVersion, got $actualCompilerVersion"
}

$standardOutput = [System.IO.Path]::GetTempFileName()
$standardError = [System.IO.Path]::GetTempFileName()
try {
    New-Item -ItemType Directory -Path $temporaryRoot | Out-Null
    Copy-Item -LiteralPath $sourcePath -Destination (Join-Path $temporaryRoot 'Multiplier.circom')
    $compiler = Start-Process `
        -FilePath $compilerPath `
        -ArgumentList @('Multiplier.circom', '--r1cs', '--wasm', '--sym', '--prime', 'bls12381', '--output=.') `
        -WorkingDirectory $temporaryRoot `
        -RedirectStandardOutput $standardOutput `
        -RedirectStandardError $standardError `
        -WindowStyle Hidden `
        -Wait `
        -PassThru

    $compilerOutput = Get-Content -LiteralPath $standardOutput -Raw
    $compilerError = Get-Content -LiteralPath $standardError -Raw
    if ($compilerOutput) {
        Write-Host $compilerOutput.TrimEnd()
    }
    if ($compilerError) {
        [Console]::Error.WriteLine($compilerError.TrimEnd())
    }
    if ($compiler.ExitCode -ne 0) {
        throw "Circom failed with exit code $($compiler.ExitCode)."
    }

    $temporaryWasmPath = Join-Path $temporaryRoot 'Multiplier_js\Multiplier.wasm'
    $actualWasmSha256 = Get-Sha256 $temporaryWasmPath
    if ($actualWasmSha256 -ne $expectedWasmSha256) {
        throw "Multiplier WASM is not reproducible: expected $expectedWasmSha256, got $actualWasmSha256"
    }
    New-Item -ItemType Directory -Path (Split-Path -Parent $wasmPath) -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $temporaryRoot 'Multiplier.r1cs') -Destination $r1csPath -Force
    Copy-Item -LiteralPath (Join-Path $temporaryRoot 'Multiplier.sym') -Destination $symPath -Force
    Copy-Item -LiteralPath $temporaryWasmPath -Destination $wasmPath -Force
    Write-Host "Multiplier R1CS, SYM, and WASM rebuilt; WASM verified: $actualWasmSha256"
}
finally {
    Remove-Item -LiteralPath $standardOutput, $standardError -Force -ErrorAction SilentlyContinue
    $resolvedTemporaryRoot = [System.IO.Path]::GetFullPath($temporaryRoot)
    if ($resolvedTemporaryRoot.StartsWith($temporaryBase, [System.StringComparison]::OrdinalIgnoreCase)) {
        Remove-Item -LiteralPath $resolvedTemporaryRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
