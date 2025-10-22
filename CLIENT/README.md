# VPN Client - Database Forwarder

## 🏗️ Arquitetura

Este cliente recebe conexões de banco de dados através da VPN Tailscale e as **externaliza no localhost**, permitindo que aplicações locais acessem bancos remotos de forma segura.

```
[Banco Remoto] ←→ [VPN Server] ←→ [VPN Tunnel] ←→ [VPN Client] ←→ [localhost:15432]
                                                                          ↓
                                                                  [DBeaver/Apps Locais]
```

## 📋 Componentes

### 1. **db-forwarder** (ginuerzh/gost)
- Recebe tráfego da VPN interna
- Encaminha para o servidor VPN configurado
- Externaliza no `localhost:15432` (configurável)

### 2. **ts-client** (tailscale)
- Conecta à rede VPN Tailscale
- Compartilha rede com o forwarder (sidecar pattern)
- Aceita rotas do servidor VPN

### 3. **connection-monitor** (opcional - compose.advanced.yaml)
- Monitora conectividade com servidor VPN
- Verifica saúde do forwarder local
- Testa ping via VPN

## ⚙️ Configuração

### 1. Configure o arquivo `.env`:

```bash
# IP do servidor VPN (obtenha do servidor)
VPN_SERVER_IP=100.94.199.41

# Porta do servidor (padrão 5432)
VPN_SERVER_PORT=5432

# Porta local onde será exposto
LOCAL_PORT=15432

# Tailscale Auth Key (mesma do servidor)
TS_AUTHKEY=tskey-auth-...
```

### 2. Descubra o IP do servidor VPN:

No servidor, execute:
```bash
docker exec ts-server tailscale ip
```

Use esse IP no `VPN_SERVER_IP` do cliente.

### 3. Execute o cliente:

```bash
cd CLIENT
docker-compose up -d
```

### 4. Teste a conexão:

```bash
# Verificar se está escutando
netstat -an | findstr 15432

# Testar conexão com psql
psql -h localhost -p 15432 -U seu_usuario -d seu_banco
```

## 🔧 Funcionamento

1. **Aplicação local** conecta em `localhost:15432`
2. **db-forwarder** recebe a conexão
3. **ts-client** roteia via VPN para o servidor
4. **Servidor VPN** encaminha para o banco externo
5. **Resposta** percorre o caminho inverso

## 📊 Monitoramento

```bash
# Status geral
docker-compose ps

# Logs do forwarder
docker-compose logs db-forwarder

# Logs da VPN
docker-compose logs ts-client

# Status da VPN
docker exec ts-client tailscale status

# IP atribuído na VPN
docker exec ts-client tailscale ip

# Ping no servidor
docker exec ts-client tailscale ping 100.94.199.41
```

## 🚀 Uso com Aplicações

### DBeaver / pgAdmin
```
Host: localhost
Port: 15432
Database: nome_do_banco
User: usuario_remoto
Password: senha_remota
```

### psql (PostgreSQL)
```bash
psql -h localhost -p 15432 -U usuario -d database
```

### MySQL Client
```bash
mysql -h localhost -P 15432 -u usuario -p
```

### Aplicações (connection string)
```
# PostgreSQL
postgresql://usuario:senha@localhost:15432/database

# MySQL
mysql://usuario:senha@localhost:15432/database
```

## 🔐 Segurança

- ✅ Conexão VPN criptografada (WireGuard)
- ✅ Exposição apenas no localhost (127.0.0.1)
- ✅ Sem portas abertas externamente
- ✅ Acesso controlado por Auth Keys

## 🔧 Troubleshooting

### 1. Cliente não conecta à VPN
```bash
# Ver logs
docker-compose logs ts-client

# Verificar auth key
docker exec ts-client tailscale status
```

### 2. Não consegue alcançar o servidor
```bash
# Verificar IP do servidor
docker exec ts-client tailscale ping <VPN_SERVER_IP>

# Verificar rotas
docker exec ts-client tailscale status
```

### 3. Porta local não responde
```bash
# Verificar se está escutando
netstat -an | findstr 15432

# Ver logs do forwarder
docker-compose logs db-forwarder

# Testar conectividade interna
docker exec db-forwarder nc -z <VPN_SERVER_IP> 5432
```

### 4. Reiniciar completamente
```bash
# Parar tudo
docker-compose down

# Limpar estado (CUIDADO!)
rm -rf ts-authkey/state/*

# Reiniciar
docker-compose up -d
```

## 📈 Versão Avançada

Para recursos extras, use `compose.advanced.yaml`:

```bash
# Com monitoramento
docker-compose -f compose.advanced.yaml up -d

# Com teste de conexão
docker-compose -f compose.advanced.yaml --profile testing up -d

# Com backup automático
docker-compose -f compose.advanced.yaml --profile backup up -d
```

### Recursos adicionais:
- ✅ Health checks automáticos
- ✅ Monitor de conectividade
- ✅ Testador de conexão com banco
- ✅ Backup automático de configuração
- ✅ Logs estruturados

## 🎯 Casos de Uso

- ✅ **Desenvolvimento Local**: Acesso seguro a bancos de produção
- ✅ **Analytics**: Conectar Tableau, Power BI, etc
- ✅ **Debugging**: Ferramentas locais acessando dados remotos
- ✅ **Migration**: Sincronização de dados entre ambientes