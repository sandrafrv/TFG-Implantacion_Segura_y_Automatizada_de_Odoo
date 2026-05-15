# CLAUDE.md — Skill de Documentación Automática del TFG

Este archivo define cómo Claude debe comportarse en este repositorio.
Se carga automáticamente en cada sesión de Claude Code.

---

## Contexto del Proyecto

**Proyecto:** TFG — Implantación Segura y Automatizada de Odoo
**Autora:** Sandra Fradejas
**Descripción:** Entorno productivo completo para el ERP Odoo con enfoque en seguridad, contenerización (Docker) y buenas prácticas de administración de sistemas. Incluye pfSense como firewall, Nginx como reverse proxy, Vagrant como IaC de 3 VMs, y PostgreSQL en VM dedicada.

### Estado actual de la arquitectura (Mayo 2026)

> ⚠️ La arquitectura evolucionó. Lee esto antes de tocar cualquier archivo.

- **3 VMs orquestadas con Vagrant:** `pfsense` (VM1), `odoo-server` (VM2), `db-server` (VM3).
- **PostgreSQL NO está en Docker.** Está instalado nativamente en la VM3 (`192.168.40.10:5432`). No intentes crear un servicio `db` en el `docker-compose.yml`.
- **El `docker-compose.yml` solo contiene 2 servicios:** `odoo-web` y `nginx-proxy`. No hay `db`, no hay `ldap`.
- **LDAP está retirado del despliegue.** Los scripts de `scripts/ldap/` son código histórico. La carpeta `extras/ldap/` contiene el material para retomarlo en el futuro.
- **El archivo `.env` está en la raíz** del repositorio, no dentro de `docker/`.
- **Las credenciales de BD para backups** se guardan en `/etc/backup_odoo.env` con permisos 600 (solo root).

### Arquitectura de Red

| VM | VLAN | IP | Rol |
|:---|:---|:---|:---|
| VM1 — pfSense | WAN/VLAN10/30/40 | dinámica WAN | Firewall + NAT + VPN |
| VM2 — Debian (Docker) | VLAN 30 | `192.168.30.10` (host) | Contenedores Odoo + Nginx |
| nginx-proxy (Docker) | VLAN 30 MACVLAN | `192.168.30.20` | Proxy inverso SSL |
| odoo-web (Docker) | VLAN 30 MACVLAN | `192.168.30.21` | Odoo 17 CE |
| VM3 — PostgreSQL | VLAN 40 | `192.168.40.10` | BD nativa (no Docker) |

### Estructura del Repositorio

```
TFG-Implantacion_Segura_y_Automatizada_de_Odoo/
├── Vagrantfile                  # Define las 3 VMs (IaC)
├── .env                         # Variables de entorno (en la RAÍZ, no en docker/)
├── .env.example                 # Plantilla sin secretos ni variables LDAP
├── vagrant/                     # Scripts de aprovisionamiento de cada VM
│   ├── provision_debian.sh      # VM2: Docker + Nginx + Odoo + SSL
│   ├── provision_pfsense.sh     # VM1: pfSense (config.xml o manual)
│   ├── provision_postgres.sh    # VM3: PostgreSQL 16 nativo
│   └── Explicacion_provision_postgres.md
├── docker/                      # Solo 2 servicios: odoo-web + nginx-proxy
│   ├── docker-compose.yml       # SIN db, SIN ldap
│   └── odoo.conf                # db_host = 192.168.40.10
├── config_nginx/                # Configuración Nginx SSL
├── scripts/
│   ├── deploy/                  # deploy.sh, configure.sh, erp.sh, install_cron.sh
│   ├── mantenimiento/           # backup_postgres.sh (NUEVO), restore.sh, monitor.sh
│   ├── odoo/                    # Gestión de usuarios Odoo
│   └── ldap/                    # ⚠️ DEPRECADO — no ejecutar en este despliegue
├── sql/                         # Triggers de auditoría PL/pgSQL
├── extras/ldap/                 # LDAP como mejora futura (no activo)
├── docs/                        # Documentación técnica
└── config/logrotate.d/          # Rotación de logs
```

---

## Skill: Auto-Documentación de Cambios

### Propósito

Cada vez que realices o asistas en un cambio técnico en este repositorio, debes **documentar automáticamente** lo que se hizo, por qué, y cómo afecta al sistema — sin que Sandra tenga que pedírtelo explícitamente.

---

### Cuándo Activar la Documentación

Documenta automáticamente cuando:

- Se **crea o modifica** cualquier archivo en `docker/`, `vagrant/`, `config_nginx/`, `scripts/`, `sql/`
- Se **añade una regla** de pfSense o se modifica la arquitectura de red
- Se **resuelve un issue** o se completa una tarea
- Se **instala, actualiza o elimina** un servicio o dependencia
- Se **cambia una variable de entorno** o configuración sensible (sin revelar valores reales)
- Se **corrige un error** o problema de seguridad

---

### Qué Documentar y Dónde

#### 1. `docs/CHANGELOG.md` — Historial de Cambios

