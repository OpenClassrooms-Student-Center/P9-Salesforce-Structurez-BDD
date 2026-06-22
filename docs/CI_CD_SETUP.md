# Configuration CI/CD GitHub Actions

## 1. Vue d'ensemble

Le pipeline GitHub Actions (`.github/workflows/main_deploy.yml`) couvre
deux scénarios :

| Évènement | Comportement |
|---|---|
| **PR vers `main`** | Validation (`sf project deploy validate`) du delta avec `RunLocalTests` — aucune modification réelle sur l'org |
| **Push sur `main`** | Déploiement réel (`sf project deploy start`) du delta avec `RunLocalTests` |

Le delta est calculé entre `origin/main` et `HEAD` via `sfdx-git-delta`,
ce qui évite de re-déployer toute la base à chaque push.

## 2. Prérequis Salesforce — Connected App + JWT

### 2.1 — Générer une paire de clés RSA

Sur ta machine locale :
```bash
openssl genrsa -des3 -passout pass:tonMotDePasse -out server.pass.key 2048
openssl rsa -passin pass:tonMotDePasse -in server.pass.key -out server.key
openssl req -new -key server.key -out server.csr
openssl x509 -req -sha256 -days 36500 -in server.csr -signkey server.key -out server.crt
```

Tu obtiens :
- `server.key` → la **clé privée** (à mettre en secret GitHub)
- `server.crt` → le **certificat public** (à uploader dans la Connected App)

### 2.2 — Créer la Connected App dans Salesforce

1. Setup → App Manager → New Connected App
2. Renseigner :
   - Connected App Name : `GitHub Actions Deploy`
   - API Name : `GitHub_Actions_Deploy`
   - Contact Email : ton email
3. Cocher **Enable OAuth Settings**
4. Callback URL : `http://localhost:1717/OauthRedirect`
5. Cocher **Use digital signatures** → uploader `server.crt`
6. OAuth Scopes :
   - `Manage user data via APIs (api)`
   - `Perform requests at any time (refresh_token, offline_access)`
   - `Provide access to your data via the Web (web)`
7. Save → après ~10 minutes, copier la **Consumer Key**
8. Manage → Edit Policies → Permitted Users : **Admin approved users
   are pre-authorized**
9. Manage Profiles → ajouter `System Administrator` (ou le profil du
   user de déploiement)

### 2.3 — Tester l'auth en local

```bash
sf org login jwt \
  --client-id <CONSUMER_KEY> \
  --jwt-key-file server.key \
  --username <ton.user@example.com> \
  --instance-url https://login.salesforce.com \
  --alias devOrg
```

Si OK → tu peux configurer les secrets GitHub.

## 3. Configurer les secrets GitHub

Repo GitHub → Settings → Secrets and variables → Actions → **New repository secret**

| Nom du secret | Valeur |
|---|---|
| `SF_CONSUMER_KEY` | Consumer Key de la Connected App |
| `SF_USERNAME` | email du user Salesforce (ex. `dev@fasha.com`) |
| `SF_JWT_KEY` | **Contenu intégral** de `server.key` (copier-coller le PEM, avec les lignes `-----BEGIN/END...`) |
| `SF_INSTANCE_URL` | `https://login.salesforce.com` (Dev Edition / Prod) |

## 4. Workflow de branches

```
feature/* ──► DEV ──► main
   │           │        │
   commits   merge    deploy CI/CD
   granulaires --no-ff
```

- **Chaque feature** se crée depuis `DEV` (ex. `git checkout -b fix/xxx DEV`)
- **Merge dans `DEV`** avec `--no-ff` pour conserver la trace de la branche
- **Merge `DEV` → `main`** = déclencheur du déploiement CI/CD

## 5. Vérifier le pipeline

Après le 1er push sur `main` :
1. Onglet **Actions** du repo GitHub
2. Cliquer sur le run en cours
3. Suivre les étapes en live :
   - `Checkout`
   - `Setup Node.js`
   - `Install Salesforce CLI and sfdx-git-delta`
   - `Authenticate to Salesforce (JWT)`
   - `Generate metadata delta package`
   - `Deploy to Salesforce`

## 6. Dépannage fréquent

| Erreur | Cause probable | Solution |
|---|---|---|
| `JWT auth failed` | Clé privée mal copiée dans le secret | Recopier `server.key` en intégralité (lignes BEGIN/END incluses) |
| `User hasn't approved this consumer` | Profil du user pas dans la Connected App | Manage Profiles → ajouter le profil |
| `INVALID_FIELD: NetAmount__c` au déploiement | Le champ existe encore en Currency dans l'org | Supprimer manuellement le champ dans Setup → Order → Fields, puis re-deployer |
| `No changes to deploy` | Le delta est vide (rien de modifié vs origin/main) | Normal, le job passe sans erreur |
| `LICENSE: Insufficient access` | User pas en System Administrator | Promouvoir le user ou utiliser un autre user |
