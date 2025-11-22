param(
  # Thư mục gốc của project Flutter (mặc định là thư mục hiện tại)
  [string]$ProjectRoot = "."
)

Write-Host "🔧 Project root: $ProjectRoot"

############################
#  ANDROID CLEANUP
############################

$androidRes = Join-Path $ProjectRoot "android\app\src\main\res"

# 1. Xoá các file launch_background.xml mà flutter_native_splash từng tạo
$launchFiles = @(
  "drawable\launch_background.xml",
  "drawable-v21\launch_background.xml",
  "drawable-night\launch_background.xml"
)

foreach ($rel in $launchFiles) {
  $f = Join-Path $androidRes $rel
  if (Test-Path $f) {
    Write-Host "🗑 Removing $f"
    Remove-Item $f -Force
  } else {
    Write-Host "ℹ️ Skip (not found): $f"
  }
}

# 2. Gỡ dòng windowBackground khỏi styles.xml / styles-night.xml
$stylesFiles = @(
  "values\styles.xml",
  "values-night\styles.xml"
)

foreach ($rel in $stylesFiles) {
  $f = Join-Path $androidRes $rel
  if (Test-Path $f) {
    Write-Host "✏️ Cleaning $f"
    $content = Get-Content $f

    # Xoá dòng tham chiếu tới launch_background
    $content = $content -replace '.*windowBackground.*launch_background.*',''
    # Xoá comment liên quan đến flutter_native_splash (nếu có)
    $content = $content -replace '.*flutter_native_splash.*',''

    Set-Content $f $content
  } else {
    Write-Host "ℹ️ Skip (not found): $f"
  }
}

# 3. Sửa theme trong AndroidManifest.xml nếu còn dùng LaunchTheme
$manifest = Join-Path $ProjectRoot "android\app\src\main\AndroidManifest.xml"
if (Test-Path $manifest) {
  Write-Host "✏️ Cleaning $manifest"
  $content = Get-Content $manifest

  # Nếu đang dùng LaunchTheme → đổi về NormalTheme
  $content = $content -replace 'android:theme="@style/LaunchTheme"', 'android:theme="@style/NormalTheme"'

  Set-Content $manifest $content
} else {
  Write-Host "ℹ️ Skip (not found): AndroidManifest.xml"
}

############################
#  iOS CLEANUP (nếu có)
############################

$iosLaunch = Join-Path $ProjectRoot "ios\Runner\Base.lproj\LaunchScreen.storyboard"
if (Test-Path $iosLaunch) {
  Write-Host "🗑 Removing iOS LaunchScreen.storyboard"
  Remove-Item $iosLaunch -Force
} else {
  Write-Host "ℹ️ Skip (not found): LaunchScreen.storyboard"
}

$infoPlist = Join-Path $ProjectRoot "ios\Runner\Info.plist"
if (Test-Path $infoPlist) {
  Write-Host "✏️ Cleaning Info.plist"
  $content = Get-Content $infoPlist

  # Xoá key UILaunchStoryboardName nếu còn
  $content = $content -replace '<key>UILaunchStoryboardName</key>\s*<string>LaunchScreen</string>', ''

  Set-Content $infoPlist $content
} else {
  Write-Host "ℹ️ Skip (not found): Info.plist"
}

Write-Host "✅ Done. Now run: flutter clean && flutter pub get"
