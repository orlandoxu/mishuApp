请参考项目根目录下的 claude-code 实现，帮我设计并实现我们自己的 AI 助手核心路由层：AgentRoute。

## 一、项目背景

我们正在开发一个 AI 小助手，但它不是单纯的一问一答聊天产品，而是一个“交互式任务型助手”。

它的整体交互形态，在逻辑上类似 claude-code：
- 用户发起一句自然语言输入
- 系统结合当前上下文、历史状态、任务阶段，判断下一步进入哪个 route / agent
- 必要时主动追问
- 收集参数（slots）
- 在合适的时机请求确认
- 然后驱动后续 skill / tool / action 执行
- 整个过程是多轮的、可推进的，而不是一次问答结束

但和 claude-code 有一个非常重要的区别：

## 二、系统架构特征（非常重要）

我们是 CS 架构，不是本地单机 agent。

- C = Client：手机 App（iOS / Android）
- S = Server：云端 AI 引擎 / AgentRoute / 分析决策中心

也就是说：

1. 用户交互入口在手机 App
2. 多轮会话的主要分析与路由决策发生在云端
3. 客户端主要负责：
   - 展示消息
   - 展示追问
   - 收集用户输入
   - 展示执行中 / 已完成 / 失败等状态
   - 根据服务端返回的结构化结果驱动 UI
4. 服务端主要负责：
   - 意图判断
   - route 决策
   - 会话状态推进
   - slot 收集
   - 是否需要确认
   - 是否可执行
   - 执行前后状态管理
   - tool / skill / action 编排

所以请你设计的 AgentRoute，不要默认它运行在终端 CLI 环境，也不要假设所有上下文都在本地内存里。它必须是一个适合云端服务端运行的、面向移动客户端的交互式路由引擎。

## 三、参考要求

请先阅读项目根目录下的 claude-code，重点参考它在以下方面的设计思想：

- agent 调度
- route / mode 切换
- 多轮任务推进
- 上下文组织
- 工具调用前的决策逻辑
- 中间态处理
- 任务执行过程中的可恢复性
- 交互式而非一次性问答的 runtime 组织方式

但是注意：

- 不要复制 claude-code 的 UI 交互方式
- 不要机械照搬它的命名
- 不要强行复刻它的文件结构
- 不要假设我们是 code agent / CLI agent
- 不要把移动端助手错误地做成命令行工具的变体

我要的是：**借鉴 claude-code 的交互式 agent runtime 思想，但实现一个适合“移动端 App + 云端决策引擎”的 AgentRoute。**

## 四、目标

请实现一个面向云端的 AgentRoute，使其能够：

- 接收用户消息、历史消息、当前 session state、客户端上下文
- 判断当前用户处于哪个任务阶段
- 决定进入哪个 route / agent / mode
- 判断缺少哪些参数
- 必要时发起追问
- 必要时请求确认
- 参数齐备时进入执行态
- 执行结束后进入 completed / failed / fallback 状态
- 能支持多轮连续推进
- 能把结果结构化返回给移动端 UI 使用

## 五、请特别按“客户端 / 服务端分工”来设计

请在方案中明确区分：

### 客户端职责
例如但不限于：
- 展示对话消息
- 展示服务端返回的追问
- 展示候选项、确认框、执行中态
- 持有轻量 UI state
- 把用户输入和客户端上下文上送服务端

### 服务端职责
例如但不限于：
- SessionState 管理
- RouteDecision 计算
- Slot 填充与缺失检测
- Confirmation 判断
- Tool 调用前的 gating
- Execution orchestration
- 异常恢复与回退
- 向客户端返回结构化 UI 指令 / 对话响应数据

请不要把本该在服务端的复杂决策丢给客户端。

## 六、这个任务里最重要的“挑战 / 容易出的问题”

请在设计和实现中重点处理下面这些问题，不要忽略：

### 1. 路由不应只是简单意图分类
不要把 AgentRoute 写成：
- 一个大的 if/else
- 一个纯关键词分类器
- 一个只判 intent、不管任务推进的 router

正确目标应该是：
- Route + State + Slot + Confirmation + Execution 的组合系统
- 更像“交互式状态路由器”，而不是一次性分发器

