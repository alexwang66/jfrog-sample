# AppTrust Sample — 完整生命周期演示

演示 JFrog AppTrust 从**构建 → 应用版本 → 证据(Evidence)采集 → 多阶段 Promotion → 正式 Release** 的端到端流程。

示例应用是一个最小的 Node.js Express 服务(`hello-service`),打成 Docker 镜像后推送到 Artifactory,以此为源在 AppTrust 中创建应用版本,并附加四类签名证据,再逐级晋升到 PROD 阶段。

> 参考文档
> - AppTrust 官方文档:https://jfrog.com/help/r/jfrog-platform-administration-documentation/apptrust
> - Evidence 服务:https://jfrog.com/help/r/jfrog-artifactory-documentation/evidence
> - `jf apptrust` CLI 参考:`jf apptrust --help`
> - `jf evd` CLI 参考:`jf evd --help`

---

## 目录结构

```
apptrust-sample/
├── app/                       # Node.js 示例服务(可独立运行的真实代码)
│   ├── server.js              # /(欢迎)、/healthz(健康检查)
│   ├── test/health.test.js    # 单元测试(node:test 原生框架)
│   └── package.json
├── Dockerfile                 # 多阶段构建,基于 node:20-alpine
├── evidence/                  # 4 类 Evidence Predicate 模板
│   ├── slsa-provenance.json   # SLSA v1 构建溯源
│   ├── unit-tests.json        # 单元测试结果
│   ├── security-scan.json     # Xray 扫描汇总
│   └── qa-approval.json       # QA 人工审批
├── scripts/                   # 端到端脚本,按顺序执行
│   ├── config.sh              # 公共配置(可用环境变量覆盖)
│   ├── 00-init.sh             # 初始化:ping、建应用、生成签名密钥
│   ├── 01-build.sh            # docker build + jf docker push + 发布 build-info
│   ├── 02-create-version.sh   # 从 build 创建 AppTrust 应用版本
│   ├── 03-attach-evidence.sh  # 附加 SLSA、测试、安全扫描 3 类证据
│   ├── 04-promote.sh          # 晋升 DEV → QA
│   ├── 05-approve-and-release.sh # QA 审批证据 → 晋升 PROD → 正式 release
│   ├── 06-verify.sh           # 验证证据签名 + 查询晋升历史(GraphQL)
│   ├── 99-cleanup.sh          # 清理版本(可选清理应用)
│   └── run-all.sh             # 一键跑通全部步骤
└── .github/workflows/apptrust-pipeline.yml   # GitHub Actions 集成示例
```

---

## 前置条件

| 依赖 | 说明 |
|---|---|
| `jf` CLI ≥ 2.100 | 需支持 `jf apptrust` 和 `jf evd` 命名空间 |
| Docker | 用于构建镜像 |
| `jq` | 校验 Evidence Predicate JSON |
| JFrog 平台 | 已启用 **AppTrust** 与 **Evidence** 服务 |
| **AppTrust 需 Access Token 认证** | Basic Auth 会被拒绝,请使用 `jf c add --access-token=...` 或 OIDC |
| JFrog Project | 需要一个已存在的 Project(默认 `apptrust-demo`),并已在平台上配置 `DEV`、`QA`、`PROD` 三个 Stage/Environment |
| Docker 仓库 | 每个 Stage 对应一个 Docker 本地仓库(默认命名 `<project>-docker-<stage>-local`) |

### 平台上需先手动完成的准备

在 JFrog 平台 UI 中:

1. **创建 Project** `apptrust-demo`(名称可通过 `JF_PROJECT` 环境变量覆盖)。
2. **创建 3 个 Docker 本地仓库**并加入该 Project:
   - `apptrust-demo-docker-dev-local`
   - `apptrust-demo-docker-qa-local`
   - `apptrust-demo-docker-prod-local`
3. **配置 Lifecycle 阶段**(Administration → AppTrust → Lifecycle):`DEV`、`QA`、`PROD`,并把上面三个仓库映射到对应阶段。

---

## 快速开始

### 1. 配置服务器

```bash
jf c add my-apptrust \
  --url https://<your-tenant>.jfrog.io \
  --access-token <token> \
  --interactive=false
jf c use my-apptrust
```

### 2. (可选)自定义变量

