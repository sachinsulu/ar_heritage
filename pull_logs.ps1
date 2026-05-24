# pull_logs.ps1
# Pulls the self-contained classifier logs from the connected Android device directly to your project folder.

adb shell "run-as com.example.ar_heritage cat app_flutter/classifier.log" > classifier.log
Write-Host "Success: Pulled latest classifier logs from device to classifier.log!" -ForegroundColor Green
