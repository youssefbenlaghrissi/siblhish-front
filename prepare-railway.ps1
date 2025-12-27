# Script PowerShell pour préparer le backend pour Railway
# À exécuter depuis le répertoire siblhish-api

Write-Host "🚀 Préparation du backend pour Railway..." -ForegroundColor Cyan

# Vérifier qu'on est dans le bon répertoire
if (-not (Test-Path "build.gradle")) {
    Write-Host "❌ Erreur: Ce script doit être exécuté depuis le répertoire siblhish-api" -ForegroundColor Red
    exit 1
}

# Chemin vers les fichiers de configuration
$configPath = "..\siblhish-front\railway-config"

# Vérifier que les fichiers existent
if (-not (Test-Path "$configPath\application-prod.properties")) {
    Write-Host "❌ Erreur: Fichiers de configuration non trouvés dans $configPath" -ForegroundColor Red
    exit 1
}

Write-Host "📋 Copie des fichiers de configuration..." -ForegroundColor Yellow

# Copier application-prod.properties
Copy-Item "$configPath\application-prod.properties" "src\main\resources\" -Force
Write-Host "✅ application-prod.properties copié" -ForegroundColor Green

# Copier Dockerfile
Copy-Item "$configPath\Dockerfile" "." -Force
Write-Host "✅ Dockerfile copié" -ForegroundColor Green

# Copier railway.json
Copy-Item "$configPath\railway.json" "." -Force
Write-Host "✅ railway.json copié" -ForegroundColor Green

# Copier .railwayignore
Copy-Item "$configPath\.railwayignore" "." -Force
Write-Host "✅ .railwayignore copié" -ForegroundColor Green

# Modifier application.properties
Write-Host "📝 Modification de application.properties..." -ForegroundColor Yellow
$appPropsPath = "src\main\resources\application.properties"
$appProps = Get-Content $appPropsPath -Raw

if ($appProps -notmatch "spring.profiles.active") {
    $appProps += "`n# Profile configuration`nspring.profiles.active=`${SPRING_PROFILES_ACTIVE:dev}`n"
    Set-Content $appPropsPath $appProps
    Write-Host "✅ spring.profiles.active ajouté" -ForegroundColor Green
} else {
    Write-Host "ℹ️  spring.profiles.active existe déjà" -ForegroundColor Blue
}

Write-Host "`n✅ Préparation terminée !" -ForegroundColor Green
Write-Host "`n📋 Prochaines étapes:" -ForegroundColor Cyan
Write-Host "1. Créer un repository GitHub pour siblhish-api" -ForegroundColor White
Write-Host "2. Pousser le code sur GitHub" -ForegroundColor White
Write-Host "3. Créer un projet Railway" -ForegroundColor White
Write-Host "4. Ajouter PostgreSQL et Spring Boot" -ForegroundColor White
Write-Host "5. Lier PostgreSQL au service Spring Boot" -ForegroundColor White
Write-Host "6. Ajouter SPRING_PROFILES_ACTIVE=railway" -ForegroundColor White
Write-Host "7. Exécuter le script SQL" -ForegroundColor White

