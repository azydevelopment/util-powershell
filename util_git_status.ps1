$gitDirs = Get-ChildItem -Directory $env:GIT

foreach ($gitDir in $gitDirs) {
    Write-Output "----------"
    Write-Output $gitDir.Name.ToUpper()
    Write-Output `n
    Set-Location $gitDir
    git status
    Set-Location ..\
    Write-Output `n
}