Mantiene un CHANGELOG siguiendo [Keep a Changelog](https://keepachangelog.com/es/1.1.0/).

**Formato:**
```markdown
## [Sin publicar]

### Añadido
- Descripción del nuevo elemento

### Modificado
- Descripción del cambio

### Eliminado
- Descripción de lo que se retiró y por qué

### Corregido
- Bug o problema resuelto

### Seguridad
- Vulnerabilidad corregida o mejora de seguridad
```

#### 2. `docs/reglas_pfsense.md` — Reglas de Firewall

Si el cambio implica nuevas reglas o modificación de las existentes:

```markdown
| Fecha      | Interfaz | Acción | Protocolo | Origen → Destino | Puerto | Descripción |
|------------|----------|--------|-----------|------------------|--------|-------------|
| YYYY-MM-DD | VLAN30   | Pass   | TCP       | .30.0/24 → .40.10| 5432   | Odoo → BD   |
```

#### 3. `REALIZADO_PDF_PASOS.md` — Checklist de Progreso

Actualiza marcando como completado cada tarea terminada con fecha.

---

### Reglas de Escritura para la Documentación

1. **Idioma:** Siempre en español.
2. **Tono:** Técnico pero claro, como si lo leyera el tutor del TFG.
3. **Nunca incluir:** contraseñas, tokens, ni secretos. Usar `<VALOR_OCULTO>` o `<IP_INTERNA>` como placeholder.
4. **Siempre incluir:** fecha del cambio, archivo(s) afectado(s), y el motivo técnico del cambio.
5. **Arquitectura:** Recuerda siempre que la BD está en `192.168.40.10`, no en localhost ni en Docker.

---

### Flujo de Trabajo Estándar

```
1. Analiza el cambio solicitado
2. Verifica que el cambio es coherente con la arquitectura de 3 VMs
3. Implementa el cambio técnico
4. Actualiza docs/CHANGELOG.md
5. Si aplica: actualiza docs/reglas_pfsense.md o REALIZADO_PDF_PASOS.md
6. Informa: "✅ Cambio realizado y documentado en docs/"
```

---

### Comandos Útiles por VM

```bash
# ───────────────────────────────
# Vagrant — orquestar las 3 VMs
# ───────────────────────────────
vagrant up                          # Levantar todas las VMs
vagrant up odoo-server              # Solo VM2
vagrant ssh odoo-server             # SSH a VM2
vagrant ssh db-server               # SSH a VM3
vagrant status                      # Estado de las 3 VMs
vagrant halt                        # Apagar todas
vagrant destroy -f                  # Destruir todo (cuidado)
vagrant provision odoo-server       # Re-aprovisionar VM2

# ───────────────────────────────
# VM2 — Contenedores Docker (odoo-web + nginx-proxy)
# ───────────────────────────────
docker compose -f docker/docker-compose.yml ps
docker compose -f docker/docker-compose.yml logs odoo-web --tail=50
docker compose -f docker/docker-compose.yml logs nginx-proxy --tail=20
docker compose -f docker/docker-compose.yml restart odoo-web
docker compose -f docker/docker-compose.yml down && docker compose -f docker/docker-compose.yml up -d

# ───────────────────────────────
# VM3 — PostgreSQL nativo (NO Docker)
# ───────────────────────────────
# Acceder desde la máquina anfitrión:
vagrant ssh db-server

# Desde VM3:
systemctl status postgresql
journalctl -u postgresql -n 50
psql -U odoo -d odooerp            # Acceso directo a la BD

# Desde VM2 (verifica conectividad):
psql -h 192.168.40.10 -U odoo -d odooerp

# ───────────────────────────────
# Backups y restauración
# ───────────────────────────────
bash scripts/mantenimiento/backup_postgres.sh
bash scripts/mantenimiento/restore.sh <archivo.sql.gz>

# Credenciales de backup (VM2, solo root)
cat /etc/backup_odoo.env            # chmod 600

# ───────────────────────────────
# Verificar Nginx
# ───────────────────────────────
docker exec nginx-proxy nginx -t    # Test configuración
curl -k https://192.168.30.20/web/health
```

---

### Detección Automática de Problemas de Seguridad

Siempre que revises o modifiques archivos, alerta si detectas:

- 🔴 **CRÍTICO:** Contraseñas o tokens hardcodeados en código fuente
- 🟠 **ADVERTENCIA:** Puertos expuestos innecesariamente en docker-compose
- 🟡 **AVISO:** Variables de entorno sensibles sin usar `.env` o secrets
- 🔵 **INFO:** Configuración mejorable pero no crítica
- 🔴 **CRÍTICO:** Referencia a `localhost` o `127.0.0.1` para la BD — debe ser siempre `192.168.40.10`
- 🟠 **ADVERTENCIA:** Cualquier intento de añadir servicio `db` o `ldap` al `docker-compose.yml`

Formato de alerta:
```
⚠️ [NIVEL] Archivo: `ruta/archivo` — Descripción del problema — Recomendación
```

---

## Notas Finales

- Este es un **TFG académico** de ASIR. La documentación es parte de la evaluación.
- Prioriza documentación **clara y pedagógica**: explica el "por qué" además del "qué".
- **Regla de oro:** Si algo no funciona con `192.168.40.10`, verifica primero que la VM3 esté levantada con `vagrant status` y que `pg_hba.conf` permite conexiones desde `192.168.30.0/24`.
- Cuando tengas dudas sobre dónde documentar algo, consulta a Sandra antes de proceder.
