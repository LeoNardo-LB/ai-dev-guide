# 栈档案范例（Kotlin / Android）

> ⚠️ 本文件是 [./stack-profile.md](./stack-profile.md) 的**填写范例**，仅作参考，新项目按需裁剪。
> 展示一份已填充的栈档案：事实、精确命令、红线标注；新项目复制 stack-profile.md 填空，不复制本文件内容。

## Use when

- 参考「如何填充 stack-profile.md」、不确定某类栈事实应写多具体时
- 需要 Android / Kotlin 栈的构建命令与红线示例时

## 1. 语言与运行时

| 项 | 内容 | 真相源 |
|----|------|--------|
| 语言/版本 | Kotlin（版本不在此复制，以构建文件为准） | `<构建文件>`（如 `app/build.gradle.kts`） |
| 工具链约束 | ⚠ JDK 21：`jvmToolchain(21)` + `JavaVersion.VERSION_21`；本地构建在 `gradle.properties` 设 `org.gradle.java.home` | `<构建文件>` / `gradle.properties` |
| 平台 | Android（minSdk / targetSdk / compileSdk 以 `defaultConfig` 为真相源） | `<构建文件>` |

## 2. UI 框架

| 项 | 内容 |
|----|------|
| 框架/组件库 | Jetpack Compose + Material 3，Compose BOM 管理版本；**优先原生组件，禁止引入额外 UI 依赖库**（UI 规范见 [../standards/ui-conventions.md](../standards/ui-conventions.md)） |
| 主题系统 | 设计令牌系统：`ui/theme/` 下的 Alpha / Spacing / Shape / Motion / Button / ListItem tokens |

## 3. 架构范式

| 项 | 内容 |
|----|------|
| 分层 | Clean Architecture 三层，**依赖方向：UI → Domain ← Data**（承重规则见 [../standards/architecture.md](../standards/architecture.md)） |
| UseCase 层 | ViewModel 调用 UseCase（`domain/usecase/`），不直接调 API；Repository 接口在 `domain/repository/`，实现与 API/DB 在 `data/` |
| DI | Hilt + **KSP**（非 kapt）；Hilt 模块位于 `di/` |
| 状态管理 | 状态单一真相源：服务持有 `statusFlow`/`activityFlow`，所有写入经纯函数 FSM（见 §10 模式 1） |

## 4. 网络与数据

| 项 | 内容 |
|----|------|
| HTTP/事件流 | Ktor Client，⚠ **OkHttp engine**（正确支持 SSE 流式传输，引擎选择是承重决策，禁止换引擎）；事件流走 SSE，终端类流走 WebSocket |
| 本地存储 | Room（消息缓存 / 日志）+ DataStore Preferences（偏好设置） |
| 序列化 | kotlinx.serialization（JSON） |

## 5. 构建与打包

```
./gradlew :app:compileDevDebugKotlin        # 编译检查（快速反馈），超时 120s
./gradlew :app:testDevDebugUnitTest --rerun # 单元测试（强制重跑防 UP-TO-DATE 跳过），超时 180s
./gradlew :app:assembleDevDebug             # 完整构建（单任务），超时 300s
```

| 项 | 内容 |
|----|------|
| 多环境/多包 | product flavors：`dev` / `beta` / `stable` 三通道，独立 `<包名>` 后缀可共存安装；flavor 名按项目裁剪 |
| 单任务构建纪律 | ⚠ 默认只跑**单个 flavor 的单个 assemble 任务**（`assemble<Flavor><BuildType>`），产出该 flavor 一个 APK；多任务仅用于同时出多包 |
| 产物输出 | `<项目名>-<版本>.apk`，按 `outputs/apk/<flavor>/<buildType>/` 分目录 |
| 禁止事项 | 无超时裸跑长时间构建；版本号修改前构建（版本规则见 [../workflows/release.md](../workflows/release.md)） |

## 6. 测试栈

| 层 | 框架 | 位置 |
|----|------|------|
| 单元 | JUnit 4 + MockK + Turbine + kotlinx-coroutines-test（版本以 `<构建文件>` 为准） | `<src/test/>` |
| 集成/插桩 | HiltTestRunner + `createComposeRule()` | `<src/androidTest/>` |
| UI/E2E | Maestro YAML 流程 | `<maestro/ 或 e2e/>` |

