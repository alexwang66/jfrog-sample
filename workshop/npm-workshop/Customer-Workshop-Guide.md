# Customer Workshop Guide (Docker + JFrog Trial)

本指南用于客户在自己的电脑上完成 workshop 实践环境准备与操作。

你将会：
- 申请一个 JFrog Cloud 试用账号
- 在本机安装 JFrog CLI、Git、Node.js（含 npm）
- 在本机 clone 本项目并完成一次 npm 构建与 build-info 发布

---

## 1) 申请 JFrog 试用账号（JFrog Cloud）

在浏览器打开并注册试用：

`https://jfrog.com/start-free/`

注册完成后，请准备好以下信息（后续 `jf` 配置会用到）：
- JFrog Platform URL（通常类似 `https://<your-domain>.jfrog.io/`）
- Artifactory URL（通常是 `https://<your-domain>.jfrog.io/artifactory/`）
- 用户名/密码或 Access Token（推荐 Access Token）

---

## 2) 安装工具（本机）

### 2.1 安装 JFrog CLI（`jf`）

从官方页面下载并安装：

`https://jfrog.com/getcli/`

安装后验证：

```bash
jf --version
```

### 2.2 安装 Git

请使用你们公司标准方式安装（或自行安装 Git）。

验证：

```bash
git --version
```

### 2.3 安装 Node.js（包含 npm）

建议安装 **Node.js 20.x LTS**（会包含 npm）。

安装方式（任选其一）：

- **方式 A：官方下载（Windows/macOS/Linux）**
  - 打开 `https://nodejs.org/`，下载并安装 “LTS（20.x）” 版本

- **方式 B：macOS（Homebrew）**
  ```bash
  brew install node@20
  brew link --force --overwrite node@20
  ```

> 注意：如果你机器上已安装其它 Node 版本，请确保当前 shell 的 `node`/`npm` 指向 20.x（可用 `which node` / `which npm` 检查）。

验证：

```bash
node -v
npm -v
```

---

## 3) 配置 JFrog CLI（登录）

在本机运行（交互式）：

```bash
# 在任意目录执行均可
jf c add
```

建议在提示时选择：
- Server ID：例如 `workshop`
- URL：你的 JFrog Platform URL（例如 `https://<your-domain>.jfrog.io/`）
- 认证方式：优先使用 Access Token

验证连接（示例）：

```bash
# 在任意目录执行均可
jf c show
# 在任意目录执行均可
jf rt ping
```

> 说明：`jf rt ping` 需要 Artifactory 可访问。

---

## 4) clone 本项目作为实践环境

在本机工作目录中 clone：

```bash
cd ~
git clone https://github.com/alexwang66/jfrog-sample.git
cd jfrog-sample
```

如果 `git clone` 过程中提示输入 GitHub 用户名/密码或失败（例如公司网络限制、需要代理、或 GitHub 不可达），可选方案：
- 方案 A：由 workshop 组织者提供离线源码包（zip/tar），你在宿主机解压到 `~/jfrog-sample`，然后直接进入该目录使用
- 方案 B：使用你们公司内部的 Git 仓库地址（由组织者提供），替换上面的 `git clone` URL

---

## 5) npm 示例：通过 Artifactory 解析依赖、发布产物、发布 build-info

进入 npm 示例目录：

```bash
cd ~/jfrog-sample/npm-sample
```

### 6.1 配置 npm 解析/部署仓库（用你环境的 repo 名称替换）

你需要提前在 Artifactory 里准备 npm 仓库（名称以客户环境为准）：
- resolve repo：一个 npm **virtual** 仓库（例如 `npm-virtual`）
- deploy repo：一个 npm **local** 仓库（例如 `npm-local`）

#### 使用 automation 脚本创建仓库（推荐）

本项目自带 automation 脚本，可用 JFrog CLI 直接创建 local/remote/virtual 仓库模板：

```bash
cd jfrog-sample/workshop/automation
chmod +x ./create-repo.sh

# 创建全部（local + remote + virtual）
./create-repo.sh all

# 或按需创建（只建某一类）
./create-repo.sh local
./create-repo.sh remote
./create-repo.sh virtual
```

脚本会读取同目录下的 `*-repo-values.json` 并用 `jf rt repo-create` 创建仓库：
- `local-repo-values.json`
- `remote-repo-values.json`
- `virtual-repo-values.json`

> 注意：
> - 需要你的 `jf` 登录账号具备创建仓库权限（Admin 或具备 repo 管理权限）。
> - 如果客户环境的仓库命名/URL 不同，请先修改 `*-repo-values.json` 再执行脚本。

接下来在 `npm-sample` 目录里配置 npm 解析/部署（把 `workshop` 换成你上一步设置的 Server ID）：

```bash
cd ~/jfrog-sample/npm-sample
jf npm-config \
  --server-id-resolve=workshop \
  --server-id-deploy=workshop \
  --repo-resolve=npm-virtual \
  --repo-deploy=npm-local \
  --global=false
```

### 6.2 安装依赖（通过 Artifactory），并收集 build-info

```bash
cd ~/jfrog-sample/npm-sample
jf npm install --build-name=npm-sample --build-number=1
```

### 6.3 发布 npm 包到 Artifactory（产生 artifact，并关联 build）

```bash
cd ~/jfrog-sample/npm-sample
jf npm publish --build-name=npm-sample --build-number=1
```

### 6.4 发布 build-info 到 Artifactory

```bash
cd ~/jfrog-sample/npm-sample
jf rt build-add-git npm-sample 1
jf rt build-collect-env npm-sample 1
jf rt build-publish npm-sample 1
```

完成后，你可以在 JFrog UI 里查看：
- Builds → `npm-sample` → `#1`
- Published Modules / Artifacts / Dependencies

---

## 常见问题

### A) Build 里 Artifacts 为空

只有执行了 **部署产物**（例如 `jf npm publish` 或 `jf rt upload`），build 的 Artifacts 才会有记录。
只跑 `jf npm install` + `build-publish` 通常只会看到 Dependencies。

### B) Published Modules 出现两条记录

同一个 build-number 过程中如果 `package.json` 的版本号发生变化（例如先 install 时是 `1.0.1`，publish 前又 `npm version` 变为 `1.0.2`），会在同一 build 下出现两个 module id。
解决方法：同一次 build 先定好版本号，再 install/publish，并保持 build-number 不变。
