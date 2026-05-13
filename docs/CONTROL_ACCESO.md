# Control de Acceso por Roles — TFG ASIR 2025/2026

**TechSolutions S.L.** | Modelo de seguridad en 3 capas + LDAP centralizado

---

## Arquitectura de Red y Acceso

```
Internet / WAN
      │
  [pfSense]
  ├── VLAN 10 (192.168.10.0/24) ── Usuarios del ERP
  ├── VLAN 40 (192.168.40.0/24) ── Admin + DBA (gestión del servidor)
  └── VLAN 30 (192.168.30.0/24) ── DMZ
        ├── .10 → Debian 13 Host  (Docker engine, SSH, Cockpit :9090)
        ├── .20 → nginx-proxy     (MACVLAN — puerta de entrada HTTPS)
        ├── .21 → odoo-web        (MACVLAN — aplicación Odoo 17)
        └── .22 → openldap        (MACVLAN — directorio de usuarios)
```

### Principio de acceso por VLAN

| VLAN | Quién | Puede acceder a |
|------|-------|-----------------|
| **VLAN 10** | Usuarios/empleados de TechSolutions | PC de trabajo (login SO vía LDAP) + Odoo ERP (vía nginx .20) |
| **VLAN 40** | Administradores del sistema, DBAs | Servidor (SSH :22, Cockpit :9090), panel BD Odoo, LDAP admin |
| **WAN** | Internet público | Solo login Odoo (HTTPS 443) |

---

## Inicio de Sesión en el Sistema Operativo (SSSD + PAM + NSS)

Script: `scripts/configurar_cliente_ldap.sh` — **ejecutar en cada PC de VLAN 10**

### Qué permite esto

Que un empleado use **el mismo usuario y contraseña LDAP** para:
1. Iniciar sesión en su PC (login de escritorio Linux)
2. Entrar a Odoo desde el navegador

Una sola cuenta centralizada → un cambio de contraseña en LDAP actualiza ambos accesos.

### Tecnología: SSSD

**SSSD** (System Security Services Daemon) es el intermediario entre el sistema operativo y el servidor LDAP. Reemplaza los paquetes antiguos `libnss-ldap` + `libpam-ldap` con ventajas importantes:

| Característica | SSSD |
|----------------|------|
| **Caché offline** | ✅ El usuario puede iniciar sesión aunque el LDAP esté caído temporalmente |
| **NSS** | ✅ Resuelve `getent passwd`, `getent group` desde LDAP |
| **PAM** | ✅ Gestiona autenticación en login, sudo, screensaver, etc. |
| **Home automático** | ✅ Crea `/home/<uid>` en el primer inicio de sesión |
| **Seguridad** | ✅ Las credenciales no viajan en claro internamente |

### Flujo completo de login en el PC

```
Empleado escribe uid + contraseña en el login del PC
                │
    ┌───────────▼──────────────┐
    │  PAM (pam_sss.so)        │  ← Intercepta el intento de login
    └───────────┬──────────────┘
                │ Pregunta a SSSD
    ┌───────────▼──────────────┐
    │  SSSD                    │  ← ¿Tengo la respuesta en caché?
    │  (System Security Svc)   │       SÍ → responde directamente
    └───────────┬──────────────┘       NO → consulta al LDAP
                │ Consulta (ldap://192.168.30.22:389)
    ┌───────────▼──────────────┐
    │  OpenLDAP (.22)          │  ← Verifica uid + contraseña
    │  cn=readonly busca user  │      en ou=usuarios,dc=tfg,dc=com
    └───────────┬──────────────┘
                │ Respuesta: OK / FAIL
    ┌───────────▼──────────────┐
    │  SSSD → PAM → Login      │  ← Si OK: abre sesión
    │  pam_mkhomedir           │      crea /home/<uid> si no existe
    └──────────────────────────┘
```

### Instalación en un cliente (una sola vez por máquina)

```bash
# Ejecutar como root en el PC de VLAN 10
sudo bash /opt/erp-odoo/scripts/configurar_cliente_ldap.sh

# El script pide:
#   1. URI del servidor LDAP (defecto: ldap://192.168.30.22)
#   2. Base DN (defecto: dc=tfg,dc=com)
#   3. Contraseña del usuario readonly
#   4. (Opcional) Grupo LDAP que puede iniciar sesión en este PC
```

