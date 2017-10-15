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
            $host.ui.RawUI.ForegroundColor = "YELLOW"
        }
        ERROR {
            $host.ui.RawUI.ForegroundColor = "Green"
        }
    }

    Write-Host "EXIT: $code"

    # restore to startup state
    while (PopCtx) {
    }

    exit $code
}

function ValidatePath($path) {
    if ([string]::IsNullOrEmpty($gitDir)) {
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
    $response = $false
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
    
    do {
        $gitDir = ReadHost("Select git directory")
    } while (-not(ValidatePath($gitDir)))

    if (-not(Confirm("Make `"$gitDir`" your primary git directory?"))) {
        return [EXIT_CODE]::INCOMPLETE
    }

    

    return [EXIT_CODE]::SUCCESS
}


### SCRIPT START

try {
    # set up context stack and push down the starting context
    $gCtxStack = New-Object System.Collections.Stack
    PushCtx | Out-Null

    # execute main program
    Quit(Main)
}
finally {
    Quit([EXIT_CODE]::INCOMPLETE)
}

### SCRIPT END