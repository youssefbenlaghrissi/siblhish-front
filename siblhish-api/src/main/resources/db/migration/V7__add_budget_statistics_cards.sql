-- Ajouter les nouvelles cartes statistiques pour les budgets
-- Migration V7 : Ajout des 5 nouvelles cartes de statistiques budgétaires

INSERT INTO cards (code, title) VALUES
    ('budget_vs_actual_chart', 'Budget vs Réel'),
    ('top_budget_categories_card', 'Top Catégories Budgétisées'),
    ('budget_efficiency_card', 'Efficacité Budgétaire'),
    ('monthly_budget_trend', 'Tendance Mensuelle Budgets'),
    ('budget_distribution_pie_chart', 'Répartition des Budgets')
ON CONFLICT (code) DO UPDATE SET title = EXCLUDED.title;

