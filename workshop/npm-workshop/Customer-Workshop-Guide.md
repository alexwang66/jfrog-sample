# NPM + Curation Workshop Guide (Customer)

目标：在客户本机完成一次 **npm 构建 + 发布 build-info**，并演示 **JFrog Curation 阻断“恶意版本” axios** 的下载。

---

## 0) 你需要准备

- JFrog Cloud 试用账号：`https://jfrog.com/start-free/`
- 本机已安装（最少 3 个工具）：
  - JFrog CLI（`jf`）
  - Git（`git`）
  - Node.js 20.x LTS（含 `npm`）

### 安装（尽量简洁）

- **安装 JFrog CLI**
  - 打开：`https://jfrog.com/getcli/`
  - 按页面选择你的 OS 下载/安装

- **安装 Node.js 20.x LTS（含 npm）**
  - 打开：`https://nodejs.org/`，选择 **LTS（20.x）** 安装包
  - **Windows 提示**：安装向导建议勾选 “Add to PATH”（安装后重新打开一个新的 PowerShell/CMD 再执行 `node -v`）
  - （macOS + Homebrew 可选）
    ```bash
    brew install node@20
    brew link --force --overwrite node@20
    ```

验证：

```bash
jf --version
git --version
node -v
npm -v
```

---

## 1) 登录 JFrog（一次即可）

```bash
jf c add
```

建议：
- Server ID：`workshop`
- 认证方式：Access Token

验证：

```bash
jf c show
jf rt ping
```

---

## 2) 拉取 workshop 代码

```bash
cd ~
git clone https://github.com/alexwang66/jfrog-sample.git
cd jfrog-sample
```

> 如果 GitHub 不可达：请使用 workshop 组织者提供的离线源码包（解压到 `~/jfrog-sample`）或公司内网 Git 地址。

---

## 3) 一键创建 workshop 仓库（推荐）

在本项目自带脚本目录执行：

```bash
cd ~/jfrog-sample/workshop/automation
chmod +x ./create-repo.sh
./create-repo.sh all
```

脚本默认会创建（示例）：
- resolve：`workshop-npm-virtual`（virtual）
- remote：`workshop-npm-remote`（remote，指向 npmjs）
- deploy：`workshop-npm-dev-local`（local）

---

## 4) NPM：通过 Artifactory 安装、发布包、发布 build-info

进入示例目录：

```bash
cd ~/jfrog-sample/npm-sample
```

配置 npm 解析/部署到你刚创建的仓库：

```bash
jf npm-config \
  --server-id-resolve=workshop \
  --server-id-deploy=workshop \
  --repo-resolve=workshop-npm-virtual \
  --repo-deploy=workshop-npm-dev-local \
  --global=false
```

为避免同一 build-number 出现多条 module 记录，先固定版本号，再执行 install/publish：

```bash
rm -rf node_modules package-lock.json
npm version 1.0.0 --no-git-tag-version
```

执行安装/发布，并发布 build-info：

```bash
BUILD_NAME=npm-sample
BUILD_NUMBER=1

jf npm install --build-name="$BUILD_NAME" --build-number="$BUILD_NUMBER"
jf npm publish --build-name="$BUILD_NAME" --build-number="$BUILD_NUMBER"

jf rt build-add-git "$BUILD_NAME" "$BUILD_NUMBER"
jf rt build-collect-env "$BUILD_NAME" "$BUILD_NUMBER"
jf rt build-publish "$BUILD_NAME" "$BUILD_NUMBER"
```

在 UI 查看：
- Artifactory → Builds → `npm-sample` → `#1`

---

## 5) Curation 演示：把 `axios@1.7.2` 当作“恶意版本”并阻断下载

本 workshop **假设**：`axios@1.7.2` 是恶意版本，目标是让 `npm install` 在解析到该版本时被 Curation 阻断。

### 5.1 确保项目依赖了这个版本

在 `~/jfrog-sample/npm-sample/package.json` 确保有这一行（若不同请修改）：

- `"axios": "1.7.2"`

然后清理并准备重新安装：

```bash
cd ~/jfrog-sample/npm-sample
rm -rf node_modules package-lock.json
```

### 5.2 在 JFrog UI 创建 Curation Policy（阻断 axios@1.7.2）

这里需要 **先创建 Custom Condition**，再用它创建 Policy。

#### 5.2.1 创建 Custom Condition（customer condition）

参考官方文档：`https://docs.jfrog.com/security/docs/create-custom-conditions`

在 JFrog UI：
- Administration → Curation Settings → **Conditions**
- 右上角 **Create Condition**
- 选择模板：**Block Specific Package Versions**
- 配置：
  - Package type：`npm`
  - Package：`axios`
  - Version：`1.7.2`
- Save

#### 5.2.2 创建 Policy 并应用到 npm remote

在 JFrog UI：
- Administration → Curation → **Policies Management**
- Create Policy：
  - Scope：选择 **Specific remote repositories**（选 `workshop-npm-remote`）
  - Condition：选择刚创建的 custom condition（axios 1.7.2）
  - Action：**Block**
- Save

确保 Curation 对该 remote 生效（UI 入口因版本略有不同）：
- Administration → Curation → Remote Repositories（或类似页面）
- 找到 `workshop-npm-remote`，确保启用 Curation

> UI 入口名称可能随版本略有不同，以你实例的实际菜单为准。

### 5.3 重新执行 install，观察被阻断

```bash
cd ~/jfrog-sample/npm-sample
jf npm install --build-name=npm-curation --build-number=1
```

期望现象：
- CLI 输出显示某个依赖版本被阻断（axios@1.7.2）
- 安装失败或被替换为允许版本（取决于你 policy 的动作与配置）
