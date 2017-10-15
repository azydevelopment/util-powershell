Enum EXIT_CODE {
    SUCCESS
    INCOMPLETE
    ERROR
}

function PrintError($msg) {
    Write-Error "$msg"
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
function Main() {
    $gitDir = $null
    
    # ask user where to put the git directory
    do {
        $gitDir = ReadHost("Select git directory")
    } while (-not(ValidatePath($gitDir)))
    
    $gitDirUpper = $gitDir.toUpper()
    if (-not(Confirm("Make `"$gitDirUpper`" your primary git directory?"))) {
        return [EXIT_CODE]::INCOMPLETE
    }

    # set git environment variable
    [Environment]::SetEnvironmentVariable("GIT_DIR", "$gitDir", "User")

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

    Set-Location $gitDir
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