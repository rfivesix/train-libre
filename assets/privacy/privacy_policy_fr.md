# Charte de confidentialité pour l'application mobile « Train Libre » et le site web

**Version 1.8**  
**En date du : 8 octobre 2026**

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
* **Architecture Local-First :** Vos données de profil, entraînements, nutrition, santé et mesures sont principalement stockées localement. Des fonctions facultatives peuvent transmettre des données ou créer des copies hors de l’appareil, comme décrit ci-dessous.
* **Pas de serveur applicatif central :** Nous n’exploitons pas de base de données cloud centrale pour stocker vos journaux d’entraînement et de nutrition. Des services facultatifs et des sauvegardes peuvent toutefois recevoir ou conserver des copies.
* **Pas de publicité :** Train Libre n’utilise pas de réseaux publicitaires ni de publicité comportementale. Les statistiques facultatives sont désactivées par défaut. Lorsqu’elles sont activées, les événements peuvent inclure des identifiants techniques et des indicateurs issus de fonctions liées à la nutrition ou au poids ; ils peuvent être personnels ou liés à la santé même sans nom. Voir la section 6 C.
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

La base juridique dépend de la fonction et de la finalité du traitement. Certains traitements reposent sur votre consentement, qui peut être retiré pour l’avenir. Supprimer des enregistrements ou réinitialiser l’application ne constitue pas automatiquement un retrait et n’annule pas les traitements déjà effectués. Les transmissions facultatives sont décrites dans les sections correspondantes. L’évaluation juridique précise doit être vérifiée à partir de la configuration réelle.

---

## 4. Services tiers & BYOK

Pour fournir des fonctions avancées, l'application dispose d'interfaces vers des services externes. Ces fonctions sont facultatives et nécessitent votre action.

### A. Intelligence artificielle : chat, reconnaissance des repas et brouillons

Train Libre propose des fonctions facultatives d’IA pour le chat, la reconnaissance des repas et la préparation de brouillons (repas, routines, plans d’entraînement et recettes). Les estimations et suggestions peuvent être incomplètes ou erronées.

**Votre contenu envoyé.** Lorsque vous envoyez un message, le texte saisi ou dicté et les images jointes sont transmis au modèle utilisé pour cette requête, avant toute demande distincte d’accès aux données enregistrées dans l’application. Votre message ou votre image peut lui-même contenir des données personnelles ou de santé. La requête peut inclure un contexte limité de conversations antérieures, des instructions, l’identifiant du modèle et des contenus précédents. Toutes les requêtes ne contiennent pas de données stockées dans l’application : envoyer un message est distinct de l’autorisation d’accéder à ces données. La dictée peut utiliser un service de reconnaissance vocale selon l’appareil et ses réglages. Le nettoyage facultatif de la transcription d’un repas peut transmettre le texte avant l’envoi du repas.

**Données enregistrées dans l’application.** L’assistant peut demander des catégories telles que les entraînements, le journal alimentaire, les pas, le sommeil, la récupération, les mesures, les objectifs, le profil, les compléments, les recettes, les exercices, les routines et les plans. Les nouveaux accès sont soumis à une demande d’autorisation. L’approbation automatique est désactivée par défaut ; si elle est activée, des demandes ultérieures peuvent être approuvées sans nouvelle décision. La carte indique les catégories et la période, mais ne prévisualise pas nécessairement chaque valeur transmise. Les résultats de requêtes locales et les échanges d’outils associés peuvent être envoyés au modèle. Désactiver l’approbation automatique ne rappelle pas les données déjà envoyées et n’arrête pas nécessairement une opération en cours.

**Destinataire.** L’autorisation n’est pas liée à un fournisseur précis. Pour le chat texte, l’application peut basculer vers un autre fournisseur configuré si le fournisseur sélectionné est indisponible ou sans identifiants, puis le résoudre à nouveau après l’approbation. Un autre destinataire peut donc être utilisé ; la carte d’autorisation n’identifie pas elle-même ce destinataire. Les configurations prises en charge comprennent Apple Foundation Models, OpenAI, Google, Anthropic, Mistral, xAI, DeepSeek, Ollama et des points de terminaison OpenAI compatibles personnalisés. Un serveur personnalisé peut être local ou distant et transmettre les données ailleurs. Train Libre ne peut pas vérifier les pratiques externes de conservation, d’examen humain, d’entraînement, de transfert ou d’effacement. Consultez les conditions de l’API ou de l’exploitant concerné.

**Historique et suppression.** Les messages, réponses, erreurs, identifiants de fournisseur et de modèle, autorisations et références aux pièces jointes peuvent être stockés localement ; les pièces jointes peuvent aussi être des fichiers. La suppression d’une conversation tente de supprimer ses pièces jointes. La réinitialisation supprime de nombreuses données et clés, mais ne garantit pas la suppression de chaque fichier, cache ou paramètre. Les sauvegardes, exports, plateformes de santé et données déjà envoyées à un fournisseur sont distincts. La suppression de l’historique local ne demande pas la suppression auprès du fournisseur d’IA.

