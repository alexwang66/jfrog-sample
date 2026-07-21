# AI Catalog Sample — 端到端 AI 供应链治理演示

覆盖 JFrog 平台侧 AI 相关能力的一次性 demo:通过 **AI Catalog(HuggingFace 代理)** 拉取模型 →
Xray 扫描 → 生成签名 evidence → **AppTrust** 应用版本 → 多阶段 promotion → 用
**Unified Policy** 阻断不符合模型治理要求的 release。

与 [../apptrust-sample](../apptrust-sample/) 使用**完全相同**的脚本结构和 evidence + policy 骨架 ——
这套 demo 是把同一治理框架**平移到 ML 模型**这个 subject 上。

> 参考:
> - AI Catalog 概念:https://jfrog.com/help/r/jfrog-artifactory-documentation/huggingfaceml-repositories
> - AppTrust 官方:https://jfrog.com/help/r/jfrog-platform-administration-documentation/apptrust
> - Unified Policy(Rego + Template/Rule/Policy):`/unifiedpolicy/api/v1/`

---

## Demo 一句话叙述

> "客户不允许 huggingface.co 的模型未经审计就直接进生产。我们用 JFrog:代理拉取,给每个模型
> 附加签名的 **model card**、**Xray ML 扫描**、**红队测试报告** 三种证据,再用一条 policy
> 阻断没有这三条证据的模型进入 PROD。同一模型同一版本,证据齐 → 放行;证据缺 → 阻断。"

---

## 目录结构

```
ai-catalog-sample/
├── evidence/                                    # 4 类 Predicate 模板
│   ├── model-card.json                          # 模型卡片(治理/许可/预期用途)
│   ├── xray-model-scan.json                     # Xray ML 扫描(pickle/CVE/license)
│   ├── red-team.json                            # OWASP-LLM + MITRE ATLAS 红队报告
│   └── deployment-approval.json                 # PROD 部署审批
├── policy/
│   └── require-model-card-and-red-team.rego     # Unified Policy 的 Rego 逻辑
├── scripts/
│   ├── config.sh                                # 集中配置(全部可用环境变量覆盖)
│   ├── 00-init.sh                               # ping + HF repos + app + 签名密钥
│   ├── 01-pull-model.sh                         # 通过 AI Catalog 代理拉 distilbert
│   ├── 02-upload-and-scan.sh                    # 上传 + build-info + Xray build-scan
│   ├── 03-create-version.sh                     # 从 build 创建 AppTrust 版本
│   ├── 04-attach-evidence.sh                    # 3 类签名证据附加到版本上
│   ├── 05-promote.sh                            # DEV → QA
│   ├── 06-approve-and-release.sh                # 审批证据 → PROD release
│   ├── 07-create-policy.sh                      # Template + Rule + Policy(阻断 PROD)
│   ├── 08-test-block.sh                         # 端到端验证 block-then-unblock
│   ├── 99-cleanup.sh                            # 清理版本(可选清理 app)
│   └── run-all.sh                               # 顺跑 00~06 的"happy path"
└── README.md
```

---

## 前置条件

| 项 | 说明 |
|---|---|
| `jf` CLI ≥ 2.100 | 必备 `jf apptrust` + `jf evd` |
| Python 3 | `01-pull-model.sh` 会临时装 `huggingface_hub[cli]` 到本地 venv |
| `curl` + `jq` | REST 调用与 JSON 解析 |
| **JFrog 平台**必须启用 AppTrust + Xray + Unified Policy(demo 实例已就绪) |
| **JFrog Project** | `alex`(默认,可用 `JF_PROJECT` 覆盖) |
| **HF Remote Repo** | `alex-huggingfaceml-remote → https://huggingface.co`(demo 已有) |
| **HF Local Repos** | `alex-huggingfaceml-{dev,qa,prod}-local`(00-init.sh 会自动创建缺失的) |

---

## 快速开始

### 1. 切到 demo 服务器
```bash
jf c use demo   # 或 export JF_SERVER_ID=demo
```

### 2. 一键跑 happy path(约 3 分钟)
```bash
cd ai-catalog-sample
./scripts/run-all.sh
```

### 3. 创建阻断 policy 并验证
```bash
./scripts/07-create-policy.sh   # 创建 template + rule + policy(block mode)
./scripts/08-test-block.sh      # 新建一个缺证据的版本,验证被 block;补齐证据后放行
```

预期 `08-test-block.sh` 打印:
```
✗ Release BLOCKED as expected. Reason: policy violation: BLOCKED: missing required evidence types: ...
...
✓ Release ALLOWED after evidence attached. End-to-end block-then-unblock verified.
```

