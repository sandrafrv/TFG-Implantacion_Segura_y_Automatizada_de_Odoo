# Guía Maestra de Instalación desde Cero

**TFG ASIR 2025/2026 — Implantación Segura y Automatizada de Odoo ERP**
*Sandra Fradejas Avedillo — IES Cañaveral*

> [!IMPORTANT]
> Este es el **punto de entrada único**. Sigue las fases en orden.
> Cada sección resume lo esencial y enlaza a la sub-guía detallada.
>
> **→ Índice completo de documentación: [`docs/README.md`](README.md)**

---

## Prerequisitos

- VirtualBox ≥ 6.1 instalado en el equipo de laboratorio
- ISOs disponibles en `ISOs/`: Debian 13 netinst + pfSense 2.7.x
- Conexión a Internet en el equipo anfitrión
- Repositorio clonado localmente

---

## Arquitectura General

```
Internet (WAN)
     │ NAT 80/443
     ▼
[ pfSense — 4 interfaces ]
     │           │           │
  VLAN 10     VLAN 30     VLAN 40
  192.168.10  192.168.30  192.168.40
  Clientes    DMZ Server  Admin
     │           │           │
  PCs           Debian 13    PCs Admin
  Login LDAP    192.168.30.10  SSH/Cockpit/pfSense
                │
    ┌───────────┴───────────────────┐
    │ nginx-proxy  → MACVLAN .20   │
    │ odoo-web     → MACVLAN .21   │
    │ openldap     → MACVLAN .22   │
    │ odoo_erp     → solo interno  │
    └───────────────────────────────┘
```

---

## Tabla de Direccionamiento

| Componente | VLAN | IP | Acceso permitido |
|:-----------|:-----|:---|:----------------|
| pfSense gateway LAN | 10 | 192.168.10.1 | Solo VLAN 40 (panel) |
| pfSense gateway DMZ | 30 | 192.168.30.1 | — |
| pfSense gateway Admin | 40 | 192.168.40.1 | Solo VLAN 40 |
| Debian 13 host | DMZ | 192.168.30.10 | SSH/Cockpit solo VLAN 40 |
| **nginx-proxy** | DMZ (MACVLAN) | 192.168.30.20 | VLAN 10 + 40 + WAN (:443) |
| **odoo-web** | DMZ (MACVLAN) | 192.168.30.21 | Solo vía Nginx |
| **openldap** | DMZ (MACVLAN) | 192.168.30.22 | VLAN 10 (:389), VLAN 40 (:389/:636) |
| **odoo_erp** (PostgreSQL) | Docker interno | 172.19.0.x | Solo contenedor Odoo |

---

## Las 3 Fases de Instalación

### 🔷 FASE 1 — Red y Firewall

**Tiempo estimado: 45–60 min**

**→ Guía completa:** [`guias/INSTALACION_RED.md`](guias/INSTALACION_RED.md)

| Paso | Descripción |
|:-----|:------------|
| 1–2 | VM pfSense: 4 adaptadores (WAN/LAN10/DMZ30/Admin40) |
| 3 | Asignación de interfaces en consola de texto |
| 4 | Acceso a la interfaz web desde LAN |
| 5 | Interfaz OPT2 (VLAN_ADMIN `192.168.40.1/24`) |
| 6 | DHCP: LAN (.100–.200) y OPT2 (.10–.50) |
| 7 | DNS Resolver: Host Override `erp.odoo.tfg.com → 192.168.30.10` |
| 8 | NAT: WAN:80/443 → servidor + DNS interceptado por VLAN |
| 9 | Reglas firewall: bloqueos anti-pivoting + permisos mínimos |
| 10 | LDAP auth en panel pfSense (solo grupo `admin`) |
| 11 | Desactivar Anti-Lockout tras confirmar acceso VLAN 40 |

**Atajo:** `bash scripts/deploy/generate_pfsense_config.sh` genera el `config.xml` completo.
Importar en **Diagnostics → Backup/Restore**. También disponible como artefacto CI en GitHub Actions.

**Verificación rápida:**
```bash
nslookup erp.odoo.tfg.com   # → 192.168.30.10 desde VLAN 10
nc -zv 192.168.30.10 5432   # → Timeout (bloqueado) desde VLAN 10
```

---

### 🖧 FASE 2 — Servidor Debian + Docker + Odoo

**Tiempo estimado: 30–60 min (+ 5 min primer arranque Odoo)**

