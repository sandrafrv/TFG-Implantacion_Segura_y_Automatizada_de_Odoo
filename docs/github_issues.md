# Plantillas para GitHub Issues (TFG ASIR)

> **¿Para qué sirve este archivo?**
> Este documento funciona como un banco de **plantillas estandarizadas** para la gestión ágil del proyecto mediante **GitHub Issues**. Cuando estás desarrollando y quieres organizar tu trabajo, puedes crear un "Issue" (incidencia/tarea) en GitHub pegando el contenido de uno de estos bloques. Esto asegura que cada tarea tenga objetivos claros y un checklist de verificación estructurado, facilitando el seguimiento del proyecto y demostrando profesionalidad en el uso de metodologías ágiles (DevOps/GitOps).

A continuación se presentan los Issues actualizados para los hitos finales de implementación del proyecto:

---

## Título del Issue: [Infra] Verificación de Aislamiento VLAN y Reglas pfSense

**Descripción (Copiar lo siguiente):**

### 🎯 Objetivo
Garantizar y verificar el endurecimiento perimetral mediante segmentación de red. La VLAN 10 (LAN Clientes) no debe tener acceso directo a la DMZ (VLAN 30), salvo a los puertos estrictamente expuestos por el proxy inverso.

### ✅ Tareas a realizar
- [ ] Revisar reglas en pfSense (Firewall → Rules → LAN y DMZ).
- [ ] Ejecutar prueba de conexión `nc -zv 192.168.30.10 5432` desde VLAN 10 (Debe fallar).
- [ ] Ejecutar prueba de conexión `nc -zv 192.168.30.10 8069` desde VLAN 10 (Debe fallar).
- [ ] Ejecutar prueba HTTP `curl -k -I https://192.168.30.10` desde VLAN 10 (Debe devolver 200/302).
- [ ] Validar que desde la DMZ no hay respuesta de ICMP (ping) hacia la VLAN 10 (Anti-pivoting).
- [ ] Documentar resultados y capturas en el directorio `screenshots/fase_A_vlan/`.

---

## Título del Issue: [Docker] Implementación de Redes MACVLAN

**Descripción (Copiar lo siguiente):**

### 🎯 Objetivo
Asignar IPs físicas de la subred DMZ (`192.168.30.0/24`) directamente a los contenedores expuestos (Nginx y Odoo) para que el firewall pfSense pueda aplicar reglas de granularidad de host individuales.

### ✅ Tareas a realizar
- [ ] Crear red MACVLAN en Docker vinculada a la interfaz física del servidor (ej. `ens18`).
- [ ] Reescribir sintaxis de `networks` en `docker-compose.yml` para soportar IPs estáticas.
- [ ] Asignar IP estática a `nginx-proxy` (ej. `192.168.30.20`).
- [ ] Asignar IP estática a `odoo-web` (ej. `192.168.30.21`).
- [ ] Mantener PostgreSQL en la red bridge interna (Sin IP MACVLAN) por seguridad.
- [ ] Ejecutar `docker compose up -d --force-recreate` para aplicar cambios.
- [ ] Verificar conectividad mediante un contenedor alpine temporal en la misma red MACVLAN.

---

## Título del Issue: [Identidad] Integración de Autenticación Centralizada (LDAP)

**Descripción (Copiar lo siguiente):**

### 🎯 Objetivo
Centralizar la gestión de credenciales del ERP Odoo utilizando un directorio activo OpenLDAP, eliminando la dependencia de contraseñas locales y permitiendo aprovisionamiento corporativo.

### ✅ Tareas a realizar
- [ ] Añadir servicio `osixia/openldap` al stack en `docker-compose.yml`.
- [ ] Crear estructura base de OUs en LDAP (ej. `ou=usuarios,dc=tfg,dc=com`).
- [ ] Desarrollar script `ldap_crear_usuarios.sh` para alta en lote de empleados.
- [ ] Configurar el módulo `auth_ldap` en Odoo vía interfaz web apuntando al contenedor.
- [ ] Probar validación cruzada: hacer login en Odoo con usuario y contraseña del LDAP.
- [ ] Verificar que el Audit Trigger captura correctamente la creación del perfil derivado en Odoo.

---

## Título del Issue: [SecOps] Conversión a Debian Headless y Hardening SSH

**Descripción (Copiar lo siguiente):**

### 🎯 Objetivo
Reducir la superficie de ataque del servidor en DMZ eliminando componentes innecesarios (Entorno Gráfico) y asegurando el acceso administrativo.

