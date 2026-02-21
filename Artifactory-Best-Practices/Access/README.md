# 🚀 Internal Developer Guide: Authenticated Artifact Downloads via JFrog CLI

As our organization transitions to a strictly authenticated access model for Artifactory to improve our security posture, anonymous (unauthenticated) downloads are no longer supported.

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

---

## Step 4: Generic File Downloads (`jf rt dl`)

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

---

## Troubleshooting

| Issue | Likely cause | Solution |
|-------|--------------|----------|
| HTTP 401/403 Error | Token expired or missing. | Run `jf config show`. Generate a new token and update it using `jf config edit`. |
| `non_authenticated_user` | CLI isn't using your config. | Ensure your default server config is active: `jf config use <server-id>`. |
| Files in nested folders | Forgot `--flat` flag. | Add `--flat` to your `jf rt dl` command. |