**→ Guía completa:** [`guias/INSTALACION_SERVIDOR.md`](guias/INSTALACION_SERVIDOR.md)

| Paso | Descripción |
|:-----|:------------|
| Parte 1 | VM Debian 13: IP estática `192.168.30.10`, Docker, Cockpit, clonar repo, `.env` |
| Parte 2 | Red MACVLAN, SSL, `docker compose up -d`, 4 contenedores `healthy`, cron |
| Parte 3 | Post-instalación Odoo: empresa, módulos, usuarios con roles, auditoría SQL |

**Atajo:** `sudo ./install.sh` ejecuta la Parte 1 y 2 automáticamente.

**Verificación rápida:**
```bash
docker compose -f docker/docker-compose.yml ps
curl -k -I https://erp.odoo.tfg.com   # → HTTP/2 200
```

---

### 🔐 FASE 3 — LDAP + CI/CD + Hardening

**Tiempo estimado: 30–45 min**

**→ Guía completa:** [`guias/INSTALACION_LDAP_CICD_HARDENING.md`](guias/INSTALACION_LDAP_CICD_HARDENING.md)

| Parte | Descripción |
|:------|:------------|
| LDAP | ACLs, crear usuarios del directorio, configurar SSSD+PAM en PCs VLAN 10 |
| CI/CD | Self-hosted runner, pipeline CI (ShellCheck/YAML/Markdown) + CD (deploy automático) |
| Hardening | UFW, SSH por clave pública, eliminar GNOME, headless |

> [!CAUTION]
> El hardening (SSH + headless) debe hacerse **siempre al final**, cuando todo lo demás funciona.

**Verificación rápida:**
```bash
systemctl get-default                  # → multi-user.target
sudo ufw status                        # → active
ldapwhoami -H ldap://192.168.30.22 \
  -D "uid=jdoe,ou=usuarios,dc=tfg,dc=com" -W   # → OK
```

---

## Orden de Arranque (tras Reinicio)

```
1. Arrancar pfSense VM     → esperar ~1 min (interfaces activas)
2. Arrancar Debian VM      → Docker arranca automáticamente
3. Esperar ~3 min          → Odoo inicializa (primer arranque)
4. Verificar desde VLAN 10 → https://erp.odoo.tfg.com
5. Verificar desde VLAN 40 → https://192.168.30.10:9090 (Cockpit)
```

---

## Checklist Final

```
FASE 1 — Red
  ✅ pfSense: 4 interfaces activas
  ✅ DHCP VLAN 10 y VLAN 40
  ✅ DNS: erp.odoo.tfg.com → 192.168.30.10
  ✅ NAT: WAN 80/443 → servidor
  ✅ Reglas: anti-pivoting + permisos mínimos
  ✅ Panel pfSense: solo VLAN 40, auth LDAP
  ✅ Anti-Lockout desactivado

FASE 2 — Servidor
  ✅ Debian: IP estática 192.168.30.10
  ✅ Docker + Cockpit activos
  ✅ MACVLAN: .20 (Nginx) · .21 (Odoo) · .22 (LDAP)
  ✅ 4 contenedores healthy
  ✅ Odoo: empresa + módulos + usuarios con roles
  ✅ Auditoría SQL (trigger en res_users)
  ✅ Cron: backup/monitor/update

FASE 3 — Seguridad
  ✅ LDAP: ACLs + usuarios + login Odoo + login PCs VLAN 10
  ✅ CI/CD: runner activo + pipeline funcional
  ✅ UFW: deny-all + 22/80/443/9090
  ✅ SSH: solo clave pública, sin root
  ✅ Debian headless: multi-user.target
```

---

## Documentación Relacionada

| Documento | Para qué sirve |
|:----------|:--------------|
| [`README.md`](README.md) | Índice completo de toda la documentación |
| [`CONTROL_ACCESO.md`](CONTROL_ACCESO.md) | Modelo de seguridad en 3 capas |
| [`reglas_pfsense.md`](reglas_pfsense.md) | Referencia completa de reglas pfSense |
| [`diagrama_red.md`](diagrama_red.md) | Diagramas de arquitectura |
| [`HISTORIAL_IMPLEMENTACION.md`](HISTORIAL_IMPLEMENTACION.md) | Historia del desarrollo |
| [`CHANGELOG.md`](CHANGELOG.md) | Registro de cambios |

---

*TFG ASIR 2025/2026 — IES Cañaveral*
