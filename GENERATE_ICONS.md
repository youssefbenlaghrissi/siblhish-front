# Génération des icônes de l'application

## Commandes à exécuter

1. **Installer les dépendances** (si pas déjà fait) :
   ```bash
   flutter pub get
   ```

2. **Générer les icônes** pour Android et iOS :
   ```bash
   flutter pub run flutter_launcher_icons
   ```

## Résultat

Après exécution, toutes les tailles d'icônes nécessaires seront générées automatiquement :
- **Android** : dans `android/app/src/main/res/mipmap-*/ic_launcher.png`
- **iOS** : dans `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

## Vérification

Pour voir les icônes sur votre appareil :
- **Android** : Rebuild l'application (`flutter run`)
- **iOS** : Rebuild l'application (`flutter run`)

L'icône `splash-icon.png` sera utilisée comme icône de l'application sur toutes les plateformes.

