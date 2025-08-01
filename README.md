<!-- markdownlint-disable MD033 -->
<!-- markdownlint-disable MD041 -->

<p align="center">
    <a href="https://project.inria.fr/corese/">
        <img src="docs/source/_static/logo/corese-gui-swing.svg" width="200" alt="Corese-GUI-logo">
    </a>
    <br>
    <strong>Graphical User Interface for the Semantic Web of Linked Data</strong>
</p>

[![License: CECILL-C](https://img.shields.io/badge/License-CECILL--C-blue.svg)](https://cecill.info/licences/Licence_CeCILL-C_V1-en.html) [![Discussions](https://img.shields.io/badge/Discussions-GitHub-blue)](https://github.com/orgs/corese-stack/discussions)

## Features

- Load and save RDF data in various formats (Turtle, RDF/XML, JSON-LD, etc.)
- Execute SPARQL queries
- Visualize RDF graphs
- Validate RDF data with SHACL
- Apply reasoning and inference
- Extend functionality with STTL SPARQL, SPARQL Rule, and LDScript
- Intuitive user interface for manipulating RDF data

## Getting Started

Install Corese-GUI using your preferred platform:

### Linux

<a href='https://flathub.org/apps/fr.inria.corese.CoreseGui'>
    <img width='140' alt='Get it on Flathub' src='docs/source/_static/logo/badge_flathub.svg'/>
</a>

```bash
curl -fsSL https://raw.githubusercontent.com/corese-stack/corese-gui-swing/main/packaging/scripts/install-linux.sh -o /tmp/corese.sh && bash /tmp/corese.sh
```

### macOS

```bash
curl -fsSL https://raw.githubusercontent.com/corese-stack/corese-gui-swing/main/packaging/scripts/install-macos.sh -o /tmp/corese.sh && bash /tmp/corese.sh
```

### Windows (PowerShell)

```powershell
iwr -useb https://raw.githubusercontent.com/corese-stack/corese-gui-swing/main/packaging/scripts/install-windows.ps1 | iex
```

### Manual Installation (cross-platform)

You can also use Corese-GUI as a standalone `.jar` file or add it to a Java project via Maven.

> Requires Java 21 or higher.

<a href='https://github.com/corese-stack/corese-gui-swing/releases'>
    <img width='140' alt='Get it on GitHub' src='docs/source/_static/logo/badge_github.svg'/>
</a>
<a href='https://central.sonatype.com/artifact/fr.inria.corese/corese-gui'>
    <img width='140' alt='Get it on Maven Central' src='docs/source/_static/logo/badge_maven.svg'/>
</a>

Run manually with:

```bash
java -jar corese-gui-standalone.jar
```

## Contributing

We welcome contributions! Here’s how to get involved:

- [GitHub Discussions](https://github.com/orgs/corese-stack/discussions)
- [Issue Tracker](https://github.com/corese-stack/corese-gui-swing/issues)
- [Pull Requests](https://github.com/corese-stack/corese-gui-swing/pulls)

## Useful Links

- [Corese Website](https://corese-stack.github.io/corese-gui-swing/)
- Mailing List: <corese-users@inria.fr>
- Subscribe: Send an email to <corese-users-request@inria.fr> with the subject: `subscribe`