### B. Mises à jour des catalogues hors-ligne
* **Fonctionnement :** L'application vérifie périodiquement la disponibilité de mises à jour des catalogues d'aliments (Open Food Facts) et d'exercices (wger) via HTTPS vers les serveurs d'hébergement.
* **Catalogue BLS :** Le catalogue alimentaire BLS 4.0 du Max Rubner-Institut est téléchargé depuis GitHub et stocké localement.
* **Minimisation :** Seules les données techniques de connexion (IP, horodatage, agent utilisateur) sont transmises pour le téléchargement. Aucun historique personnel n'est envoyé.
* **Recherche hors-ligne :** La recherche d'aliments et le scan de code-barres s'effectuent entièrement hors-ligne sur votre appareil.

---

## 5. Interfaces de données de santé

Train Libre peut utiliser Apple HealthKit ou Google Health Connect si vous activez les fonctions correspondantes et accordez les autorisations de la plateforme. Vous pouvez modifier ces autorisations dans les réglages système. Les données importées sont stockées et analysées dans l’application et peuvent être incluses dans des sauvegardes ou dans une requête d’IA selon les règles d’autorisation de la section 4. Modifier une autorisation système ne supprime pas automatiquement les données déjà importées ou exportées. L’autorisation d’accès aux données par l’assistant est distincte de l’autorisation Health.

## 6. Sécurité des données, sauvegardes et télémétrie

La sécurité de votre appareil est importante pour protéger les données locales et les identifiants.

### A. Isolation applicative
Le système d'exploitation isole l'application dans un bac à sable (sandbox), empêchant les autres applications d'accéder à sa base SQLite ou aux clés API.

### B. Sauvegardes

Vous pouvez créer et partager des sauvegardes ou exports, et activer des sauvegardes automatiques vers un emplacement choisi. Selon l’option, ils peuvent contenir des enregistrements de la base de données, des réglages, l’historique IA et des médias. L’export chiffré par mot de passe est disponible ; protégez les mots de passe et les copies non chiffrées. L’emplacement choisi ou le système d’exploitation peut stocker une copie dans un service cloud. La synchronisation iCloud facultative peut téléverser un instantané de la base et des médias après activation. Vérifiez les réglages et pratiques du fournisseur de stockage. La réinitialisation de l’application ne supprime pas les sauvegardes, exports, données des plateformes de santé ou copies chez les fournisseurs. Des fichiers temporaires ou un nettoyage incomplet peuvent laisser d’autres copies ; leur suppression immédiate et complète n’est pas garantie.

### C. Statistiques d’utilisation facultatives

Les statistiques sont désactivées par défaut. Lorsqu’elles sont activées, l’application utilise le point d’entrée PostHog EU pour des événements pseudonymes. Ceux-ci peuvent inclure des identifiants techniques, le contexte de l’application et de l’appareil, l’utilisation des écrans et fonctions, des nombres exacts d’exercices et leur durée, le nombre d’entrées alimentaires, l’état des requêtes d’IA et des indicateurs issus de fonctions liées à la nutrition ou au poids. Même sans nom, ces événements peuvent être personnels ou liés à la santé. L’application configure des options liées à l’IP et à la géolocalisation, mais le traitement réseau et serveur dépend également de la configuration du service.

Vous pouvez désactiver les futurs envois dans les réglages. La commande d’effacement réinitialise les identifiants et compteurs locaux et tente une demande d’effacement ; elle ne confirme pas l’effacement côté serveur et peut ne pas couvrir les identifiants antérieurs ou les sauvegardes. Contactez feedback@schotte.me pour obtenir de l’aide. Les rapports de diagnostic peuvent aussi être partagés par les moyens que vous choisissez ; leur envoi direct à PostHog nécessite l’activation des statistiques. Vérifiez le contenu et le destinataire avant le partage. La conservation, les accords de sous-traitance, les lieux d’hébergement et les transferts internationaux doivent être confirmés à partir de la configuration et des accords actuels du service.

## 7. Vos droits (RGPD)

Selon le droit applicable, vous pouvez disposer de droits d’accès, de rectification, d’effacement, de portabilité, de limitation ou d’opposition, ainsi que du droit de retirer un consentement lorsque le traitement repose sur celui-ci. Le retrait n’annule pas les traitements déjà effectués. Vous pouvez également déposer une plainte auprès d’une autorité de contrôle compétente. Pour toute demande, contactez feedback@schotte.me.

Vous pouvez modifier ou supprimer de nombreux enregistrements dans l’application et exporter des données. La réinitialisation locale supprime de nombreux enregistrements, réglages et identifiants de fournisseur, mais ne garantit pas la suppression de chaque pièce jointe, cache ou paramètre. Elle ne supprime pas les copies dans les sauvegardes, exports, Apple Health, Health Connect ou services d’IA externes. Gérez ces copies séparément et contactez le fournisseur concerné si nécessaire. La commande d’effacement de télémétrie tente une demande mais ne confirme pas l’effacement à distance.
