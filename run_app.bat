@echo off
echo ========================================
echo Lancement de l'application Siblhish
echo ========================================
echo.

echo [1/4] Verification des appareils connectes...
flutter devices
echo.

echo [2/4] Installation des dependances...
flutter pub get
if %errorlevel% neq 0 (
    echo ERREUR: Echec de l'installation des dependances
    pause
    exit /b 1
)
echo.

echo [3/4] Generation des adapters Hive...
flutter pub run build_runner build --delete-conflicting-outputs
if %errorlevel% neq 0 (
    echo ERREUR: Echec de la generation des adapters
    pause
    exit /b 1
)
echo.

echo [4/4] Lancement de l'application sur votre telephone...
flutter run
echo.

pause

