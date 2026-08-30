$env:JAVA_TOOL_OPTIONS = '-Dskiko.renderApi=OPENGL'
Set-Location 'C:\Users\Co\animeko'
cmd /c "gradlew.bat :app:desktop:run -Pani.desktop.mainClass=me.him188.ani.app.desktop.MpvVerifyKt -Pani.mpv.selftest=true -Pani.seekverify.video=C:/Users/Co/animeko/seek-verify.mp4"
Write-Output ("exit=" + $LASTEXITCODE)
