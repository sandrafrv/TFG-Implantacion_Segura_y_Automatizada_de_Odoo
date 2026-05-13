# Diagrama de Red — Arquitectura Completa

**TFG ASIR 2025/2026 — TechSolutions S.L.**

---

## Diagrama de Topología General

```mermaid
graph TD
    WAN["☁️ Internet / WAN"]
    GITHUB["☁️ GitHub\n(Repositorio + CI/CD)"]

    WAN -->|"NAT 80/443"| PFSENSE
    GITHUB -->|"Self-hosted runner"| DEBIAN

    PFSENSE(["🔷 pfSense\nFirewall · DHCP · DNS · Router\nIP WAN: dinámica (NAT)"])

    PFSENSE -->|"VLAN 10 · 192.168.10.1/24"| VLAN10
    PFSENSE -->|"VLAN 30 · 192.168.30.1/24"| DMZ
    PFSENSE -->|"VLAN 40 · 192.168.40.1/24"| VLAN40

    subgraph VLAN10["🟧 VLAN 10 — Clientes / Empleados"]
        CLIENT["🖥️ PC Empleado\n192.168.10.x\nLogin: LDAP (SSSD+PAM)"]
    end

    subgraph VLAN40["🟥 VLAN 40 — Administración"]
        ADMIN["👤 Admin / DBA\n192.168.40.x\nAcceso: SSH · Cockpit · pfSense"]
    end

    subgraph DMZ["🟩 Debian 13 · DMZ — VLAN 30"]
        DEBIAN["🖧 Host Debian 13\n192.168.30.10\nSSH :22 · Cockpit :9090"]

        NGINX["🐳 nginx-proxy\nMACV: 192.168.30.20\n:80 :443"]
        ODOO["🐳 odoo-web\nMACV: 192.168.30.21\n:8069 :8072"]
        POSTGRES["🐳 odoo_erp (PostgreSQL)\nSolo red interna\n:5432"]
        LDAP["🐳 openldap\nMACV: 192.168.30.22\n:389 :636"]

        NGINX -->|"reverse proxy :8069"| ODOO
        ODOO -->|"SQL :5432"| POSTGRES
    end

    CLIENT -->|"HTTPS :443"| NGINX
    CLIENT -->|"LDAP auth :389"| LDAP
    ADMIN -->|"HTTPS :443"| NGINX
    ADMIN -->|"SSH :22"| DEBIAN
    ADMIN -->|"Cockpit :9090"| DEBIAN
    ADMIN -->|"LDAP admin :389/:636"| LDAP

    classDef firewall fill:#BBDEFB,stroke:#1565C0,color:#000
    classDef vlan10 fill:#FFE0B2,stroke:#E65100,color:#000
    classDef vlan40 fill:#FFCDD2,stroke:#B71C1C,color:#000
    classDef dmzhost fill:#E8F5E9,stroke:#2E7D32,color:#000
    classDef container fill:#CE93D8,stroke:#6A1B9A,color:#000

    class PFSENSE firewall
    class CLIENT vlan10
    class ADMIN vlan40
    class DEBIAN dmzhost
    class NGINX,ODOO,POSTGRES,LDAP container
```

---

## Tabla de Direccionamiento IP Completa

| Componente | Zona | IP | Puerto(s) | Acceso desde |
|:-----------|:-----|:---|:---------|:-------------|
| pfSense — gateway LAN | VLAN 10 | `192.168.10.1` | 443 (panel) | Solo VLAN 40 |
| pfSense — gateway DMZ | VLAN 30 | `192.168.30.1` | — | — |
| pfSense — gateway Admin | VLAN 40 | `192.168.40.1` | 443 (panel) | Solo VLAN 40 |
| **Debian 13 host** | DMZ | `192.168.30.10` | 22, 9090 | Solo VLAN 40 |
| **nginx-proxy** (MACVLAN) | DMZ | `192.168.30.20` | 80, 443 | VLAN 10 + VLAN 40 + WAN |
| **odoo-web** (MACVLAN) | DMZ | `192.168.30.21` | 8069, 8072 (solo interno) | Solo via Nginx |
| **openldap** (MACVLAN) | DMZ | `192.168.30.22` | 389 (readonly), 636 (admin) | VLAN 10 (:389), VLAN 40 (:389/:636) |
| **odoo_erp** (PostgreSQL) | Red Docker | `172.19.0.x` | 5432 (solo interno) | Solo contenedor Odoo |
| Clientes empleados | VLAN 10 | `192.168.10.100–200` | — | DHCP |
| PCs administradores | VLAN 40 | `192.168.40.10–50` | — | DHCP |

