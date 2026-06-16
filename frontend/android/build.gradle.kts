allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Keep ALL build output on D: drive
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("D:/AndroidFiles/Projects/LocalSync3/build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
