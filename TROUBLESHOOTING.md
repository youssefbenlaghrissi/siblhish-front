# Guide de dépannage - Connexion Frontend-Backend

## 🔍 Problème : L'application affiche "Bonjour Utilisateur" au lieu de "Bonjour Youssef"

### Causes possibles :
1. **URL API incorrecte** - L'application utilise `10.0.2.2:8081` (pour émulateur) au lieu de votre IP locale
2. **Backend non accessible** - Le backend n'est pas accessible depuis le téléphone
3. **Erreur réseau silencieuse** - Les erreurs ne sont pas affichées

## ✅ Solution 1 : Configurer l'URL API pour téléphone physique

### Étape 1 : Trouver votre IP locale

**Sur Windows :**
1. Ouvrir PowerShell ou CMD
2. Exécuter : `ipconfig`
3. Chercher votre IP sous :
   - `Wireless LAN adapter Wi-Fi` → `IPv4 Address`
   - OU `Ethernet adapter` → `IPv4 Address`
4. Exemple : `192.168.1.100`

**Sur Mac/Linux :**
```bash
ifconfig | grep "inet "
# ou
ip addr show
```

### Étape 2 : Modifier la configuration

Ouvrir `lib/config/api_config.dart` et modifier :

```dart
// AVANT (pour émulateur)
static const String baseUrl = 'http://10.0.2.2:8081/api/v1';

// APRÈS (pour téléphone physique - remplacer par VOTRE IP)
static const String baseUrl = 'http://192.168.1.100:8081/api/v1';
```

### Étape 3 : Vérifier que le téléphone et l'ordinateur sont sur le même réseau WiFi

- Le téléphone et l'ordinateur doivent être connectés au **même réseau WiFi**
- Désactiver temporairement le pare-feu Windows si nécessaire

### Étape 4 : Tester la connexion

1. Redémarrer l'application Flutter
2. Vérifier les logs dans la console :
   - `🌐 API GET: http://...` - Requête envoyée
   - `📥 Response status: 200` - Réponse reçue
   - `✅ User loaded: Youssef Benlaghrissi` - Utilisateur chargé
   - `❌ API Error: ...` - Erreur de connexion

## ✅ Solution 2 : Vérifier que le backend est accessible

### Test depuis le navigateur

Ouvrir dans le navigateur (sur votre ordinateur) :
```
http://localhost:8081/api/v1/users/1/profile
```

Vous devriez voir une réponse JSON avec les données de l'utilisateur.

### Test depuis le téléphone

1. Connecter le téléphone au même WiFi
2. Ouvrir le navigateur sur le téléphone
3. Aller à : `http://[VOTRE_IP]:8081/api/v1/users/1/profile`
4. Vous devriez voir la même réponse JSON

Si ça ne fonctionne pas :
- Vérifier que le backend Spring Boot est démarré
- Vérifier que le port 8081 n'est pas bloqué par le pare-feu
- Vérifier que le backend écoute sur `0.0.0.0` et pas seulement `localhost`

## ✅ Solution 3 : Vérifier les logs de l'application

Les logs sont maintenant affichés dans la console Flutter :

```
🚀 Initializing app with user ID: 1
👤 Loading user with ID: 1
🌐 API GET: http://192.168.1.100:8081/api/v1/users/1/profile
📥 Response status: 200
📥 Response body: {"status":"success","data":{...}}
✅ User loaded: Youssef Benlaghrissi
✅ Initialization complete
```

Si vous voyez des erreurs :
- `❌ API Error: SocketException: Failed host lookup` → URL incorrecte ou réseau non accessible
- `❌ API Error: TimeoutException` → Backend ne répond pas ou trop lent
- `❌ API Error: Failed to load data: 404` → Endpoint incorrect ou utilisateur n'existe pas
- `❌ API Error: Failed to load data: 500` → Erreur côté backend

## ✅ Solution 4 : Vérifier que l'utilisateur existe dans la base de données

### Vérifier dans PostgreSQL

```sql
SELECT id, first_name, last_name, email FROM users;
```

Vous devriez voir :
```
 id | first_name | last_name  | email
----+------------+------------+------------------
  1 | Youssef    | Benlaghrissi | youssef@example.com
```

### Si l'utilisateur n'existe pas

Réexécuter le script SQL :
```bash
psql -U youssefbenlaghrissi -d siblhish -f scripts/seed_database.sql
```

## 🔧 Configuration du backend Spring Boot

Vérifier que le backend écoute sur toutes les interfaces :

Dans `application.properties` :
```properties
server.address=0.0.0.0  # Écouter sur toutes les interfaces
server.port=8081
```

Ou dans `application.yml` :
```yaml
server:
  address: 0.0.0.0
  port: 8081
```

## 🐛 Désactiver le pare-feu Windows (temporairement)

1. Ouvrir "Pare-feu Windows Defender"
2. Cliquer sur "Paramètres avancés"
3. Règles de trafic entrant → Nouvelle règle
4. Port → TCP → 8081 → Autoriser la connexion

## 📱 Alternative : Utiliser ngrok pour exposer le backend

Si vous ne pouvez pas utiliser l'IP locale :

1. Installer ngrok : https://ngrok.com/
2. Exécuter : `ngrok http 8081`
3. Copier l'URL HTTPS (ex: `https://abc123.ngrok.io`)
4. Modifier `api_config.dart` :
   ```dart
   static const String baseUrl = 'https://abc123.ngrok.io/api/v1';
   ```

## ✅ Checklist de vérification

- [ ] Backend Spring Boot démarré sur le port 8081
- [ ] Base de données PostgreSQL accessible
- [ ] Utilisateur avec ID=1 existe dans la base de données
- [ ] Téléphone et ordinateur sur le même réseau WiFi
- [ ] IP locale trouvée et configurée dans `api_config.dart`
- [ ] Pare-feu Windows autorise le port 8081 (ou désactivé temporairement)
- [ ] Backend accessible depuis le navigateur du téléphone
- [ ] Logs de l'application vérifiés dans la console Flutter

## 📞 Si le problème persiste

1. Vérifier les logs du backend Spring Boot
2. Vérifier les logs de l'application Flutter (console)
3. Tester l'API avec Postman ou curl
4. Vérifier que CORS est configuré dans le backend (si nécessaire)

