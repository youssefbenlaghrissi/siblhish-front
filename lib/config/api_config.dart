// Configuration de l'API backend
class ApiConfig {
  // URL de base du backend Spring Boot
  // Pour Android Emulator : http://10.0.2.2:8081
  // Pour iOS Simulator : http://localhost:8081
  // Pour téléphone physique : http://[IP_LOCALE]:8081 (ex: http://192.168.1.100:8081)
  // 
  // IMPORTANT: Pour trouver votre IP locale sur Windows:
  // 1. Ouvrir PowerShell
  // 2. Exécuter: ipconfig
  // 3. Chercher "IPv4 Address" sous "Wireless LAN adapter Wi-Fi" ou "Ethernet adapter"
  // 4. Remplacer l'IP ci-dessous par votre IP (ex: 192.168.1.100)
  // 
  // NOTE: localhost ne fonctionne QUE depuis l'ordinateur, pas depuis le téléphone
  // Pour téléphone physique via USB: utiliser l'IP locale du réseau WiFi
  static const String baseUrl = 'https://siblhish-api-production.up.railway.app/api/v1';
  
  // Timeout pour les requêtes (réduit pour détecter les erreurs plus rapidement)
  static const Duration timeout = Duration(seconds: 10);
  
  // Headers par défaut
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}

