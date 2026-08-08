# Charte de confidentialité pour l'application mobile « Train Libre » et le site web

**Version 1.7**  
**En date du : 7 août 2026**

Cette charte de confidentialité vous informe conformément aux articles 13 et 14 du Règlement Général sur la Protection des Données (RGPD) du traitement des données à caractère personnel et des données relatives à la santé dans l'application mobile « Train Libre » ainsi que lors de votre visite sur ce site web.

Train Libre étant une application conçue selon le principe « Local-First », le contrôle total de vos données vous revient directement à tout moment. Nous n'exploitons aucune base de données centrale ni aucun serveur applicatif pour stocker vos profils, vos séances d'entraînement ou vos journaux de nutrition.

---

## 1. Responsable du traitement

Le responsable du traitement des données au sens de l'article 4, point 7 du RGPD est le développeur et prestataire de services :

**Richard Georg Schotte**  
Bundesallee 114  
12161 Berlin  
Allemagne  

E-Mail : feedback@schotte.me  
Téléphone : (+49) 1520 6915571  

S'agissant d'un projet de développeur indépendant et les critères de désignation obligatoire d'un délégué à la protection des données n'étant pas remplis conformément à l'article 37 du RGPD et § 38 du BDSG allemand, aucun délégué à la protection des données n'a été nommé. Vous pouvez adresser toutes vos questions à l'adresse e-mail ci-dessus.

---

## 2. Philosophie fondamentale

Train Libre repose sur les principes de « Privacy by Design » et « Privacy by Default » (Article 25 du RGPD) ainsi que sur le principe de minimisation des données (Article 5(1)(c) du RGPD).

* **Pas de compte utilisateur :** Aucune inscription n'est requise. Aucun identifiant, mot de passe ou adresse e-mail n'est stocké sur des serveurs distants.
* **Architecture Local-First :** Vos données de profil, vos entraînements, vos repas, vos mesures corporelles et vos constantes restent stockés exclusivement dans une base SQLite locale sur votre appareil.
* **Pas de serveur applicatif central :** Nous n'hébergeons aucun cloud pour collecter ou traiter vos informations quotidiennes. Vos données restent sous votre possession physique.
* **Pas de suivi commercial (Télémétrie anonyme optionnelle) :** Train Libre renonce aux réseaux publicitaires, au suivi commercial et au profilage comportemental. Une intégration de statistiques d'utilisation purement anonyme (PostHog EU) est désactivée par défaut et ne collecte aucune donnée à caractère personnel (PII) ni aucun contenu personnel d'entraînement ou de nutrition.
* **Hébergement web & Cookies (Visite du site) :** Lorsque vous visitez ce site, votre navigateur se connecte aux serveurs de notre hébergeur (GitHub Pages / GitHub Inc., 88 Colin P. Kelly Jr St, San Francisco, CA 94107, USA) pour des raisons techniques. Des fichiers de log technique standard (IP, agent utilisateur, horodatage) sont traités pour délivrer la page, sur la base de notre intérêt légitime (Art. 6(1)(f) RGPD). Ce site n'utilise aucun cookie ni script analytique.

---

## 3. Données traitées localement

L'utilisation de l'application implique le traitement de vos données par le système d'exploitation de votre appareil dans une base SQLite locale (via Drift/sqflite). Ce stockage est nécessaire au fonctionnement de l'application.

### A. Catégories de données traitées
1. **Profil et objectifs :** Nom d'utilisateur, date de naissance, taille, genre, chemin de photo de profil et objectifs quotidiens (calories, protéines, glucides, lipides, eau, pas).
2. **Historique d'activité (Workouts) :** Routines d'entraînement, modèles d'exercices, historique des séances (début, fin, notes, séries, répétitions, charges, RPE/RIR, temps de repos, cardio).
3. **Historique nutritionnel et hydratation :** Aliments consommés, quantités, type de repas, consommations d'eau et de boissons (nutriments, caféine).
4. **Catalogue alimentaire personnalisé :** Produits créés par l'utilisateur avec code-barres, marque et valeurs nutritionnelles pour 100g/ml.
5. **Suppléments :** Suppléments configurés et historique des prises.
6. **Mesures corporelles :** Historique du poids corporel et des mensurations avec date et unité.
7. **Fréquence cardiaque :** Agrégations horaires calculées localement sur l'appareil.
8. **Analyses du sommeil :** Phases de sommeil, efficacité et régularité importées des interfaces système.
9. **Segments de pas :** Pas importés des interfaces système avec nettoyage des doublons.