### 2. 云端状态管理与客户端展示解耦
因为交互在 App 上，决策在云端，所以容易出现：
- 客户端状态和服务端 session 不一致
- 同一条用户输入被重复处理
- 因重试导致重复执行 action
- 客户端 UI 已显示成功，服务端实际失败
- 服务端已进入新阶段，客户端还停留在旧阶段

请设计时考虑：
- session version / turn id / message id
- 幂等处理
- 去重
- 状态推进的一致性

### 3. 多轮交互中的“中间态”非常容易失控
需要明确表达这些状态，而不是模糊处理：
- intent_detected
- collecting_slots
- awaiting_confirmation
- ready_to_execute
- executing
- completed
- failed
- fallback
- cancelled

要特别避免：
- 状态跳变混乱
- 缺参数时直接执行
- 用户已经确认却没有进入执行
- 执行完成后 session 没有正确收尾
- 一个 route 处理到一半，被另一个 route 粗暴覆盖

### 4. Slot 收集不是一次性的
用户可能：
- 一次把参数说全
- 只说一部分
- 中途修改前面说过的参数
- 否认之前的确认
- 改口
- 说模糊值（比如“明天下午”“那个张总”“晚点提醒我”）

请支持：
- 增量填槽
- 槽位覆盖
- 缺失槽位追问
- 低置信度候选
- 模糊值待确认

### 5. 执行与路由要解耦
AgentRoute 不应该直接塞满业务执行细节。
它应该负责：
- 决策
- 判断
- 推进
- 组织执行条件

具体 skill / tool / action 执行逻辑应分离。

### 6. 移动端产品不是 CLI
claude-code 中某些交互思路可以借鉴，但请不要做成：
- 命令式输入优先
- 终端日志式输出
- 本地同步阻塞式流程
- 假设用户能接受非常技术化的过程展示

移动端更适合：
- 结构化响应
- 可驱动 UI 的返回
- 明确的 step / status / prompt
- 可恢复、可继续的 session

### 7. 失败恢复与重试
请考虑：
- tool 超时
- 外部服务失败
- 参数解析失败
- 用户取消
- 客户端断线重连
- 服务端重试
- 网络重复提交

需要考虑：
- 哪些动作可重试
- 哪些动作必须防重
- 哪些错误应该回到 collecting_slots
- 哪些错误应该进入 failed
- 哪些错误应该要求再次确认

### 8. 新 route / 新 skill 扩展性
我们未来会持续加 route 和 skill。
所以设计不能把所有东西耦合死在一个类里。
需要有清晰的扩展点，但也不要过度抽象。

### 9. 服务端分析结果要可直接驱动客户端
服务端不能只返回一句自然语言。
更理想的是返回类似这种结构化结果：

- 当前 route
- 当前阶段
- 是否需要用户继续输入
- 追问文案
- 缺失槽位
- 是否需要确认
- 是否可执行
- 客户端推荐展示形态（纯文本 / 候选项 / 确认框 / loading / success / error）

### 10. 不要默认一次就能做完
这个任务很可能比较复杂，可能不能一次性完全做对。
因此请你在输出中考虑“如何分阶段落地”，让 Codex 可以多轮迭代把它做出来，而不是第一轮就试图写一个巨大但不可靠的系统。

## 七、我希望你输出的内容

请不要只做高层分析，我要的是“可落地方案 + 代码”。

至少输出以下内容：

1. AgentRoute 的职责定义
2. 客户端 / 服务端职责边界
3. 核心数据结构设计
4. SessionState 设计
5. RouteDecision 设计
6. 状态流转设计
7. slot 收集机制
8. confirmation 机制
9. execution orchestration 设计
10. TypeScript 代码骨架
11. 最小可运行版本
12. 后续扩展方式
13. 哪些点借鉴了 claude-code，哪些点根据移动端云端场景做了调整

## 八、代码要求

请使用 TypeScript 输出代码。

要求：
- 不要只给伪代码
- 尽量直接可用
- 不要过度抽象
- 不要为了“架构好看”牺牲可落地性
- 不要把所有逻辑堆进一个文件
- 不要把 route 决策和具体执行混在一起
- 保持模块边界清晰
- 命名要贴近我们的产品，而不是机械沿用 claude-code

## 九、建议实现的代码结构

你可以按需调整，但建议至少拆成类似这些模块：

