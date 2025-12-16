# 🚀 Guide de déploiement sur DigitalOcean

## 📋 Vue d'ensemble

DigitalOcean offre un excellent rapport qualité/prix avec un contrôle total sur votre infrastructure.

**Architecture recommandée :**
- 1 Droplet (Ubuntu 22.04) pour Spring Boot : ~6$/mois
- 1 Managed Database PostgreSQL : ~15$/mois
- Total : ~21$/mois

---

## 🎯 Étape 1 : Créer un compte DigitalOcean

1. Aller sur [digitalocean.com](https://digitalocean.com)
2. Créer un compte (promo : 200$ de crédit gratuit pendant 60 jours)
3. Ajouter une méthode de paiement

---

## 🗄️ Étape 2 : Créer la base de données PostgreSQL

### 2.1 Créer la Managed Database

1. Dans le dashboard DigitalOcean, aller à **Databases**
2. Cliquer sur **Create Database Cluster**
3. Choisir :
   - **PostgreSQL** (version 15 ou 16)
   - **Datacenter** : Choisir le plus proche (ex: Frankfurt, Amsterdam)
   - **Plan** : Basic - 1GB RAM, 1 vCPU (~15$/mois)
   - **Database name** : `siblhish`
   - **User** : `siblhish_user` (ou votre choix)
4. Cliquer sur **Create Database Cluster**

### 2.2 Configurer la base de données

1. Attendre que le cluster soit créé (~5 minutes)
2. Cliquer sur le cluster créé
3. Aller dans l'onglet **Users & Databases**
4. Noter les informations de connexion :
   - **Host** : `db-postgresql-fra1-xxxxx-do-user-xxxxx-0.db.ondigitalocean.com`
   - **Port** : `25060`
   - **Database** : `siblhish`
   - **Username** : `siblhish_user`
   - **Password** : (celui que vous avez créé)

### 2.3 Configurer le firewall

1. Dans l'onglet **Settings** → **Trusted Sources**
2. Ajouter l'IP de votre Droplet (vous l'obtiendrez après la création)
3. Ou temporairement : **0.0.0.0/0** (pour tester, puis restreindre)

### 2.4 Exécuter le script SQL

1. Télécharger le script `seed_database.sql`
2. Se connecter à la base de données avec un client PostgreSQL (pgAdmin, DBeaver, ou psql)
3. Exécuter le script pour créer les tables et données initiales

**Connexion avec psql :**
```bash
psql -h db-postgresql-fra1-xxxxx-do-user-xxxxx-0.db.ondigitalocean.com \
     -p 25060 \
     -U siblhish_user \
     -d siblhish \
     -f seed_database.sql
```

---

## 🖥️ Étape 3 : Créer le Droplet (Serveur)

### 3.1 Créer le Droplet

1. Dans le dashboard, aller à **Droplets**
2. Cliquer sur **Create Droplet**
3. Configurer :
   - **Choose an image** : Ubuntu 22.04 (LTS)
   - **Choose a plan** : Basic - Regular Intel - 1GB RAM, 1 vCPU (~6$/mois)
   - **Choose a datacenter** : Même région que la base de données
   - **Authentication** : SSH keys (recommandé) ou Password
   - **Hostname** : `siblhish-api`
4. Cliquer sur **Create Droplet**

### 3.2 Noter l'IP du Droplet

Une fois créé, noter l'**IP address** du Droplet (ex: `157.230.45.123`)

---

## 🔧 Étape 4 : Configurer le Droplet

### 4.1 Se connecter au serveur

```bash
ssh root@VOTRE_IP_DROPLET
```

### 4.2 Mettre à jour le système

```bash
apt update && apt upgrade -y
```

### 4.3 Installer Java 17

```bash
apt install -y openjdk-17-jdk
java -version  # Vérifier l'installation
```

### 4.4 Installer Maven

```bash
apt install -y maven
mvn -version  # Vérifier l'installation
```

### 4.5 Installer Git

```bash
apt install -y git
```

### 4.6 Cloner le projet (ou transférer les fichiers)