> ⚠ 单测配置 `isReturnDefaultValues = true` 时 mock 返回默认值而非抛异常，可能掩盖 bug——断言必须显式写出。各层覆盖要求见 [../standards/test-strategy.md](../standards/test-strategy.md)。

## 7. 签名与发布

| 项 | 内容 |
|----|------|
| 密钥/证书 | ⚠ release keystore 位于 `<keystore 目录>`，密码在 `<signing 配置>`（不进 git）；配置存在 → 用 release keystore，不存在 → 回退 debug 签名（**禁止无条件覆盖为 debug**，否则 release keystore 永不生效） |
| CI Secrets | ⚠ CI 用 Secrets 注入 keystore（base64 + alias + password）；**Secrets 未配置时 CI 回退 debug 签名**，每次全新 runner 生成不同 debug.keystore → 每次发版签名不同 → 用户升级报「已安装签名冲突」 |
| 发布渠道 | GitHub Release / 应用商店（按项目定） |
| 发布验证 | ⚠ 发版后必须用 `<签名证书校验命令>` 验证产物为 release 证书（非 `CN=Android Debug`）；发版流程见 [../workflows/release.md](../workflows/release.md) |

## 8. 平台与网络约束

| 项 | 内容 |
|----|------|
| 网络/代理 | ⚠ `<构建文件>`（gradle.properties）硬编码 `<代理地址>`；代理不可达时构建失败，无代理构建需注释 `systemProp.*` 配置 |
| 环境依赖 | 模拟器访问宿主机：`10.0.2.2`；服务地址与端口按项目配置 |

## 9. 本项目红线补充

> 把 AGENTS.md 内联红线背后的栈事实补在这里（示例）：

| 红线 | 栈事实 |
|------|--------|
| SSE 引擎 | Ktor 只用 OkHttp engine（SSE 流式传输的正确支持），不换引擎 |
| 日志门面 | 统一日志门面（如 `AppLogger.i/w/e`），新代码不用平台 Log API，日志进应用内诊断屏 |
| 导航参数 | 路径/URL 参数用安全解码工具（容错畸形 `%` 序列），不用裸 `URLDecoder.decode()` |
| 跨平台路径 | 远程路径（`/` 与 `\`）统一用跨平台路径工具；JDK `File.name`/`Path.of` 只识别 `/` |

## 10. 可复用工程模式（从 oc-beacon 提炼，示例）

| # | 模式 | 说明 | 反例 |
|---|------|------|------|
| 1 | 状态单一真相源 + 纯函数 FSM | 会话/流式状态由一个服务持有流，所有状态写入经纯函数 FSM（穷举转移矩阵）；禁止按 handler 各自维护状态 | 按 handler 维护的状态管理器（已被移除） |
| 2 | 统一日志门面 | 全局日志门面（Channel → 持久化，崩溃捕获，脱敏），日志出现在应用内诊断屏 | `android.util.Log` 散落调用 |
| 3 | 安全解码 | URL/导航参数安全解码，容错畸形编码序列 | 裸 `URLDecoder.decode()` 遇 `%NR` 崩溃 |
| 4 | 跨平台路径工具 | 统一封装文件名/父目录/相对路径，兼容 `/` 与 `\` | `File(name)`、`substringAfterLast('/')` |
| 5 | 流式管线批处理 | SSE 流式管线：固定时间窗批处理 token → 高度补偿 → 渲染；不取消进行中的定时器 | 每个 token 取消定时器 → 高频下饿死 flush → 卡顿 |

> 模式提炼自 oc-beacon 的架构文档与 AGENTS.md 承重规则；新项目按需裁剪，非必选清单。

## Related

- 模板本体与填写规则：[./stack-profile.md](./stack-profile.md)
- 架构承重规则：[../standards/architecture.md](../standards/architecture.md)
- 测试各层定义：[../standards/test-strategy.md](../standards/test-strategy.md)
- 发版流程：[../workflows/release.md](../workflows/release.md)
- UI 规范：[../standards/ui-conventions.md](../standards/ui-conventions.md)