-- Script d'insertion des cartes de statistiques utilisées dans l'application
-- Table: cards (id, code, title)
-- Seules les cartes actives dans le code sont incluses

-- 1. Graphique en barres (Calendrier Revenus vs Dépenses)
INSERT INTO cards (code, title) VALUES 
('bar_chart', 'Graphique Revenus vs Dépenses');

-- 2. Graphique secteurs (Répartition par Catégorie)
INSERT INTO cards (code, title) VALUES 
('pie_chart', 'Répartition par Catégorie');

-- 3. Carte Moyenne Dépenses
INSERT INTO cards (code, title) VALUES 
('average_expense_card', 'Moyenne Dépenses');

-- 4. Carte Moyenne Revenus
INSERT INTO cards (code, title) VALUES 
('average_income_card', 'Moyenne Revenus');

-- 5. Carte Nombre de Transactions
INSERT INTO cards (code, title) VALUES 
('transaction_count_card', 'Nombre de Transactions');

-- 6. Top Catégories Budgétisées
INSERT INTO cards (code, title) VALUES 
('top_budget_categories_card', 'Top Catégories Budgétisées');

-- 7. Répartition des Budgets (Graphique secteurs)
INSERT INTO cards (code, title) VALUES 
('budget_distribution_pie_chart', 'Répartition des Budgets');

-- Note: Les cartes suivantes sont définies dans le code mais désactivées (retournent SizedBox.shrink()):
-- - balance_card (Solde Actuel)
-- - top_expense_card (Dépense la Plus Élevée)
-- - top_category_card (Top Catégorie)
-- - scheduled_payments_card (Paiements Planifiés)
-- - goals_progress_card (Progression des Objectifs)
-- - budget_vs_actual_chart (Budget vs Réel)
-- - budget_efficiency_card (Efficacité Budgétaire)
-- - savings_card (Économies)
-- Elles ne sont pas incluses dans ce script car non utilisées actuellement.