**Option A : Cloner depuis GitHub**
```bash
cd /opt
git clone https://github.com/VOTRE_USERNAME/siblhish-api.git
cd siblhish-api
```

**Option B : Transférer avec SCP (depuis votre machine)**
```bash
# Depuis votre machine Windows
scp -r C:\Users\youssef.benlaghrissi\Documents\siblhish-api root@VOTRE_IP:/opt/
```

### 4.7 Configurer l'application

Créer le fichier `src/main/resources/application-prod.properties` :

```bash
nano /opt/siblhish-api/src/main/resources/application-prod.properties
```

Contenu :
```properties
spring.application.name=siblhish-api

# Database Configuration (DigitalOcean Managed Database)
spring.datasource.url=jdbc:postgresql://db-postgresql-fra1-xxxxx-do-user-xxxxx-0.db.ondigitalocean.com:25060/siblhish?sslmode=require
spring.datasource.username=siblhish_user
spring.datasource.password=VOTRE_PASSWORD
spring.datasource.driver-class-name=org.postgresql.Driver

# JPA/Hibernate Configuration
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=false
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.PostgreSQLDialect
spring.jpa.properties.hibernate.format_sql=false

# Server Configuration
server.port=8080
server.address=0.0.0.0
```

### 4.8 Builder l'application

```bash
cd /opt/siblhish-api
mvn clean package -DskipTests
```

### 4.9 Créer un service systemd

Créer le fichier `/etc/systemd/system/siblhish-api.service` :

```bash
nano /etc/systemd/system/siblhish-api.service
```

Contenu :
```ini
[Unit]
Description=Siblhish API Spring Boot Application
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/siblhish-api
ExecStart=/usr/bin/java -jar /opt/siblhish-api/target/siblhish-api-1.0.0.jar --spring.profiles.active=prod
Restart=always
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=siblhish-api

[Install]
WantedBy=multi-user.target
```

### 4.10 Démarrer le service

```bash
systemctl daemon-reload
systemctl enable siblhish-api
systemctl start siblhish-api
systemctl status siblhish-api  # Vérifier que ça fonctionne
```

### 4.11 Vérifier les logs

```bash
journalctl -u siblhish-api -f
```

---

## 🔒 Étape 5 : Configurer HTTPS avec Nginx et Let's Encrypt

### 5.1 Installer Nginx

```bash
apt install -y nginx
systemctl enable nginx
systemctl start nginx
```

### 5.2 Configurer Nginx

Créer le fichier `/etc/nginx/sites-available/siblhish-api` :

```bash
nano /etc/nginx/sites-available/siblhish-api
```

Contenu :
```nginx
server {
    listen 80;
    server_name api.siblhish.com;  # Remplacer par votre domaine

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Activer la configuration :
```bash
ln -s /etc/nginx/sites-available/siblhish-api /etc/nginx/sites-enabled/
rm /etc/nginx/sites-enabled/default
nginx -t  # Tester la configuration
systemctl reload nginx
```

### 5.3 Installer Certbot (Let's Encrypt)

```bash
apt install -y certbot python3-certbot-nginx
```

### 5.4 Obtenir un certificat SSL

**Option A : Avec un domaine**
```bash
certbot --nginx -d api.siblhish.com
```

**Option B : Sans domaine (IP seulement)**
- Utiliser Cloudflare Tunnel (gratuit)
- Ou utiliser un service comme ngrok (gratuit avec limitations)

### 5.5 Vérifier le renouvellement automatique

```bash
certbot renew --dry-run
```

---

## 🌐 Étape 6 : Configurer le domaine (optionnel mais recommandé)

### 6.1 Acheter un domaine

- Namecheap, GoDaddy, Google Domains, etc.
- Prix : ~10-15$/an

### 6.2 Configurer les DNS

Dans votre registrar DNS, ajouter un enregistrement A :
- **Type** : A
- **Name** : `api` (ou `@` pour le domaine racine)
- **Value** : IP de votre Droplet
- **TTL** : 3600

### 6.3 Attendre la propagation DNS

Attendre 5-30 minutes pour la propagation.

---

## 🔥 Étape 7 : Configurer le firewall

### 7.1 Configurer UFW (Uncomplicated Firewall)

```bash
ufw allow 22/tcp   # SSH
ufw allow 80/tcp   # HTTP
ufw allow 443/tcp  # HTTPS
ufw enable
ufw status
```

---

## 📱 Étape 8 : Mettre à jour Flutter

Mettre à jour `lib/config/api_config.dart` :

```dart
// Avec domaine
static const String baseUrl = 'https://api.siblhish.com/api/v1';

