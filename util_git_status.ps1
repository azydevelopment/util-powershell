$gitDirs = Get-ChildItem -Directory $env:GIT

foreach ($gitDir in $gitDirs) {
    Write-Output "----------"
    Write-Output $gitDir.Name.ToUpper()
    Write-Output `n
    git status $gitDir
    Write-Output `n
}