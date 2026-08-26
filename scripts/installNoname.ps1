$ErrorActionPreference = 'Stop'

$repository = 'https://github.com/zksecurity/noname.git'
$revision = '0e91c05b60b2c5a1b4ca9f7da71f61220531ed66'
$rustToolchain = '1.79.0'
$installRoot = Join-Path $PSScriptRoot "../.cache/noname/$revision"
$binary = Join-Path $installRoot 'bin/noname.exe'

if (Test-Path -LiteralPath $binary) {
    & $binary --version
    exit 0
}

New-Item -ItemType Directory -Force -Path $installRoot | Out-Null
rustup toolchain install $rustToolchain --profile minimal --no-self-update
if ($LASTEXITCODE -ne 0) {
    throw "Pinned Rust $rustToolchain installation failed with exit code $LASTEXITCODE."
}

$previousCargoGitFetchWithCli = [Environment]::GetEnvironmentVariable('CARGO_NET_GIT_FETCH_WITH_CLI', 'Process')
$previousGitConfigCount = [Environment]::GetEnvironmentVariable('GIT_CONFIG_COUNT', 'Process')
$previousGitConfigKey0 = [Environment]::GetEnvironmentVariable('GIT_CONFIG_KEY_0', 'Process')
$previousGitConfigValue0 = [Environment]::GetEnvironmentVariable('GIT_CONFIG_VALUE_0', 'Process')

try {
    # Kimchi contains paths that exceed the legacy Windows limit. Keep these
    # overrides process-local so a clean checkout installs without global Git changes.
    $env:CARGO_NET_GIT_FETCH_WITH_CLI = 'true'
    $env:GIT_CONFIG_COUNT = '1'
    $env:GIT_CONFIG_KEY_0 = 'core.longpaths'
    $env:GIT_CONFIG_VALUE_0 = 'true'

    rustup run $rustToolchain cargo install --locked --git $repository --rev $revision --root $installRoot noname
    if ($LASTEXITCODE -ne 0) {
        throw "Pinned Noname installation failed with exit code $LASTEXITCODE."
    }
}
finally {
    [Environment]::SetEnvironmentVariable('CARGO_NET_GIT_FETCH_WITH_CLI', $previousCargoGitFetchWithCli, 'Process')
    [Environment]::SetEnvironmentVariable('GIT_CONFIG_COUNT', $previousGitConfigCount, 'Process')
    [Environment]::SetEnvironmentVariable('GIT_CONFIG_KEY_0', $previousGitConfigKey0, 'Process')
    [Environment]::SetEnvironmentVariable('GIT_CONFIG_VALUE_0', $previousGitConfigValue0, 'Process')
}

if (-not (Test-Path -LiteralPath $binary)) {
    throw "Pinned Noname binary was not installed at $binary."
}

& $binary --version
if ($LASTEXITCODE -ne 0) {
    throw "Pinned Noname executable check failed with exit code $LASTEXITCODE."
}
