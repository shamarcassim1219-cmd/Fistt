from pathlib import Path

path = Path("android/app/build.gradle.kts")
content = path.read_text()

content = content.replace(
    "signingConfig = signingConfigs.getByName(\"debug\")",
    "signingConfig = signingConfigs.getByName(\"release\")"
)

if "signingConfigs.create(\"release\")" not in content:
    block = '''    signingConfigs {
        create("release") {
            storeFile = file(System.getProperty("user.home") + "/.android/debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
    }

'''
    content = content.replace("    buildTypes {", block + "    buildTypes {", 1)

path.write_text(content)
print("Signing config patched for Kotlin DSL")
