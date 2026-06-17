# Control de Acceso por Roles — ASIR 2025/2026

**TechSolutions S.L.** | Modelo de seguridad en 3 capas — Autenticación nativa Odoo

> [!NOTE]
> A partir de la versión 1.7 del proyecto, **LDAP no está activo en el despliegue**.
> La autenticación se realiza mediante los usuarios nativos de Odoo.
> Ver `extras/ldap/README.md` si quieres retomar la integración en el futuro.

---

## Arquitectura de Red y Acceso

```
Internet / WAN
   │
 [pfSense]
 ├── VLAN 10 (192.168.10.0/24) ── Usuarios del ERP
 ├── VLAN 40 (192.168.40.0/24) ── Admin + DBA + PostgreSQL
 └── VLAN 30 (192.168.30.0/24) ── DMZ
    └── .10 → Debian 13 Host (Docker engine, SSH :22, Cockpit :9090)
          ├── odoo-web (contenedor Docker, puerto :8069 interno)
          └── nginx-proxy (contenedor Docker, puertos :80/:443 mapeados)

 [VLAN 40]
    └── .10 → VM3 PostgreSQL (BD nativa, sin acceso desde VLAN 10)
```

> [!NOTE]
> La arquitectura original incluía MACVLAN (IPs `.20` y `.21`). Fue eliminada
> porque VMware host-only no soporta modo promiscuo. Actualmente nginx y odoo-web
> son accesibles a través de port mapping en el host `192.168.30.10`.

### Principio de acceso por VLAN

| VLAN | Quién | Puede acceder a |
|------|-------|-----------------|
| **VLAN 10** | Usuarios/empleados de TechSolutions | Odoo ERP vía nginx `192.168.30.10` (HTTPS) |
| **VLAN 40** | Administradores del sistema, DBAs | SSH :22, Cockpit :9090, PostgreSQL :5432, panel Odoo admin |
| **WAN** | Internet público | Solo login Odoo (HTTPS 443) |

---

## Las 3 Capas de Seguridad

El modelo aplica **defensa en profundidad**: aunque una capa falle, las otras siguen protegiendo.

```
[Petición HTTPS del usuario]
      │
  ┏━━━━━━┳━━━━━━┓
  ┃ CAPA C: Nginx ┃ ← Primera barrera: filtra rutas por IP/VLAN
  ┗━━━━━━┻━━━━━━┛
      │ (solo rutas permitidas pasan)
  ┏━━━━━━┳━━━━━━┓
  ┃ CAPA B: Odoo ┃ ← Segunda barrera: tipo de usuario (Portal/Interno/Admin)
  ┃ Tipo usuario ┃
  ┗━━━━━━┻━━━━━━┛
      │ (solo tipo correcto accede)
  ┏━━━━━━┳━━━━━━┓
  ┃ CAPA A: Odoo ┃ ← Tercera barrera: grupos = qué módulos y acciones ve
  ┃ Grupos/Roles ┃
  ┗━━━━━━┻━━━━━━┛
```

---

## Capa C — Nginx: Restricción de Rutas por VLAN

Archivo: `config_nginx/odoo_proxy.conf`

### Rutas restringidas

| Ruta | Permitido desde | Bloqueado para | Riesgo sin restricción |
|------|----------------|----------------|----------------------|
| `/web/database/manager` | Solo VLAN 40 | VLAN 10 + WAN | Borrar/crear bases de datos |
| `/web/database/selector` | Solo VLAN 40 | VLAN 10 + WAN | Exposición de nombres de BD |
| `/odoo/action-base_setup` | Solo VLAN 40 | VLAN 10 + WAN | Reconfigurar Odoo desde cero |
| `/web/tests` | Nadie | Todos | Exposición de estructura interna |
| `/web?debug=` | Solo VLAN 40 | VLAN 10 + WAN | Información técnica del sistema |

### Verificar desde línea de comandos

```bash
# Desde VLAN 10 — debe devolver 403 Forbidden
curl -k https://erp.odoo.com/web/database/manager
# Resultado esperado: 403 Forbidden

# Desde VLAN 40 — debe cargar el panel
curl -k https://erp.odoo.com/web/database/manager
# Resultado esperado: 200 OK (panel de administración de BD)

# Tests: siempre bloqueado
curl -k https://erp.odoo.com/web/tests
# Resultado esperado: 403 Forbidden
```

