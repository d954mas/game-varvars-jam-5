if not defined in_subprocess (cmd /k set in_subprocess=y ^& %0 %*) & exit )
cd ../


java -jar bob/bob.jar --settings bob/settings/release_game.project_settings --settings bob/settings/itch_io_game.project_settings --archive  --texture-compression true --with-symbols --variant release --platform=js-web --bo bob/releases/itch_io -brhtml bob/releases/itch_io/report.html --liveupdate yes clean resolve build bundle 
