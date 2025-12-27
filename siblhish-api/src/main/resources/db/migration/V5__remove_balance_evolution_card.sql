-- Supprimer la carte "Évolution du Solde" de la base de données
-- Cette carte est supprimée car elle n'est plus utilisée dans l'application

-- Supprimer les favoris associés à cette carte
DELETE FROM favorites 
WHERE card_id IN (SELECT id FROM cards WHERE code = 'balance_evolution_card');

-- Supprimer la carte elle-même
DELETE FROM cards WHERE code = 'balance_evolution_card';