---

## Capa B — Odoo: Tipo de Usuario

Campo `sel_groups_1_10_11` en `res.users`:

| Valor | Tipo | Quién lo usa |
|-------|------|--------------|
| `1` | **Portal** | Clientes externos (acceso solo a `/my/`) |
| `10` | **Interno** | Todos los empleados de VLAN 10 |
| `11` | **Admin** | Administrador del sistema (VLAN 40) |

---

## Capa A — Odoo: Grupos por Rol (Módulos accesibles)

Script: `scripts/odoo/odoo_crear_usuarios.sh`

### VLAN 10 — Usuarios del ERP

| Rol | Módulos visibles | Puede eliminar | Tipo Odoo |
|-----|-----------------|----------------|-----------|
| **Becario** | Solo CRM (lectura) | ❌ Nunca | Interno (10) |
| **Ventas** | CRM, Pipeline, Contactos, Facturas de cliente | ✅ Solo sus registros | Interno (10) |
| **RRHH** | Empleados, Contratos, Nóminas | ✅ Solo su departamento | Interno (10) |
| **Almacén** | Inventario, Recepciones, Pedidos de compra | ✅ Solo su área | Interno (10) |
| **Técnico** | Inventario, Soporte técnico | ✅ Solo tickets asignados | Interno (10) |
| **Jefe Ventas** | CRM + Ventas completo + aprobaciones | ✅ Dentro de su dpto. | Interno (10) |
| **Jefe RRHH** | RRHH completo + aprobaciones | ✅ Dentro de su dpto. | Interno (10) |
| **Jefe Almacén** | Inventario + Compras completo + aprobaciones | ✅ Dentro de su dpto. | Interno (10) |

### VLAN 40 — Gestión del servidor

| Rol | Acceso en Odoo | Acceso al servidor | Tipo Odoo |
|-----|---------------|-------------------|-----------|
| **Admin** | Administrador total | SSH, Cockpit, Docker, pfSense, PostgreSQL | Admin (11) |
| **DBA** | Sin acceso UI Odoo | Solo PostgreSQL + backups en VM3 | Interno (10) |
| **API** | Solo XML-RPC | Solo curl/scripts | Interno (10) |

### Grupos Odoo asignados por rol

| Rol | XML-IDs de grupos Odoo |
|-----|----------------------|
| `becario` | `base.group_user` |
| `ventas` | `base.group_user`, `sales_team.group_sale_salesman`, `account.group_account_invoice` |
| `rrhh` | `base.group_user`, `hr.group_hr_user` |
| `almacen` | `base.group_user`, `stock.group_stock_user`, `purchase.group_purchase_user` |
| `tecnico` | `base.group_user`, `stock.group_stock_user` |
| `jefe_ventas` | `base.group_user`, `sales_team.group_sale_manager`, `account.group_account_invoice` |
| `jefe_rrhh` | `base.group_user`, `hr.group_hr_manager` |
| `jefe_almacen` | `base.group_user`, `stock.group_stock_manager`, `purchase.group_purchase_manager` |
| `api` | `base.group_user` |

> [!NOTE]
> En Odoo 17, `crm.group_crm_salesperson` y `crm.group_crm_manager` no existen
> como XML-IDs independientes. El acceso a CRM se gestiona mediante
> `sales_team.group_sale_salesman` y `sales_team.group_sale_manager`.

---

## Autenticación — Estado actual y mejora futura

### Estado actual: autenticación nativa de Odoo

Todos los usuarios se autentican directamente con su contraseña de la base de datos de Odoo (tabla `res_users` en PostgreSQL `192.168.40.10`). El módulo `auth_ldap` **no está instalado** en esta versión.

**Gestión de usuarios:**
```bash
# Crear usuarios con roles predefinidos
bash scripts/odoo/odoo_crear_usuarios.sh

# O directamente desde la UI de Odoo
# Configuración → Usuarios y Compañías → Usuarios
```

### Mejora futura: integración LDAP

