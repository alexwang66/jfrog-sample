Gradle Android build-info scan (CentOS 9 x86)

Prereqs

OS: CentOS 9 x86_64
Project: https://github.com/gyzong1/gradle-android-example.git
JDK: 17
Gradle: 7.6.3
Android cmdline-tools: 12.0
Artifactory: Maven virtual repo proxying Maven Central, Google Maven, and Gradle Plugin Portal; Xray indexing enabled on local/remote repos.
1) Install JDK 17

Install java-17-openjdk*
Set JAVA_HOME=/usr/lib/jvm/java-17-openjdk
Verify: java --version
2) Install Gradle 7.6.3

Download/unzip gradle-7.6.3-bin.zip to /usr/local/src/gradle/gradle-7.6.3
Add .../bin to PATH
Verify: gradle --version
3) Install Android SDK (cmdline tools)

SDK root: /usr/local/src/android-sdk
Install commandlinetools-linux-11076708_latest.zip under cmdline-tools/latest
Set ANDROID_HOME and update PATH
Accept licenses + install packages:
yes | sdkmanager --licenses
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"
4) Configure Artifactory repositories

Create:
maven-dev-local (deploy)
maven-remote → https://repo1.maven.org/maven2/
maven-android-remote → https://dl.google.com/dl/android/maven2/
maven-gradle-plugin-remote → https://plugins.gradle.org/m2/
maven-virtual containing all above
Enable Xray indexing for local + all remotes.
5) Configure the project to resolve via Artifactory

Clone repo
Update settings.gradle to use maven-virtual for pluginManagement and dependencies.
6) Install and configure JFrog CLI

Install jf and add an Artifactory server config (example my_server).
7) Configure Gradle via JFrog CLI

jf gradle-config --server-id-resolve=my_server --repo-resolve=maven-virtual --server-id-deploy=my_server --repo-deploy=maven-virtual
8) Build + publish artifacts with build-info

Run (must include assembleRelease):
jf gradle clean assembleRelease artifactoryPublish --build-name="gradle-android-build" --build-number="1"
Artifacts deployed (example):
gradle-android-app-1.0.0.aab
gradle-android-app-1.0.0.module
gradle-android-app-1.0.0.pom
9) Publish build-info

jf rt bp gradle-android-build 1
10) Xray policy + watch

Create a policy (with “Fail build” enabled) and a watch targeting the build.
11) Scan the build

jf bs gradle-android-build 1