### ✅ Tareas a realizar
- [ ] Cambiar el target de arranque del sistema operativo a `multi-user.target`.
- [ ] Purgar paquetes gráficos (`gnome`, `x11`, `xorg`, etc.) y auto-remover dependencias.
- [ ] Modificar `/etc/ssh/sshd_config` para deshabilitar login por contraseña (`PasswordAuthentication no`).
- [ ] Modificar `/etc/ssh/sshd_config` para deshabilitar acceso root (`PermitRootLogin no`).
- [ ] Restringir por UFW el acceso al puerto 22, permitiéndolo únicamente desde IPs de administración de la VLAN 10.
- [ ] Reiniciar servidor y verificar acceso exclusivo mediante clave pública (SSH Key).

---

## Título del Issue: [DevOps] CI/CD Pipeline con GitHub Actions (IaC)

**Descripción (Copiar lo siguiente):**

### 🎯 Objetivo
Tratar la infraestructura del servidor como código (IaC), permitiendo que cualquier cambio en la arquitectura o en los scripts se valide y se despliegue automáticamente en el servidor DMZ al hacer push a la rama principal.

### ✅ Tareas a realizar
- [ ] Desarrollar workflow `ci.yml` con linter estático (`shellcheck`, validación YAML, markdownlint).
- [ ] Instalar y registrar un Self-Hosted Runner de GitHub Actions en el servidor Debian de la DMZ.
- [ ] Desarrollar workflow `deploy.yml` que se active tras un CI exitoso.
- [ ] Configurar GitHub Secrets y Variables para IPs, credenciales y rutas de red.
- [ ] Validar pipeline end-to-end: commit local -> push -> validación CI -> despliegue automático en Debian.

---

## Título del Issue: [SecOps] Endurecimiento Avanzado de Salida (Egress Filtering FQDN)

**Descripción (Copiar lo siguiente):**

### 🎯 Objetivo
Aplicar el principio de mínimo privilegio (Zero Trust) al tráfico de salida del servidor DMZ. En lugar de permitir la salida a Internet a cualquier IP por el puerto 443, se restringirá exclusivamente a los dominios necesarios (Docker Hub, GitHub, repositorios Debian) mediante un Alias FQDN en pfSense, previniendo exfiltración de datos y malware C2.

### ✅ Tareas a realizar
- [ ] Crear un Alias en pfSense llamado `SERVICIOS_PERMITIDOS_DMZ` de tipo Host(s).
- [ ] Añadir dominios de Docker Hub (`registry-1.docker.io`, `auth.docker.io`, `production.cloudflare.docker.com`).
- [ ] Añadir dominios de GitHub (`github.com`, `api.github.com`).
- [ ] Añadir repositorios base de OS (`deb.debian.org`).
- [ ] Modificar las reglas de Firewall de la DMZ (OPT1) que permitían salida HTTP/HTTPS.
- [ ] Cambiar el "Destination" de `any` a "Single host or alias" -> `SERVICIOS_PERMITIDOS_DMZ`.
- [ ] Probar un `docker pull` desde el servidor para validar que Docker puede actualizar imágenes.
- [ ] Probar conexión a una IP bloqueada (`curl -I https://1.1.1.1`) para confirmar que el Egress Filtering funciona y bloquea tráfico no listado.

---

## Título del Issue: [SecOps] Securización Extrema del Panel de pfSense (VLAN 40 + LDAP)

**Descripción (Copiar lo siguiente):**

### 🎯 Objetivo
Evitar que el cortafuegos pueda ser administrado desde la LAN de usuarios (VLAN 10) y restringir el acceso exclusivamente a la red de administración (VLAN 40). Además, implementar autenticación centralizada mediante LDAP para garantizar que solo el usuario `admin` tenga acceso al panel web, bloqueando a otros usuarios de administración como `dba`.

### ✅ Tareas a realizar
- [ ] Configurar regla en VLAN 40 (OPT2) para permitir tráfico TCP puerto 443 hacia `This Firewall (self)`.
- [ ] **Importante:** Comprobar que puedes acceder a la interfaz web de pfSense desde una máquina en la VLAN 40.
- [ ] Desactivar la regla *Anti-Lockout* en la configuración avanzada de pfSense (esto bloqueará el acceso desde la VLAN 10).
- [ ] Integrar el servidor OpenLDAP de la DMZ (`192.168.30.22`) en `User Manager -> Authentication Servers`.
- [ ] Crear el grupo `admin` en pfSense y asignarle permisos completos (`WebCfg - All pages`).
- [ ] Cambiar el método de autenticación por defecto de pfSense al servidor LDAP.
- [ ] Intentar acceder con el usuario `dba` y verificar que el acceso es **denegado**.
- [ ] Intentar acceder con el usuario `admin` y verificar que el acceso es **permitido**.