### Restricción de acceso por grupo (opcional)

Se puede limitar qué grupo LDAP puede iniciar sesión en un PC concreto:

```bash
# Solo el grupo "ventas" puede iniciar sesión en los PCs de ventas
# (el script pregunta esto durante la instalación)
Grupo de acceso: ventas

# En /etc/sssd/sssd.conf queda:
ldap_access_filter = (&(objectClass=posixAccount)(memberOf=cn=ventas,ou=grupos,dc=tfg,dc=com))
```

Esto permite, por ejemplo:
- Los PCs del almacén solo los usa el grupo `almacen` y `jefe_almacen`
- Los PCs de dirección los usa solo `jefe_ventas`, `jefe_rrhh`, `jefe_almacen`
- Los becarios solo pueden entrar en los PCs designados para ellos

### Permisos Linux de cada grupo en el PC

Una vez dentro del sistema, los permisos locales del PC se controlan con grupos POSIX. Para que un grupo LDAP tenga `sudo` en una máquina, añadir en `/etc/sudoers.d/ldap_grupos`:

```bash
# Solo el grupo admin de LDAP puede hacer sudo completo
%admin ALL=(ALL:ALL) ALL

# El grupo tecnico puede reiniciar servicios sin contraseña
%tecnico ALL=(ALL) NOPASSWD: /bin/systemctl restart *, /bin/systemctl status *
```

### Verificar que funciona

```bash
# Ver si el sistema resuelve usuarios de LDAP
getent passwd <uid_del_usuario>
# Resultado esperado: uid:x:2001:2000:Nombre Completo:/home/uid:/bin/bash

# Probar autenticación sin hacer login gráfico
su - <uid_del_usuario>
# Pedirá la contraseña LDAP y abrirá una shell

# Ver los grupos LDAP disponibles en el sistema
getent group

# Ver logs de SSSD en tiempo real (útil para depurar)
journalctl -u sssd -f

# Forzar a SSSD a limpiar su caché y reconectar con el LDAP
sss_cache -E && systemctl restart sssd
```

### Qué pasa si el servidor LDAP cae

Con `cache_credentials = true` en SSSD:
- Si el usuario ya inició sesión antes → puede seguir iniciando sesión hasta que expire la caché (1 hora por defecto)
- Si nunca inició sesión → no puede entrar hasta que el LDAP vuelva

```bash
# Ver cuánto tiempo lleva SSSD sin contactar el servidor
sssctl domain-status tfg.com
```

### Limitación actual: Equipos Windows

El diseño actual con **OpenLDAP estándar** permite el inicio de sesión nativo en clientes Linux (mediante SSSD). Sin embargo, **Windows no admite OpenLDAP directamente** para el inicio de sesión del sistema operativo. 

En la infraestructura actual, si se conecta un PC Windows a la VLAN 10:
- El inicio de sesión en el PC Windows debe realizarse con una **cuenta local**.
- El acceso al ERP (`https://erp.odoo.tfg.com`) en el navegador **sí** utilizará las credenciales de LDAP.

> [!TIP]
> **Mejora Futura: Integración de Active Directory (Samba 4)**
> Para permitir que los equipos Windows se unan al dominio y utilicen las cuentas de red para el inicio de sesión del sistema operativo, se propone como futura mejora **sustituir OpenLDAP por Samba 4 AD DC**. 
> Samba 4 proporciona compatibilidad nativa con Active Directory, lo que permite centralizar completamente la gestión tanto de clientes Linux (SSSD con el proveedor `ad`) como de clientes Windows, además de proporcionar servicios de DNS requeridos por AD y autenticación mediante Kerberos.

---

## Las 3 Capas de Seguridad

El modelo aplica **defensa en profundidad**: aunque una capa falle, las otras siguen protegiendo.

