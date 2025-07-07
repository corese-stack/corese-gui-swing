#!/bin/bash

# Automatic formatting installation script
echo "🔧 Installing automatic formatting..."

# Check that we are in a git repository
if [ ! -d ".git" ]; then
    echo "❌ Error: This script must be executed from the git project root"
    exit 1
fi

# Create the pre-commit hook
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash

# Pre-commit hook to automatically format Java code
echo "🎨 Automatic code formatting..."

# Execute Spotless to format the code
./gradlew spotlessApply --quiet

# Add files modified by formatting to the commit
git add -u

echo "✅ Code formatted automatically"
EOF

# Make the hook executable
chmod +x .git/hooks/pre-commit

echo "✅ Pre-commit hook installed!"
echo ""
echo "💡 Now, the code will be automatically formatted on each commit."
echo "   You no longer need to run './gradlew spotlessApply' manually."
