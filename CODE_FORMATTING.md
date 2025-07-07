# Formatage du Code

Ce projet utilise **Spotless** pour maintenir un formatage uniforme du code Java.

## � Installation (une seule fois)

```bash
# Installer le formatage automatique à chaque commit
./install-formatting.sh
```

## �🚀 Commandes manuelles (optionnelles)

```bash
# Formater automatiquement tout le code
./gradlew spotlessApply

# Vérifier que le code est bien formaté
./gradlew spotlessCheck
```

## 📏 Règles de formatage

- **Indentation** : 4 espaces (défini dans `.editorconfig`)
- **Longueur de ligne** : 120 caractères max
- **Formatage** : Google Java Format (style AOSP)
- **Imports** : Organisés automatiquement (pas de wildcards *)

## 💡 Workflow automatique

1. **Installez une fois** : `./install-formatting.sh`
2. **Codez normalement** dans votre IDE
3. **Commitez** : Le code est automatiquement formaté !

Le formatage se fait automatiquement :
- ✅ À chaque commit (grâce au hook Git)
- ✅ Dans VS Code lors de la sauvegarde (grâce à `.vscode/settings.json`)

## 🛠️ Pour les nouveaux développeurs

Chaque nouveau développeur doit juste lancer :
```bash
./install-formatting.sh
```

Et c'est tout ! Le formatage devient transparent.
