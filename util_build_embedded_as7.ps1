function ScriptMain() {
    $solutions =
    "embedded\embedded\embedded_as7.atsln",
    "core\core\core_as7.atsln"
    
    $buildConfigs = 
    "DEBUG",
    "RELEASE"

    $exitCode = [EXIT_CODE]::SUCCESS

    foreach ($solution in $solutions) {
        foreach ($buildConfig in $buildConfigs) {
            Write-Host "`n------------------------------"
            PushCtx | Out-Null
            $host.ui.RawUI.ForegroundColor = "Blue"
            Write-Host "Building: ${env:GIT}\$solution"
            Write-Host "Config: $buildConfig"
            PopCtx | Out-Null
            Write-Host "------------------------------"

            # TODO HACK: Magic string
            $atmelStudioPath = "C:\Program Files (x86)\Atmel\Studio\7.0\AtmelStudio.exe"

            $dateTime = Get-Date -Format FileDateTime

            $logFileName = $(
                ((Split-Path ${solution} -Leaf) -Replace "[.]", "_")
                , "${dateTime}.txt"
            ) -Join "_"

            $logFileDirectory = [io.path]::combine(
                $env:TEMP
                , "build" # TODO HACK: Magic string
                , $(Split-Path $solution -Parent)
                , ${buildConfig}
            ).toLower()

            # create log directory if doesn't exist
            New-Item -ItemType Directory -Force -Path $logFileDirectory | Out-Null

            $logFilePath = [io.path]::combine(
                $logFileDirectory
                , $logFileName
            ).toLower()

            # TODO HACK: Magic slash
            $solutionPath = "${env:GIT}\$solution"

            Start-Process -Wait $atmelStudioPath -ArgumentList "$solutionPath /build $buildConfig /out $logFilePath"

            $output = Get-Content -Path $logFilePath

            PushCtx | Out-Null
            Write-Host "Build: " -NoNewLine
            if ($output -match "Build FAILED") {
                $host.ui.RawUI.ForegroundColor = "Red"
                Write-Host "FAIL"
            }
            elseif ($output -match "Build SUCCEEDED") {
                $host.ui.RawUI.ForegroundColor = "Green"
                Write-Host "SUCCESS"
            }
            else {
                $host.ui.RawUI.ForegroundColor = "Yellow"
                Write-Host "INDETERMINATE"
            }
            PopCtx | Out-Null
            
            Write-Host "Log: $logFilePath"
            Write-Host "------------------------------"
        }
    }
    
    Write-Host "`nDONE"

    return $exitCode
}

function ScriptCleanup {
}

# use the script runner to execute ScriptMain
& "${env:UTIL}\util_powershell_runner.ps1" | Write-Host