---

## 三类证据与 Predicate 类型

| 证据 | Predicate Type | 何时产生 | 谁签发 |
|---|---|---|---|
| Model Card | `https://jfrog.com/evidence/model-card/v1` | 治理评审通过 | ML Governance Lead |
| Xray ML Scan | `https://jfrog.com/evidence/ml-security-scan/v1` | Xray 扫描通过 | 安全 CI |
| Red-Team | `https://jfrog.com/evidence/red-team/v1` | 红队测试通过 | 安全团队 |
| Deployment Approval | `https://jfrog.com/evidence/approval/v1` | PROD 前人工审批 | AI 产品负责人 |

所有证据都用同一把 ECDSA P-256 私钥签名。`jf evd verify-evidence` 可用平台
Trusted Keys 离线校验。

---

## Policy 的工作方式

Unified Policy Service 使用 **Template → Rule → Policy** 三层结构:

- **Template**:承载 Rego 代码,声明输入 schema(`data_source_type: evidence`)
- **Rule**:模板实例化,可带参数(本 demo 无参数)
- **Policy**:把 rule 绑定到 `{application, stage, gate, mode}`

本 demo 中 `07-create-policy.sh` 创建的 policy 属性:
- `scope.type = application`,`scope.application_keys = [alex-ml-classifier]`
- `action.type = certify_to_gate`
- `action.stage = { gate: release, key: PROD }`(在 PROD release 网关处评估)
- `mode = block`(不满足直接拒绝)
- 规则要求:版本上必须同时存在 `model-card/v1` 和 `red-team/v1` 两类 predicate

---

## 与 apptrust-sample 的差异

| 维度 | apptrust-sample | ai-catalog-sample |
|---|---|---|
| Subject | Node.js Docker 镜像 | HuggingFace 模型 |
| Source type | `--source-type-builds` from docker push build | 同,只是 build 内容是模型文件 |
| Evidence 类型 | SLSA / test / security-scan / approval | model-card / ML scan / red-team / approval |
| Policy 关注点 | 有无 security-scan 证据 | 有无 model-card + red-team 两条证据 |
| Policy 网关位置 | DEV entry_gate | PROD release_gate |

两个 sample 共享同一套 evidence 签名密钥流程、AppTrust CLI 流程和 Unified Policy REST 结构。

---

## UI 定位

- 应用版本:Application → alex-ml-classifier → 1.0.0
- 模型文件:Repositories → alex-huggingfaceml-dev-local / -qa-local / -prod-local
- 证据:Application Version → Evidence 页签
- Policies:Administration → Unified Policy → Policies(`alex-ml-classifier-prod-release-gate`)

---

## 故障排查

| 症状 | 原因 | 解决 |
|---|---|---|
| `--project flag is not allowed` on evd create | 用 `--application-key` 时 project 自动推断 | 移除 `--project` |
| `promotion to release stage 'PROD' is not allowed` | PROD 是 release stage | 改用 `version-release` |
| `Build not found ... repository: artifactory-build-info` | build 在 project 下时不在全局 build-info | 传 `repo-key=<project>-build-info` |
| `huggingface-cli: command not found` | huggingface_hub 1.0+ 改名为 `hf` | 脚本已 fallback 到 `hf`,或手工升级 |
| `Client error '404 Not Found' ... /api/models/...` | JFrog HF proxy 校验 `User-Agent`,curl 默认 UA 不通过 | 用 `hf` CLI(自带正确 UA)或加 `-H "User-Agent: huggingface_hub"` |
| HF proxy 拉不到模型 | remote 指向 `huggingface.co`,demo(中国)访问不了 | 把 remote URL 改为 `https://hf-mirror.com` |
| `Forbidden to copy/move artifacts from/to Release Bundles repository` | AppTrust 内部 `<project>-application-versions` 是 Release Bundle 型仓库,禁止普通 copy;HF 模型文件大,promotion 触发这个限制 | 用 `--promotion-type keep + --include-repos <目标 repo>`;先把模型上传到 DEV 再 promote |
| `The first promotion cannot be 'no-op'` | 第一次 promotion 不能是 `keep`(平台规则) | 让文件已经在目标 repo 中,或使用 copy(前提是没有 release-bundle 源限制) |
| Xray 扫描无 finding | distilbert 是安全模型 | 换已知有 pickle 漏洞的模型作对比 |
| `Build ... is not selected for indexing` | Xray 未把该 build 加入索引 | UI Administration → Xray → Watches 中添加 build 到 watch |