- agent-route/types.ts
- agent-route/AgentRoute.ts
- agent-route/routeMatcher.ts
- agent-route/sessionState.ts
- agent-route/slotCollector.ts
- agent-route/confirmation.ts
- agent-route/execution.ts
- agent-route/responseBuilder.ts
- agent-route/builtinRoutes/chatRoute.ts
- agent-route/builtinRoutes/reminderRoute.ts
- agent-route/builtinRoutes/contactRoute.ts
- agent-route/builtinRoutes/taskRoute.ts

如果你认为更好的目录结构更适合，也可以调整，但请保持清晰。

## 十、最小状态模型要求

至少支持这些状态：

- intent_detected
- collecting_slots
- awaiting_confirmation
- ready_to_execute
- executing
- completed
- failed
- fallback
- cancelled

并明确每个状态下：
- 允许的输入
- 输出内容
- 是否可进入执行
- 是否需要客户端继续交互
- 是否允许回退 / 改口 / 覆盖 slots

## 十一、请给出结构化响应模型

因为客户端在 App 上，所以请给出服务端返回给客户端的结构模型，例如但不限于：

- message
- route
- phase
- missingSlots
- filledSlots
- askUser
- confirmation
- executable
- uiHints
- actions
- error

请把它设计成可直接驱动移动端 UI 的形式，而不是只有自然语言文案。

## 十二、内置 route 示例要求

请至少给出以下 route 的接入示例：

- chat
- reminder
- contact
- task

并演示：
- 如何声明 route
- 如何定义 slots
- 如何判断是否缺失参数
- 如何生成追问
- 如何进入确认
- 如何触发执行
- 如何返回客户端结构化结果

## 十三、关于 Codex 的工作方式：请按“可分阶段提交”的方式输出

这个任务可能一次做不完，请不要试图第一轮就生成一个庞大而脆弱的系统。

请把实现过程拆成“多轮可推进”的阶段，并明确每一阶段应该产出什么。

例如你可以按类似方式拆分：

### Phase 1
只完成：
- types
- SessionState
- RouteDecision
- 最小 AgentRoute 主入口
- routeMatcher
- 一个最小 chatRoute

目标：
- 先跑通最基础的 route 决策链路

### Phase 2
增加：
- slotCollector
- reminderRoute / contactRoute / taskRoute
- 追问机制
- missing slots 检测

目标：
- 跑通 collecting_slots 流程

### Phase 3
增加：
- confirmation
- ready_to_execute
- execution orchestration

目标：
- 跑通“收集参数 -> 请求确认 -> 执行”

### Phase 4
增加：
- failed / fallback / cancelled
- 幂等、防重、状态恢复
- responseBuilder
- 面向客户端 UI 的结构化返回

目标：
- 系统接近可接入真实 App

### Phase 5
增加：
- 扩展机制
- 测试样例
- 更完整的 route 插件化方式
- 更接近生产可用的代码整理

请在输出时，直接按照这种“可持续多轮推进”的模式组织答案。

## 十四、请特别避免以下常见错误

请不要产出下面这些我不想要的结果：

1. 只分析 claude-code，不落地到我们项目
2. 只给概念图，不给 TypeScript 代码
3. 写成一个巨大无边界的 AgentRoute 类
4. 只做 intent classifier，没有状态推进
5. 忽略客户端 / 服务端职责边界
6. 忽略幂等、防重、重复提交、断线重连
7. 把移动端交互写成 CLI 风格
8. 过度抽象，导致第一轮代码根本接不进去
9. 路由和执行强耦合，后面无法扩展
10. 不考虑这个任务需要多轮迭代完成

## 十五、最终输出要求

请先阅读并参考根目录下的 claude-code，再直接输出：

1. 适合我们场景的总体方案
2. 与 claude-code 的借鉴点 / 差异点
3. 分阶段落地计划
4. 第一阶段应提交的 TypeScript 代码
5. 后续每一阶段应如何继续推进

请不要停留在高层分析。
请把 claude-code 的思路翻译成“适合移动端 App + 云端 AI 路由引擎”的实际实现。
请优先保证第一阶段代码真实可落地、可继续迭代。

注意，AgentRoute的文件夹我已经搞好了，在backend/agentRoute