content = open('android/app/build.gradle').read()

content = content.replace(
    'signingConfig = signingConfigs.debug',
    'signingConfig = signingConfigs.release'
)

insert_block = '''    signingConfigs {
        release {
            storeFile file(System.getProperty("user.home") + "/.android/debug.keystore")
            storePassword "android"
            keyAlias "androiddebugkey"
            keyPassword "android"
        }
    }

    '''

content = content.replace('    buildTypes {', insert_block + 'buildTypes {', 1)

open('android/app/build.gradle', 'w').write(content)
print("Signing config patched")
