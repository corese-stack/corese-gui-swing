plugins {
    // Core Gradle plugins
    `java-library`                                              // For creating reusable Java libraries
    application                                                 // Adds support for building and running Java applications

    // Publishing plugins
    signing                                                     // Signs artifacts for Maven Central
    `maven-publish`                                             // Enables publishing to Maven repositories
    id("io.github.gradle-nexus.publish-plugin") version "2.0.0" // Automates Nexus publishing

    // Tooling plugins
    `jacoco`                                                    // For code coverage reports
    id("com.gradleup.shadow") version "8.3.6"                   // Bundles dependencies into a single JAR
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
  
    // Sonatype OSSRH publishing settings
    const val release = "https://oss.sonatype.org/service/local/staging/deploy/maven2/"
    const val snapshot = "https://oss.sonatype.org/content/repositories/snapshots/"
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

// Define dependencies
dependencies {

    // === Corese GUI dependencies ===
    implementation("fr.inria.corese:corese-core:4.6.4-SNAPSHOT")     // Core module of Corese
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

// Publication configuration for Maven repositories
publishing {
    publications {
        create<MavenPublication>("mavenJava") {

            // Configure the publication to include JAR, sources, and Javadoc
            from(components["java"])

            // Configures version mapping to control how dependency versions are resolved 
            // for different usage contexts (API and runtime).
            versionMapping {
                // Defines version mapping for Java API usage.
                // Sets the version to be resolved from the runtimeClasspath configuration.
                usage("java-api") {
                    fromResolutionOf("runtimeClasspath")
                }

                // Defines version mapping for Java runtime usage.
                // Uses the result of dependency resolution to determine the version.
                usage("java-runtime") {
                    fromResolutionResult()
                }
            }

            // Configure the publication metadata
            groupId = Meta.groupId
            artifactId = Meta.artifactId
            version = Meta.version

            pom {
                name.set(Meta.artifactId)
                description.set(Meta.desc)
                url.set("https://github.com/${Meta.githubRepo}")
                licenses {
                    license {
                        name.set(Meta.license)
                        url.set(Meta.licenseUrl)
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
                    url.set("https://github.com/${Meta.githubRepo}.git")
                    connection.set("scm:git:git://github.com/${Meta.githubRepo}.git")
                    developerConnection.set("scm:git:git://github.com/${Meta.githubRepo}.git")
                }
                issueManagement {
                    url.set("https://github.com/${Meta.githubRepo}/issues")
                }
            }
        }
    }
}

// Configure artifact signing
signing {
    // Retrieve the GPG signing key and passphrase from environment variables for secure access.
    val signingKey = providers.environmentVariable("GPG_SIGNING_KEY")
    val signingPassphrase = providers.environmentVariable("GPG_SIGNING_PASSPHRASE")

    // Sign the publications if the GPG signing key and passphrase are available.
    if (signingKey.isPresent && signingPassphrase.isPresent) {
        useInMemoryPgpKeys(signingKey.get(), signingPassphrase.get())
        sign(publishing.publications)
    }
}

// Configure Nexus publishing and credentials
nexusPublishing {
    repositories {
        // Configure Sonatype OSSRH repository for publishing.
        sonatype {
            // Retrieve Sonatype OSSRH credentials from environment variables.
            val ossrhUsername = providers.environmentVariable("OSSRH_USERNAME")
            val ossrhPassword = providers.environmentVariable("OSSRH_PASSWORD")
            
            // Set the credentials for Sonatype OSSRH if they are available.
            if (ossrhUsername.isPresent && ossrhPassword.isPresent) {
                username.set(ossrhUsername.get())
                password.set(ossrhPassword.get())
            }

            // Define the package group for this publication, typically following the group ID.
            packageGroup.set(Meta.groupId)
        }
    }
}

/////////////////////////
// Task configuration  //
/////////////////////////

// Set UTF-8 encoding for Java compilation tasks
tasks.withType<JavaCompile>() {
    options.encoding = "UTF-8"
    options.compilerArgs.addAll(listOf(
        "-Xlint:deprecation",
        "-Xlint:unchecked",
        "-parameters"
    ))
}

// Configure Javadoc tasks with UTF-8 encoding and disable failure on error.
// This ensures that Javadoc generation won't fail due to minor issues.
tasks.withType<Javadoc>() {
    options.encoding = "UTF-8"
    isFailOnError = false
}

// Configure the shadow JAR task to include dependencies in the output JAR.
// This creates a single JAR file with all dependencies bundled.
// The JAR file is named with the classifier "standalone" to indicate it contains all dependencies.
tasks {
    shadowJar {
        this.archiveClassifier = "standalone"
    }
}

// Configure Javadoc tasks to disable doclint warnings.
tasks {
    javadoc {
        options {
            (this as CoreJavadocOptions).addBooleanOption("Xdoclint:none", true)
        }
    }
}

// Configure the build task to depend on the shadow JAR task.
// This ensures that the shadow JAR is built when the project is built.
tasks.build {
    dependsOn(tasks.shadowJar)
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
