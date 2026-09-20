# 家庭共享（FamilyShare）服务端 · 飞牛OS + Docker 部署全攻略

> **适用对象**：把 FamilyShare 服务端跑在自己的 NAS（飞牛OS / fnOS）上，让家人手机无论在不在家、用 WiFi 还是 4G/5G 流量，都能连上来实时共享位置。
>
> **项目**：<https://github.com/yujianxi666/FamilyShare>　服务端 = Spring Boot 3.3.4 + Redis，REST + WebSocket(WSS)，监听端口 3000。
>
> **一句话流程**：`把 server/ 传上 NAS → 一键 docker compose 跑起来 → 用域名 + Nginx 反向代理把 3000 变成 443 的 HTTPS/WSS → 手机 App 指到你的域名`。

---

## ⚠️ 先读：Java 版本（必须 17，别改成 25）

- 本服务端是 **Java 17 / Spring Boot 3.3.4**（`pom.xml` 的 `<java.version>17</java.version>`）。
- **Spring Boot 3.3.x 官方只支持 Java 17–22，不支持 Java 25**。把 `<java.version>` 或 Docker 镜像改成 25，编译能过，但**启动时 Spring 的 ASM 识别不了 Java 25 字节码，会直接崩溃**（`Unsupported class file major version 69`）。
- 所以：**pom 和 Dockerfile 都保持 17 即可**，这个项目在 17 上跑得很好，别升级。下面的 Dockerfile 已经写成 17。

---

## 先看结论（三步走）

| 步骤 | 做什么 | 难度 |
| --- | --- | --- |
| ① 服务端跑起来 | NAS 上 Docker 运行 `server/docker-compose.yml`（内含 Spring Boot + Redis） | ★ |
| ② 公网通路 | 让外网手机能连到你家（大陆家宽大多没有公网 IP，需方案，见第 5 章） | ★★★ |
| ③ 反代 + 手机 | Nginx 反代出 HTTPS/WSS + 手机 App 指到域名 | ★★ |

**好消息**：服务端很小（2C2G 的 NAS 绰绰有余），数据库只用 Redis，无 MySQL。仓库已自带 `server/Dockerfile`、`server/docker-compose.yml`、`server/.env.example`，几乎开箱即用。

---

## 0. 先理清：高德 SDK 到底要不要？（郑重澄清）

你的直觉没错——**这个 App 确实需要高德地图 SDK，README 也确实给了高德配置过程。** 但请把**「服务器」和「App」**分开看，这是两件完全不同的事：

- **NAS 上 Docker 部署的「服务端」：不需要高德。** 证据：`server/pom.xml` 的依赖只有 `spring-boot-starter-web` / `-websocket` / `-data-redis`，**没有任何地图包**。服务端只管收发坐标、存 Redis，地图渲染完全发生在手机 App 里。
- **Android 手机 App：需要高德 SDK + 高德 Key。** 高德真正上场是在这里，完整流程见**第 5 章「方式 B」**。

### ⚠️ 你下载的 zip：被 README 一段「过期说明」误导了

你下载 `Lite3DMap_AMapSearch_AMapLocation.zip`，是因为 README 有一段「**先决条件：放入高德轻量版地图SDK**」让你下这个文件放进 `libs/`。**那段说明已经过期**——README 自相矛盾，作者忘了改：

| 位置 | 内容 | 状态 |
| --- | --- | --- |
| README 第 85–87 行「先决条件」 | 让你下载 Lite3DMap.zip 放进 `android/app/libs/` | ❌ **过期**（2026.09.10 轻量版时期留下的） |
| README 第 181 行「变更记录」 | 已**换回完整版 3D 地图 SDK 9.8.3（Maven）**，并**删除**轻量版 jar | ✅ 当前真实现状（2026.09.12） |
| `android/app/build.gradle` 第 70 行 | `implementation 'com.amap.api:3dmap:9.8.3'`（Maven 拉取） | ✅ 以它为准 |
| `android/app/libs/` 目录 | **根本不存在** | ✅ 证实 |

**所以：当前源码用的是高德 Maven 完整版 9.8.3，不需要你那个 zip。** 把 zip 里的 jar 硬塞进 `libs/` 反而会和 Maven 的 3dmap 类重复、**构建失败**。

