# 🚀 Guia Rápido de Conexão - Cliente VPN

## ⚡ Setup em 3 Passos

### 1️⃣ Descubra o IP do Servidor VPN

No **servidor**, execute:
```bash
docker exec ts-server tailscale ip
```
Resultado exemplo: `100.94.199.41`

### 2️⃣ Configure o Cliente

Edite o arquivo `.env`:
```env
VPN_SERVER_IP=100.94.199.41  # IP obtido no passo 1
TS_AUTHKEY=tskey-auth-kprhQp1TJ611CNTRL-Wd55VnA2nhPp9ttq4ambhP4KTYokzqMt
```

### 3️⃣ Inicie o Cliente

**Windows (PowerShell):**
```powershell
.\start.ps1
```

**Linux/Mac:**
```bash
chmod +x start.sh
./start.sh
```

**Ou manualmente:**
```bash
docker-compose up -d
```

---

## 🔌 Conectar Aplicações

### DBeaver / DataGrip

1. Criar nova conexão
2. Configurar:
   - **Host:** `localhost` (ou `127.0.0.1`)
   - **Port:** `15432`
   - **Database:** nome do banco remoto
   - **User:** usuário do banco remoto
   - **Password:** senha do banco remoto

### pgAdmin

1. Add New Server
2. Connection tab:
   - **Host:** `localhost`
   - **Port:** `15432`
   - **Maintenance database:** nome do banco
   - **Username:** usuário remoto
   - **Password:** senha remota

### psql (Command Line)

```bash
psql -h localhost -p 15432 -U usuario -d database
```

Com password inline:
```bash
PGPASSWORD=suasenha psql -h localhost -p 15432 -U usuario -d database
```

### MySQL Workbench

1. New Connection
2. Parameters:
   - **Hostname:** `127.0.0.1`
   - **Port:** `15432`
   - **Username:** usuário remoto
   - **Password:** senha remota
   - **Default Schema:** nome do banco

### Python (psycopg2)

```python
import psycopg2

conn = psycopg2.connect(
    host="localhost",
    port=15432,
    database="seu_database",
    user="seu_usuario",
    password="sua_senha"
)
```

### Python (SQLAlchemy)

```python
from sqlalchemy import create_engine

engine = create_engine(
    'postgresql://usuario:senha@localhost:15432/database'
)
```

### Node.js (pg)

```javascript
const { Client } = require('pg');

const client = new Client({
    host: 'localhost',
    port: 15432,
    database: 'seu_database',
    user: 'seu_usuario',
    password: 'sua_senha'
});

await client.connect();
```

### Java (JDBC)

```java
String url = "jdbc:postgresql://localhost:15432/database";
Properties props = new Properties();
props.setProperty("user", "usuario");
props.setProperty("password", "senha");

Connection conn = DriverManager.getConnection(url, props);
```

### .NET (Npgsql)

```csharp
using Npgsql;

var connectionString = "Host=localhost;Port=15432;Database=database;Username=usuario;Password=senha";
using var conn = new NpgsqlConnection(connectionString);
conn.Open();
```

---

## 🔍 Verificar Status

### Status Geral
```bash
docker-compose ps
```

### Logs em Tempo Real
```bash
docker-compose logs -f
```

### Logs de um Serviço Específico
```bash
docker-compose logs -f db-forwarder
docker-compose logs -f ts-client
```

### Status da VPN
```bash
docker exec ts-client tailscale status
```

### IP da VPN
```bash
docker exec ts-client tailscale ip
```

### Testar Ping no Servidor
```bash
docker exec ts-client tailscale ping 100.94.199.41
```

### Verificar Porta Local (Windows)
```powershell
netstat -an | findstr 15432
```

### Verificar Porta Local (Linux/Mac)
```bash
netstat -an | grep 15432
# ou
lsof -i :15432
```

---

## 🛠️ Troubleshooting Rápido

### ❌ "Connection refused" ao conectar no localhost:15432

**Solução:**
```bash
# Verificar se containers estão rodando
docker-compose ps

# Reiniciar se necessário
docker-compose restart

# Ver logs
docker-compose logs db-forwarder
```

### ❌ VPN não conecta

**Solução:**
```bash
# Ver logs da VPN
docker-compose logs ts-client

# Verificar auth key no .env
cat .env | grep TS_AUTHKEY

# Recriar containers
docker-compose down
docker-compose up -d
```

### ❌ Não alcança o servidor VPN

**Solução:**
```bash
# Verificar IP do servidor
docker exec ts-client tailscale ping 100.94.199.41

# Verificar status da VPN
docker exec ts-client tailscale status

# Confirmar que VPN_SERVER_IP está correto no .env
cat .env | grep VPN_SERVER_IP
```

### ❌ Timeout ao conectar no banco

**Solução:**
```bash
# Verificar se servidor está acessível
docker exec db-forwarder nc -z 100.94.199.41 5432

# Ver logs do forwarder
docker-compose logs db-forwarder

# Testar conectividade VPN
docker exec ts-client tailscale ping 100.94.199.41
```

---

## 🔄 Reiniciar Completamente

### Soft Restart
```bash
docker-compose restart
```

### Full Restart
```bash
docker-compose down
docker-compose up -d
```

### Clean Restart (Remove estado)
```bash
docker-compose down
rm -rf ts-authkey/state/*  # CUIDADO: Remove autenticação
docker-compose up -d
```

---

## 📞 Precisa de Ajuda?

1. **Ver todos os logs**: `docker-compose logs`
2. **Status da VPN**: `docker exec ts-client tailscale status`
3. **Testar conectividade**: `docker exec ts-client tailscale ping <VPN_SERVER_IP>`
4. **Verificar porta**: `netstat -an | grep 15432`