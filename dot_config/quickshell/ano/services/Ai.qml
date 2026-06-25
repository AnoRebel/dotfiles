pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import qs.services.ai
import Quickshell
import Quickshell.Io
import QtQuick

/**
 * AI chat service. Supports OpenAI-compatible, Gemini, and Anthropic API formats.
 * Manages messages, models, API keys, temperature, system prompts,
 * chat save/load, and streaming responses.
 */
Singleton {
    id: root

    readonly property string interfaceRole: "interface"
    property Component messageComponent: AiMessageData {}

    // State
    property var messageIDs: []
    property var messageByID: ({})
    property bool pendingRequest: false
    property string pendingFilePath: ""
    property real temperature: Config.options?.ai?.temperature ?? 0.5
    property string currentModelId: Config.options?.ai?.defaultModel ?? ""
    property var apiKeys: ({})
    property string systemPrompt: Config.options?.ai?.systemPrompt ?? "You are a helpful assistant integrated into a Linux desktop shell called Ano."
    property QtObject tokenCount: QtObject { property int input: -1; property int output: -1; property int total: -1 }

    // Models — loaded from config
    property var models: Config.options?.ai?.models ?? ({
        "gemini-2.5-flash": {
            "name": "Gemini 2.5 Flash", "icon": "neurology",
            "endpoint": "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:streamGenerateContent?alt=sse",
            "model": "gemini-2.5-flash", "api_format": "gemini",
            "requires_key": true, "key_id": "google_gemini",
            "key_get_link": "https://aistudio.google.com/apikey",
            "description": "Google's fast & capable model"
        },
        "gpt-4.1-mini": {
            "name": "GPT-4.1 Mini", "icon": "neurology",
            "endpoint": "https://api.openai.com/v1/chat/completions",
            "model": "gpt-4.1-mini", "api_format": "openai",
            "requires_key": true, "key_id": "openai",
            "key_get_link": "https://platform.openai.com/api-keys",
            "description": "OpenAI's fast model"
        },
        "claude-sonnet-4": {
            "name": "Claude Sonnet 4", "icon": "neurology",
            "endpoint": "https://api.anthropic.com/v1/messages",
            "model": "claude-sonnet-4-20250514", "api_format": "anthropic",
            "requires_key": true, "key_id": "anthropic",
            "key_get_link": "https://console.anthropic.com/settings/keys",
            "description": "Anthropic's balanced model"
        },
        "claude-haiku-3.5": {
            "name": "Claude 3.5 Haiku", "icon": "neurology",
            "endpoint": "https://api.anthropic.com/v1/messages",
            "model": "claude-3-5-haiku-20241022", "api_format": "anthropic",
            "requires_key": true, "key_id": "anthropic",
            "key_get_link": "https://console.anthropic.com/settings/keys",
            "description": "Anthropic's fast & cheap model"
        },
        "gemini-3-flash": {
            "name": "Gemini 3 Flash Preview", "icon": "neurology",
            "endpoint": "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:streamGenerateContent?alt=sse",
            "model": "gemini-3-flash-preview", "api_format": "gemini",
            "requires_key": true, "key_id": "google_gemini",
            "key_get_link": "https://aistudio.google.com/apikey",
            "description": "Google's pro-level intelligence at Flash speed"
        },
        "mistral-medium-3": {
            "name": "Mistral Medium 3", "icon": "neurology",
            "endpoint": "https://api.mistral.ai/v1/chat/completions",
            "model": "mistral-medium-2505", "api_format": "openai",
            "requires_key": true, "key_id": "mistral",
            "key_get_link": "https://console.mistral.ai/api-keys",
            "description": "Mistral's fast, well-formatted model"
        }
    })

    // Dynamic model loading: OpenRouter free models + Ollama local models
    property bool _ollamaChecked: false
    property bool _openrouterChecked: false

    function addModel(id, modelDef) {
        const m = Object.assign({}, models)
        m[id] = modelDef
        models = m
    }

    function safeModelName(name) {
        return (name || "unknown").replace(/[^a-zA-Z0-9_\-\.\/]/g, "_").toLowerCase()
    }

    // Load Ollama local models on startup
    Process {
        id: getOllamaModels
        running: false
        command: ["bash", "-c", "curl -s http://localhost:11434/api/tags 2>/dev/null || echo '{}'"]
        stdout: StdioCollector {
            id: ollamaCollector
            onStreamFinished: {
                try {
                    const data = JSON.parse(ollamaCollector.text)
                    const ollamaModels = data.models ?? []
                    for (const m of ollamaModels) {
                        const id = root.safeModelName(`ollama/${m.name}`)
                        root.addModel(id, {
                            "name": `Ollama: ${m.name}`, "icon": "neurology",
                            "endpoint": "http://localhost:11434/v1/chat/completions",
                            "model": m.name, "api_format": "openai",
                            "requires_key": false, "key_id": "",
                            "description": `Local • ${(m.size / 1e9).toFixed(1)}GB • ${m.details?.family ?? "unknown"}`
                        })
                    }
                    if (ollamaModels.length > 0) root._log(`Loaded ${ollamaModels.length} Ollama models`)
                } catch (e) {}
                root._ollamaChecked = true
            }
        }
    }

    // Load OpenRouter free models on startup
    Process {
        id: getOpenRouterModels
        running: false
        command: ["bash", "-c", "curl -s 'https://openrouter.ai/api/v1/models' 2>/dev/null || echo '{}'"]
        stdout: StdioCollector {
            id: orCollector
            onStreamFinished: {
                try {
                    const data = JSON.parse(orCollector.text)
                    const freeModels = (data.data ?? []).filter(m =>
                        m.pricing && parseFloat(m.pricing.prompt ?? "1") === 0 && parseFloat(m.pricing.completion ?? "1") === 0
                    ).slice(0, 10) // Limit to 10 free models
                    for (const m of freeModels) {
                        const id = root.safeModelName(`or/${m.id}`)
                        root.addModel(id, {
                            "name": `OR: ${m.name ?? m.id}`, "icon": "neurology",
                            "endpoint": "https://openrouter.ai/api/v1/chat/completions",
                            "model": m.id, "api_format": "openai",
                            "requires_key": true, "key_id": "openrouter",
                            "key_get_link": "https://openrouter.ai/keys",
                            "description": `Free via OpenRouter • ${m.context_length ?? "?"} ctx`
                        })
                    }
                    if (freeModels.length > 0) root._log(`Loaded ${freeModels.length} OpenRouter free models`)
                } catch (e) {}
                root._openrouterChecked = true
            }
        }
    }

    function _log(msg) { if (Quickshell.env("QS_DEBUG") === "1") console.log("[Ai] " + msg) }

    // Also load user-defined extra models from config
    Connections {
        target: Config
        function onReadyChanged() {
            if (!Config.ready) return
            // Load extra models from config
            const extraModels = Config.options?.ai?.extraModels ?? []
            for (const m of extraModels) {
                const id = root.safeModelName(m.model ?? m.name ?? "custom")
                root.addModel(id, m)
            }
            // Try loading Ollama and OpenRouter
            getOllamaModels.running = true
            getOpenRouterModels.running = true
        }
    }

    property var modelList: Object.keys(models)

    readonly property bool currentModelHasApiKey: {
        const model = models[currentModelId]
        if (!model || !model.requires_key) return true
        const key = apiKeys[model.key_id]
        return (key?.length > 0)
    }

    function idForMessage() { return Date.now().toString(36) + Math.random().toString(36).substr(2, 8) }

    // Message management
    function addMessage(content, role, model) {
        const id = idForMessage()
        const msg = messageComponent.createObject(root, {
            role: role ?? interfaceRole, content: content, model: model ?? currentModelId, done: true
        })
        messageByID[id] = msg
        messageIDs = [...messageIDs, id]
        return id
    }

    function removeMessage(index) {
        if (index < 0 || index >= messageIDs.length) return
        const id = messageIDs[index]
        messageIDs = messageIDs.filter((_, i) => i !== index)
        delete messageByID[id]
    }

    function clearMessages() {
        messageIDs = []
        messageByID = ({})
        tokenCount.input = -1; tokenCount.output = -1; tokenCount.total = -1
    }

    // Model/key management
    function setModel(modelId) {
        if (!models[modelId]) { addMessage(`Unknown model: ${modelId}`, interfaceRole); return }
        currentModelId = modelId
        addMessage(`Model set to: ${models[modelId].name}`, interfaceRole)
    }

    function getModel() { return models[currentModelId] ?? null }

    function setApiKey(key) {
        const model = models[currentModelId]
        if (!model) { addMessage("No model selected", interfaceRole); return }
        apiKeys[model.key_id] = key
        // Persist
        const keysPath = `${Directories.config}/quickshell/ano/api_keys.json`
        keysSaveProc.exec(["bash", "-c", `echo '${JSON.stringify(apiKeys)}' > '${keysPath}'`])
        addMessage("API key saved", interfaceRole)
    }

    function printApiKey() {
        const model = models[currentModelId]
        if (!model) { addMessage("No model selected", interfaceRole); return }
        const key = apiKeys[model.key_id] ?? ""
        addMessage(key.length > 0 ? `Key: ${key.substring(0, 8)}...` : "No API key set", interfaceRole)
    }

    function setTemperature(value) {
        temperature = Math.max(0, Math.min(2, parseFloat(value)))
        addMessage(`Temperature set to: ${temperature.toFixed(1)}`, interfaceRole)
    }

    function printTemperature() { addMessage(`Temperature: ${temperature.toFixed(1)}`, interfaceRole) }
    function printPrompt() { addMessage(`System prompt:\n${systemPrompt}`, interfaceRole) }

    function loadPrompt(promptText) {
        systemPrompt = promptText
        addMessage(`System prompt updated (${promptText.length} chars)`, interfaceRole)
    }

    function attachFile(filePath) {
        pendingFilePath = filePath ?? ""
        if (pendingFilePath.length > 0) addMessage(`File attached: ${FileUtils.fileNameForPath(pendingFilePath)}`, interfaceRole)
    }

    // Chat save/load
    property string chatSavePath: `${Directories.cache}/anoshell/ai_chats`

    function saveChat(name) {
        const data = messageIDs.map(id => {
            const msg = messageByID[id]
            return { role: msg.role, content: msg.content, model: msg.model }
        })
        const path = `${chatSavePath}/${name}.json`
        chatSaveProc.exec(["bash", "-c", `mkdir -p '${chatSavePath}' && echo '${JSON.stringify(data).replace(/'/g, "'\\''")}' > '${path}'`])
        addMessage(`Chat saved as: ${name}`, interfaceRole)
    }

    function loadChat(name) {
        const path = `${chatSavePath}/${name}.json`
        chatLoadProc.exec(["cat", path])
    }

    Process { id: keysSaveProc }
    Process { id: chatSaveProc }
    Process {
        id: chatLoadProc
        stdout: StdioCollector {
            id: chatLoadCollector
            onStreamFinished: {
                try {
                    const data = JSON.parse(chatLoadCollector.text)
                    root.clearMessages()
                    data.forEach(msg => root.addMessage(msg.content, msg.role, msg.model))
                    root.addMessage("Chat loaded", root.interfaceRole)
                } catch (e) { root.addMessage(`Failed to load chat: ${e.message}`, root.interfaceRole) }
            }
        }
    }

    // Send user message
    function sendUserMessage(text) {
        if (pendingRequest) return
        if (!currentModelId || !models[currentModelId]) { addMessage("No model selected. Use /model MODEL_ID", interfaceRole); return }
        if (!currentModelHasApiKey) { addMessage("No API key. Use /key YOUR_API_KEY", interfaceRole); return }

        addMessage(text, "user")

        const model = models[currentModelId]
        const assistantId = idForMessage()
        const assistantMsg = messageComponent.createObject(root, {
            role: "assistant", content: "", model: currentModelId, done: false
        })
        messageByID[assistantId] = assistantMsg
        messageIDs = [...messageIDs, assistantId]

        pendingRequest = true

        if (model.api_format === "gemini") sendGemini(model, assistantId)
        else if (model.api_format === "anthropic") sendAnthropic(model, assistantId)
        else sendOpenAI(model, assistantId)
    }

    function regenerate(index) {
        if (index < 0 || index >= messageIDs.length) return
        // Remove from index onward, re-send the last user message
        const lastUserMsg = messageIDs.slice(0, index).reverse().find(id => messageByID[id]?.role === "user")
        if (!lastUserMsg) return
        const userContent = messageByID[lastUserMsg].content
        messageIDs = messageIDs.slice(0, index)
        sendUserMessage(userContent)
    }

    // Build conversation history for API
    function buildMessages() {
        const msgs = []
        if (systemPrompt.length > 0) msgs.push({ role: "system", content: systemPrompt })
        messageIDs.forEach(id => {
            const msg = messageByID[id]
            if (!msg || msg.role === interfaceRole) return
            if (!msg.done && msg.role === "assistant") return
            msgs.push({ role: msg.role, content: msg.content })
        })
        return msgs
    }

    // OpenAI-compatible API
    function sendOpenAI(model, assistantId) {
        const apiKey = apiKeys[model.key_id] ?? ""
        const msgs = buildMessages()
        // QML's JS engine doesn't support object-spread, so merge with
        // Object.assign — base fields first, then extraParams overrides.
        const body = JSON.stringify(Object.assign({
            model: model.model,
            messages: msgs,
            temperature: temperature,
            stream: true,
        }, model.extraParams || {}))

        openaiProc.environment = { API_KEY: apiKey, ENDPOINT: model.endpoint, BODY: body }
        openaiProc.assistantId = assistantId
        openaiProc.running = true
    }

    Process {
        id: openaiProc
        property string assistantId: ""
        command: ["bash", "-c", `curl -sN "$ENDPOINT" -H "Content-Type: application/json" -H "Authorization: Bearer $API_KEY" -d "$BODY"`]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                if (!line.startsWith("data: ")) return
                const json = line.substring(6).trim()
                if (json === "[DONE]") return
                try {
                    const data = JSON.parse(json)
                    const delta = data.choices?.[0]?.delta?.content ?? ""
                    const msg = root.messageByID[openaiProc.assistantId]
                    if (msg) msg.content += delta
                    if (data.usage) {
                        root.tokenCount.input = data.usage.prompt_tokens ?? -1
                        root.tokenCount.output = data.usage.completion_tokens ?? -1
                        root.tokenCount.total = data.usage.total_tokens ?? -1
                    }
                } catch (e) {}
            }
        }
        onExited: (exitCode, exitStatus) => {
            const msg = root.messageByID[openaiProc.assistantId]
            if (msg) msg.done = true
            root.pendingRequest = false
        }
    }

    // Gemini API
    function sendGemini(model, assistantId) {
        const apiKey = apiKeys[model.key_id] ?? ""
        const msgs = buildMessages()
        const contents = msgs.filter(m => m.role !== "system").map(m => ({
            role: m.role === "assistant" ? "model" : "user",
            parts: [{ text: m.content }]
        }))
        const body = { contents, generationConfig: { temperature } }
        const systemInstruction = msgs.find(m => m.role === "system")
        if (systemInstruction) body.system_instruction = { parts: [{ text: systemInstruction.content }] }

        const endpoint = model.endpoint.includes("?")
            ? `${model.endpoint}&key=${apiKey}`
            : `${model.endpoint}?key=${apiKey}`

        geminiProc.environment = { ENDPOINT: endpoint, BODY: JSON.stringify(body) }
        geminiProc.assistantId = assistantId
        geminiProc.running = true
    }

    Process {
        id: geminiProc
        property string assistantId: ""
        command: ["bash", "-c", `curl -sN "$ENDPOINT" -H "Content-Type: application/json" -d "$BODY"`]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                if (!line.startsWith("data: ")) return
                const json = line.substring(6).trim()
                try {
                    const data = JSON.parse(json)
                    const parts = data.candidates?.[0]?.content?.parts ?? []
                    const text = parts.map(p => p.text ?? "").join("")
                    const msg = root.messageByID[geminiProc.assistantId]
                    if (msg) msg.content += text
                    if (data.usageMetadata) {
                        root.tokenCount.input = data.usageMetadata.promptTokenCount ?? -1
                        root.tokenCount.output = data.usageMetadata.candidatesTokenCount ?? -1
                        root.tokenCount.total = data.usageMetadata.totalTokenCount ?? -1
                    }
                } catch (e) {}
            }
        }
        onExited: (exitCode, exitStatus) => {
            const msg = root.messageByID[geminiProc.assistantId]
            if (msg) msg.done = true
            root.pendingRequest = false
        }
    }

    // Anthropic Messages API
    function sendAnthropic(model, assistantId) {
        const apiKey = apiKeys[model.key_id] ?? ""
        const allMsgs = buildMessages()
        // Anthropic uses separate system parameter, not in messages array
        const systemMsg = allMsgs.find(m => m.role === "system")
        const chatMsgs = allMsgs.filter(m => m.role !== "system").map(m => ({
            role: m.role, content: m.content
        }))
        const body = {
            model: model.model,
            messages: chatMsgs,
            max_tokens: model.extraParams?.max_tokens ?? 8192,
            temperature: temperature,
            stream: true,
        }
        if (systemMsg) body.system = systemMsg.content

        anthropicProc.environment = { API_KEY: apiKey, ENDPOINT: model.endpoint, BODY: JSON.stringify(body) }
        anthropicProc.assistantId = assistantId
        anthropicProc.running = true
    }

    Process {
        id: anthropicProc
        property string assistantId: ""
        command: ["bash", "-c", `curl -sN "$ENDPOINT" -H "Content-Type: application/json" -H "x-api-key: $API_KEY" -H "anthropic-version: 2023-06-01" -d "$BODY"`]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                if (!line.startsWith("data: ")) return
                const json = line.substring(6).trim()
                if (json === "[DONE]") return
                try {
                    const data = JSON.parse(json)
                    // Anthropic streaming events:
                    // content_block_delta: { delta: { type: "text_delta", text: "..." } }
                    // message_delta: { usage: { output_tokens } }
                    // message_start: { message: { usage: { input_tokens } } }
                    if (data.type === "content_block_delta") {
                        const msg = root.messageByID[anthropicProc.assistantId]
                        if (data.delta?.type === "text_delta" && msg) {
                            msg.content += data.delta.text
                        } else if (data.delta?.type === "thinking_delta" && msg) {
                            // Extended thinking — wrap in <think> tags for display
                            if (!msg.content.includes("<think>")) msg.content += "<think>"
                            msg.content += data.delta.thinking
                        }
                    } else if (data.type === "content_block_stop") {
                        const msg = root.messageByID[anthropicProc.assistantId]
                        // Close any open thinking block before text starts
                        if (msg && msg.content.includes("<think>") && !msg.content.includes("</think>")) {
                            msg.content += "</think>\n"
                        }
                    } else if (data.type === "message_start" && data.message?.usage) {
                        root.tokenCount.input = data.message.usage.input_tokens ?? -1
                    } else if (data.type === "message_delta" && data.usage) {
                        root.tokenCount.output = data.usage.output_tokens ?? -1
                        root.tokenCount.total = (root.tokenCount.input > 0 ? root.tokenCount.input : 0) + (data.usage.output_tokens ?? 0)
                    }
                } catch (e) {}
            }
        }
        onExited: (exitCode, exitStatus) => {
            const msg = root.messageByID[anthropicProc.assistantId]
            if (msg) msg.done = true
            root.pendingRequest = false
        }
    }

    // Load API keys from file on startup
    Component.onCompleted: {
        keysLoadProc.running = true
    }

    Process {
        id: keysLoadProc
        command: ["bash", "-c", `cat '${Directories.config}/quickshell/ano/api_keys.json' 2>/dev/null || echo '{}'`]
        stdout: StdioCollector {
            id: keysCollector
            onStreamFinished: {
                try { root.apiKeys = JSON.parse(keysCollector.text) }
                catch (e) { root.apiKeys = ({}) }
            }
        }
    }

    IpcHandler {
        target: "ai"
        function run(inputText: string): void {
            const text = (inputText ?? "").trim()
            if (text.length === 0) return
            if (text.startsWith("/")) {
                const parts = text.split(" "); const cmd = parts[0].substring(1); const args = parts.slice(1)
                switch (cmd) {
                    case "model": root.setModel(args[0] ?? ""); break
                    case "key": root.setApiKey(args[0] ?? ""); break
                    case "clear": root.clearMessages(); break
                    case "temp": root.setTemperature(args[0] ?? "0.5"); break
                    case "save": root.saveChat(args.join(" ")); break
                    case "load": root.loadChat(args.join(" ")); break
                    default: root.addMessage("Unknown command: " + cmd, root.interfaceRole)
                }
            } else root.sendUserMessage(text)
        }
    }
}