```bash
export JF_SERVER_ID=my-apptrust
export JF_PROJECT=apptrust-demo
export APP_VERSION=1.0.0
```

其他所有可覆盖变量见 `scripts/config.sh`。

### 3. 一键执行

```bash
cd apptrust-sample
./scripts/run-all.sh
```

或按步骤逐个执行,便于观察每一步的输出:

```bash
./scripts/00-init.sh              # 初始化应用与密钥
./scripts/01-build.sh             # 构建并推送镜像 + 发布 build-info
./scripts/02-create-version.sh    # 创建 AppTrust 应用版本(PRE_RELEASE)
./scripts/03-attach-evidence.sh   # 附加 3 类 Evidence
./scripts/04-promote.sh           # DEV → QA
./scripts/05-approve-and-release.sh  # QA 审批 → PROD → RELEASED
./scripts/06-verify.sh            # 验证签名并查询晋升历史
```

---

## Evidence 类型说明

Evidence(证据)是对应用版本的可验证、可签名的声明,构成 SLSA 意义上的供应链信任链。示例覆盖四类常见 Predicate:

| Predicate Type | 用途 | 触发时机 |
|---|---|---|
| `https://slsa.dev/provenance/v1` | 记录构建来源(git commit、runner、工具链、基础镜像) | 构建完成 |
| `https://jfrog.com/evidence/test-results/v1` | 单元/集成测试结果 | 测试通过 |
| `https://jfrog.com/evidence/security-scan/v1` | Xray 扫描汇总 + 策略结论 | 扫描完成 |
| `https://jfrog.com/evidence/approval/v1` | 人工审批(QA、安全、合规) | 每个阶段之间 |

所有证据都用同一把 ECDSA P-256 私钥签名(`jf evd generate-key-pair` 生成),公钥同步上传到平台的 **Trusted Keys**,`jf evd verify-evidence` 可以离线校验。

---

## 生命周期示意

```
[git commit]
     │
     ▼
  docker build          ──► apptrust-demo-docker-dev-local
     │
     ▼
 jf rt build-publish
     │
     ▼                                     ┌──────────────────┐
 jf apptrust version-create ──► PRE_RELEASE│ Evidence 附加     │
     │                                     │  • SLSA           │
     │  ◄──────────────────────────────────┤  • Tests          │
     │                                     │  • Xray scan      │
     ▼                                     └──────────────────┘
 promote DEV  ─► apptrust-demo-docker-dev-local  (记录 promotion)
     │
     ▼
 promote QA   ─► apptrust-demo-docker-qa-local
     │
     ▼
 Evidence: QA approval
     │
     ▼
 promote PROD ─► apptrust-demo-docker-prod-local
     │
     ▼
 jf apptrust version-release  ─► releaseStatus = RELEASED (immutable)
```

---

## 常见问题

**Q1: `jf apptrust ping` 报 `does not support basic authentication`**

AppTrust 只接受 Access Token。请用 `jf c add --access-token=...` 重新配置,或用 `jf c edit`。

**Q2: `version-create` 报找不到 build**

确认 `jf rt build-publish` 已成功执行,且 `build-name` / `build-number` 与 `--source-type-builds` 中的完全一致,`--project` 也必须一致。

**Q3: Promotion 报 stage 不存在**

平台端(Administration → AppTrust → Lifecycle)必须先手动创建 `DEV/QA/PROD` 阶段并映射仓库。

**Q4: Evidence 验证失败**

`00-init.sh` 上传公钥后需要几秒钟同步。若仍失败,检查:
- `--key-alias` 一致
- 私钥 `.keys/evidence.key` 权限为 600
- 平台 Trusted Keys 中确实存在同名公钥

**Q5: 想清理**

```bash
DELETE_APPLICATION=true ./scripts/99-cleanup.sh
```

---

## CI/CD 集成

见 `.github/workflows/apptrust-pipeline.yml` — 一个包含 OIDC 认证、Xray 扫描、Evidence 附加、多阶段 promote、GitHub Environment 审批网关的完整 GitHub Actions 示例。所需的仓库级配置:

- **Variables**: `JF_URL`, `JF_OIDC_PROVIDER`
- **Secrets**: `EVIDENCE_PRIVATE_KEY`(签名私钥 PEM 内容)
- **Environments**: `production`(启用 required reviewers 即可作为 PROD gate)
