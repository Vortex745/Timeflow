// 📄 android/build.gradle.kts

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ✅ 修复点：这里改成单层上一级 "../build"，而不是双层 "../../build"
// Set the build directory to the project root's build directory
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()

rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects { project.evaluationDependsOn(":app") }

tasks.register<Delete>("clean") { delete(rootProject.layout.buildDirectory) }
