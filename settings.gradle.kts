rootProject.name = "AetherEngine"

pluginManagement {
    repositories {
        gradlePluginPortal()
        maven("https://repo.papermc.io/repository/maven-public/")
        maven("https://s01.oss.sonatype.org/content/repositories/snapshots/") 
        {
            mavenContent { snapshotsOnly() 
        }
    }
  }
}