```
[Petición HTTPS del usuario]
           │
    ┌──────▼────────┐
    │  CAPA C: Nginx │  ← Primera barrera: filtra rutas por IP/VLAN
    └──────┬────────┘
           │ (solo rutas permitidas pasan)
    ┌──────▼────────┐
    │  CAPA B: Odoo  │  ← Segunda barrera: tipo de usuario (Portal/Interno/Admin)
    │  Tipo usuario  │
    └──────┬────────┘
           │ (solo tipo correcto accede)
    ┌──────▼────────┐
    │  CAPA A: Odoo  │  ← Tercera barrera: grupos = qué módulos y acciones ve
    │  Grupos/Roles  │
    └───────────────┘
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
curl -k https://erp.odoo.tfg.com/web/database/manager
# Resultado esperado: 403 Forbidden

# Desde VLAN 40 — debe cargar el panel
curl -k https://erp.odoo.tfg.com/web/database/manager
# Resultado esperado: 200 OK (panel de administración de BD)

# Tests: siempre bloqueado
curl -k https://erp.odoo.tfg.com/web/tests
# Resultado esperado: 403 Forbidden
```

---

## Capa B — Odoo: Tipo de Usuario

Campo `sel_groups_1_10_11` en `res.users`:

| Valor | Tipo | Quién lo usa |
|-------|------|--------------|
| `1` | **Portal** | Clientes externos (acceso solo a `/my/` — portal público) |
| `10` | **Interno** | Todos los empleados de VLAN 10 |
| `11` | **Admin** | Administrador del sistema (VLAN 40) |

> [!NOTE]
> El tipo "Portal" se reserva para clientes de TechSolutions que accedan al portal de pedidos/facturas de Odoo (`/my/`). No se usa para empleados internos.

---

## Capa A — Odoo: Grupos por Rol (Módulos accesibles)

Script: `scripts/odoo_crear_usuarios.sh`

### VLAN 10 — Usuarios del ERP

| Rol | Módulos visibles | Puede eliminar | Tipo Odoo |
|-----|-----------------|----------------|-----------|
| **Becario** | Solo CRM (lectura), sin botones de creación/eliminación | ❌ Nunca | Interno (10) |
| **Ventas** | CRM, Pipeline, Contactos, Facturas de cliente | ✅ Solo sus registros | Interno (10) |
| **RRHH** | Empleados, Contratos, Nóminas | ✅ Solo su departamento | Interno (10) |
| **Almacén** | Inventario, Recepciones, Pedidos de compra | ✅ Solo su área | Interno (10) |
| **Técnico** | Inventario, Soporte técnico | ✅ Solo tickets asignados | Interno (10) |
| **Jefe Ventas** | CRM + Ventas completo + aprobaciones de equipo | ✅ Dentro de su dpto. | Interno (10) |
| **Jefe RRHH** | RRHH completo + aprobaciones de contratos | ✅ Dentro de su dpto. | Interno (10) |
| **Jefe Almacén** | Inventario + Compras completo + aprobaciones | ✅ Dentro de su dpto. | Interno (10) |

### VLAN 40 — Gestión del servidor

| Rol | Acceso en Odoo | Acceso al servidor | Tipo Odoo |
|-----|---------------|-------------------|-----------|
| **Admin** | Administrador total (todos los módulos + ajustes) | SSH, Cockpit, Docker, pfSense | Admin (11) |
| **DBA** | Sin acceso UI Odoo (solo BD vía herramienta externa) | Solo PostgreSQL + backups | Interno (10) |
| **API** | Solo XML-RPC (sin menú UI visible) | Solo curl/scripts | Interno (10) |

### Grupos Odoo asignados por rol

| Rol | XML-IDs de grupos Odoo |
|-----|----------------------|
| `becario` | `base.group_user` |
| `ventas` | `base.group_user`, `crm.group_crm_salesperson`, `sales_team.group_sale_salesman`, `account.group_account_invoice` |
| `rrhh` | `base.group_user`, `hr.group_hr_user` |
| `almacen` | `base.group_user`, `stock.group_stock_user`, `purchase.group_purchase_user` |
| `tecnico` | `base.group_user`, `stock.group_stock_user` |
| `jefe_ventas` | `base.group_user`, `crm.group_crm_manager`, `sales_team.group_sale_manager`, `account.group_account_invoice` |
| `jefe_rrhh` | `base.group_user`, `hr.group_hr_manager` |
| `jefe_almacen` | `base.group_user`, `stock.group_stock_manager`, `purchase.group_purchase_manager` |
| `api` | `base.group_user` |

---

## LDAP — Directorio Centralizado de Usuarios

