# Résumé des modifications - Register/Login

## ✅ Modifications effectuées dans siblhish-api

### 1. **build.gradle**
- ✅ Ajout de la dépendance `spring-security-crypto:6.3.0` pour le hashage BCrypt

### 2. **SecurityConfig.java** (NOUVEAU)
- ✅ Créé dans `src/main/java/ma/siblhish/config/SecurityConfig.java`
- ✅ Configure le bean `PasswordEncoder` avec BCrypt

### 3. **DTOs créés**
- ✅ `RegisterDto.java` - DTO pour la création de compte
- ✅ `LoginDto.java` - DTO pour la connexion

### 4. **AuthController.java** (MODIFIÉ)
- ✅ Ajout de l'endpoint `POST /auth/register`
- ✅ Ajout de l'endpoint `POST /auth/login`
- ✅ Gestion des erreurs avec logs appropriés

### 5. **UserService.java** (MODIFIÉ)
- ✅ Ajout de la méthode `register()` - Crée un utilisateur avec mot de passe hashé
- ✅ Ajout de la méthode `login()` - Authentifie avec email/password
- ✅ Gestion des utilisateurs OAuth (refuse la connexion email/password si compte créé via OAuth)
- ✅ Injection de `PasswordEncoder` pour le hashage BCrypt

## ✅ Modifications effectuées dans siblhish-front

### 1. **auth_service.dart** (MODIFIÉ)
- ✅ Ajout de la méthode `register()` - Crée un compte avec email/password
- ✅ Ajout de la méthode `login()` - Connexion avec email/password
- ✅ Demande automatique des permissions de notifications après register
- ✅ Parsing de la réponse identique à `signInWithGoogle()`

### 2. **Écrans créés**
- ✅ `register_screen.dart` - Écran de création de compte avec formulaire complet
- ✅ `login_email_screen.dart` - Écran de connexion avec email/password

### 3. **login_screen.dart** (MODIFIÉ)
- ✅ Ajout du bouton "Se connecter avec email"
- ✅ Ajout du lien "Créer un compte"

### 4. **main.dart** (MODIFIÉ)
- ✅ Ajout des routes `/login-email` et `/register`

## 📡 Endpoints API

### POST /auth/register
**Request:**
```json
{
  "firstName": "John",
  "lastName": "Doe",
  "email": "user@example.com",
  "password": "password123",
  "language": "fr",
  "notificationsEnabled": true
}
```

**Response (201):**
```json
{
  "status": "success",
  "data": {
    "id": 1,
    "firstName": "John",
    "lastName": "Doe",
    "email": "user@example.com",
    "language": "fr",
    "notificationsEnabled": true
  },
  "message": "Compte créé avec succès"
}
```

### POST /auth/login
**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response (200):**
```json
{
  "status": "success",
  "data": {
    "id": 1,
    "firstName": "John",
    "lastName": "Doe",
    "email": "user@example.com",
    "language": "fr",
    "notificationsEnabled": true
  },
  "message": "Connexion réussie"
}
```

## 🔐 Sécurité

- ✅ Mots de passe hashés avec BCrypt (10 rounds)
- ✅ Validation des données avec Jakarta Validation
- ✅ Protection contre les utilisateurs OAuth (ne peuvent pas se connecter avec email/password)
- ✅ Gestion des erreurs appropriée

## 🚀 Prochaines étapes

1. **Tester les endpoints** avec Postman/curl
2. **Vérifier la migration SQL** - Le champ `password` doit exister dans la table `users`
3. **Tester le frontend** - Créer un compte et se connecter
4. **Vérifier les logs** - Les logs doivent afficher les tentatives de connexion/inscription

## ⚠️ Notes importantes

- Les utilisateurs créés via Google Sign-In ont un password qui commence par `"oauth_"` et ne peuvent pas se connecter avec email/password
- Les mots de passe sont hashés avec BCrypt avant sauvegarde
- Les favoris par défaut sont créés automatiquement lors de la création d'un compte (comme pour socialLogin)

