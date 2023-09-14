::adb shell pm uninstall com.d954mas.game.mineuniverse.dev
adb install -r ".\releases\dev\playmarket\Mine Universe Dev\Mine Universe Dev.apk"
adb shell monkey -p com.d954mas.game.mineuniverse.dev -c android.intent.category.LAUNCHER 1
pause
