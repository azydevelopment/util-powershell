Enum EXIT_CODE {
    SUCCESS
    INCOMPLETE
    ERROR
}

function PrintError($msg) {
    PushCtx | Out-Null
    $host.ui.RawUI.ForegroundColor = "Red"
    Write-Host "ERROR: $msg"
    PopCtx | Out-Null
}

function ReadHost($prompt) {
    PushCtx | Out-Null
    $host.ui.RawUI.ForegroundColor = "Cyan"
    $response = Read-Host -Prompt "$prompt"
    PopCtx | Out-Null
    return $response
}

function GetCtx {
    return [PSCustomObject] @{
        "dir"       = Get-Location
        "fontColor" = $host.ui.RawUI.ForegroundColor
    }
}

function PushCtx {
    $ctx = GetCtx
    $gCtxStack.Push($ctx)
    return $gCtxStack.Count
}

function PopCtx {
    $ctx = $gCtxStack.Pop()
    Set-Location $ctx.dir
    $host.ui.RawUI.ForegroundColor = $ctx.fontColor
    return $gCtxStack.Count
}

function Quit([EXIT_CODE]$code) {
    switch ($code) {
        SUCCESS {
            $host.ui.RawUI.ForegroundColor = "Green"
        }
        INCOMPLETE {
            $host.ui.RawUI.ForegroundColor = "Yellow"
        }
        ERROR {
            $host.ui.RawUI.ForegroundColor = "Red"
        }
    }

    Write-Host "`nEXIT: $code"

    # restore to startup state
    while (PopCtx) {
    }

    exit $code
}

function ValidatePath($path) {
    if ([string]::IsNullOrEmpty($path)) {
        PrintError("Invalid path")
        return $false
    }

    try {
        $path = [System.IO.FileInfo]$path
    }
    catch [Exception] {
        PrintError("Invalid path")
        return $false
    }
    return $true
}

function Confirm($prompt) {
    while (1) {
        $response = ReadHost("$prompt [y/n]")

        if ($response -eq "n") {
            return $false
        }
        elseif ($response -eq "y") {
            return $true
        }
        else {
            PrintError("Invalid response")
        }
    }
}

### PROGRAM MAIN

function NewDevCfg {
    return [PSCustomObject] @{
        "gitDir"     = $null
        "includeDir" = $null
        "libDir"     = $null
    }
}

function Main() {
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

    # confirm desired setup parameters
    Write-Host "`n--------"
    Write-Host "GIT directory      : " $devCfg.gitDir
    Write-Host "INCLUDE directory  : " $devCfg.includeDir
    Write-Host "LIB directory      : " $devCfg.libDir
    Write-Host "--------`n"
    if (-not(Confirm("Create environment using the above config?"))) {
        return [EXIT_CODE]::INCOMPLETE
    }

    # set environment variables
    [Environment]::SetEnvironmentVariable("GIT", "$($devCfg.gitDir)", "User")
    [Environment]::SetEnvironmentVariable("INCLUDE", "$($devCfg.includeDir)", "User")
    [Environment]::SetEnvironmentVariable("LIB", "$($devCfg.libDir)", "User")

    # create directories if don't exist
    New-Item -ItemType Directory -Force -Path $devCfg.gitDir | Out-Null
    New-Item -ItemType Directory -Force -Path $devCfg.includeDir | Out-Null
    New-Item -ItemType Directory -Force -Path $devCfg.libDir | Out-Null
    
    # save context
    PushCtx | Out-Null

    # clone desired git repos
    $gitRepos = 
    "https://github.com/azydevelopment/util-powershell.git",
    "https://github.com/azydevelopment/preferences-store.git",
    "https://github.com/azydevelopment/core.git",
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
    
    # copy clang-format config file into $env:GIT for use
    Copy-Item .\preferences-store\clang\.clang-format .\
    
    # restore context
    PopCtx | Out-Null
    
    # if we got here, all is good
    return [EXIT_CODE]::SUCCESS
}


### SCRIPT START

$exitCode = [EXIT_CODE]::INCOMPLETE
try {
    # set up context stack and push down the starting context
    $gCtxStack = New-Object System.Collections.Stack
    PushCtx | Out-Null

    # execute main program
    $exitCode = Main
}
catch [Exception] {
    PrintError($_.Exception.Message)
    $exitCode = [EXIT_CODE]::ERROR
}
finally {
    Quit($exitCode)
}

### SCRIPT END