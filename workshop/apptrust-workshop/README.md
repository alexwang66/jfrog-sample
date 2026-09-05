# AppTrust Codespaces Workshop

目标：让客户在 GitHub Codespaces 里完成一次端到端的 JFrog AppTrust 发布：

```text
Docker build -> push to Artifactory -> build-info -> AppTrust version
-> signed evidence -> DEV -> QA -> release
```

本 workshop 复用仓库里的 `apptrust-sample`，避免客户在本机安装 Docker、Java、Node 或 JFrog CLI。所有命令都在 Codespace 终端里执行。

## 1. 准备 GitHub Codespace

在 GitHub 仓库页面点击：

```text
Code -> Codespaces -> Create codespace on main
```

如果 GitHub 询问 dev container 配置，选择：

```text
.devcontainer/apptrust-workshop/devcontainer.json
```

`workshop/apptrust-workshop/.devcontainer/devcontainer.json` 保留为 workshop 目录内的参考配置；Codespaces 实际入口放在仓库根目录 `.devcontainer/apptrust-workshop/`。

## 2. 配置 JFrog 凭据

在 Codespace 终端里设置 JFrog Platform URL 和 Access Token：

```bash
export JF_URL=https://demo.jfrogchina.com
export JF_ACCESS_TOKEN=<your-access-token>
```

可选配置：

```bash
export JF_PROJECT=alex
export JF_SERVER_ID=demo
export APP_KEY=alex-codespace-apptrust
export APP_VERSION=1.0.$(date +%s)
```

默认值已经按 demo 环境设置：

| 变量 | 默认值 | 说明 |
| --- | --- | --- |
| `JF_SERVER_ID` | `demo` | Codespace 内的 JFrog CLI server id |
| `JF_PROJECT` | `alex` | JFrog Project |
| `APP_KEY` | `alex-codespace-apptrust` | AppTrust application key |
| `APP_NAME` | `Alex Codespace AppTrust` | AppTrust application display name |
| `APP_VERSION` | `1.0.<timestamp>` | 每次 workshop 自动生成新版本 |
| `DOCKER_REPO_DEV` | `alex-docker-dev-local` | DEV Docker repo |
| `STAGE_DEV` | `DEV` | demo lifecycle stage |
| `STAGE_QA` | `QA` | demo lifecycle stage |
| `STAGE_PROD` | `PROD` | release stage |

## 3. Bootstrap Codespace

安装/检查必要工具，并在 Codespace 内配置 JFrog CLI：

```bash
cd workshop/apptrust-workshop
./scripts/bootstrap-codespace.sh
```

脚本会做这些事：

- 检查 `git`、`jq`、`docker`
- 安装或检查 `jf` CLI
- 使用 `JF_URL` 和 `JF_ACCESS_TOKEN` 创建非交互式 JFrog CLI server
- 执行 `jf apptrust ping`

## 4. 运行端到端发布

```bash
./scripts/run-apptrust-release.sh
```

执行后会依次运行：

```text
00-init.sh
01-build.sh
02-create-version.sh
03-attach-evidence.sh
04-promote.sh
05-approve-and-release.sh
06-verify.sh
```

完成后在 JFrog UI 查看：

```text
Application -> alex-codespace-apptrust -> Versions -> <APP_VERSION>
```

## 5. 客户实操讲解点

AppTrust application version 是业务发布对象，不只是 Docker image 或 build-info。

Evidence 是签名的发布事实，包括：

- SLSA provenance
- unit test results
- Xray security scan
- QA approval

Promotion 会把同一个 application version 推进到 lifecycle stage，并触发 AppTrust policy gate。

Release 会把版本标记为已发布，用于审计、追踪和后续治理。

## 6. 常见问题

### `JF_URL and JF_ACCESS_TOKEN are required`

没有导出 JFrog 连接信息。重新执行：

```bash
export JF_URL=https://demo.jfrogchina.com
export JF_ACCESS_TOKEN=<your-access-token>
```

### `docker: command not found`

当前 Codespace 没有 Docker CLI。请使用包含 Docker 的 Codespace image，或根据 `.devcontainer/devcontainer.json` 创建 workshop 环境。

### `target stage 'TEST' does not exist`

本 workshop 不使用 `TEST` stage。demo lifecycle 使用 `DEV -> QA -> PROD/release`。

### Evidence 创建失败

确认 Access Token 有 Evidence/AppTrust 权限。`00-init.sh` 会生成 signing key，并把 public key 上传到 JFrog trusted keys。
