#  High-Level Artifactory Permission Matrix

| Role | Dev Repository | Test Repository | Release Repository | Notes |
|------|---------------|----------------|-------------------|-------|
| **Developer** | Read + Deploy | Read | Read | Developers can deploy only to Dev |
| **CI Server** | Read + Deploy + Delete | Read + Deploy + Annotate| Read + Deploy + Annotate | All promotions handled by pipeline. Add annotation after build promotion, e.g. Add "UI-Test-Passed"="True" as the package property's key and value |
| **Release Engineer** | Read | Read | Read + Deploy + Annotate | No delete in Release |
| **Security Team** | Read | Read | Read | Audit and compliance visibility |
| **Platform Administrator** | Full Control | Full Control | Full Control |   |


# 🚀 Internal Developer Guide: Authenticated Artifact Downloads via JFrog CLI
The most efficient and secure way to interact with Artifactory from your local terminal is using the **JFrog CLI**. The CLI wraps standard package managers (Maven, npm, pip, etc.), automatically injecting your credentials so you don't have to hardcode passwords in your local configuration files.

---

## Step 1: Install the JFrog CLI

Depending on your operating system, install the latest version of the CLI:

- **macOS (Homebrew):**

  ```bash
  brew install jfrog-cli
  ```

- **Windows (Chocolatey / PowerShell):**

  ```powershell
  choco install jfrog
  ```

  Or install via PowerShell module:

  ```powershell
  Install-Module -Name JFrogCLI
  ```

- **Linux (cURL):**

  ```bash
  curl -fL https://install-cli.jfrog.io | sh
  ```

Verify the installation:

```bash
jf -v
```

---

## Step 2: Authenticate with Your Access Token

Because anonymous access is disabled, you must provide the CLI with your Artifactory Access Token.

1. Generate your Access Token from your JFrog Artifactory user profile (**Edit Profile** → **Generate Identity Token**).
2. Configure the CLI using the interactive setup:

   ```bash
   jf config add
   ```

   Provide the following details when prompted:

   - **Server ID:** A memorable name for your connection (e.g. `company-artifactory`).
   - **JFrog Platform URL:** Our company's Artifactory URL (e.g. `https://<our-company>.jfrog.io`).
   - **Access Token:** Paste your generated token.

3. Verify your connection:

   ```bash
   jf rt ping
   ```

   If it returns `OK`, you are authenticated.

---

## Step 3: Package Manager Integrations

Instead of modifying your local `settings.xml`, `.npmrc`, or `pip.conf` with hardcoded credentials, use the `jf` wrapper commands.

> **Note:** During the initial configuration for each tool, you will be prompted to select a **Resolution Repository**. Always select the appropriate Virtual Repository for your technology.

### ☕ Maven (`jf mvn`)

**Configure (once per project):**

Run this in your project root to generate the config file:

```bash
jf mvnc
```

**Build and download:**

Replace the standard `mvn` command with `jf mvn`. The CLI handles authentication automatically:

```bash
jf mvn clean install
```

**Deploy to Artifactory:**

```bash
jf mvn deploy
```

Optionally with build info for Xray scanning:

```bash
jf mvn deploy --build-name=<build-name> --build-number=<build-number>
jf rt bp <build-name> <build-number>
```

**Sample (e.g. from repo root `maven-sample`):**

```bash
cd maven-sample
jf mvnc
jf mvn clean install
jf mvn deploy --build-name=my-app --build-number=1
jf rt bp my-app 1
```

### 🐍 Python / Pip (`jf pip`)

**Configure (once per environment):**

```bash
jf pipc
```

**Install packages:**

```bash
jf pip install requests
jf pip install -r requirements.txt
```
### 🐳 Docker (`jf docker`)

**Authenticate Docker daemon:**

Use your Server ID to log in to the Artifactory Docker registry securely:

```bash
jf docker login <your-server-id>
```

**Pull images:**

```bash
jf docker pull <your-company>.jfrog.io/<docker-repo>/<image>:<tag>
```

**Push images:**

```bash
jf docker push <your-company>.jfrog.io/<docker-repo>/<image>:<tag>
```

**Sample:**

```bash
jf docker login <your-server-id>
docker build -t mycompany.jfrog.io/docker-repo/my-image:1.0.0 .
jf docker push mycompany.jfrog.io/docker-repo/my-image:1.0.0
```

### 📦 NPM (`jf npm`)

**Configure (once per project):**

Run this in your project directory containing `package.json`:

```bash
jf npmc
```

**Install dependencies:**

Replace standard `npm` commands with `jf npm`:

```bash
jf npm install
```

**Publish package:**

```bash
jf npm publish
```

**Sample (e.g. from repo root `npm-sample`):**

```bash
cd npm-sample
jf npmc
jf npm install
jf npm publish
```

### 🐹 Go (`jf go`)

**Configure (once per project):**

```bash
jf goc
```

**Resolve and build:**

```bash
jf go get <package-name>
jf go build
```

**Publish module:**

```bash
jf go publish
```

**Sample (e.g. from repo root `go-sample`):**

```bash
cd go-sample
jf goc
jf go build
jf go publish
```

---

## Step 4: Generic File Transfers (`jf rt dl` / `jf rt ul`)

### Download (`jf rt dl`)

If you need to download raw binaries or generic files outside of a package manager, use the `jf rt dl` command.

**Basic download:**

```bash
jf rt dl "my-local-repo/path/to/my-artifact.zip"
```

**Download to current directory (flattening):**

To avoid recreating the Artifactory folder structure locally, use the `--flat` flag:

```bash
jf rt dl "my-local-repo/path/to/my-artifact.zip" --flat
```

### Upload (`jf rt ul`)

To upload generic files or binaries to a local repository:

```bash
jf rt ul "./local-artifact.zip" "my-local-repo/path/to/"
```

Upload with flat layout (no source path in target):

```bash
jf rt ul "./local-artifact.zip" "my-local-repo/path/to/" --flat
```

**Sample:**

```bash
echo "demo" > demo.txt
jf rt ul "demo.txt" "my-local-repo/samples/" --flat
jf rt dl "my-local-repo/samples/demo.txt" . --flat
```

---

## Troubleshooting

| Issue | Likely cause | Solution |
|-------|--------------|----------|
| HTTP 401/403 Error | Token expired or missing. | Run `jf config show`. Generate a new token and update it using `jf config edit`. |
| `non_authenticated_user` | CLI isn't using your config. | Ensure your default server config is active: `jf config use <server-id>`. |
| Files in nested folders | Forgot `--flat` flag. | Add `--flat` to your `jf rt dl` command. |
