# Explication Simple : Firebase vs Google Cloud Console

## 🤔 Pourquoi deux consoles ?

**Firebase** et **Google Cloud Console** sont liés mais servent des objectifs différents :

### Firebase Console
- **Pour quoi ?** Configurer Firebase (notifications push, base de données, etc.)
- **Ce qu'on a fait :** Ajouter le SHA-1 pour que Firebase reconnaisse votre application
- **C'est fait ✅** : Vous avez déjà ajouté le SHA-1 dans Firebase Console

### Google Cloud Console
- **Pour quoi ?** Configurer les APIs Google (comme Google Sign-In)
- **Ce qu'il faut faire :** Créer un "OAuth client Android" pour que Google Sign-In fonctionne
- **C'est à faire ⏳** : Créer l'OAuth client Android

## 🎯 En résumé

Pour que **Google Sign-In** fonctionne, il faut **les deux** :

1. ✅ **SHA-1 dans Firebase** → Pour que Firebase reconnaisse votre app
2. ⏳ **OAuth client Android dans Google Cloud** → Pour que Google Sign-In fonctionne

## 🔗 Le lien entre les deux

- Firebase et Google Cloud Console utilisent le **même projet** (`siblhish-app`)
- Quand vous ajoutez le SHA-1 dans Firebase, ça informe Google Cloud
- Mais Google Cloud a besoin d'un **OAuth client Android** séparé pour Google Sign-In

## 📝 Analogie simple

Imaginez :
- **Firebase Console** = Le bureau d'enregistrement (vous vous inscrivez)
- **Google Cloud Console** = Le bureau des permis (vous obtenez le permis de conduire)

Les deux sont nécessaires, mais pour des choses différentes !

## ✅ Solution Simple

**Une seule chose à faire maintenant :**

1. Allez sur [Google Cloud Console](https://console.cloud.google.com/)
2. Sélectionnez le projet `siblhish-app`
3. Menu gauche → "APIs & Services" → "Credentials"
4. Cliquez sur "+ CREATE CREDENTIALS" → "OAuth client ID"
5. Type: "Android"
6. Package: `ma.siblhish`
7. SHA-1: `63:3D:D0:8F:A9:29:88:39:C8:86:DC:62:B0:3B:70:6D:DC:AC:F6:84`
8. Créez !

C'est tout ! Après ça, Google Sign-In devrait fonctionner.

