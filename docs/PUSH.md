# 推送远端

Unflatten Studio 当前在本地 git 仓库（`5afd39a` → `167259a` → `757431c`，tag `v0.1.0`）。本文档说明把仓库推上远端的完整流程。

## 0. 选择远端平台

| 平台 | 推荐场景 |
|---|---|
| GitHub | 公开发布，社区可见 |
| Gitea / Forgejo | 自建服务器，私有 + 自由 |
| GitLab | 公司内部，CI 集成 |
| Codeberg | 公益开源镜像 |

任何 Git 远端协议都支持。

## 1. 创建远端仓库

按平台文档新建空仓库，**不要**勾选「Initialize with README / .gitignore / license」（本地已有）。

仓库名建议：

```
unflatten-studio/unflatten       # GitHub org
hhdhh/unflatten           # 个人
unflatten/unflatten              # Gitea / 自建
```

## 2. 选择认证方式

按主人偏好选一种：

### 方式 A · HTTPS + Personal Access Token（最简单）

1. 在 GitHub 打开 `Settings → Developer settings → Personal access tokens → Tokens (classic)`
2. `Generate new token`，选 `repo` scope，过期 90 天或更长
3. 复制 token（GitHub 只显示一次）
4. 本机配置：

   ```bash
   git credential.helper store      # 仅 Linux / macOS
   git push https://github.com/<owner>/unflatten.git main
   # 用户名: <owner>
   # 密码: <粘贴 token>
   ```

   或一次性推送：

   ```bash
   git push https://<owner>:<token>@github.com/<owner>/unflatten.git main --tags
   ```

### 方式 B · SSH（推荐长期）

1. 生成 key：

   ```bash
   ssh-keygen -t ed25519 -C "dingxianghao@users.noreply.github.com"
   # 默认路径 ~/.ssh/id_ed25519，可设 passphrase
   ```

2. 复制公钥到 GitHub：

   ```bash
   pbcopy < ~/.ssh/id_ed25519.pub
   # GitHub → Settings → SSH and GPG keys → New SSH key
   ```

3. 测试：

   ```bash
   ssh -T git@github.com
   # Hi <owner>! You've successfully authenticated...
   ```

4. 推送：

   ```bash
   git remote add origin git@github.com:<owner>/unflatten.git
   git push -u origin main --tags
   ```

### 方式 C · gh CLI（GitHub 专属）

```bash
brew install gh
gh auth login                          # 走浏览器 OAuth
gh repo create unflatten --public      # 创建远端
git push -u origin main --tags
```

## 3. 推送命令

无论选哪种认证方式，最终推送都是：

```bash
cd /Users/kk/Documents/New\ project/unflatten-studio

# 配远端
git remote add origin <url>

# 推送 main + 标签
git push -u origin main --tags

# 验证
git remote -v
git ls-remote --tags origin
```

期望输出：

```
* [new tag]         v0.1.0        -> v0.1.0
To <url>
 * [new branch]      main          -> main
```

## 4. 推送后 5 步验证

1. **仓库页面** 能看到 160 个文件、3 个 commit、1 个 tag
2. **GitHub Actions** 自动跑 CI（`.github/workflows/ci.yml`）—— 应该全绿
3. **README 截图** 自动渲染（`test/goldens/camera_lab_*.png`）
4. **LICENSE / CHANGELOG** 在仓库首页展示
5. **首次 release**：GitHub → Releases → Draft a new release → 选 `v0.1.0` → 粘贴 `RELEASE_NOTES_v0.1.0.md` 内容 → Publish

## 5. 后续小版本流程

```bash
# 改代码 → commit → push
git add -A
git commit -m "fix: ..."
git push

# 新版本
git tag -a v0.1.1 -m "..."
git push --tags
```

## 6. 回退

```bash
# 删除远端 tag（慎用）
git push origin --delete v0.1.0

# 强推（慎用）
git push -f origin main

# 删除远端
git remote remove origin
```

## 7. 故障排查

- `Permission denied (publickey)` → SSH 没加，详见方式 B 步骤 1-2
- `Repository not found` → 远端 URL 拼写错，或还没创建仓库
- `failed to push some refs` → 远端有初始文件，先 `git pull --rebase origin main` 再 push
- `GH013: Repository rule violations` → 仓库启用了保护规则，先在网页放行 main
- 大文件 push 卡住 → 检查 `~/.gitconfig` 里 `http.postBuffer` 是不是设到了 500MB+（已设）
