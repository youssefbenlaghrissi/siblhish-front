# Explication de la Granularité des Statistiques

## 📋 Pourquoi déterminer automatiquement la granularité ?

Le backend détermine automatiquement **comment agréger les données** selon la plage de dates envoyée par le frontend. Voici pourquoi :

## 🎯 Principe

Le frontend envoie `startDate` et `endDate` selon la période choisie :
- **daily** : `startDate = 2025-12-23`, `endDate = 2025-12-23` (1 jour)
- **weekly** : `startDate = 2025-12-29`, `endDate = 2026-01-04` (7 jours)
- **monthly** : `startDate = 2025-12-01`, `endDate = 2025-12-31` (~30 jours)
- **3months** : `startDate = 2025-10-01`, `endDate = 2025-12-23` (~90 jours)
- **6months** : `startDate = 2025-07-01`, `endDate = 2025-12-23` (~180 jours)

Le backend utilise le **nombre de jours** entre `startDate` et `endDate` pour décider comment agréger les données.

## 📊 Logique de Granularité

### 1. **≤ 1 jour** (daily)
```java
if (daysBetween <= 1) {
    periodFormat = "TO_CHAR(creation_date, 'YYYY-MM-DD')";
}
```
**Résultat** : Agrégation par jour
- **Exemple** : `[{period: "2025-12-23", totalIncome: 1000, totalExpenses: 500}]`
- **Pourquoi** : Même pour 1 jour, on groupe par jour pour avoir un format cohérent

### 2. **≤ 31 jours** (weekly ou monthly)
```java
else if (daysBetween <= 31) {
    periodFormat = "TO_CHAR(creation_date, 'YYYY-MM-DD')";
}
```
**Résultat** : Agrégation par jour
- **Exemple weekly** : 
  ```json
  [
    {period: "2025-12-29", totalIncome: 500, totalExpenses: 200},
    {period: "2025-12-30", totalIncome: 300, totalExpenses: 150},
    ...
    {period: "2026-01-04", totalIncome: 400, totalExpenses: 100}
  ]
  ```
- **Pourquoi** : Pour voir chaque jour de la semaine/mois dans le graphique

### 3. **≤ 93 jours** (3months)
```java
else if (daysBetween <= 93) {
    periodFormat = "TO_CHAR(DATE_TRUNC('week', creation_date), 'YYYY-MM-DD')";
}
```
**Résultat** : Agrégation par semaine
- **Exemple** :
  ```json
  [
    {period: "2025-10-06", totalIncome: 2000, totalExpenses: 1500}, // Semaine du 6 oct
    {period: "2025-10-13", totalIncome: 1800, totalExpenses: 1200}, // Semaine du 13 oct
    ...
  ]
  ```
- **Pourquoi** : 90 jours = ~13 semaines. Si on agrégeait par jour, on aurait 90 points, ce qui serait trop pour un graphique. Par semaine, on a ~13 points, ce qui est lisible.

### 4. **> 93 jours** (6months ou plus)
```java
else {
    periodFormat = "TO_CHAR(creation_date, 'YYYY-MM')";
}
```
**Résultat** : Agrégation par mois
- **Exemple** :
  ```json
  [
    {period: "2025-07", totalIncome: 5000, totalExpenses: 4000},
    {period: "2025-08", totalIncome: 5500, totalExpenses: 4200},
    ...
    {period: "2025-12", totalIncome: 6000, totalExpenses: 4500}
  ]
  ```
- **Pourquoi** : 180 jours = ~6 mois. Par mois, on a 6 points, ce qui est idéal pour un graphique.

## 🔍 Exemple Concret

### Scénario : Utilisateur choisit "weekly" (semaine du 29 déc au 4 janv)

1. **Frontend calcule** :
   - `startDate = 2025-12-29`
   - `endDate = 2026-01-04`
   - `daysBetween = 6 jours`

2. **Backend reçoit** :
   ```
   GET /api/v1/statistics/expense-and-income-by-period/1?startDate=2025-12-29&endDate=2026-01-04
   ```

3. **Backend calcule** :
   ```java
   daysBetween = ChronoUnit.DAYS.between(startDate, endDate); // = 6
   // 6 <= 31 → agrégation par jour
   periodFormat = "TO_CHAR(creation_date, 'YYYY-MM-DD')";
   ```

4. **Résultat SQL** :
   ```sql
   SELECT 
       TO_CHAR(creation_date, 'YYYY-MM-DD') as period,
       SUM(amount) as total_income,
       ...
   FROM incomes
   WHERE DATE(creation_date) >= '2025-12-29' 
     AND DATE(creation_date) <= '2026-01-04'
   GROUP BY TO_CHAR(creation_date, 'YYYY-MM-DD')
   ```

5. **Résultat API** :
   ```json
   [
     {"period": "2025-12-29", "totalIncome": 500, "totalExpenses": 200},
     {"period": "2025-12-30", "totalIncome": 300, "totalExpenses": 150},
     {"period": "2025-12-31", "totalIncome": 400, "totalExpenses": 100},
     {"period": "2026-01-01", "totalIncome": 600, "totalExpenses": 250},
     {"period": "2026-01-02", "totalIncome": 350, "totalExpenses": 180},
     {"period": "2026-01-03", "totalIncome": 450, "totalExpenses": 200},
     {"period": "2026-01-04", "totalIncome": 400, "totalExpenses": 150}
   ]
   ```

## ✅ Avantages de cette Approche

1. **Flexibilité** : Le backend s'adapte automatiquement à la plage de dates
2. **Performance** : Moins de points de données pour les grandes plages (mois au lieu de jours)
3. **Lisibilité** : Le nombre de points est adapté à la visualisation dans un graphique
4. **Simplicité** : Le frontend n'a qu'à envoyer les dates, pas la granularité

## 🎨 Visualisation dans le Graphique

- **daily/weekly/monthly** : Graphique avec points par jour (7-30 points)
- **3months** : Graphique avec points par semaine (~13 points)
- **6months** : Graphique avec points par mois (6 points)

Cela garantit que le graphique reste lisible et performant, peu importe la période choisie !

