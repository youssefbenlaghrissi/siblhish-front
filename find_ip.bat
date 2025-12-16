@echo off
echo ========================================
echo Trouver votre IP locale pour l'API
echo ========================================
echo.
echo Recherche de votre adresse IP...
echo.

ipconfig | findstr /i "IPv4"

echo.
echo ========================================
echo Instructions:
echo 1. Copiez l'adresse IP affichée ci-dessus
echo 2. Ouvrez lib/config/api_config.dart
echo 3. Remplacez 10.0.2.2 par votre IP
echo 4. Exemple: http://192.168.1.100:8081/api/v1
echo ========================================
echo.
pause

