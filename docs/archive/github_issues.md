# Plantillas para GitHub Issues — TFG ASIR 2025/2026

> Este documento contiene plantillas estandarizadas para gestionar el trabajo mediante **GitHub Issues**.
> Copiar el bloque de descripción de cada plantilla al crear un nuevo Issue en GitHub.
>
> **→ Estado del proyecto:** Ver [`docs/HISTORIAL_IMPLEMENTACION.md`](HISTORIAL_IMPLEMENTACION.md)

---

## [Infra] Verificación de Aislamiento VLAN y Reglas pfSense

**Labels sugeridos:** `infraestructura`, `seguridad`, `pfSense`

### 🎯 Objetivo

Garantizar y verificar el endurecimiento perimetral mediante segmentación de red.
La VLAN 10 (clientes) no debe tener acceso directo a la DMZ (VLAN 30) salvo a los
puertos estrictamente expuestos por el proxy inverso (Nginx).

### ✅ Tareas

- [ ] Revisar reglas en pfSense → Firewall → Rules → LAN, OPT1 (DMZ), OPT2 (VLAN 40)
- [ ] Verificar anti-lockout desactivado y acceso al panel solo desde VLAN 40
- [ ] `nc -zv 192.168.30.10 5432` desde VLAN 10 → **debe fallar** (PostgreSQL bloqueado)
- [ ] `nc -zv 192.168.30.10 8069` desde VLAN 10 → **debe fallar** (Odoo directo bloqueado)
- [ ] `nc -zv 192.168.30.10 22` desde VLAN 10 → **debe fallar** (SSH bloqueado)
- [ ] `curl -k -I https://erp.odoo.tfg.com` desde VLAN 10 → **debe devolver 200**
- [ ] `ping 192.168.10.x` desde DMZ → **sin respuesta** (anti-pivoting activo)
- [ ] `curl -k https://192.168.40.1` desde VLAN 10 → **debe fallar** (panel pfSense bloqueado)
- [ ] Capturar pantalla de las reglas en pfSense → guardar en `screenshots/fase_A_vlan/`

### 🔗 Referencias

- [`docs/reglas_pfsense.md`](reglas_pfsense.md)
- [`docs/guias/01_PFSENSE_INSTALACION.md`](guias/01_PFSENSE_INSTALACION.md)

---

## [Docker] Implementación de Redes MACVLAN

**Labels sugeridos:** `docker`, `red`, `macvlan`

### 🎯 Objetivo

Asignar IPs físicas de la subred DMZ (`192.168.30.0/24`) a los contenedores expuestos
(Nginx `.20`, Odoo `.21`, LDAP `.22`) para que pfSense aplique reglas por host individual.

### ✅ Tareas

- [ ] Crear red MACVLAN vinculada a la interfaz física del servidor (`ens18` u otra)
- [ ] Verificar sintaxis de `networks` en `docker-compose.yml` (formato mapa, no lista)
- [ ] `nginx-proxy` → IP `192.168.30.20` en red MACVLAN
- [ ] `odoo-web` → IP `192.168.30.21` en red MACVLAN
- [ ] `openldap` → IP `192.168.30.22` en red MACVLAN
- [ ] `odoo_erp` (PostgreSQL) → sin IP MACVLAN (solo red interna)
- [ ] `docker compose up -d --force-recreate` para aplicar cambios
- [ ] Verificar desde contenedor temporal: `docker run --rm --network macvlan_vlan30 alpine wget -qO- https://192.168.30.20`
- [ ] Captura de `docker network inspect macvlan_vlan30` → `screenshots/fase_B_macvlan/`

### 🔗 Referencias

- [`docs/guias/03_DOCKER_STACK.md`](guias/03_DOCKER_STACK.md)

---

## [Identidad] Integración de Autenticación Centralizada (LDAP)

**Labels sugeridos:** `ldap`, `autenticación`, `seguridad`

### 🎯 Objetivo

Centralizar la gestión de credenciales mediante OpenLDAP. Una misma cuenta
permite al empleado iniciar sesión en su PC Linux y en el ERP Odoo.

### ✅ Tareas

- [ ] Contenedor OpenLDAP activo con IP MACVLAN `192.168.30.22`
- [ ] Estructura base cargada: `ou=usuarios`, `ou=grupos`, `ou=servicios`
- [ ] ACLs aplicadas (`ldap_politica_acceso.sh`): admin → escritura, readonly → lectura, tecnico → solo contraseñas
- [ ] Usuarios de empleados creados con `ldap_crear_usuarios.sh`
- [ ] Módulo `auth_ldap` instalado en Odoo
- [ ] Conexión LDAP configurada en Odoo (IP `192.168.30.22`, bind: `cn=readonly`)
- [ ] Login en Odoo con credencial LDAP → **acceso OK**
- [ ] `configurar_cliente_ldap.sh` ejecutado en un PC de VLAN 10
- [ ] `getent passwd <uid>` en el PC cliente → **muestra el usuario LDAP**
- [ ] Login en el PC con credencial LDAP → **sesión abierta, `/home/<uid>` creado**
- [ ] Captura de login LDAP en Odoo y en PC → `screenshots/fase_C_ldap/`

### 🔗 Referencias

- [`docs/guias/05_LDAP_INSTALACION.md`](guias/05_LDAP_INSTALACION.md)
- [`docs/CONTROL_ACCESO.md`](CONTROL_ACCESO.md)

---

## [SecOps] Conversión a Debian Headless y Hardening SSH

