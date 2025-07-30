plugins {
    // Core Gradle plugins
    `java-library`                                              // For creating reusable Java libraries
    application                                                 // Adds support for building and running Java applications

    // Publishing plugins
    signing                                                     // Signs artifacts for Maven Central
    `maven-publish`                                             // Enables publishing to Maven repositories
    id("com.vanniktech.maven.publish") version "0.34.0"         // Automates Maven publishing tasks

    // Tooling plugins
    `jacoco`                                                    // For code coverage reports
    id("com.gradleup.shadow") version "8.3.7"                   // Bundles dependencies into a single JAR
    id("com.diffplug.spotless") version "6.25.0"                // Code formatting and style checking
}

/////////////////////////
// Project metadata    //
/////////////////////////

object Meta {
    // Project coordinates
    const val groupId = "fr.inria.corese"
    const val artifactId = "corese-gui"
    const val version = "4.6.0"

    // Project description
    const val desc = "A graphical desktop application for exploring, querying, and visualizing RDF data using SPARQL and SHACL with the Corese engine."
    const val githubRepo = "corese-stack/corese-gui-swing"

    // License information
    const val license = "CeCILL-C License"
    const val licenseUrl = "https://opensource.org/licenses/CeCILL-C"
}

////////////////////////
// Project settings  //
///////////////////////

// Java compilation settings
java {
    withJavadocJar()                             // Include Javadoc JAR in publications
    withSourcesJar()                             // Include sources JAR in publications
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(21))
    }
}

application {
    mainClass.set("fr.inria.corese.gui.core.MainFrame") // Define the main class for the application
}

/////////////////////////
// Dependency settings //
/////////////////////////

// Define repositories to resolve dependencies from
repositories {
    mavenLocal()    // First, check the local Maven repository
    mavenCentral()  // Then, check Maven Central
}

dependencies {

    // === Corese GUI dependencies ===
    implementation("fr.inria.corese:corese-core:4.6.4")              // Core module of Corese
    implementation("org.graphstream:gs-ui:1.2")                      // GraphStream UI library
    implementation("org.json:json:20250517")                         // JSON processing library for handling JSON data

    // === Logging ===
    implementation("org.slf4j:slf4j-api:2.0.9")                      // Logging API only (SLF4J)
    implementation("org.apache.logging.log4j:log4j-core:2.20.0")     // Log4j2 core for internal logging
    runtimeOnly("org.apache.logging.log4j:log4j-slf4j2-impl:2.20.0") // SLF4J binding for Log4j2 (runtime)
}

/////////////////////////
// Publishing settings //
/////////////////////////

mavenPublishing {
    coordinates(Meta.groupId, Meta.artifactId, Meta.version)

    pom {
        name.set(Meta.artifactId)
        description.set(Meta.desc)
        url.set("https://github.com/${Meta.githubRepo}")
        licenses {
            license {
                name.set(Meta.license)
                url.set(Meta.licenseUrl)
                distribution.set("repo")
            }
        }
        developers {
            developer {
                id.set("OlivierCorby")
                name.set("Olivier Corby")
                email.set("olivier.corby@inria.fr")
                url.set("http://www-sop.inria.fr/members/Olivier.Corby")
                organization.set("Inria")
                organizationUrl.set("http://www.inria.fr/")
            }
            developer {
                id.set("remiceres")
                name.set("Rémi Cérès")
                email.set("remi.ceres@inria.fr")
                url.set("http://www-sop.inria.fr/members/Remi.Ceres")
                organization.set("Inria")
                organizationUrl.set("http://www.inria.fr/")
            }
        }
        scm {
            url.set("https://github.com/${Meta.githubRepo}/")
            connection.set("scm:git:git://github.com/${Meta.githubRepo}.git")
            developerConnection.set("scm:git:ssh://git@github.com/${Meta.githubRepo}.git")
        }
        issueManagement {
            url.set("https://github.com/${Meta.githubRepo}/issues")
        }
    }

    publishToMavenCentral()

    // Only sign publications when GPG keys are available (CI environment)
    if (project.hasProperty("signingInMemoryKey") || project.hasProperty("signing.keyId")) {
        signAllPublications()
    }
}

/////////////////////////
// Task configuration  //
/////////////////////////

// Set UTF-8 encoding for Java compilation tasks
tasks.withType<JavaCompile> {
    options.encoding = "UTF-8"
    options.compilerArgs.add("-Xlint:none")
}

// Configure Javadoc tasks with UTF-8 encoding and disable failure on error.
// This ensures that Javadoc generation won't fail due to minor issues.
tasks.withType<Javadoc>().configureEach {
    options.encoding = "UTF-8"
    isFailOnError = false
    // Configure Javadoc tasks to disable doclint warnings.
    (options as CoreJavadocOptions).addBooleanOption("Xdoclint:none", true)
}


// Configure the shadow JAR task to include dependencies in the output JAR.
// This creates a single JAR file with all dependencies bundled.
// The JAR file is named with the classifier "standalone" to indicate it contains all dependencies.
tasks {
    shadowJar {
        this.archiveClassifier = "standalone"
    }
}

// Configure the build task to depend on the shadow JAR task.
// This ensures that the shadow JAR is built when the project is built.
tasks.build {
    dependsOn(tasks.shadowJar)
}

// Apply formatting automatically before building and testing
tasks.build {
    dependsOn(tasks.spotlessApply)
}

tasks.test {
    dependsOn(tasks.spotlessApply)
}

tasks.shadowJar {
    archiveClassifier.set("standalone")
}

// Ensure that all local Maven publication tasks depend on signing tasks.
// This guarantees that artifacts are signed before they are published locally.
tasks.withType<PublishToMavenLocal>().configureEach {
    dependsOn(tasks.withType<Sign>())
}

// Ensure that all remote Maven publication tasks depend on signing tasks.
// This guarantees that artifacts are signed before they are published to Maven repositories.
tasks.withType<PublishToMavenRepository>().configureEach {
    dependsOn(tasks.withType<Sign>())
}

/////////////////////////
// Code formatting     //
/////////////////////////

// Configure Spotless for consistent code formatting across the project
spotless {
    // Java source files formatting
    java {
        target("src/**/*.java")

        // Use Google Java Format as the base formatter
        googleJavaFormat("1.22.0").aosp()

        // Remove unused imports
        removeUnusedImports()

        // Organize imports
        importOrder("java", "javax", "org", "com", "fr.inria.corese", "")

        // Ensure consistent line endings and formatting
        endWithNewline()
        trimTrailingWhitespace()
    }
}

// Make sure spotless apply runs as part of the compilation and check tasks
tasks.compileJava {
    dependsOn(tasks.spotlessApply)
}

tasks.check {
    dependsOn(tasks.spotlessApply)
}
