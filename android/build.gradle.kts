allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

gradle.projectsEvaluated {
    subprojects {
        val javaCompileTasks = tasks.withType<JavaCompile>()
        val javaTarget = javaCompileTasks.firstOrNull { it.name.contains("Java") }?.targetCompatibility
        
        if (javaTarget != null) {
            var cleanTarget = javaTarget
            if (cleanTarget.startsWith("VERSION_")) {
                cleanTarget = cleanTarget.substringAfter("VERSION_").replace("_", ".")
            }
            if (cleanTarget == "1.8") {
                cleanTarget = "1.8"
            }
            
            tasks.configureEach {
                if (name.startsWith("compile") && name.contains("Kotlin")) {
                    try {
                        val kotlinOptions = this.property("kotlinOptions")
                        val setJvmTarget = kotlinOptions?.javaClass?.getMethod("setJvmTarget", String::class.java)
                        setJvmTarget?.invoke(kotlinOptions, cleanTarget)
                        println("[Antigravity] ProjectsEvaluated: Set Kotlin JVM target to '${cleanTarget}' for task '${name}' in project '${project.name}'")
                    } catch (e: Exception) {
                        // Ignore if task has no kotlinOptions property
                    }
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

