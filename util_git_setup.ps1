function NewDevCfg {
    return [PSCustomObject] @{
        "gitDir"     = $null
        "includeDir" = $null
        "libDir"     = $null
        "utilDir"    = $null
    }
}

function ScriptMain() {
    $devCfg = NewDevCfg
    
    # ask user where to put the development directories
    do {
        $devCfg.gitDir = ReadHost("Select GIT directory")
    } while (-not(ValidatePath($devCfg.gitDir)))
    
    do {
        $devCfg.includeDir = ReadHost("Select INCLUDE directory")
    } while (-not(ValidatePath($devCfg.includeDir)))

    do {
        $devCfg.libDir = ReadHost("Select LIB directory")
    } while (-not(ValidatePath($devCfg.libDir)))

    do {
        $devCfg.utilDir = ReadHost("Select UTIL directory")
    } while (-not(ValidatePath($devCfg.utilDir)))

    # confirm desired setup parameters
    Write-Host "`n--------"
    Write-Host "GIT directory      : " $devCfg.gitDir
    Write-Host "INCLUDE directory  : " $devCfg.includeDir
    Write-Host "LIB directory      : " $devCfg.libDir
    Write-Host "UTIL directory     : " $devCfg.utilDir
    Write-Host "--------`n"
    if (-not(Confirm("Create environment using the above config?"))) {
        return [EXIT_CODE]::INCOMPLETE
    }

    # set environment variables
    [Environment]::SetEnvironmentVariable("GIT", "$($devCfg.gitDir)", "User")
    [Environment]::SetEnvironmentVariable("INCLUDE", "$($devCfg.includeDir)", "User")
    [Environment]::SetEnvironmentVariable("LIB", "$($devCfg.libDir)", "User")
    [Environment]::SetEnvironmentVariable("UTIL", "$($devCfg.utilDir)", "User")

    # create directories if don't exist
    New-Item -ItemType Directory -Force -Path $devCfg.gitDir | Out-Null
    New-Item -ItemType Directory -Force -Path $devCfg.includeDir | Out-Null
    New-Item -ItemType Directory -Force -Path $devCfg.libDir | Out-Null
    New-Item -ItemType Directory -Force -Path $devCfg.utilDir | Out-Null
    
    # save context
    PushCtx | Out-Null

    # clone desired git repos
    $gitRepos = 
    "https://github.com/azydevelopment/util-powershell.git",
    "https://github.com/azydevelopment/preferences-store.git",
    "https://github.com/azydevelopment/core.git",
    "https://github.com/azydevelopment/embedded.git",
    "https://github.com/azydevelopment/template-atmelstudio.git",
    "https://github.com/azydevelopment/util-src-flattener.git",
    "https://github.com/azydevelopment/template-readme.git"

    Set-Location $devCfg.gitDir
    foreach ($gitRepo in $gitRepos) {
        PushCtx | Out-Null
        Write-Host "`n------------------"
        $host.ui.RawUI.ForegroundColor = "Cyan"
        Write-Host $gitRepo
        PopCtx | Out-Null
        git clone $gitRepo
    }
    
    # copy utils into the $env:UTIL folder
    Copy-Item .\util-powershell\*.ps1 $env:UTIL

    # copy clang-format config file into $env:GIT for use
    Copy-Item .\preferences-store\clang\.clang-format .\
    
    # restore context
    PopCtx | Out-Null
    
    # TODO IMPLEMENT: Copy utils into the util folder

    # if we got here, all is good
    return [EXIT_CODE]::SUCCESS
}

function ScriptCleanup {
    Remove-Item -Path Function:\NewDevCfg
}

# use the script runner to execute ScriptMain

if (Test-Path .\util_powershell_runner.ps1) {
    .\util_powershell_runner.ps1
}
else {
    Invoke-Expression "${env:UTIL}\util_powershell_runner.ps1"
}