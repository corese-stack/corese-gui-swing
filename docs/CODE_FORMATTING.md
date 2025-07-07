# Code Formatting

This project uses **Spotless** to maintain consistent Java code formatting.

## Installation (one time only)

```bash
# Set up automatic formatting on every commit
./install-formatting.sh
```

## Manual commands (optional)

```bash
# Automatically format all code
./gradlew spotlessApply

# Check that the code is properly formatted
./gradlew spotlessCheck
```

## Formatting rules

- **Indentation**: 4 spaces (set in `.editorconfig`)
- **Line length**: 120 characters max
- **Formatting**: Google Java Format (AOSP style)
- **Imports**: Automatically organized (no wildcards *)

## Automatic workflow

1. **Install once**: `./install-formatting.sh`
2. **Code as usual** in your IDE
3. **Commit**: The code is automatically formatted!

Formatting happens automatically:

- On every commit (thanks to the Git hook)
- In VS Code on save (thanks to `.vscode/settings.json`)

## For new developers

Each new developer just needs to run:

```bash
./install-formatting.sh
```

And that's it! Formatting becomes seamless.
