#!/bin/zsh

swift build -c release
cp .build/release/ProjectPicker workflow/
codesign -s 'Developer ID Application' -o runtime workflow/ProjectPicker
zip -9j 'Project Picker.alfredworkflow' workflow/*
xcrun notarytool submit --wait --keychain-profile "Personal" 'Project Picker.alfredworkflow'
