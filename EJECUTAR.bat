@echo off
chcp 65001 >nul
echo === VetCare: preparando proyecto ===
call flutter create . --project-name vetcare_innis --platforms=web,windows,android
call flutter pub get
echo === Abriendo en Chrome ===
call flutter run -d chrome
pause
