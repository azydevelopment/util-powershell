function ScriptMain() {

    $projects = $(
        "embedded\embedded\embedded\embedded_as7.cppproj",
        "core\core\core\core_as7.cppproj"
    )

    $buildConfigs = 
    "DEBUG",
    "RELEASE"

    $exitCode = [EXIT_CODE]::SUCCESS

    foreach ($project in $projects) {
        # TODO HACK: Magic slashes
        $projectFileName = Split-Path $project -Leaf
        $projectSubDir = Split-Path $project -Parent
        $projectDir = "${env:GIT}\$projectSubDir"
        $projectPath = "${env:GIT}\$project"

        # TODO HACK: Magic string
        $atmelStudioPath = "C:\Program Files (x86)\Atmel\Studio\7.0\AtmelStudio.exe"

        foreach ($buildConfig in $buildConfigs) {
            Write-Host "`n------------------------------"
            PushCtx | Out-Null
            $host.ui.RawUI.ForegroundColor = "Blue"
            Write-Host "Building: ${env:GIT}\$project"
            Write-Host "Config: $buildConfig"
            PopCtx | Out-Null
            Write-Host "------------------------------"

            $dateTime = Get-Date -Format FileDateTime

            $logFileName = $(
                ($projectFileName -Replace "[.]", "_")
                , "${dateTime}.txt"
            ) -Join "_"

            $logFileDir = [io.path]::combine(
                $env:TEMP
                , "build" # TODO HACK: Magic string
                , $projectSubDir
                , $buildConfig
            ).toLower()

            # create log directory if doesn't exist
            New-Item -ItemType Directory -Force -Path $logFileDir | Out-Null

            $logFilePath = [io.path]::combine(
                $logFileDir
                , $logFileName
            ).toLower()

            # build using Atmel Studio command line
            Start-Process -Wait $atmelStudioPath -ArgumentList "$projectPath /build $buildConfig /out $logFilePath"

            # print the build results
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

            # deploy the build results to the ${env:LIB} directory
            $libDir = [io.path]::combine(
                $projectDir
                , $buildConfig
            ).toLower()

            $libDeployDir = [io.path]::combine(
                $env:LIB
                , $projectSubDir
                , $buildConfig
            ).toLower()

            # create lib deploy directory if doesn't exist
            New-Item -ItemType Directory -Force -Path $libDeployDir | Out-Null

            Write-Host "Lib: " -NoNewLine
            Write-Host $libDir
            Write-Host $libDeployDir

            # TODO HACK: Magic strings
            Copy-Item -Path "${libDir}\*" -Include "*.a" -Destination $libDeployDir

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