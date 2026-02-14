# Instructions pour ajouter l'icône de l'application

## Taille recommandée

**Pour une qualité optimale, utilisez une image de 1024x1024 pixels.**

Parmi vos options (128, 16, 32, 64, 256), **256x256 est le minimum acceptable**, mais **1024x1024 est fortement recommandé** pour avoir une excellente qualité sur tous les appareils.

## Format de l'image

- **Format** : PNG (avec transparence si nécessaire)
- **Taille** : 1024x1024 pixels (recommandé) ou minimum 512x512 pixels
- **Couleur** : RVB (RGB)
- **Fond** : Transparent ou couleur unie selon votre design

## Étapes

1. **Placez votre icône** dans ce dossier (`assets/icons/`) avec le nom `app_icon.png`

2. **Installez les dépendances** :
   ```bash
   flutter pub get
   ```

3. **Générez les icônes** pour toutes les plateformes :
   ```bash
   flutter pub run flutter_launcher_icons
   ```

4. **Vérifiez** que les icônes ont été générées dans :
   - Android : `android/app/src/main/res/mipmap-*/ic_launcher.png`
   - iOS : `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

## Notes importantes

- L'icône doit être carrée (même largeur et hauteur)
- Évitez les détails trop fins qui ne seront pas visibles en petite taille
- Testez l'icône sur différents appareils après génération
- Pour Android, vous pouvez utiliser une icône adaptive (fond + premier plan) pour un meilleur rendu

## Configuration actuelle

Le fichier `pubspec.yaml` est configuré pour :
- Générer les icônes pour Android et iOS
- Utiliser `assets/icons/app_icon.png` comme source
- Générer automatiquement toutes les tailles nécessaires