**Labels sugeridos:** `hardening`, `seguridad`, `debian`

### 🎯 Objetivo

Reducir la superficie de ataque del servidor Debian eliminando el entorno gráfico
y asegurando el acceso administrativo exclusivamente por clave SSH desde VLAN 40.

### ✅ Tareas

- [ ] UFW instalado y activo: puertos 22, 80, 443, 9090 abiertos, deny-all el resto
- [ ] Clave SSH pública copiada al servidor (`ssh-copy-id`)
- [ ] Login SSH con clave pública verificado desde PC VLAN 40
- [ ] `PasswordAuthentication no` en `/etc/ssh/sshd_config`
- [ ] `PermitRootLogin no` en `/etc/ssh/sshd_config`
- [ ] `sshd` reiniciado y funcionando
- [ ] `systemctl set-default multi-user.target`
- [ ] Paquetes gráficos eliminados (`gnome*`, `x11*`, `xorg*`)
- [ ] Servidor reiniciado → arranca en modo texto
- [ ] SSH funciona tras el reinicio
- [ ] Docker y los 4 contenedores activos tras el reinicio
- [ ] `https://erp.odoo.tfg.com` accesible tras el reinicio
- [ ] Captura SSH activo y Cockpit funcionando → `screenshots/fase_D_headless/`

### 🔗 Referencias

- [`docs/guias/08_HARDENING_FINAL.md`](guias/08_HARDENING_FINAL.md)

---

## [DevOps] CI/CD Pipeline con GitHub Actions (IaC)

**Labels sugeridos:** `ci-cd`, `github-actions`, `devops`

### 🎯 Objetivo

Tratar la infraestructura como código: cualquier cambio en el repositorio se valida
automáticamente y se despliega en el servidor sin intervención manual.

### ✅ Tareas

- [ ] Workflow `ci.yml` activo: ShellCheck en scripts + YAML lint + Markdownlint
- [ ] Self-hosted runner instalado en Debian como servicio systemd
- [ ] Runner visible en GitHub → Settings → Actions → Runners (estado: Idle)
- [ ] Permisos de `docker/.env` ajustados para el usuario del runner (640)
- [ ] Workflow `deploy.yml` activo: dispara CD tras CI exitoso en `main`
- [ ] Prueba end-to-end: `git push` → CI ✅ → CD ✅ → contenedores actualizados
- [ ] Captura del pipeline ejecutándose en GitHub → `screenshots/fase_E_cicd/`

### 🔗 Referencias

- [`docs/guias/07_CICD_GITHUB.md`](guias/07_CICD_GITHUB.md)

---

## [SecOps] Securización del Panel de pfSense (VLAN 40 + LDAP)

**Labels sugeridos:** `pfSense`, `seguridad`, `ldap`

### 🎯 Objetivo

Restringir el panel web de pfSense exclusivamente a la red de administración (VLAN 40)
e implementar autenticación LDAP para que solo el usuario `admin` pueda acceder.

### ✅ Tareas

- [ ] Interfaz OPT2 (VLAN 40) configurada con IP `192.168.40.1/24` y DHCP activo
- [ ] Regla en OPT2: `VLAN40 → This Firewall :443 → PASS`
- [ ] Acceso al panel comprobado desde una IP de VLAN 40 (`https://192.168.40.1`)
- [ ] Servidor LDAP añadido en System → User Manager → Authentication Servers
- [ ] Grupo `admin` creado en pfSense con privilegio `WebCfg - All pages`
- [ ] Authentication Server cambiado a `OpenLDAP DMZ`
- [ ] Anti-Lockout Rule desactivada en System → Advanced → Admin Access
- [ ] Login con usuario `dba` → **denegado** ✅
- [ ] Login con usuario `admin` → **acceso concedido** ✅
- [ ] Login en panel desde VLAN 10 → **no accesible** ✅

### 🔗 Referencias

- [`docs/guias/01_PFSENSE_INSTALACION.md`](guias/01_PFSENSE_INSTALACION.md) — sección 1.10–1.11
- [`docs/GUIA_AISLAMIENTO_ADMIN.md`](GUIA_AISLAMIENTO_ADMIN.md)

---

## [Control Acceso] Configuración de Roles y 3 Capas de Seguridad

**Labels sugeridos:** `odoo`, `ldap`, `seguridad`, `roles`

### 🎯 Objetivo

Implementar el modelo de seguridad en 3 capas: Nginx filtra rutas por IP/VLAN,
Odoo controla el tipo de usuario, y los grupos LDAP definen los módulos visibles.

### ✅ Tareas

- [ ] Nginx recargado con restricciones de rutas activas
- [ ] `/web/database/manager` desde VLAN 10 → **403 Forbidden**
- [ ] `/web/tests` → **403 Forbidden** (todos)
- [ ] `/web?debug=` desde VLAN 10 → **403 Forbidden**
- [ ] Usuarios Odoo creados con `odoo_crear_usuarios.sh`
- [ ] Login becario → solo CRM, sin botón Eliminar
- [ ] Login ventas → CRM + Ventas + Facturas
- [ ] Login admin (VLAN 40) → acceso total + panel BD
- [ ] Readonly LDAP no puede modificar → error `Insufficient access (50)`
- [ ] Técnico puede cambiar contraseña de empleado con `ldappasswd`

### 🔗 Referencias

- [`docs/CONTROL_ACCESO.md`](CONTROL_ACCESO.md)

---

*Proyecto: TFG ASIR 2025/2026 — Sandra Fradejas Avedillo — IES Cañaveral*
