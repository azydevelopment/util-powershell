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

# context stack
$gCtxStack = New-Object System.Collections.Stack
function ScriptRun {
    $exitCode = [EXIT_CODE]::INCOMPLETE
    try {
        # set up context stack and push down the starting context
        PushCtx | Out-Null

        # check if the script's main function exists
        if (Get-Command ScriptMain -CommandType:function -errorAction SilentlyContinue) {
            $exitCode = ScriptMain
        }
        else {
            PrintError("ScriptMain function doesn't exist")
            $exitCode = [EXIT_CODE]::ERROR
        }
    }
    catch [Exception] {
        PrintError($_.Exception.Message)
        $exitCode = [EXIT_CODE]::ERROR
    }
    finally {
        # remove ScriptMain if it exists
        if (Get-Command ScriptMain -CommandType:function -errorAction SilentlyContinue) {
            Remove-Item -Path Function:\ScriptMain
        }

        # run ScriptCleanup if it exists
        if (Get-Command ScriptCleanup -CommandType:function -errorAction SilentlyContinue) {
            ScriptCleanup
            Remove-Item -Path Function:\ScriptCleanup
        }

        switch ($exitCode) {
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

        Write-Host "`nEXIT: $exitCode"

        # restore to startup state
        while (PopCtx) {
        }

        # remove functions from active use
        Remove-Item -Path Function:\PrintError
        Remove-Item -Path Function:\ReadHost
        Remove-Item -Path Function:\GetCtx
        Remove-Item -Path Function:\PushCtx
        Remove-Item -Path Function:\PopCtx
        Remove-Item -Path Function:\ValidatePath
        Remove-Item -Path Function:\Confirm

        exit $exitCode
    }
}

# Run the script
ScriptRun