> [!TIP]
> **LDAP (OpenLDAP) fue implementado durante el desarrollo del proyecto pero retirado del despliegue
> activo por complejidad operativa.** Ver `extras/ldap/README.md` para:
> Razón exacta de por qué se retiró
> Cómo retomarlo con un contenedor adicional
> La estructura de árbol LDAP diseñada (`extras/ldap/estructura.ldif`)
> Los scripts de configuración disponibles en `extras/ldap/`
>
> La integración permitiría: una sola cuenta por empleado para el PC + Odoo,
> gestión centralizada de contraseñas y acceso por grupo departamental.

---

## Reglas pfSense relevantes para el control de acceso

| Prioridad | Acción | Protocolo | Origen | Destino | Puerto | Descripción |
|-----------|--------|-----------|--------|---------|--------|-------------|
| 1 | ✅ Pass | TCP | VLAN 40 | `192.168.30.10` | 22 | SSH al servidor Debian |
| 2 | ✅ Pass | TCP | VLAN 40 | `192.168.30.10` | 9090 | Cockpit (gestión visual) |
| 3 | ✅ Pass | TCP | VLAN 40 | `192.168.30.10` | 443 | Odoo admin completo |
| 4 | ✅ Pass | TCP | VLAN 40 | `192.168.40.10` | 5432 | Acceso DBA directo a PostgreSQL |
| 5 | ✅ Pass | TCP | VLAN 30 | `192.168.40.10` | 5432 | Odoo → BD externa |
| 6 | ❌ Block | TCP | VLAN 10 | `192.168.40.10` | 5432 | Usuarios NO tocan la BD |
| 7 | ❌ Block | TCP | VLAN 10 | `192.168.30.10` | 8069 | No acceso directo a Odoo |
| 8 | ❌ Block | * | DMZ | VLAN 10 | * | Anti-pivoting |
| 9 | ❌ Block | * | WAN | `192.168.40.10` | 5432 | BD nunca expuesta a Internet |

---

## Flujo completo de autenticación (versión actual)

```
Empleado (VLAN 10, 192.168.10.x)
  │
  │ 1. Abre https://erp.odoo.com
  │   DNS → 192.168.30.10 (pfSense DNS Resolver)
  │
  ▼
[pfSense — VLAN 10 → DMZ]
  │ Regla: VLAN 10 → .10 :443 → PASS
  │
  ▼
[Nginx — 192.168.30.10:443]    ← CAPA C
  │ Ruta /web/database → 403 (VLAN 10 bloqueada)
  │ Ruta / → proxy_pass a odoo-web:8069
  │
  ▼
[Odoo 17 — odoo-web:8069]
  │ 2. Login: usuario y contraseña nativos de Odoo
  │ Odoo consulta res_users en PostgreSQL (192.168.40.10)
  │
  ▼
[Odoo — Sesión iniciada]      ← CAPA B + CAPA A
  │ Tipo: Interno (10)
  │ Grupos: según su rol
  │ Menús visibles: solo los de su departamento
  │
  ▼
Usuario ve su panel personalizado ✅
```

---

## Checklist de verificación

| Prueba | Comando/Acción | Resultado esperado |
|--------|---------------|-------------------|
| Nginx bloquea panel BD desde VLAN 10 | `curl -k https://erp.odoo.com/web/database/manager` | `403 Forbidden` |
| Nginx permite panel BD desde VLAN 40 | Mismo curl desde PC en VLAN 40 | `200 OK` |
| Nginx bloquea `/web/tests` | `curl -k https://erp.odoo.com/web/tests` | `403 Forbidden` |
| Becario no ve botón Eliminar | Login con `becario@...` | Sin botón Eliminar en CRM |
| Becario no ve módulo Ventas | Login con `becario@...` | Solo menú CRM visible |
| Ventas ve sus módulos | Login con `ventas@...` | CRM + Ventas + Facturas |
| VLAN 10 no accede a PostgreSQL | `nc -zv 192.168.40.10 5432` desde VLAN 10 | Timeout |
| Odoo conecta con BD externa | `psql -h 192.168.40.10 -U odoo -d odoo_erp` desde VM2 | Conexión OK |

---

*ASIR 2025/2026 — IES Cañaveral*
