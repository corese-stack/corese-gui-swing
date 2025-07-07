#!/bin/bash

# Script d'installation du formatage automatique
echo "🔧 Installation du formatage automatique..."

# Vérifier qu'on est dans un repo git
if [ ! -d ".git" ]; then
    echo "❌ Erreur: Ce script doit être exécuté à la racine du projet git"
    exit 1
fi

# Créer le hook pre-commit
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash

# Hook pre-commit pour formatter automatiquement le code Java
echo "🎨 Formatage automatique du code..."

# Exécuter Spotless pour formatter le code
./gradlew spotlessApply --quiet

# Ajouter les fichiers modifiés par le formatage au commit
git add -u

echo "✅ Code formaté automatiquement"
EOF

# Rendre le hook exécutable
chmod +x .git/hooks/pre-commit

echo "✅ Hook pre-commit installé !"
echo ""
echo "💡 Maintenant, le code sera automatiquement formaté à chaque commit."
echo "   Vous n'avez plus besoin de lancer './gradlew spotlessApply' manuellement."
