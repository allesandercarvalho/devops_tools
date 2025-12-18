# Guia de Testes - DevOps Tools

## 🧪 Como Testar o Sistema Completo

### Pré-requisitos

Certifique-se de ter instalado:
- Go 1.21+
- Flutter 3.x
- AWS CLI (opcional, para testes AWS)
- Terraform (opcional, para testes Terraform)
- Kubectl (opcional, para testes Kubernetes)

---

## 1️⃣ Testar o Backend

### Iniciar o Backend

```bash
cd /Users/allesander.rewells/amigotech/projetos/devops-tools/backend

# Criar diretório de logs
mkdir -p logs

# Iniciar servidor
PORT=3003 ./server
```

**Saída esperada:**
```
🚀 Server starting on port 3003
```

### Testar Endpoints Básicos

```bash
# Health check
curl http://localhost:3003/health

# Métricas
curl http://localhost:3003/api/metrics | jq

# Executar comando simples
curl -X POST http://localhost:3003/api/commands/execute \
  -H "Content-Type: application/json" \
  -d '{
    "command": "echo",
    "args": ["Hello DevOps Tools!"]
  }'
```

### Testar Command Queue

```bash
# Criar uma fila
curl -X POST http://localhost:3003/api/queue \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Queue",
    "commands": ["cmd-1", "cmd-2"]
  }'

# Verificar status da fila (use o ID retornado)
curl http://localhost:3003/api/queue/{QUEUE_ID}
```

### Testar WebSocket

```bash
# Instalar wscat se não tiver
npm install -g wscat

# Conectar ao WebSocket
wscat -c ws://localhost:3003/ws

# Em outro terminal, execute um comando
curl -X POST http://localhost:3003/api/commands/execute \
  -H "Content-Type: application/json" \
  -d '{
    "command": "echo",
    "args": ["Testing WebSocket"]
  }'

# Você verá a saída em tempo real no wscat
```

### Script de Teste Automatizado

```bash
cd /Users/allesander.rewells/amigotech/projetos/devops-tools/backend

# Executar testes Phase 2
./test_phase2.sh

# Executar testes de integração
./test_integration.sh
```

---

## 2️⃣ Testar o Agent

### Iniciar o Agent

```bash
cd /Users/allesander.rewells/amigotech/projetos/devops-tools/agent

# Iniciar agent
./agent
```

**Saída esperada:**
```
🤖 DevOps Tools Agent v1.0.0 starting...
Device: MacBook-Pro (dev-1234567890)
OS: macOS
CLI Tools Status:
✅ aws: aws-cli/2.x.x
✅ terraform: Terraform v1.x.x
✅ kubectl: Client Version: v1.x.x
✅ Agent is running. Press Ctrl+C to stop.
```

### Verificar Coleta de Dados

Aguarde 30 segundos (intervalo de coleta) e observe os logs:

```
🔄 Starting periodic collection...
📊 Collected Data Summary:
  - AWS Stacks: X
  - AWS ECS Clusters: X
  - K8s Contexts: X
  - Terraform Workspaces: X
✅ Data synced to backend successfully
```

---

## 3️⃣ Testar Frontend

### Iniciar Frontend

```bash
cd /Users/allesander.rewells/amigotech/projetos/devops-tools/frontend

# Executar em modo web
flutter run -d chrome --web-port 8116
```

### Acessar no Navegador

Abra: `http://localhost:8116`

### Testar Módulos

#### 1. AWS Module
- Navegue para **CLI Hub → AWS**
- Teste cada submódulo:
  - ✅ **Configurações**: Adicionar/editar profiles
  - ✅ **Facilitador**: Gerar comandos AWS
  - ✅ **Base de Conhecimento**: Buscar comandos
  - ✅ **Histórico**: Ver execuções anteriores
  - ✅ **Diagnóstico**: Criar workflows de troubleshooting
  - ✅ **Navegador**: Explorar recursos S3/EC2

---

## 4️⃣ Testar Integração End-to-End

### Cenário 1: Executar Comando via Frontend

1. **Frontend**: Vá para AWS → Facilitador
2. Selecione: **Compute → EC2 → List Instances**
3. Clique em "Executar"
4. **Verifique**:
   - ✅ Comando aparece no terminal
   - ✅ Saída em tempo real
   - ✅ Backend registra no histórico
   - ✅ Métricas são atualizadas

### Cenário 2: Sync Agent → Backend

1. **Agent**: Aguarde coleta automática (30s)
2. **Backend**: Verifique logs
   ```bash
   tail -f logs/backend-$(date +%Y-%m-%d).log | grep "agent_sync"
   ```
3. **Verifique**:
   - ✅ Agent envia dados
   - ✅ Backend recebe e loga
   - ✅ WebSocket broadcast para clientes

---

## 5️⃣ Verificar Logs e Métricas

### Backend Logs

```bash
# Logs estruturados JSON
tail -f logs/backend-$(date +%Y-%m-%d).log | jq

# Filtrar por nível
tail -f logs/backend-*.log | jq 'select(.level == "error")'
```

### Métricas em Tempo Real

```bash
# Atualizar a cada 2 segundos
watch -n 2 'curl -s http://localhost:3003/api/metrics | jq .summary'
```

---

## 6️⃣ Troubleshooting

### Backend não inicia

```bash
# Verificar se porta está em uso
lsof -i :3003

# Matar processo
kill -9 $(lsof -t -i:3003)

# Verificar logs de erro
cat logs/backend-*.log | jq 'select(.level == "error")'
```

### Agent não conecta

```bash
# Verificar se backend está rodando
curl http://localhost:3003/health

# Verificar URL no agent
grep "backendURL" cmd/agent/main.go
```

---

## 📊 Checklist de Validação

### Backend ✅
- [ ] Servidor inicia sem erros
- [ ] Health check responde
- [ ] Comandos executam corretamente
- [ ] WebSocket funciona
- [ ] Métricas são coletadas
- [ ] Logs são gerados em JSON
- [ ] Queue processa comandos

### Agent ✅
- [ ] Agent inicia sem erros
- [ ] CLI tools são detectados
- [ ] Coleta periódica funciona
- [ ] Dados são enviados ao backend
- [ ] Parsers funcionam (AWS, TF, K8s)

### Frontend ✅
- [ ] App carrega sem erros
- [ ] Navegação funciona
- [ ] Módulos AWS/TF/ArgoCD funcionam
- [ ] Comandos podem ser executados
- [ ] Histórico é exibido

---

**Pronto para testar!** 🚀