- **路线 A（推荐，跟着当前源码走）**：申请一个高德 **Key** 即可，zip 用不上。APK 约 17MB，渲染正确。
- **路线 B（可选）**：若你一定要用下载的轻量版（APK 能瘦到约 3MB），需要**回溯代码**（`build.gradle` 改 `fileTree`、`MainActivity` 改回异步 `getMapAsyn`、去掉隐私接口等），工作量大，且项目当初正是因轻量版有「缩放时地名漂移」的渲染问题才换回完整版，**不建议**。真要做再生造，参考 `docs/SETUP_AMAP.md` 第 6 节。

---

## 1. 你要准备的东西

| 依赖 | 说明 |
| --- | --- |
| 飞牛OS 已装 Docker | 一般 fnOS 0.8.x+ 自带 Docker（应用中心里叫「Docker」，没有就先在应用中心搜装） |
| 一个自己的域名 | 例如 `fs.example.com`。建议买普通商域名（.com/.top/.xyz 等），海外注册商或阿里云/腾讯云都行 |
| 公网通路方案 | 看第 5 章：**推荐一台香港/新加坡低价 VPS（约 ¥30–40/月）** |
| Docker Compose | 新版 Docker 自带 `docker compose` 命令 |
| 一台能 SSH 进 NAS 的终端 | Windows 的 PowerShell / CMD，或 `ssh 用户名@NAS的IP` |