Contenedor: `openldap` (IP MACVLAN: `192.168.30.22`)

### Estructura del árbol LDAP

```
dc=tfg,dc=com
├── ou=usuarios          ← Cuentas personales de empleados
├── ou=grupos            ← Grupos departamentales
│   ├── cn=becarios      (VLAN 10)
│   ├── cn=ventas        (VLAN 10)
│   ├── cn=rrhh          (VLAN 10)
│   ├── cn=almacen       (VLAN 10)
│   ├── cn=tecnico       (VLAN 10) ← puede cambiar contraseñas
│   ├── cn=jefe_ventas   (VLAN 10)
│   ├── cn=jefe_rrhh     (VLAN 10)
│   ├── cn=jefe_almacen  (VLAN 10)
│   ├── cn=admin         (VLAN 40) ← acceso total al servidor
│   └── cn=dba           (VLAN 40) ← solo base de datos
└── ou=servicios         ← Cuentas técnicas (readonly, api)
```

### ACLs de LDAP (configuradas por `ldap_politica_acceso.sh`)

| Cuenta | Permisos | Para qué se usa |
|--------|----------|-----------------|
| `cn=admin` | Escritura total | Administración del directorio (solo VLAN 40) |
| `cn=tecnico` (grupo) | `write` solo en `userPassword` de `ou=usuarios` | Cambio de contraseñas de empleados VLAN 10 |
| `cn=readonly` | Lectura de todo el árbol | Odoo autentica usuarios; PAM en máquinas VLAN 10 |
| Anónimo | Solo `auth` en `userPassword` | Verificación de credenciales en login |
| Resto | Ninguno | `deny all` |

> [!IMPORTANT]
> El técnico **puede cambiar contraseñas** de los empleados de VLAN 10 usando `ldappasswd`, pero **no puede crear, modificar ni eliminar** entradas de usuario. Esta restricción la aplica la ACL número 3 del script `ldap_politica_acceso.sh`.

### Verificar autenticación LDAP

```bash
# Probar autenticación de un usuario de VLAN 10
ldapwhoami -H ldap://192.168.30.22 \
  -D "uid=empleado,ou=usuarios,dc=tfg,dc=com" -W

# Técnico cambia contraseña de un empleado (tiene permiso)
ldappasswd -H ldap://192.168.30.22 \
  -D "uid=tecnico,ou=usuarios,dc=tfg,dc=com" -W \
  -S "uid=becario,ou=usuarios,dc=tfg,dc=com"

# Readonly no puede modificar (debe fallar con Insufficient Access)
ldapmodify -H ldap://192.168.30.22 \
  -D "cn=readonly,dc=tfg,dc=com" -w "password" <<EOF
dn: uid=test,ou=usuarios,dc=tfg,dc=com
changetype: modify
replace: cn
cn: Test
EOF
# Resultado esperado: ldap_modify: Insufficient access (50)
```

---

## Reglas pfSense para VLAN 40

Interfaz `OPT2` (VLAN 40 — Red de Administración):

| Prioridad | Acción | Protocolo | Origen | Destino | Puerto | Descripción |
|-----------|--------|-----------|--------|---------|--------|-------------|
| 1 | ✅ Pass | TCP | VLAN 40 | 192.168.30.10 | 22 | SSH al servidor Debian |
| 2 | ✅ Pass | TCP | VLAN 40 | 192.168.30.10 | 9090 | Cockpit (gestión visual) |
| 3 | ✅ Pass | TCP | VLAN 40 | 192.168.30.20 | 443 | Odoo admin completo (sin restricciones Nginx) |
| 4 | ✅ Pass | TCP | VLAN 40 | 192.168.30.22 | 389, 636 | LDAP admin (lectura + escritura) |
| 5 | ✅ Pass | TCP | VLAN 40 | * | 80, 443 | Actualizaciones internet |
| 6 | ❌ Block | * | VLAN 40 | 192.168.10.0/24 | * | Anti-pivoting a VLAN 10 |
| 7 | ❌ Block | * | VLAN 40 | * | * | Deny all |

Restricciones adicionales desde **VLAN 10** hacia LDAP:

