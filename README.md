
# Food App (Healthy Eating)

## Informations Etudiant
- **Nom :** NOUBISSIE KAMGA WILFRIED
- **Matricule :** 20U2671

## Table des Matières
1. [Présentation de l'Application](#présentation-de-lapplication)
2. [Étapes d'Exécution](#étapes-dexécution)
3. [Fonctionnalités Implémentées](#fonctionnalités-implémentées)


## Présentation de l'Application
Application conçue pour aider les utilisateurs à organiser leurs repas, suivre leur apport
nutritionnel, calculer des indicateurs de santé comme l’IMC et recevoir des recommandations de repas personnalisées

## Étapes d'Exécution :

1. **Installer les dépendances**
   ```bash
   flutter pub get
   ```

2. **Démarrer l'application**
   ```bash
   flutter run
   ```


## Fonctionnalités Implémentées

- **Authentification** : Système complet d'inscription (nom, email, mot de passe) et de connexion sécurisée

- **Gestion du Profil et IMC** : 
  - Saisie et modification des données personnelles (taille, poids)
  - Calcul automatique de l'IMC avec interprétation des résultats
  - Affichage des catégories (insuffisance pondérale, poids normal, surpoids, obésité)

- **Gestion des Repas** :
  - Enregistrement détaillé des repas (nom, calories, date et heure)
  - Visualisation de l'historique complet des repas
  - Fonctionnalités de modification et suppression des repas existants

- **Analyses Statistiques** :
  - Calcul des calories totales (jour, semaine, mois, année)
  - Calcul de la moyenne hebdomadaire des calories
  - Système d'alertes pour le dépassement des objectifs caloriques

- **Recommandations Personnalisées** :
  - Suggestions de repas adaptées à l'IMC de l'utilisateur
  - Recommandations nutritionnelles personnalisée basé sur l'algorithme du sac à dos

- **Services de Géolocalisation** :
  - Localisation des restaurants à proximité
  - Recherche des diététiciens proches

- **Chatbot Intégré** :
  - Messagerie interactive en temps réel
  - Support pour l'envoi et la réception de messages
  - Fonction de téléchargement de fichiers
