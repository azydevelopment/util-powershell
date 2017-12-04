function ScriptMain() {
    $solutions =
    "\embedded\embedded\embedded_vs2013.sln",
    "\core\core\core_vs2013.sln"
    
    $buildConfigs = 
    "Debug",
    "Release"

    $exitCode = [EXIT_CODE]::SUCCESS

    foreach ($solution in $solutions) {
        foreach ($buildConfig in $buildConfigs) {
            Write-Host "`n`n------------------------------"
            PushCtx | Out-Null
            $host.ui.RawUI.ForegroundColor = "Blue"
            Write-Host "Building $solution | Config: $buildConfig"
            PopCtx | Out-Null
            Write-Host "------------------------------"
            $output = & "$env:MSBUILD" "${env:GIT}$solution" "/property:Configuration=$buildConfig" /nologo /verbosity:minimal

            PushCtx | Out-Null
            if ($output -match "error") {
                $host.ui.RawUI.ForegroundColor = "Red"
                $exitCode = [EXIT_CODE]::ERROR
            }
            else {
                $host.ui.RawUI.ForegroundColor = "Green"
            }
            Write-Host $output
            PopCtx | Out-Null
            
            Write-Host "------------------------------"
        }
    }


    return $exitCode
}

function ScriptCleanup {
}

# use the script runner to execute ScriptMain
& "${env:UTIL}\util_powershell_runner.ps1" | Write-Host