$targetPath = "C:\Users\【RST-11】リバイブ新所沢\OneDrive\デスクトップ\プロジェクト\REC-OFF-AIR\scenes\KiriharaVillageMap"
Get-ChildItem -Path $targetPath -Include *.tscn, *.gd, *.import -Recurse | ForEach-Object {
    $file = $_.FullName
    $content = Get-Content $file -Raw
    # res:// に続いて scenes/KiriharaVillageMap/ が来ていない場合のみ置換
    $newContent = $content -replace "res://(?!(scenes/KiriharaVillageMap/))", "res://scenes/KiriharaVillageMap/"
    $newContent | Set-Content $file
}
