# Custom Domain 部署指南

把 Unflatten Studio 部署到自定义域名（推荐用 DigitalPlat FreeDomain 免费域名）。

## 1. 注册免费子域名

打开 [dash.domain.digitalplat.org](https://dash.domain.digitalplat.org/) 注册账号 + 注册子域名。

可选后缀（5 个）：

| 后缀 | 例子 |
|---|---|
| `.dpdns.org` | `unflatten.dpdns.org`（推荐） |
| `.us.kg` | `unflatten.us.kg` |
| `.qzz.io` | `unflatten.qzz.io` |
| `.xx.kg` | `unflatten.xx.kg` |
| `.qd.je` | `unflatten.qd.je` |

> ⚠️ 选好后记住完整域名，下一步用。

## 2. 注册 Cloudflare 账号 + 添加 zone

打开 [dash.cloudflare.com](https://dash.cloudflare.com/) 注册（免费 tier 够用）。

- 点 `Add site` → 输入完整子域名（如 `unflatten.dpdns.org`）
- 选 `Free` plan
- Cloudflare 会自动扫描现有 records，**全部删掉**（只是子域名，没有真实 records）

## 3. 把 Cloudflare 分配的 nameservers 填到 DigitalPlat

Cloudflare 会给两个 nameserver 主机名，格式像：
```
kia.ns.cloudflare.com
sid.ns.cloudflare.com
```

回到 [DigitalPlat dashboard](https://dash.domain.digitalplat.org/)：
- 找到你的域名 → Nameservers
- 把上面两个填进去 → Save
- 等待 5-30 分钟生效（用 `dig NS unflatten.dpdns.org` 验证）

## 4. 在 Cloudflare DNS 添加 GitHub Pages 记录

回到 Cloudflare → 你的域名 → `DNS` → `Records`：

### 4a. Apex / root（`unflatten.dpdns.org` 本身）

点 `Add record`，选 `CNAME`：

| 字段 | 值 |
|---|---|
| Type | CNAME |
| Name | `@` |
| Target | `hhdhh.github.io` |
| Proxy status | **DNS only**（灰云，不是橙色代理） |

> Cloudflare 在 apex 自动做 CNAME flattening，免费 tier 即可。

### 4b. `www` 子域名（可选）

| 字段 | 值 |
|---|---|
| Type | CNAME |
| Name | `www` |
| Target | `hhdhh.github.io` |
| Proxy status | **DNS only**（灰云） |

## 5. 在 GitHub Pages 添加 custom domain

打开 [github.com/hhdhh/unflatten/settings/pages](https://github.com/hhdhh/unflatten/settings/pages)：

- `Custom domain` 输入完整域名（如 `unflatten.dpdns.org`）
- 点 `Save`
- 等待 DNS check 通过（5-30 分钟）
- ✅ 勾选 `Enforce HTTPS`

## 6. （可选）本项目加 CNAME 文件

让 GitHub Pages 自动认这个域名。在 `gh-pages` 分支根目录加 `CNAME` 文件：

```bash
echo "unflatten.dpdns.org" > CNAME
git add CNAME
git commit -m "chore: add CNAME for custom domain"
git push origin gh-pages
```

`./deploy.sh` 脚本下次部署时也会自动写 CNAME（如果环境变量 `CUSTOM_DOMAIN` 设置了）：

```bash
CUSTOM_DOMAIN=unflatten.dpdns.org ./deploy.sh
```

## 验证

```bash
# DNS 解析验证
dig unflatten.dpdns.org +short
# 期望: hhdhh.github.io. (CNAME) → 185.199.108.153 (A) 等

# HTTPS 验证
curl -I https://unflatten.dpdns.org/
# 期望: HTTP/2 200
```

## 故障排查

| 症状 | 原因 | 修复 |
|---|---|---|
| `dig` 找不到记录 | DigitalPlat nameserver 没生效 | 等 30 分钟再试；确认 NS 拼写 |
| `Custom domain` 灰色不可点 | repo 还没启用 Pages | Settings → Pages → Source = gh-pages |
| `DNS check in progress` 卡住 | Cloudflare 代理开启（橙云） | 关掉 Proxy（改 DNS only） |
| `Enforce HTTPS` 灰色 | 证书还没签 | 等 30 分钟；Custom domain 不要带 `https://` |

