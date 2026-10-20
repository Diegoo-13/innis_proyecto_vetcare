#!/bin/sh
flutter create . --project-name vetcare_innis --platforms=web,macos,android
flutter pub get
flutter run -d chrome