### B. Base légale du traitement
* **Données générales et paramètres (Art. 6(1)(b) RGPD) :** Le traitement est nécessaire à l'exécution de la relation d'utilisation (fourniture des fonctions de l'application).
* **Données de santé (Art. 9(2)(a) en conjonction avec Art. 6(1)(a) RGPD) :** En saisissant vos mesures corporelles ou en activant l'import des données de santé (sommeil, pouls), vous consentez explicitement au traitement local. Vous pouvez retirer ce consentement à tout moment en supprimant vos entrées ou en réinitialisant l'application.

---

## 4. Services tiers & BYOK

Pour fournir des fonctions avancées, l'application dispose d'interfaces vers des services externes. Ces fonctions sont facultatives et nécessitent votre action.

### A. Reconnaissance des repas par IA (BYOK)
Train Libre vous permet d'analyser vos repas par photo ou texte en fournissant votre propre clé API (BYOK) d'un fournisseur pris en charge.

* **Fournisseurs pris en charge :** OpenAI, Google Gemini, Anthropic Claude, Mistral AI, xAI Grok, Ollama et end-points compatibles OpenAI.
* **Stockage sécurisé :** Votre clé API est chiffrée en AES-256 via `flutter_secure_storage` dans le trousseau sécurisé de l'appareil (iOS Keychain / Android Keystore) et n'est jamais transmise de notre côté.
* **Transmission limitée :** L'image ou la description est envoyée chiffrée en HTTPS directement à l'API du fournisseur sélectionné. Aucune métadonnée personnelle n'est jointe.
* **Traitement analytique :** L'IA est utilisée uniquement pour décomposer la description ou l'image en ingrédients. Train Libre ne génère pas de conseils ou de plans de repas via l'IA.
* **Protection par prompt système :** Le prompt système demande à l'IA de ne pas calculer les nutriments. Les aliments sont mis en correspondance localement sur votre appareil avec la base SQLite hors-ligne pour en déduire les macros.
* **Algorithme local :** Les calculs de calories et le suivi restent 100% locaux sur votre appareil et ne servent pas à entraîner les modèles globaux d'IA.
* **Responsabilité :** L'utilisation de votre clé implique une relation directe avec le fournisseur d'IA. Veuillez consulter sa charte de confidentialité avant utilisation.

| Fournisseur | Charte de confidentialité |
| :--- | :--- |
| OpenAI | https://openai.com/policies/privacy-policy |
| Google Gemini | https://policies.google.com/privacy |
| Anthropic Claude | https://www.anthropic.com/privacy |
| Mistral AI | https://mistral.ai/privacy-policy |
| xAI Grok | https://x.ai/privacy-policy |
| Ollama | https://ollama.com/privacy |

### B. Mises à jour des catalogues hors-ligne
* **Fonctionnement :** L'application vérifie périodiquement la disponibilité de mises à jour des catalogues d'aliments (Open Food Facts) et d'exercices (wger) via HTTPS vers les serveurs d'hébergement.
* **Minimisation :** Seules les données techniques de connexion (IP, horodatage, agent utilisateur) sont transmises pour le téléchargement. Aucun historique personnel n'est envoyé.
* **Recherche hors-ligne :** La recherche d'aliments et le scan de code-barres s'effectuent entièrement hors-ligne sur votre appareil.

---

## 5. Données de santé du système (HealthKit / Health Connect)

Train Libre peut interagir avec les bases de santé système (Apple HealthKit ou Google Health Connect). Cela requiert votre autorisation explicite et peut être révoqué dans les réglages système.

* **Importation (Lecture) :** Pas, sommeil et fréquence cardiaque pour affichage local.
* **Exportation (Écriture) :** Séances, repas et poids.
* **Protection contre les doublons :** Registre local d'idempotence (`health_export_records`) pour éviter les écritures en double.

---

## 6. Sécurité des données, sauvegardes et télémétrie

Puisque toutes les données résident sur votre appareil, la sécurité physique et logique de ce dernier est essentielle.

### A. Isolation applicative
Le système d'exploitation isole l'application dans un bac à sable (sandbox), empêchant les autres applications d'accéder à sa base SQLite ou aux clés API.

### B. Sauvegardes
1. **Exportation de fichiers :** Vous pouvez générer une sauvegarde JSON complète exportable via le menu de partage.
2. **Chiffrement :** Les sauvegardes peuvent être chiffrées localement par mot de passe.
3. **Sauvegardes automatiques :** Sur Android via SAF (Storage Access Framework).
4. **Sauvegardes système :** Incluses dans iCloud/Google Drive Backup si activé au niveau système.
5. **Sauvegarde iCloud (iOS uniquement) :** Optionnelle et gérée par votre identifiant Apple. Chiffrée par Apple.

### C. Statistiques d'utilisation pseudonymisées optionnelles

Train Libre propose une mesure d'utilisation purement optionnelle et respectueuse de la vie privée, destinée à améliorer la stabilité de l'application et l'usage des fonctionnalités, opérée via PostHog EU (https://eu.i.posthog.com). Dans l'application, la fonction est intitulée « Partager des statistiques d'utilisation anonymes ». PostHog associant des identifiants techniques aux événements transmis, il s'agit juridiquement de données pseudonymisées ; une anonymité complète ne peut être garantie pour des données techniques d'utilisation.

1. **Opt-in strict par défaut:** La télémétrie est entièrement désactivée par défaut. Tant que vous n'avez pas expressément consenti, la bibliothèque de télémétrie n'est même pas initialisée. Aucun événement n'est transmis et aucune connexion réseau vers PostHog n'est établie — pas même une requête technique de configuration. Ce n'est qu'au moment où vous activez « Partager des statistiques d'utilisation anonymes » dans les Paramètres, sous Support & Info, que l'application contacte PostHog pour la première fois. Un identifiant d'appareil aléatoire est certes généré localement dès le premier lancement, afin que le décompte des appareils actifs fonctionne à partir de votre consentement ; cette génération a lieu exclusivement sur votre appareil et sans aucune transmission.
2. **Étendue des événements collectés:** Si vous avez consenti, seules les catégories suivantes sont collectées :

   - Lancements de l'application (pour déterminer le nombre d'appareils actifs)
   - Écrans ouverts, identifiés uniquement par des identifiants techniques issus d'une liste figée dans le code source (par exemple diary_tab, live_workout)
   - Fonctions déclenchées, également au moyen d'identifiants fixes (par exemple routine_created, barcode_scanned)
   - Un compteur agrégé des entrées alimentaires enregistrées (le nombre ainsi que le mode de saisie, par exemple recherche, scan de code-barres ou reconnaissance par IA)
   - Indicateurs des séances d'entraînement terminées : nombre d'exercices, de séries et de minuteurs de repos, durée en minutes, ainsi que des indications par oui/non sur les fonctions d'entraînement utilisées. Le type de séance est transmis exclusivement sous la forme « routine » ou « custom », jamais sous forme de nom
   - Progression dans l'intégration initiale (numéro d'étape, nom de l'étape, temps passé)
   - Paramètres modifiés (identifiant du paramètre et nouvelle valeur)
   - État des requêtes IA de reconnaissance de repas (fournisseur choisi, succès ou code d'erreur, temps de réponse par plages larges telles que « 2-5s »)
   - État des migrations de base de données (version de départ et version cible, succès)
   - Indicateurs de l'estimation calorique adaptative : nombre d'entrées de poids et d'alimentation prises en compte, longueur de la fenêtre d'analyse, niveau de confiance et indicateurs de qualité — mais aucune valeur de poids, de calories ou d'objectif
   - Données techniques de contexte : version de l'application, build, système d'exploitation et sa version, plateforme, fuseau horaire, ainsi qu'une indication précisant si l'application s'exécute dans un émulateur

   Les compteurs tels que le nombre d'exercices ou de séries et la durée de l'entraînement sont transmis sous forme de valeurs numériques exactes et non de plages. Ces valeurs sont transmises sans nom, adresse e-mail ni identifiant d'appareil du fabricant. L'identification d'utilisateurs individuels n'est ni recherchée ni techniquement prévue.

3. **Aucun contenu ni valeur de santé:** Aucun nom, adresse e-mail, identifiant de compte ou identifiant d'appareil du fabricant n'est collecté, ni aucun contenu que vous saisissez — en particulier aucun titre de programme d'entraînement, nom d'exercice ou d'aliment, nom de recette, note ou texte libre. De même, aucune mensuration corporelle, aucun poids, aucune valeur calorique ou nutritionnelle n'est transmis. Tous les événements sont envoyés avec $ip : 0.0.0.0 ; les adresses IP ne sont pas conservées comme données d'événement et la résolution de localisation basée sur l'IP est expressément désactivée au moyen de $geoip_disable.
4. **Pays et langue:** Afin d'analyser la répartition géographique de l'application, votre pays, votre continent et votre paramètre de langue sont transmis (par exemple « DE », « Europe », « de_DE »). Ces informations sont déduites sur votre appareil à partir de vos réglages système, et non de votre adresse IP. Aucune résolution jusqu'à la ville, la région, le code postal ou les coordonnées n'a lieu ; elle est désactivée côté serveur.
5. **Rapport de diagnostic volontaire:** Dans la section Retour d'expérience, vous pouvez envoyer activement un rapport de diagnostic au développeur. Le rapport vous est présenté intégralement dans un aperçu avant l'envoi, et vous sélectionnez individuellement les sections incluses. Si vous le transmettez par e-mail, via le menu de partage, le presse-papiers ou l'export de fichier, il parvient directement au développeur sous votre propre contrôle et non par l'intermédiaire de PostHog. Pour l'envoi direct vers PostHog proposé en complément, le point 3 s'applique sans changement : votre note en texte libre, votre poids corporel ainsi que vos valeurs caloriques et de macronutriments ne sont pas transmis ; seules le sont des mesures techniques telles que le nombre d'entrées, les niveaux de confiance, les indicateurs de qualité et l'état de vos sauvegardes. L'envoi direct suppose un consentement actif au sens du point 1 ; si les statistiques d'utilisation sont désactivées, l'application vous en informe au lieu de signaler un envoi.
6. **Révocation et effacement:** Vous pouvez retirer votre consentement à tout moment dans les Paramètres, ce qui interrompt immédiatement toute transmission. Le bouton « Supprimer les données de télémétrie » dans les Paramètres vous permet en outre de demander l'effacement des données associées à votre identifiant de télémétrie chez PostHog ; dans le même temps, tous les identifiants stockés localement sont réinitialisés. L'effacement peut faire l'objet d'exceptions techniques, par exemple pour les copies de sauvegarde. Un simple e-mail à feedback@schotte.me suffit également.
7. **Base légale:** Le traitement des données de télémétrie repose exclusivement sur votre consentement explicite conformément à l'article 6, paragraphe 1, point a) du RGPD.
8. **Sous-traitant:** PostHog, Inc. (2261 Market St., #4008, San Francisco, CA 94114, USA) agit en qualité de sous-traitant au sens de l'article 28 du RGPD. Un contrat de sous-traitance (Data Processing Agreement, DPA) a été conclu.
9. **Lieu de stockage, durée de conservation et transferts hors UE:** Le projet PostHog EU utilisé s'appuie, comme infrastructure d'hébergement principale, sur des serveurs situés à Francfort-sur-le-Main, en Allemagne (AWS eu-central-1). Les données de télémétrie sont automatiquement supprimées après 12 mois au maximum. Selon les processus d'assistance, de sécurité et de sous-traitance ultérieure, des accès ou des traitements peuvent également avoir lieu en dehors de l'UE. De tels transferts sont couverts par les garanties appropriées convenues dans le contrat de sous-traitance, complétées par la certification au titre du EU-US Data Privacy Framework (DPF).
10. **Transparence complète:** Le catalogue complet de tous les événements et des attributs transmis pour chacun d'eux est consultable publiquement dans le dépôt du code source, dans le fichier TELEMETRY.md. Les versions F-Droid et hors ligne sont compilées sans la bibliothèque de télémétrie et n'en contiennent pas le code.

---

## 7. Vos droits (RGPD)

Vous disposez de droits étendus sous le RGPD :

* **Accès et portabilité (Art. 15 & 20 RGPD) :** Exportation JSON complète.
* **Rectification (Art. 16 RGPD) :** Modification directe dans l'application.
* **Effacement (Art. 17 RGPD) :** Suppression manuelle d'enregistrements.
* **Réinitialisation totale (AppData Reset) :** Effacement définitif de toutes les données locales, paramètres et clés API.
* **Droits relatifs aux données de télémétrie :** Si vous avez accepté la télémétrie anonyme, vous pouvez exercer vos droits (accès, effacement, opposition) concernant les données de télémétrie traitées en contactant le responsable du traitement à feedback@schotte.me. Sur simple demande, tous vos événements de télémétrie seront supprimés des serveurs de PostHog.
* **Réclamation auprès d'une autorité de contrôle (Art. 77 RGPD) :** Droit de déposer une plainte auprès de la CNIL ou de l'autorité compétente.
