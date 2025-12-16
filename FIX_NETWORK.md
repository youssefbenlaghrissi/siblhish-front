# 🔧 Correction du problème de timeout

## Problème identifié

Les requêtes API expirent après 30 secondes (`TimeoutException`). Cela signifie que :
- ✅ L'URL est correcte (`192.168.11.105:8081`)
- ✅ Les requêtes sont envoyées
- ❌ Le backend n'est pas accessible depuis le téléphone

## Solution : Configurer le backend pour écouter sur toutes les interfaces

### Étape 1 : Modifier application.properties

J'ai déjà modifié le fichier `application.properties` du backend pour ajouter :
```properties
server.address=0.0.0.0
```

Cela permet au backend d'écouter sur toutes les interfaces réseau, pas seulement `localhost`.

### Étape 2 : Redémarrer le backend Spring Boot

**IMPORTANT** : Vous devez redémarrer le backend pour que les changements prennent effet.

1. Arrêter le backend (Ctrl+C dans le terminal où il tourne)
2. Redémarrer le backend :
   ```bash
   cd C:\Users\youssef.benlaghrissi\Documents\siblhish-api
   mvn spring-boot:run
   # ou
   ./mvnw spring-boot:run
   ```

### Étape 3 : Vérifier que le backend écoute sur toutes les interfaces

Après le redémarrage, vous devriez voir dans les logs :
```
Tomcat started on port(s): 8081 (http) with context path ''
```

### Étape 4 : Tester depuis le navigateur du téléphone

1. Connecter le téléphone au même WiFi que l'ordinateur
2. Ouvrir le navigateur sur le téléphone
3. Aller à : `http://192.168.11.105:8081/api/v1/categories/1`
4. Vous devriez voir la réponse JSON

Si ça ne fonctionne pas, vérifier le pare-feu Windows.

### Étape 5 : Vérifier le pare-feu Windows

Le pare-feu peut bloquer les connexions entrantes sur le port 8081.

**Option A : Autoriser le port 8081 (recommandé)**

1. Ouvrir "Pare-feu Windows Defender"
2. Cliquer sur "Paramètres avancés"
3. Règles de trafic entrant → Nouvelle règle
4. Port → TCP → 8081 → Autoriser la connexion
5. Appliquer à tous les profils
6. Nommer la règle : "Spring Boot API 8081"

**Option B : Désactiver temporairement le pare-feu (pour test uniquement)**

⚠️ **Attention** : Ne faites cela que pour tester, réactivez-le ensuite.

### Étape 6 : Relancer l'application Flutter

Après avoir redémarré le backend et vérifié le pare-feu :

```bash
flutter run -d 46210DLAQ000NV
```

Vous devriez maintenant voir dans les logs :
```
🌐 API GET: http://192.168.11.105:8081/api/v1/users/1/profile
📥 Response status: 200
✅ User loaded: Youssef Benlaghrissi
```

## Vérifications supplémentaires

### Vérifier que le téléphone est sur le bon réseau WiFi

1. Sur le téléphone : Paramètres → WiFi
2. Vérifier que vous êtes connecté au même réseau que l'ordinateur
3. La connexion USB seule ne suffit pas pour le réseau

### Tester avec curl (depuis l'ordinateur)

```bash
curl http://192.168.11.105:8081/api/v1/users/1/profile
```

Si ça fonctionne depuis l'ordinateur mais pas depuis le téléphone, c'est un problème de pare-feu ou de réseau.

### Vérifier l'IP du téléphone

Sur le téléphone :
- Paramètres → À propos du téléphone → Statut
- Vérifier que l'IP du téléphone est dans le même sous-réseau (192.168.11.x)

## Si le problème persiste

1. Vérifier les logs du backend Spring Boot pour voir s'il reçoit les requêtes
2. Vérifier que le backend est bien démarré et écoute sur le port 8081
3. Essayer de ping l'IP depuis le téléphone (si possible)
4. Vérifier que le pare-feu Windows autorise bien les connexions entrantes

## Alternative : Utiliser ADB port forwarding (si USB debugging)

Si le WiFi ne fonctionne pas, vous pouvez utiliser le port forwarding ADB :

```bash
adb reverse tcp:8081 tcp:8081
```

Puis dans `api_config.dart`, utiliser :
```dart
static const String baseUrl = 'http://localhost:8081/api/v1';
```

Mais cette méthode nécessite que le téléphone soit connecté en USB et que le debugging USB soit activé.