// Ou avec IP (si pas de domaine, mais nécessite un certificat SSL)
// static const String baseUrl = 'https://VOTRE_IP/api/v1';
```

---

## 🔄 Étape 9 : Automatiser le déploiement (optionnel)

### 9.1 Créer un script de déploiement

Créer `deploy.sh` sur le serveur :

```bash
#!/bin/bash
cd /opt/siblhish-api
git pull
mvn clean package -DskipTests
systemctl restart siblhish-api
```

Rendre exécutable :
```bash
chmod +x deploy.sh
```

### 9.2 Utiliser GitHub Actions (recommandé)

Créer `.github/workflows/deploy.yml` dans votre repo :

```yaml
name: Deploy to DigitalOcean

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Deploy to server
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.DROPLET_IP }}
          username: root
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            cd /opt/siblhish-api
            git pull
            mvn clean package -DskipTests
            systemctl restart siblhish-api
```

---

## 📊 Monitoring et logs

### Voir les logs en temps réel

```bash
journalctl -u siblhish-api -f
```

### Vérifier le statut

```bash
systemctl status siblhish-api
```

### Redémarrer le service

```bash
systemctl restart siblhish-api
```

---

## 🔐 Sécurité supplémentaire

### 1. Désactiver l'accès root par SSH

```bash
# Créer un utilisateur non-root
adduser deploy
usermod -aG sudo deploy

# Configurer SSH pour cet utilisateur
# Puis désactiver root dans /etc/ssh/sshd_config
```

### 2. Configurer fail2ban

```bash
apt install -y fail2ban
systemctl enable fail2ban
systemctl start fail2ban
```

### 3. Mettre à jour régulièrement

```bash
apt update && apt upgrade -y
```

---

## 💰 Coûts estimés

| Service | Prix/mois | Description |
|---------|-----------|-------------|
| Droplet Basic | 6$ | 1GB RAM, 1 vCPU |
| Managed Database | 15$ | PostgreSQL 1GB |
| Domaine (optionnel) | ~1$/mois | 10-15$/an |
| **Total** | **~22$/mois** | |

---

## ✅ Checklist de déploiement

- [ ] Compte DigitalOcean créé
- [ ] Managed Database PostgreSQL créée
- [ ] Script SQL exécuté
- [ ] Droplet créé et configuré
- [ ] Java 17 et Maven installés
- [ ] Application Spring Boot déployée
- [ ] Service systemd configuré et démarré
- [ ] Nginx installé et configuré
- [ ] Certificat SSL obtenu (Let's Encrypt)
- [ ] Firewall configuré
- [ ] Domaine configuré (optionnel)
- [ ] Application Flutter mise à jour avec la nouvelle URL
- [ ] Tests effectués

---

## 🆘 Dépannage

### L'application ne démarre pas

```bash
journalctl -u siblhish-api -n 50
```

### La base de données n'est pas accessible

1. Vérifier le firewall de la base de données (Trusted Sources)
2. Vérifier les credentials dans `application-prod.properties`
3. Tester la connexion depuis le serveur :
```bash
psql -h db-postgresql-fra1-xxxxx -p 25060 -U siblhish_user -d siblhish
```

### Nginx ne fonctionne pas

```bash
nginx -t
systemctl status nginx
tail -f /var/log/nginx/error.log
```

---

## 📚 Ressources

- [DigitalOcean Documentation](https://docs.digitalocean.com)
- [Spring Boot Production Guide](https://spring.io/guides/gs/spring-boot-for-azure/)
- [Nginx Configuration](https://nginx.org/en/docs/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)

---

Souhaitez-vous que je vous aide à créer les fichiers de configuration spécifiques pour votre projet ?

