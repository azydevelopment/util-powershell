$gitDirs = Get-ChildItem -Directory $env:GIT

$curDir = Get-Location

foreach ($gitDir in $gitDirs) {
    Write-Output "----------"
    Write-Output $gitDir.Name.ToUpper()
    Write-Output `n
    Set-Location $gitDir.FullName
    git pull
    Set-Location ..\
    Write-Output `n
}

Set-Location $curDir