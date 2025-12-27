# Script SQL pour Ajouter les Cartes de Statistiques Budgets

## 📋 Description

Ce script SQL permet d'ajouter les 5 nouvelles cartes de statistiques budgétaires dans la base de données backend.

## 🗄️ Script SQL

```sql
-- Migration V7 : Ajouter les nouvelles cartes statistiques pour les budgets
-- Date: 2025-12-XX
-- Description: Ajout des 5 nouvelles cartes de statistiques budgétaires

INSERT INTO cards (code, title) VALUES
    ('budget_vs_actual_chart', 'Budget vs Réel'),
    ('top_budget_categories_card', 'Top Catégories Budgétisées'),
    ('budget_efficiency_card', 'Efficacité Budgétaire'),
    ('monthly_budget_trend', 'Tendance Mensuelle Budgets'),
    ('budget_distribution_pie_chart', 'Répartition des Budgets')
ON CONFLICT (code) DO UPDATE SET title = EXCLUDED.title;
```

## 📝 Cartes à ajouter

| Code | Titre | Description |
|------|-------|-------------|
| `budget_vs_actual_chart` | Budget vs Réel | Graphique en barres comparant budgetisé vs dépensé |
| `top_budget_categories_card` | Top Catégories Budgétisées | Liste des top catégories avec barres de progression |
| `budget_efficiency_card` | Efficacité Budgétaire | Jauge circulaire avec montant économisé |
| `monthly_budget_trend` | Tendance Mensuelle Budgets | Graphique linéaire sur plusieurs mois |
| `budget_distribution_pie_chart` | Répartition des Budgets | Graphique en secteurs (camembert) |

## 🚀 Instructions d'utilisation

### Option 1 : Via Migration Flyway (Recommandé)

1. Copier le script dans un nouveau fichier de migration :
   ```
   siblhish-api/src/main/resources/db/migration/V7__add_budget_statistics_cards.sql
   ```

2. Le script sera exécuté automatiquement au prochain démarrage de l'application

### Option 2 : Exécution manuelle

1. Se connecter à la base de données PostgreSQL
2. Exécuter le script SQL ci-dessus
3. Vérifier que les cartes ont été ajoutées :
   ```sql
   SELECT * FROM cards WHERE code LIKE 'budget%';
   ```

## ✅ Vérification

Après l'exécution du script, vérifier que les 5 cartes sont bien présentes :

```sql
SELECT id, code, title FROM cards 
WHERE code IN (
    'budget_vs_actual_chart',
    'top_budget_categories_card',
    'budget_efficiency_card',
    'monthly_budget_trend',
    'budget_distribution_pie_chart'
)
ORDER BY code;
```

Vous devriez voir 5 lignes avec les codes et titres correspondants.

## 📱 Frontend

Une fois les cartes ajoutées dans la base de données :

1. Les cartes apparaîtront automatiquement dans le modal de sélection des cartes (`SelectCardsModal`)
2. Les utilisateurs pourront les sélectionner pour les afficher dans l'écran des statistiques
3. Les graphiques utiliseront des données mockées jusqu'à ce que les endpoints API soient implémentés

## 🔗 Fichiers concernés

- **Backend** : `siblhish-api/src/main/resources/db/migration/V7__add_budget_statistics_cards.sql`
- **Frontend** : Les widgets sont déjà créés dans `lib/widgets/statistics/`
- **Modèle** : `lib/models/statistics_card.dart` (types déjà ajoutés)
- **Écran** : `lib/screens/statistics_screen.dart` (cas déjà ajoutés)

## 📌 Notes

- Le script utilise `ON CONFLICT (code) DO UPDATE SET title = EXCLUDED.title` pour éviter les erreurs si les cartes existent déjà
- Les cartes seront disponibles immédiatement après l'exécution du script
- Les graphiques utilisent actuellement des données mockées pour la démonstration

