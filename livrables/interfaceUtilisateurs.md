# Configuration de l'App Manager pour Fasha

> Ce document décrit la création et la configuration d'une **Lightning App
> personnalisée pour Fasha** dans l'org Salesforce, afin que les utilisateurs
> métier (vendeurs, gestionnaires) accèdent à un espace de travail dédié,
> avec leurs objets, leurs onglets et le composant LWC `orders` exposé sur
> la fiche compte.

## Sommaire

1. [Prérequis](#1-prérequis)
2. [Créer la Lightning App « Fasha »](#2-créer-la-lightning-app--fasha-)
3. [Ajouter les onglets nécessaires](#3-ajouter-les-onglets-nécessaires)
4. [Exposer le composant LWC `orders` sur la fiche Compte](#4-exposer-le-composant-lwc-orders-sur-la-fiche-compte)
5. [Configurer le Permission Set « Fasha User »](#5-configurer-le-permission-set--fasha-user-)
6. [Assigner le Permission Set aux utilisateurs](#6-assigner-le-permission-set-aux-utilisateurs)
7. [Vérifier la configuration](#7-vérifier-la-configuration)
8. [Captures d'écran à inclure dans le PDF](#8-captures-décran-à-inclure-dans-le-pdf)

---

## 1. Prérequis

- L'org Salesforce du client Fasha (Dev Edition pour la démo)
- Profil **System Administrator** sur l'org
- Le code du repo déployé sur l'org (via `sf project deploy start`
  ou via le pipeline CI/CD)
- En particulier :
  - Le composant LWC `orders` doit être déployé (`isExposed=true` dans
    son `meta.xml`)
  - Le champ `Chiffre_d_affaire__c` sur Account doit exister
  - Le champ `NetAmount__c` sur Order doit exister (en Formule)

## 2. Créer la Lightning App « Fasha »

### Étapes

1. **Setup** (icône engrenage en haut à droite) → **Setup**
2. Barre de recherche → tape **« App Manager »** → clique sur **App Manager**
3. Bouton **New Lightning App** (en haut à droite)
4. **App Details & Branding** :
   - App Name : `Fasha`
   - Developer Name : `Fasha` (généré automatiquement)
   - Description : `Application metier Fasha — gestion commerciale (comptes, commandes, produits)`
   - **Image** (optionnel) : uploader le logo Fasha
   - **Primary Color Hex Value** : `#0070D2` (bleu Salesforce, ou couleur Fasha)
   - Clique **Next**
5. **App Options** :
   - **Setup Experience** : `Standard navigation` (recommandé, plus moderne)
   - **Supported Form Factors** : cocher `Desktop` et `Phone`
   - Clique **Next**
6. **Utility Items (optional)** : laisser vide pour l'instant, **Next**
7. **Navigation Items** : voir étape suivante (§3)
8. **User Profiles** : sélectionner :
   - `System Administrator`
   - `Standard User` (et tout autre profil métier de Fasha)
   - Bouton **Save & Finish**

## 3. Ajouter les onglets nécessaires

Dans l'écran **Navigation Items** de l'assistant (ou plus tard via
App Manager → Edit) :

### Onglets à ajouter (dans cet ordre)

| Onglet | Type | Justification |
|---|---|---|
| **Home** | Standard | Page d'accueil de l'app |
| **Comptes** (Accounts) | Standard | Objet central : gestion des clients |
| **Commandes** (Orders) | Standard | Objet métier clé |
| **Produits** (Products) | Standard | Catalogue produits |
| **Reports** | Standard | Rapports (CA, ventes...) |
| **Dashboards** | Standard | Tableaux de bord |

Les **OrderItems** ne sont pas un onglet (ils sont accessibles via la
fiche Order, ne s'utilisent pas en standalone).

### Comment activer un onglet standard

Certains onglets (comme **Orders**) ne sont pas toujours actifs par défaut.

1. Setup → barre de recherche → **Tabs**
2. Section **Custom Object Tabs** ou **Standard Tabs**
3. Pour `Orders` : si non listé, vérifier que l'objet Order est activé :
   - Setup → **Order Settings** → cocher **Enable Orders** → Save

## 4. Exposer le composant LWC `orders` sur la fiche Compte

Le composant LWC affiche le **total des commandes Activated** du compte.
Il doit apparaître sur la **record page** des comptes.

### Étapes — Lightning App Builder

1. Aller sur la fiche d'un compte existant (Onglet **Accounts** → choisir
   un compte → ouvrir sa fiche)
2. Cliquer sur l'icône **engrenage** en haut à droite → **Edit Page**
3. L'App Builder s'ouvre
4. Dans le **panneau gauche** (Components), section **Custom** → tu dois
   voir **`orders`** (c'est le LWC déployé)
5. **Glisser-déposer** `orders` à l'endroit voulu sur la page :
   - **Recommandation** : dans la **colonne droite**, en haut, au-dessus
     des Activities, pour qu'il soit visible immédiatement à l'ouverture
     de la fiche compte
6. Le composant utilise automatiquement le `recordId` du compte courant
   (pas de configuration à faire)
7. Clique **Save** (en haut à droite)
8. Si c'est la **1ère fois** que tu modifies la page, Salesforce demande
   d'activer la page :
   - Choisir **Activate**
   - Onglet **App, Record Type, and Profile** :
     - **Assign as App Default** : sélectionner l'app **Fasha**
     - (ou Org Default si tu veux que ce soit la page par défaut partout)
   - **Save**
9. Retour à la fiche compte → **Back** → le LWC est désormais visible

### Comportement attendu

- Si le compte a au moins une commande Activated → bloc **vert** avec
  `Total des Commandes : 1 234,56 €`
- Si pas de commande Activated → bloc **rouge** avec le message d'erreur

## 5. Configurer le Permission Set « Fasha User »

Plutôt que de modifier des profils existants (risqué), on crée un
**Permission Set** dédié.

### Étapes

1. Setup → barre de recherche → **Permission Sets** → **New**
2. **Label** : `Fasha User`
3. **API Name** : `Fasha_User`
4. **License** : `Salesforce` (ou laisser vide selon licences disponibles)
5. **Save**

### Configurer les accès

Dans le Permission Set créé :

#### a) Apps Settings → Apps → Assigned Apps
- Cliquer **Edit** → cocher **Fasha** → **Save**

#### b) Object Settings → Account
- Cliquer sur `Account`
- **Object Permissions** : `Read`, `Create`, `Edit` (pas Delete pour
  les utilisateurs métier, à laisser aux admins)
- **Field Permissions** : `Chiffre_d_affaire__c` en **Read** uniquement
  (champ calculé, pas modifiable manuellement)
- Save

#### c) Object Settings → Order
- Cliquer sur `Order`
- **Object Permissions** : `Read`, `Create`, `Edit`
- **Field Permissions** :
  - `TotalAmount` : Read
  - `NetAmount__c` : Read (champ Formule, read-only par nature)
  - `ShipmentCost__c` : Read, Edit (peut être modifié)
  - `Status` : Read, Edit
- Save

#### d) Object Settings → Product2 et PricebookEntry
- Permissions : `Read` uniquement (les vendeurs consultent, ne créent pas)
- Save

#### e) Apex Class Access
- Cliquer **Edit**
- Cocher :
  - `MyTeamOrdersController` (utilisée par le LWC `orders`)
- ⚠️ **Ne PAS cocher** `UpdateAllAccounts`, `OrderTriggerHandler`,
  `AccountCAService`, `OrderSelector`, `TestDataFactory` : ce sont des
  classes internes ou de tests, jamais appelées directement par l'utilisateur
- Save

#### f) Visualforce Page Access
- N/A (pas de page VF dans ce projet)

## 6. Assigner le Permission Set aux utilisateurs

### Méthode 1 — depuis le Permission Set

1. Dans le Permission Set `Fasha User` → bouton **Manage Assignments**
2. **Add Assignments** → cocher les utilisateurs métier Fasha
3. **Assign**

### Méthode 2 — depuis l'utilisateur

1. Setup → **Users** → choisir un utilisateur
2. Section **Permission Set Assignments** → **Edit Assignments**
3. Déplacer `Fasha User` de gauche à droite
4. **Save**

## 7. Vérifier la configuration

### Test utilisateur

1. **Se déconnecter** du profil admin
2. Se reconnecter avec un utilisateur ayant le permission set `Fasha User`
3. **Vérifier** :
   - Le sélecteur d'app en haut à gauche affiche **Fasha**
   - Cliquer dessus → la nav bar contient :
     `Home | Accounts | Orders | Products | Reports | Dashboards`
   - Ouvrir un compte ayant des commandes Activated → le composant
     `orders` affiche le total formaté en euros
   - Ouvrir un compte sans commande Activated → le composant affiche
     le message d'erreur

### Test du batch (pour les admins uniquement)

1. Setup → **Developer Console** → Debug → **Open Execute Anonymous Window**
2. Coller :
   ```apex
   Id jobId = Database.executeBatch(new UpdateAllAccounts(), 200);
   System.debug('Job ID : ' + jobId);
   ```
3. **Execute**
4. Setup → **Apex Jobs** → le job apparaît, statut `Queued` puis `Completed`
5. Vérifier sur quelques comptes que `Chiffre_d_affaire__c` reflète bien
   la somme de leurs Orders Activated

## 8. Captures d'écran à inclure dans le PDF

À réaliser pendant la configuration et à intégrer dans le PDF du livrable :

1. **App Manager** : capture de la liste des apps avec **Fasha** créée
2. **Lightning App « Fasha »** ouverte avec la nav bar visible
3. **Edit Page** d'un compte avec le panneau LWC montrant **`orders`**
   dans la section Custom
4. **Fiche compte** avec le composant `orders` affiché en **cas succès**
   (montant > 0, vert avec format EUR)
5. **Fiche compte** avec le composant `orders` affiché en **cas erreur**
   (montant 0 ou aucune commande, rouge)
6. **Permission Set `Fasha User`** :
   - Page principale
   - Section Object Settings → Account avec les permissions cochées
   - Section Apex Class Access avec `MyTeamOrdersController` coché
7. **Permission Set Assignments** : la liste des utilisateurs assignés
8. **Apex Jobs** : le batch `UpdateAllAccounts` avec status `Completed`

## Annexe — Pourquoi cette architecture utilisateur

- **App dédiée** plutôt que d'utiliser l'app Sales par défaut → expérience
  utilisateur ciblée Fasha, pas d'options inutiles
- **Permission Set** plutôt que modification des profils → réversible,
  non destructif sur les profils existants
- **LWC sur record page** plutôt qu'app standalone → l'utilisateur voit
  le CA dans son contexte de travail naturel (la fiche compte)
- **Champ Formule `NetAmount__c`** → pas de permission « Edit » à donner :
  Salesforce le rend automatiquement read-only et toujours à jour
- **Champ `Chiffre_d_affaire__c`** en **Read only** côté utilisateur →
  protège l'intégrité (seuls le trigger et le batch peuvent l'écrire)