| Prioridad | Acción | Protocolo | Origen | Destino | Puerto | Descripción |
|-----------|--------|-----------|--------|---------|--------|-------------|
| + | ✅ Pass | TCP | VLAN 10 | 192.168.30.22 | 389 | LDAP autenticación (solo lectura vía cn=readonly) |
| + | ❌ Block | TCP | VLAN 10 | 192.168.30.22 | 636 | LDAPS admin bloqueado desde VLAN 10 |

---

## Flujo completo de autenticación de un empleado

```
Empleado (VLAN 10, 192.168.10.x)
    │
    │  1. Abre https://erp.odoo.tfg.com en el navegador
    │     DNS → 192.168.30.20 (pfSense DNS Resolver)
    │
    ▼
[pfSense — VLAN 10 → DMZ]
    │  Regla: VLAN 10 → .20 :443 → PASS
    │
    ▼
[Nginx — 192.168.30.20:443]   ← CAPA C
    │  Ruta /web/database → 403 (VLAN 10 bloqueada)
    │  Ruta / → proxy_pass a odoo-web:8069
    │
    ▼
[Odoo 17 — odoo-web:8069]
    │  2. Login: usuario LDAP (ej: uid=jdoe)
    │
    ▼
[LDAP — 192.168.30.22:389]
    │  Odoo usa cn=readonly para verificar la contraseña
    │  Bind: uid=jdoe, password OK → autenticado
    │
    ▼
[Odoo — Sesión iniciada]        ← CAPA B + CAPA A
    │  Tipo: Interno (10)
    │  Grupos: según su rol (ventas → CRM + Ventas + Facturas)
    │  Menús visibles: solo los de su rol
    │
    ▼
Usuario ve su panel personalizado según su departamento ✅
```

---

## Orden de ejecución para aplicar el control de acceso

```bash
# 1. Actualizar docker/.env con las nuevas variables LDAP
#    (LDAP_ADMIN_PASSWORD y LDAP_READONLY_PASSWORD)
nano docker/.env

# 2. Levantar el contenedor OpenLDAP
docker compose -f docker/docker-compose.yml up -d ldap

# 3. Crear la estructura LDAP (OUs y grupos)
#    El LDIF se carga automáticamente al arrancar el contenedor

# 4. Configurar las ACLs de LDAP
bash scripts/ldap_politica_acceso.sh

# 5. Crear usuarios en LDAP con sus grupos
bash scripts/ldap_crear_usuarios.sh

# 6. Recargar Nginx con los nuevos bloques de restricción
docker exec nginx-proxy nginx -s reload
docker exec nginx-proxy nginx -t   # Verificar sintaxis

# 7. Crear usuarios en Odoo con sus roles
bash scripts/odoo_crear_usuarios.sh

# 8. Verificar restricciones
curl -k https://erp.odoo.tfg.com/web/database/manager  # → 403
curl -k https://erp.odoo.tfg.com/web/tests             # → 403
```

---

## Checklist de verificación

| Prueba | Comando/Acción | Resultado esperado |
|--------|---------------|-------------------|
| Nginx bloquea panel BD desde VLAN 10 | `curl -k https://erp.odoo.tfg.com/web/database/manager` | `403 Forbidden` |
| Nginx permite panel BD desde VLAN 40 | Mismo curl desde PC en VLAN 40 | `200 OK` (formulario) |
| Nginx bloquea `/web/tests` | `curl -k https://erp.odoo.tfg.com/web/tests` | `403 Forbidden` |
| Becario no ve botón Eliminar | Login con `becario@erp.odoo.tfg.com` | Sin botón Eliminar en CRM |
| Becario no ve módulo Ventas | Login con `becario@erp.odoo.tfg.com` | Solo menú CRM visible |
| Ventas ve sus módulos | Login con `ventas@erp.odoo.tfg.com` | CRM + Ventas + Facturas |
| Jefe Ventas tiene aprobaciones | Login con `jefe.ventas@erp.odoo.tfg.com` | Botones de aprobación visibles |
| Técnico puede cambiar contraseña LDAP | `ldappasswd` con credenciales técnico | Éxito |
| Readonly no puede modificar LDAP | `ldapmodify` con credenciales readonly | `Insufficient access (50)` |
| DBA no tiene UI Odoo | Login con `dba@erp.odoo.tfg.com` | Solo CRM base, sin módulos extra |
