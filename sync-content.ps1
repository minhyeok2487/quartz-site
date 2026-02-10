# Obsidian 볼트에서 Quartz 콘텐츠 동기화 및 배포 스크립트
# 대상: 00_정리된 책 + 03_TIL + images 폴더를 quartz-site/content/에 복사

$ErrorActionPreference = "Stop"
$vault = Join-Path $PSScriptRoot "..\network"
$quartz = $PSScriptRoot
$content = Join-Path $quartz "content"

# index.md 백업
$indexBackup = $null
$indexPath = Join-Path $content "index.md"
if (Test-Path $indexPath) {
    $indexBackup = Get-Content $indexPath -Raw
}

# 콘텐츠 교체
Remove-Item -Recurse -Force "$content\*"
Copy-Item -Recurse (Join-Path $vault "00_정리된 책\*") "$content\"
Copy-Item -Recurse (Join-Path $vault "03_TIL") (Join-Path $content "03_TIL")
Copy-Item -Recurse (Join-Path $vault "images") (Join-Path $content "images")

# index.md 복원
if ($indexBackup) {
    Set-Content -Path $indexPath -Value $indexBackup -NoNewline
}

# Git 커밋 및 배포
Set-Location $quartz
git add content/
git commit -m "Update content $(Get-Date -Format 'yyyy-MM-dd')"
npx quartz sync
