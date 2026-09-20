@echo off
REM ============================================================
REM  FamilyShare · 一键编译 APK（命令行方式，需已装 JDK 17+ 和 Gradle）
REM  更省事的替代：装 Android Studio，直接用 File->Open 打开本 android/ 目录构建。
REM  本脚本编译「debug 包」（自动用 debug.keystore 签名，可直接安装），
REM  并打印高德 Key 要绑定的「调试版 SHA1」。
REM ============================================================
chcp 65001 >nul
cd /d "%~dp0"

REM ---- 1) 定位 Android SDK ----
if "%ANDROID_HOME%"=="" set "ANDROID_HOME=%LOCALAPPDATA%\Android\Sdk"
if not exist "%ANDROID_HOME%" (
    echo [错误] 找不到 Android SDK：%ANDROID_HOME%
    echo   请先安装 Android Studio（它会自带 SDK），或手动设置 ANDROID_HOME 环境变量。
    pause & exit /b 1
)
echo [OK] Android SDK = %ANDROID_HOME%

REM ---- 2) 检查 Java（需 JDK 17+）----
java -version >nul 2>&1 || (
    echo [错误] 找不到 java。请安装 JDK 17 并把 bin 加入 PATH，
    echo   或直接装 Android Studio（自带 JDK）。
    pause & exit /b 1
)

REM ---- 3) 构建 debug APK（自动签名，可直接安装）----
echo 开始编译 debug 包（首次会下载依赖，请耐心等待几分钟）...
if exist "gradlew.bat" (
    call gradlew.bat assembleDebug
) else (
    gradle assembleDebug
)
if errorlevel 1 (
    echo 编译失败，请把上方错误信息发给我。
    pause & exit /b 1
)

REM ---- 4) 提示产物 ----
echo.
echo ============================================================
echo  编译完成！安装包：%CD%\app\build\outputs\apk\debug\app-debug.apk
echo  把它传到手机直接安装即可（需在手机允许"安装未知来源应用"）。
echo ============================================================

REM ---- 5) 打印 SHA1（高德 Key 绑定用：PackageName 填 com.familyshare.simonel）----
for /f "tokens=2 delims==" %%a in ('findstr /b "RELEASE_KEYSTORE_PASSWORD=" gradle.properties') do set RELPASS=%%a
echo.
echo  ============================================================
echo   请把下面两组 SHA1 填到高德控制台 lbs.amap.com：
echo     PackageName（包名）  ：com.familyshare.simonel
echo     调试版安全码（Debug）：debug.keystore 的 SHA1
echo     发布版安全码（Rel. ）：release.keystore 的 SHA1
echo  ============================================================
if exist "app\debug.keystore" (
    echo.
    echo 【调试版 SHA1】=  （来自 app\debug.keystore，密码 android）
    keytool -list -v -keystore "app\debug.keystore" -alias androiddebugkey -storepass android -keypass android 2>nul | findstr /i "SHA1"
)
if exist "app\release.keystore" (
    echo.
    echo 【发布版 SHA1】=  （来自 app\release.keystore，别名 familyshare）
    keytool -list -v -keystore "app\release.keystore" -alias familyshare -storepass "%RELPASS%" -keypass "%RELPASS%" 2>nul | findstr /i "SHA1"
)

pause