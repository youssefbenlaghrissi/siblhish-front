# Corriger le Package Name dans l'OAuth Client

## 🚨 Problème identifié

Vous avez déjà un OAuth client Android, mais le **package name est incorrect** :
- ❌ Dans l'OAuth client : `com.example.siblhish_front` (ancien)
- ✅ Dans votre app : `ma.siblhish` (nouveau)

C'est pour ça que Google Sign-In ne fonctionne pas !

## ✅ Solution : Modifier l'OAuth client existant

### Option 1 : Modifier l'OAuth client existant (Recommandé)

1. Dans Google Cloud Console, sur la page de l'OAuth client Android que vous voyez
2. Modifiez le champ **"Nom du package"** :
   - Changez `com.example.siblhish_front` 
   - En `ma.siblhish`
3. Cliquez sur **"Enregistrer"** (ou "Save") en bas de la page

### Option 2 : Créer un nouveau OAuth client (Si vous ne pouvez pas modifier)

1. Dans Google Cloud Console → "APIs & Services" → "Credentials"
2. Cliquez sur "+ CREATE CREDENTIALS" → "OAuth client ID"
3. Type: **"Android"**
4. Name: `Siblhish Android` (ou un nom de votre choix)
5. **Package name** : `ma.siblhish` ⚠️ **IMPORTANT : Le bon package name !**
6. **SHA-1** : `63:3D:D0:8F:A9:29:88:39:C8:86:DC:62:B0:3B:70:6D:DC:AC:F6:84`
7. Cliquez sur **"Create"**
8. (Optionnel) Supprimez l'ancien OAuth client avec le mauvais package name

## 🔄 Après la modification

1. Attendez **2-5 minutes** pour que Google synchronise
2. Rebuild l'application :
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```
3. Testez la connexion Google

## ✅ Vérification

Pour vérifier que c'est correct :
- Package name dans OAuth client : `ma.siblhish` ✅
- Package name dans `android/app/build.gradle.kts` : `ma.siblhish` ✅
- SHA-1 : `63:3D:D0:8F:A9:29:88:39:C8:86:DC:62:B0:3B:70:6D:DC:AC:F6:84` ✅

Si les trois correspondent, ça devrait fonctionner !

