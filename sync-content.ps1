# Obsidian 볼트에서 Quartz 콘텐츠 동기화 및 배포 스크립트
$vault = "C:\Users\user\Desktop\03_공부\network"
$content = "C:\Users\user\Desktop\03_공부\quartz-site\content"

# index.md 백업
Copy-Item "$content\index.md" "$env:TEMP\index.md.bak"

# 콘텐츠 교체
Remove-Item -Recurse -Force "$content\*"
Copy-Item -Recurse "$vault\00_정리된 책\*" "$content\"
Copy-Item -Recurse "$vault\images" "$content\images"

# index.md 복원
Copy-Item "$env:TEMP\index.md.bak" "$content\index.md"

# Git 커밋 및 배포
Set-Location "C:\Users\user\Desktop\03_공부\quartz-site"
git add content/
git commit -m "Update content $(Get-Date -Format 'yyyy-MM-dd')"
npx quartz sync
