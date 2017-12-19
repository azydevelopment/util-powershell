function ScriptMain() {

    $projects = $(
        "core\core\abdeveng_core\abdeveng_core_as7.cppproj",
        "embedded\embedded\azydev_embedded\azydev_embedded_as7.cppproj"
    )

    $libOutput = $(
        "azydev\embedded",
        "abdeveng\core"
    )

    $buildConfigs = 
    "DEBUG",
    "RELEASE"

    $exitCode = [EXIT_CODE]::SUCCESS

    for ($i = 0; $i -lt $projects.Count; $i++) {
        $project = $projects[$i]
        # TODO HACK: Magic slashes
        $projectFileName = Split-Path $project -Leaf
        $projectSubDir = Split-Path $project -Parent
        $projectDir = "${env:GIT}\$projectSubDir"
        $projectPath = "${env:GIT}\$project"
        $projectIncludeDir = "${env:GIT}\$projectSubDir\include"

        # TODO HACK: Magic string
        $atmelStudioPath = "C:\Program Files (x86)\Atmel\Studio\7.0\AtmelStudio.exe"

        # deploy the include files to the ${env:INCLUDE} directory
        # TODO HACK: Magic strings
        Copy-Item ${projectIncludeDir}\* $env:INCLUDE -Recurse -Force

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
                ($projectFileName -Replace "[.]", "_"),
                "${dateTime}.txt"
            ) -Join "_"

            # TODO HACK: Magic string
            $logFileDir = [io.path]::combine(
                $env:TEMP,
                "build", 
                $projectSubDir,
                $buildConfig
            ).toLower()

            # create log directory if doesn't exist
            New-Item -ItemType Directory -Force -Path $logFileDir | Out-Null

            $logFilePath = [io.path]::combine(
                $logFileDir,
                $logFileName
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
                $projectDir,
                $buildConfig
            ).toLower()

            $libDeployDir = [io.path]::combine(
                $env:LIB,
                $libOutput[$i],
                $buildConfig
            ).toLower()

            # create lib deploy directory if doesn't exist
            New-Item -ItemType Directory -Force -Path $libDeployDir | Out-Null

            Write-Host "Lib: " -NoNewLine
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