> **端口小结**：服务端容器内监听 **3000**；对外统一用 **443(HTTPS/WSS)** + **80**(Let's Encrypt 证书验证)。`33445` 是这个项目**不用的**端口（那是 Telegram 的端口），别管它。

---

## 2. 第 ① 步：在飞牛OS 上把服务端跑起来（局域网先自测）

### 2.1 把 `server/` 文件夹传上 NAS

在电脑上把仓库里的 **`server/`** 文件夹整体上传到 NAS 数据目录，例如 `/vol1/docker/familyshare/server`（路径按你 NAS 的卷来）。

> ⚠️ **构建上下文必须是 `server/` 整个目录**（Dockerfile 需要 `pom.xml`、`src/`、`update.json`）。别只传一个 jar。

### 2.2 开启 SSH 并登录飞牛OS

飞牛OS 一般默认没开 SSH：**系统设置 → 终端/SSH → 开启**（默认端口 22，勾选允许）。然后在电脑上：

```bash
ssh 用户名@你的NAS局域网IP
```

### 2.3 建共享网络（关键，别忘了）

compose 里的 `fms-net` 是 `external` 网络，**必须先手动建一次**（它给后面的反向代理 NPM 和 app/redis 共用）：

```bash
docker network create fms-net
```

> 忘了建 → `docker compose up` 会直接报「external network not found」。

### 2.4 进入 server/ 目录并写 `.env`（关键，错了起不来）

```bash
cd /vol1/docker/familyshare/server
cp .env.example .env
```

然后编辑 `.env`（用 `nano .env` 或 vi），**全部改成自己的随机长字符串**，共 4 个必填项：

```ini
# 访问口令：手机 App 的 API_TOKEN 必须和它完全一致（/api/**、/ws、/icons/** 都要带）
APP_API_TOKEN=用随机命令生成：openssl rand -hex 24

# Bug 反馈管理页：访问 https://你的域名/bugadmin/<这个值>
APP_BUG_ADMIN_TOKEN=再写一个随机串

# 只读状态看板：访问 https://你的域名/dashboard/<这个值>
APP_DASHBOARD_TOKEN=再写一个随机串

# Redis 密码（至少 8 位，别用弱密码）
REDIS_PASSWORD=写一个强口令
```

> compose 里用了 `${VAR:?提示}`，**四个值缺任何一个，启动都会直接报错提示你**，不会带病运行。

### 2.5 一键构建 + 启动

```bash
docker compose up -d --build
```

- 首次会拉取 `eclipse-temurin:17-jre`（运行）和 `maven:3.9-eclipse-temurin-17`（编译）两个官方镜像并编译，**需几分钟**。这两个镜像都是 amd64/arm64 双架构，x86 或 ARM 的 NAS 都能跑。
- 查看状态：`docker compose ps`　看日志：`docker compose logs -f app`

> ⚠️ 不要 `docker pull family-share-server` —— **仓库没有发布任何现成镜像**，必须用上面命令从源码构建。

### 2.6 局域网先自测（确认服务本身是好的）

先临时放开 3000 端口自测。编辑 `docker-compose.yml`，把 `app` 服务里注释掉的那段 `ports` 解开（去掉注释）：

```yaml
    ports:
      - "3000:3000"
```

然后重启并测试：

```bash
docker compose up -d
curl http://你的NAS局域网IP:3000/api/health
```

应返回类似 `{"status":"ok", ...}`。**看到 ok 说明服务端+Redis 已经正常工作了。** 测完再把那段 `ports` 注释回去（公网不直接暴露 3000，只走 443 反代）。

> 到这一步，**局域网内**其实已经能用了（手机连家里 WiFi 时可用）。接下来是「外网怎么连」。

---

## 3. 第 ② 步：公网通路 —— 外网手机怎么连上你家？

这是整件事**唯一真正的技术难点**。先看大陆家宽的现实：

### 3.1 现实前提（2024–2026 大陆家宽）

- **家庭 IPv4 大多没有公网入方向 IP**：电信/联通/移动自 2021 年起大规模把家宽放进 CGNAT/大内网。移动基本不给公网 IP；电信/联通部分省份可以「打电话给客服申请公网 IP」，但越来越难。即便拿到公网 IP，家宽入站 **80/443 常被运营商过滤**，且国内主机/域名还要 **ICP 备案**才能被正常解析 80/443。
- **IPv6 是免费的隐藏选项**：现在三大运营商光猫大多默认下发 IPv6，4G/5G 也基本全支持。所以「手机流量直连家里 IPv6」很多时候其实是通的（详见 3.4）。坑在于光猫默认防火墙常拦入站，且**异网**（电信宽带下用联通卡）偶发不通。

> **一句话结论**：别赌公网 IPv4，也别把原生 IPv6 当主路线；**用一条「有公网 IP 的中转」最稳**。

### 3.2 方案横评

| 方案 | 公网可达性 | HTTPS/WSS | 月成本 | 适合谁 | 评价 |
| --- | --- | --- | --- | --- | --- |
| ① 公网IPv4 + 端口转发 | 多数拿不到 / 443被滤 | 要备案+证书 | 0 | 少数电信/联通老用户 | 不稳定，**不推荐当主路线** |
| ② 原生 IPv6 + DDNS(AAAA) | 多数家宽/手机可 | 可 | 0 | 愿意折腾的人 | 免费，但光猫防火墙+异网偶发不通 |
| ③ **香港/新加坡 VPS + frp 内网穿透** | **稳定** | **稳** | **¥30–40** | **推荐首选** | 见 3.3 |
| ④ 花生壳/贝锐(付费穿透) | 一般 | 自定义域名/HTTPS要加钱 | ¥150–400/年 | 完全不想碰 VPS | 长连接WS偶掉、带宽受限 |
| ⑤ Cloudflare Tunnel | 大陆访问边缘慢/可能被墙 | 可 | 0 | —— | **大陆手机不推荐**当主线路 |
| ⑥ Tailscale | 可(P2P+DERP中继) | 需再套反代 | 免费档 | 愿意给家人装App | 家人也要装、走国外DERP |

### 3.3 ★ 推荐路线：香港 VPS + frp + Nginx 反代（给非专业用户）

**为什么是它**：香港 VPS 有真公网 IP、**域名不用备案**、对大陆延迟低（约 30–80ms）。frp 把家里的 3000 端口无感接到 VPS，做好 HTTPS/WSS 后**家人手机在任何网络都能稳定长连接**。这个 App 需要 30 秒心跳的 WebSocket——这正是隧道方案里最容易断的类型，自建 frp 在长连接/带宽上最可控。

**步骤（约 1 小时）**：

1. **买 VPS**：阿里云/腾讯云/华为云「轻量应用服务器」，选**香港**节点（大陆未备案也能用域名+443；别买大陆节点，大陆节点域名必须有备案）。最低配 1C2G（约 ¥30–40/月）就够。
2. **把域名 A 记录指向 VPS 公网 IP**：`fs.example.com → 香港IP`（DNS 控制台加一条 A 记录）。
3. **在 VPS 上装 frp 服务端 `frps`**（github.com/fatedier/frp 下载对应平台的 binary，做成 systemd 服务）：
   ```ini
   # frps.toml
   bindPort = 7000
   vhostHTTPPort = 80
   ```
4. **在 NAS 上跑 frp 客户端 `frpc`**（Docker 跑 `fatedier/frpc` 最省事），把本地 `app:3000` 透到 VPS 的 `127.0.0.1:3000`：
   ```ini
   # frpc.toml
   serverAddr = "香港VPS公网IP"
   serverPort = 7000
   [[proxies]]
   name = "familyshare"
   type = "tcp"
   localIP = "familyshare-app"   # compose 里 app 的服务名
   localPort = 3000
   remotePort = 3000             # 在 VPS 上开放 3000
   ```
5. **在 VPS 上跑一个 Nginx Proxy Manager（NPM）容器**，把 `443(你的域名)` 反代到 `127.0.0.1:3000`（具体配置见第 4 章），用 Let's Encrypt 签 HTTPS 证书。这样外网 HTTPS/WSS 到 VPS 就通了。
6. **验证**：手机断开 WiFi、用 4G/5G 流量访问 `https://fs.example.com/api/health`，应返回 ok——**此时已达成「家人哪怕在异地也能连」**。
7. 位置上报是低频小包，香港 VPS 带宽完全够用，延迟可忽略。

> **诚实补充**：如果你其实不在乎「一定在 NAS 上」，终极省事方案是把整套 compose 直接部署在这台香港 VPS 上（不在 NAS），完全绕开内网穿透。但既然你想用 NAS，就走上面的 frp 路线，把 NAS 当一个需要「探出头」的节点。

### 3.4 备选（免费）：原生 IPv6 + DDNS

1. 光猫/路由开启 IPv6（大多默认开），给 NAS 主机「防火墙放行入站 3000/443」。
2. NAS 上装一个 DDNS 工具（如 `ddns-go`），解析 **AAAA 记录**指向 NAS 的 IPv6 地址。
3. 手机流量直接访问 `https://你的域名/api/health`（域名带 AAAA 记录）。异网偶发不通时，回退用 3.3 的 frp。

---

## 4. 第 ③ 步：域名反代，把 3000 变成 443 的 HTTPS/WSS

这里用 **Nginx Proxy Manager（NPM，图形化，最适合非专业用户）**。它和 app/redis 必须在**同一个 `fms-net` 网络**里，才能用服务名 `app` 访问到 3000。

### 4.1 起一个 NPM 容器（在 NAS 上）

```bash
docker run -d --name npm \
  --network fms-net \
  -p 443:443 -p 80:80 -p 81:81 \
  -v /vol1/docker/npm:/data \
  --restart unless-stopped \
  jc21/nginx-proxy-manager:latest
```

浏览器打开 `http://你的NASIP:81`，默认账号 `admin@example.com` / 密码 `changeme`，**登录后立即改密码**。

### 4.2 添加 Proxy Host（反代规则）

在 NPM 界面：**Hosts → Proxy Hosts → Add Proxy Host**，按下面填：

| 项 | 填什么 |
| --- | --- |
| Domain Names | 你的公网域名，如 `fs.example.com` |
| Forward Hostname / IP | `app`（compose 里 app 的服务名，同网按服务名互访） |
| Forward Port | `3000` |
| Scheme | `http`（HTTPS 由 NPM 终结，后端仍是 http 3000） |
| **Websockets Support** | **打开**（这一项必须开，WSS 心跳长连接全靠它） |
| Block Common Exploits | 打开 |

**再点 Advanced 标签，在 Custom Nginx Configuration 里粘贴这行（必须）**：

```nginx
client_max_body_size 20m;
```

> **为什么必须加**：NPM/nginx 默认 `client_max_body_size` 是 1m，而成员头像上传是 1MB 的 multipart，会触发 **413 Request Entity Too Large**。加 20m 就够（APK 下载是响应流，不受此限制，无需设置）。
>
> **不要**自己再在 Advanced 里加 `Upgrade` / `Connection` / `X-Forwarded-*` 头——NPM 开「Websockets Support」后会自动注入 `proxy_set_header Upgrade $http_upgrade` 等，也默认带 `X-Forwarded-Proto`。后端已配 `server.forward-headers-strategy=framework`，会正确消费它，让生成的 APK 下载地址是 https。

### 4.3 申请 HTTPS 证书（Let's Encrypt）

同一 Proxy Host 的 **SSL 标签页**：勾选 **Request a new SSL certificate** → 填你的域名 → **Force SSL** → HTTP/2 → 提交。NPM 内置 ACME 客户端自动签发并**自动续期**。

> **前提**：Let's Encrypt 走 **HTTP-01 验证**，需要公网**能访问到你的 80 和 443**（域名 A 记录已解析、路由已把 80/443 转发到 NPM）。若你在第 5 章走了香港 VPS + frp 方案，这一步是在 **VPS 上的 NPM** 里做的，域名指向 VPS 的公网 IP 即可（免备案、80/443 可用）。
>
> 若你的宽带确实 80/443 进不来，又不想买 VPS，可退而用第 3.4 章的 IPv6 + 自签证书，或 Cloudflare 前置（走 DNS-01）。

### 4.4 验证反代

```bash
curl https://fs.example.com/api/health      # 应返回 ok
```

手机上能打开 `https://fs.example.com` 说明 HTTPS 通了。WSS 由 App 里 `SERVER_URL=https://...` 自动推导，无需额外配置。

---

## 5. 手机 App 连过来（两步，任选其一）

### 方式 A（最快，无需重新编译）：App 内切换服务器

仓库里的 App **自带「切换服务器」功能**（`AppConfig.switchServer()`，服务器地址会随设置自动推导出 wss）。装好官方 APK 后：在 App 里进入**服务器切换**入口，添加自定义服务器，填 `https://fs.example.com`，点应用即可。家人不用重装，随时可切回官方服务器。

### 方式 B：自己编译一个「默认就指向你家服务器」的 APK（高德完整配置）

> 下面是 README / `docs/SETUP_AMAP.md` 里**整个高德配置过程**，我串成一条龙放进这里，照着做即可。

**第 1 步｜注册高德开放平台 + 实名认证**
打开 <https://lbs.amap.com/>，用高德账号登录。个人开发者做**免费「个人实名认证」**即可满足默认配额（企业认证只在需要更高配额时才需要）。

**第 2 步｜创建应用 + 添加 Android Key**
控制台 → **应用管理 → 我的应用 → 创建新应用**（填应用名）→ 点该应用「**添加 Key**」，弹窗里：

| 项 | 填什么 |
| --- | --- |
| 服务平台 | **Android平台**（别选成 Web 端 / 小程序等） |
| 发布版安全码 SHA1 | 你签名 keystore 的 SHA1（取法见下） |
| PackageName | `com.family.share`（必须与 `android/app/build.gradle` 的 `applicationId` 完全一致） |
| 勾选服务 | **地图（Map）+ 定位（Location）**——一个 Android 平台 Key 天然覆盖地图/定位/搜索，无需分开申请 |

阅读并勾选《高德地图 API 服务条款》→ 提交 → 得到 **32 位 Key**。

> 🔑 **关于 SHA1（关键）**：高德 Key 在运行时会按「**包名 AND 签名 SHA1 双匹配**」校验，两者必须都绑对才生效；否则地图空白/定位失败，Logcat 过滤 `amap` 可见 `INVALID_USER_SCODE`。**调试版与发布版的 SHA1 不同**：
> - 默认用调试签名（`~/.android/debug.keystore`，密码 `android`），Windows 取 SHA1：
>   ```bash
>   keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
>   ```
>   复制输出里 `SHA1:` 那行（形如 `AB:CD:EF:...`）。
> - 若你用**自己的 release keystore** 出包，发布版 SHA1 是另一个值，到控制台再按它添加/更新 Key。

**第 3 步｜把配置写进工程**——编辑 `android/gradle.properties`：

```properties
AMAP_KEY=你的32位高德Key
SERVER_URL=https://fs.example.com
API_TOKEN=和 .env 里的 APP_API_TOKEN 完全一致
```

- `AMAP_KEY` 会在构建时经 `manifestPlaceholders` 自动注入 `AndroidManifest.xml` 的 `com.amap.api.v2.apikey`（该节点已就位），**无需改代码**。
- `SERVER_URL` 决定 App 连到哪台服务器（`https://你的域名`）；`API_TOKEN` **必须和 `.env` 里的 `APP_API_TOKEN` 完全一致**，否则 App 所有 `/api/**`、`/ws` 请求会被服务器拒绝。
- 也可以用命令行覆盖，不改文件：`./gradlew assembleRelease -PAMAP_KEY=xxx -PSERVER_URL=https://fs.example.com -PAPI_TOKEN=xxx`。

**第 4 步｜编译 APK**（需要 JDK 17 + Android SDK / Android Studio）

```bash
cd android
./gradlew assembleRelease
```

产物在 `app/build/outputs/apk/release/app-release.apk`，直接装到家人手机。

**第 5 步｜验证**
- 打开 App：**地图正常显示底图、定位能返回坐标** ⇒ 高德 Key 配好了；
- 家庭里能实时看到彼此位置 ⇒ 连上你的服务器了（`SERVER_URL` + `API_TOKEN` 正确）。

**可选（应用内更新）**：把编译出的 APK **改名为 `app-release.apk`**（必须这个名字，`ApiController` 只认这个），复制进 NAS 的 `fms-downloads` 卷（见 6.3），家人就能在 App 里「检查更新 / 下载」安装。

> **首次使用**：手机 A 建家庭（切到「创建家庭」→ 设昵称 → 得 6 位家庭码）；手机 B 输家庭码申请加入，A 在 ⋮「消息」里同意；两台都授权定位「始终允许」。

---

## 6. 运维：升级、备份、常见坑

### 6.1 改设置 / 重启

改 `.env` 里的 token 后：`cd server && docker compose up -d` 即可生效（容器会重建）。

### 6.2 升级服务端

```bash
cd /vol1/docker/familyshare/server
# （仓库源码更新后）重新拷贝 server/ 覆盖
docker compose up -d --build
```

### 6.3 数据备份

| 数据 | 在哪 | 怎么备份 |
| --- | --- | --- |
| 位置/家庭数据 | Redis 卷 `fms-redis` | 定期备份 NAS 的 docker volume 目录 |
| 成员头像 | 卷 `fms-icons` | 同上 |
| 更新 APK | 卷 `fms-downloads` | 把新 `app-release.apk`（**必须叫这个名**）拷进去即可分发 |
| Bug 反馈 | 容器内 `/app/bugs.json` | 非关键，可忽略 |

> 卷位置：`docker volume inspect fms-redis` 看 `Mountpoint`，在 NAS 上找到后整个目录拷走备份即可。

### 6.4 常见坑速查

1. **`external network "fms-net" not found`** → 忘了 `docker network create fms-net`。
2. **WSS 心跳掉线 / App 连不上** → 反代没开「Websockets Support」。
3. **上传头像报 413** → NPM Advanced 里没加 `client_max_body_size 20m;`。
4. **手机在外连不上、家里 WiFi 却可以** → 公网通路没通（第 5 章：多半是光猫没放行，或走了 CGNAT，走 VPS+frp）。
5. **地图空白 / 定位失败** → 高德 Key 没绑定对包名+SHA1，或服务平台选成了 Web 端（`docs/SETUP_AMAP.md` 第 5 节）。
6. **想 `docker pull family-share-server` 失败** → 不存在这个镜像，必须用 `docker compose up -d --build` 从源码构建。
7. **构建/启动跟 Java 有关报错** → 确认 pom 和 Dockerfile 都是 **17**（别用 25，见文首警告）。

### 6.5 安全建议

- 本项目**无账号体系**：`deviceId` 即身份、6 位家庭码即授权凭证、`API_TOKEN` 是访问口令。请妥善保管。
- 只走 HTTPS/WSS 的话，可把 `network_security_config.xml` 收紧为仅允许你的域名（见 README「安全与免责」）。
- NPM 界面默认账号 `admin@example.com / changeme`，务必改掉。
- 家人手机建议都开启「忽略电池优化」与自启动管理，保证后台持续上报。

---

## 7. 一句话路线图

**香港 VPS（¥30–40/月·免备案） + frp 内网穿透 + 域名（¥50–100/年） + NPM 反代(HTTPS/WSS) + 手机 App 自定义服务器指到你的域名** → 家人异地 4G/5G 也能稳定实时看到彼此位置。

---

> 参考文件：`docs/SETUP_AMAP.md`（高德 Key）、`docs/PROTOCOL.md`（协议）、`server/Dockerfile`、`server/docker-compose.yml`、`server/.env.example`。
> 高德 SDK 下载的 `Lite3DMap_AMapSearch_AMapLocation.zip` 仅与 Android 客户端构建相关，**与本次服务端部署无关**（见第 0 章）。