---

## Zonas de Seguridad y Políticas de Acceso

```
┌─────────────────────────────────────────────────────────────────────┐
│  INTERNET (WAN)                                                     │
│  Solo puertos 80/443 redirigidos por NAT al nginx-proxy             │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                          [ pfSense ]
                               │
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
   VLAN 10                VLAN 30 (DMZ)          VLAN 40
 (Clientes)              (Servidor)           (Admin)
192.168.10.0/24         192.168.30.0/24     192.168.40.0/24
        │                      │                      │
  PCs empleados       Debian + Docker          Admins/DBAs
  Login LDAP          Nginx/Odoo/LDAP         SSH/Cockpit/pfSense
        │                      │
        └──── solo HTTPS ──────┘  (pfSense regla: VLAN10→DMZ :443 ✅)
        └──── PostgreSQL ──── ❌   (pfSense regla: VLAN10→DMZ :5432 ✗)
        └──── SSH/Cockpit ─── ❌   (pfSense regla: VLAN10→DMZ :22/:9090 ✗)
```

### Principio de anti-pivoting

| Origen | Destino | Estado |
|:-------|:--------|:------:|
| DMZ → VLAN 10 | Cualquier puerto | ❌ Bloqueado |
| DMZ → VLAN 40 | Cualquier puerto | ❌ Bloqueado |
| DMZ → pfSense LAN | Cualquier puerto | ❌ Bloqueado |
| VLAN 10 → VLAN 40 | Cualquier puerto | ❌ Bloqueado |
| VLAN 40 → VLAN 10 | Cualquier puerto | ❌ Bloqueado |

---

## Flujo de Autenticación de un Empleado

```
Empleado (VLAN 10) abre https://erp.odoo.tfg.com
         │
         ▼  DNS → pfSense DNS Resolver
         │  Host Override: erp.odoo.tfg.com → 192.168.30.10
         │
         ▼  pfSense: VLAN10→DMZ:443 → PASS ✅
         │
    [ nginx-proxy — 192.168.30.20:443 ]   ← CAPA C: filtra rutas por IP
         │  /web/database → 403 (VLAN 10 bloqueada)
         │  / → proxy_pass a odoo-web:8069
         │
    [ odoo-web — 192.168.30.21:8069 ]    ← CAPA B: tipo de usuario
         │  Login LDAP → consulta a cn=readonly
         │
    [ openldap — 192.168.30.22:389 ]
         │  uid=jdoe, password OK → ✅
         │
    [ Odoo — Sesión iniciada ]            ← CAPA A: grupos y módulos
         │  Tipo: Interno
         │  Grupos: ventas → CRM + Ventas + Facturas
         ▼
    Panel personalizado según rol ✅
```

---

## Red Docker Interna

```
┌──────────────────────────────────────────────────────┐
│  Red Docker: odoo_net (bridge — 172.19.0.0/16)       │
│                                                      │
│  nginx-proxy ──────► odoo-web ──────► odoo_erp       │
│  (172.19.0.4)        (172.19.0.3)    (172.19.0.2)   │
│  + macvlan .20       + macvlan .21   (sin MACVLAN)  │
│                                                      │
│  openldap                                            │
│  (172.19.0.5)                                        │
│  + macvlan .22                                       │
└──────────────────────────────────────────────────────┘
```

> [!NOTE]
> PostgreSQL (`odoo_erp`) no tiene IP MACVLAN intencionalmente: solo es accesible desde dentro de la
> red Docker interna. pfSense y los clientes de la LAN no pueden alcanzarlo directamente.

---

*Referencia de reglas detalladas: [`docs/reglas_pfsense.md`](reglas_pfsense.md)*
*Guía de instalación: [`docs/INSTALACION_COMPLETA.md`](INSTALACION_COMPLETA.md)*
