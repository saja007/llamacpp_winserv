# llamacpp_winserv
deploy a simple service on windows


# 🚀 llama.cpp 模型部署工具（Windows）

> 一键部署 Qwen3 Embedding / Reranker 模型为本地服务  
> 支持 **测试运行** 或 **安装为 Windows 系统服务**，开机自启，无需手动操作！

本工具专为在 **Windows 环境**下快速部署 `llama.cpp` 的 Embedding 或 Reranker 模型（如 `qwen3-embedding-0.6b`、`qwen3-reranker-0.6b`）而设计，特别适合搭配 [Dify](https://github.com/langgenius/dify)、[AnythingLLM](https://github.com/Mintplex-Labs/anything-llm) 等 RAG 应用使用。

---

## ✅ 功能特性

- 🖱️ **图形化选择模型文件**（支持任意目录，如 `Models/`）
- 🔍 **自动检测端口占用**，避免启动冲突
- 🧪 **测试运行模式**：前台启动，方便调试
- ⚙️ **安装为 Windows 服务**：支持自定义服务名，开机自启
- 💾 **低资源占用**：0.6B 模型仅需 ~800MB 内存
- 📦 **开箱即用**：只需双击 `.bat` 文件，无需编程知识

---

## 📁 推荐目录结构

```
llama.cpp/
├── bin/
│   ├── llama-server.exe          ← llama.cpp 官方预编译文件
│   ├── nssm.exe                  ← (可选) 用于安装服务
│   ├── deploy_llama_single.ps1   ← 本工具主脚本
│   └── Start_Deploy.bat          ← 启动器（双击运行）
└── Models/
    ├── qwen3-embedding-0.6b-Q4_K_M.gguf
    └── qwen3-reranker-0.6b-Q4_K_M.gguf
```

> 💡 模型文件可放在任意位置（不限于 `Models/`），通过对话框选择即可。

---

## 🛠️ 使用步骤

### 1. 准备工作

- 下载 [llama.cpp Windows 预编译版](https://github.com/ggerganov/llama.cpp/releases)（含 `llama-server.exe`）
- 下载 Qwen3 GGUF 模型（推荐 `Q4_K_M` 量化）：
  - [Qwen3-Embedding-0.6B-GGUF](https://huggingface.co/Qwen/Qwen3-Embedding-0.6B-GGUF)
  - [Qwen3-Reranker-0.6B-GGUF](https://huggingface.co/Qwen/Qwen3-Reranker-0.6B-GGUF)
- （可选）下载 [NSSM](https://nssm.cc/download) 并将 `nssm.exe` 放入 `bin/` 目录，或将其加入系统 `PATH`

### 2. 运行部署工具

- 解压 `DeployPackage.zip` 文件到 `llama.cpp` 目录
- 双击 `Start_Deploy.bat`
- 在弹出窗口中选择你的 `.gguf` 模型文件
- 输入希望监听的端口号（默认 `8080`，会自动检测是否被占用）
- 选择操作模式：
  - **1 → 测试运行**：临时启动服务（按 `Ctrl+C` 停止）
  - **2 → 安装为服务**：以管理员身份运行后，可设置服务名并安装为系统服务

### 3. 验证服务

- 访问 `http://localhost:你的端口/docs` 查看 OpenAI 兼容 API 文档
- 在 Dify 中配置 Embedding/Reranker 模型时，填写：
  - **Base URL**: `http://localhost:端口/v1`
  - **API Key**: 任意填写（如 `dummy`）
- Dify 如果是配置在 Docker Desktop中时，访问宿主提供的接口，请填写URL： `http://host.docker.internal:端口/v1 `



---

## ⚙️ 安装为系统服务说明

- 安装服务时会提示输入 **服务名称**（只能包含字母、数字、下划线，长度 1–24）
- 默认名称示例：`llama_qwen3_reranker_0`
- 服务安装后会**自动启动**，并设置为**开机自启**
- 管理服务：按 `Win+R` → 输入 `services.msc` → 搜索你的服务名

> 🔒 注意：安装服务必须 **以管理员身份运行** `Start_Deploy.bat`！

---

## ❓ 常见问题

### Q: 双击 `.ps1` 文件打不开？

A: 请始终通过 `Start_Deploy.bat` 启动，它会自动处理 PowerShell 执行策略。

### Q: 提示“找不到模型文件”？

A: 确保在服务安装时，`bin/` 目录被设为工作目录（本工具已自动处理）。如果手动配置 NSSM，请检查 **AppDirectory** 是否指向 `bin/`。

### Q: 如何卸载已安装的服务？

A: 以管理员身份运行 PowerShell，执行：

```powershell
nssm remove 你的服务名
```

### Q: 如何修改已安装的服务？

A: 以管理员身份运行 PowerShell，执行：

```powershell
nssm edit 你的服务名
```

### Q: 能同时部署 Embedding 和 Reranker 吗？

A: 可以！复制两份llama.cpp分别运行两次本工具：

- 第一次：选择 embedding 模型，端口 `8080`
- 第二次：选择 reranker 模型，端口 `8081`

---

## 📜 许可证

本工具脚本基于 MIT 许可发布，可自由使用、修改和分发。

> `llama.cpp` 和 Qwen3 模型的许可证请参考其官方仓库。

---

## 🙏 致谢

- [llama.cpp](https://github.com/ggerganov/llama.cpp) — 高性能 CPU 推理引擎  
- [NSSM](https://nssm.cc) — 非吸服务管理器，让 Windows 服务更简单  
- [Qwen](https://qwen.ai) — 阿里通义千问团队开源的 Embedding & Reranker 模型

---

> 💡 **提示**：本工具仅用于本地私有化部署，不收集任何用户数据。  
> 如有建议或问题，欢迎提交 Issue 或 PR！

---

将此 `README.md` 放在 `llama.cpp/bin/` 目录下，用户即可快速上手！
