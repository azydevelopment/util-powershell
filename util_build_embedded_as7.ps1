# TODO HACK: Does this variable even go away? Ideally this comes down as a ScriptMain function parameter
$inputs = $args

function ScriptMain() {

    $solutionRelDir = "embedded\embedded"
    $solutionCommonIncludeRelDir = "$solutionRelDir\common\include"

    $architectures = @(
        $(
            "saml21"
        )
    )

    $buildConfigs = 
    "DEBUG",
    "RELEASE"

    if ($inputs.Count -gt 1) {
        Write-Host "Too many args"
        return [EXIT_CODE]::ERROR
    }
    elseif ($inputs.Count -eq 1) {
        if ($buildConfigs -Contains $inputs[0]) {
            $buildConfigs = @($inputs[0])
        }
        else {
            Write-Host "Build config doesn't exist"
            return [EXIT_CODE]::ERROR
        }
    }

    # deploy the solution common include files to the ${env:INCLUDE} directory
    # TODO HACK: Magic strings
    Copy-Item ${env:GIT}\${solutionCommonIncludeRelDir}\* $env:INCLUDE -Recurse -Force

    $exitCode = [EXIT_CODE]::SUCCESS

    for ($i = 0; $i -lt $architectures.Count; $i++) {
        $architecture = "$($architectures[$i])"
        $projectFileName = "$architecture.cppproj"
        $projectRelDir = "$solutionRelDir\$architecture"
        $projectDir = "${env:GIT}\$projectRelDir"
        $projectPath = "$projectDir\$projectFileName"
        $projectIncludeDir = "$projectDir\include"

        # TODO HACK: Magic string
        $atmelStudioPath = "C:\Program Files (x86)\Atmel\Studio\7.0\AtmelStudio.exe"

        # deploy the include files to the ${env:INCLUDE} directory
        # TODO HACK: Magic strings
        Copy-Item ${projectIncludeDir}\* $env:INCLUDE -Recurse -Force

        foreach ($buildConfig in $buildConfigs) {
            Write-Host "`n------------------------------"
            PushCtx | Out-Null
            $host.ui.RawUI.ForegroundColor = "Blue"
            Write-Host "Building: $projectPath"
            Write-Host "Config: $($buildConfig.toUpper())"
            PopCtx | Out-Null
            Write-Host "------------------------------"

            $dateTime = Get-Date -Format FileDateTime

            # create log directory if doesn't exist

            # TODO HACK: Magic string
            $logFileDir = [io.path]::combine(
                $env:TEMP,
                "build", 
                $projectRelDir,
                $buildConfig
            ).toLower()

            New-Item -ItemType Directory -Force -Path $logFileDir | Out-Null

            $logFileName = $(
                ($projectFileName -Replace "[.]", "_"),
                "${dateTime}.txt"
            ) -Join "_"

            $logFilePath = [io.path]::combine(
                $logFileDir,
                $logFileName
            ).toLower()

            # $logFilePath = "C:\Users\azy48\Desktop\test.txt"

            # build using Atmel Studio command line
            Start-Process -Wait $atmelStudioPath -ArgumentList "${projectPath} /build ${buildConfig} /out ${logFilePath}"

            # print the build results
            $output = (Get-Content -Path $logFilePath) -join "`n"
            PushCtx | Out-Null
            Write-Host "Build: " -NoNewLine
            if ($output -match "1 failed") {
                $host.ui.RawUI.ForegroundColor = "Red"
                Write-Host "FAIL"
                Write-Host "`n$output"
            }
            elseif ($output -match "1 succeeded") {
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

            # TODO HACK: Magic strings
            $libDeployDir = [io.path]::combine(
                $env:LIB,
                "azydev",
                "embedded",
                $buildConfig
            ).toLower()

            # create lib deploy directory if doesn't exist
            New-Item -ItemType Directory -Force -Path $libDeployDir | Out-Null

            # TODO HACK: Magic strings
            Copy-Item -Path "${libDir}\*" -Include "*.a" -Destination $libDeployDir

            Write-Host "Lib: " -NoNewLine
            Write-Host $libDeployDir

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