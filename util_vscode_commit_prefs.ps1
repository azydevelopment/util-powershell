$curDir = Get-Location

Copy-Item C:\Users\azy48\AppData\Roaming\Code\User\keybindings.json C:\git\preferences-store\visual_studio_code\
Copy-Item C:\Users\azy48\AppData\Roaming\Code\User\settings.json C:\git\preferences-store\visual_studio_code\

Set-Location C:\git\preferences-store

git pull
git add -A
git status

$commitMsg = Read-Host -Prompt "Enter commit message"

git commit -m "$commitMsg"
git push

Set-Location $curDir