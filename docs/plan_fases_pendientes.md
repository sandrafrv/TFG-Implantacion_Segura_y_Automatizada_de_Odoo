# Plan Técnico por Fases — Hitos Pendientes del TFG

> **Documento complementario** al `implementation_plan.md` principal.  
> Cubre los cuatro hitos pendientes en el orden de implantación correcto.

---

## Fase A — VLAN + Aislamiento de Red en pfSense

**Objetivo:** Verificar y endurecer la segmentación entre VLAN 10 (LAN Clientes) y VLAN 30 (DMZ Servidor).

### Tareas

```bash
# Desde el cliente VLAN 10, comprobar que NO hay acceso directo a PostgreSQL
nc -zv 192.168.30.10 5432   # Debe fallar (bloqueado por pfSense)

# Comprobar que SÍ hay acceso a Odoo por HTTPS
curl -k -I https://192.168.30.10   # Debe devolver 200 o 302
```

**Reglas pfSense a verificar (Firewall → Rules → LAN):**

| Prioridad | Acción | Protocolo | Origen | Destino | Puerto | Descripción |
|-----------|--------|-----------|--------|---------|--------|-------------|
| 1 | PASS | TCP | LAN net | 192.168.30.10 | 80, 443, 9090 | Odoo + Cockpit |
| 2 | PASS | TCP | LAN net | 192.168.30.10 | 22 | SSH administración |
| 3 | BLOCK | TCP/UDP | LAN net | 192.168.30.0/24 | 5432 | Bloquear PostgreSQL |
| 4 | BLOCK | TCP/UDP | LAN net | 192.168.30.0/24 | 8069 | Bloquear Odoo directo |
| 5 | PASS | * | LAN net | * | * | Salida a Internet |

**Reglas pfSense a verificar (Firewall → Rules → DMZ):**

| Prioridad | Acción | Protocolo | Origen | Destino | Puerto | Descripción |
|-----------|--------|-----------|--------|---------|--------|-------------|
| 1 | PASS | TCP/UDP | DMZ net | * | 53 | DNS saliente |
| 2 | PASS | TCP | DMZ net | * | 80, 443 | HTTP/HTTPS saliente |
| 3 | BLOCK | * | DMZ net | 192.168.10.0/24 | * | Bloquear acceso a LAN |

### Validación ✅

- [ ] `nc -zv 192.168.30.10 5432` → **falla** (bloqueado)
- [ ] `nc -zv 192.168.30.10 8069` → **falla** (bloqueado)
- [ ] `curl -k https://192.168.30.10` → **200/302** (Odoo accesible)
- [ ] Desde DMZ, `ping 192.168.10.x` → **sin respuesta** (aislado)

### Entregable
Screenshot de las reglas de pfSense y salida de los comandos `nc` y `curl` guardados en `screenshots/fase_A_vlan/`.

---

## Fase B — MACVLAN en Docker ✅ COMPLETADA — 08/05/2026

**Objetivo:** Asignar IPs reales de la VLAN30 directamente a los contenedores Docker para que pfSense los vea como hosts independientes.

### Implementación realizada

**Problema encontrado:** El `docker-compose.yml` usaba formato lista (`- odoo_net`) en la sección `networks`, lo que impedía añadir la red MACVLAN con IP fija. Se resolvió reescribiendo el fichero con Python para garantizar indentación YAML correcta.

**1. Red MACVLAN creada** (interfaz física: `ens18`)
```bash
docker network create \
  --driver macvlan \
  --subnet=192.168.30.0/24 \
  --gateway=192.168.30.1 \
  --opt parent=ens18 \
  macvlan_vlan30
```

**2. `docker-compose.yml` actualizado** — cambios clave:
- Formato `networks` cambiado de lista a mapa en los 3 servicios
- Bloque `macvlan_vlan30` con IP fija añadido a `odoo-web` y `nginx-proxy`
- Red `macvlan_vlan30` declarada como `external: true` en la sección global
- PostgreSQL (`odoo_erp`) excluido intencionalmente de MACVLAN (solo red interna)

**3. Contenedores recreados**
```bash
docker compose -f docker/docker-compose.yml down
docker compose -f docker/docker-compose.yml up -d --force-recreate
```

### Resultado final

| Contenedor | Red bridge `odoo_net` | Red MACVLAN `192.168.30.x` | Justificación |
|---|---|---|---|
| `odoo_erp` (PostgreSQL) | `172.19.0.x` | ❌ Sin IP pública | Seguridad: BD no expuesta |
| `odoo-web` (Odoo 17) | `172.19.0.3` | ✅ `192.168.30.21` | IP física en la DMZ |
| `nginx-proxy` (Nginx) | `172.19.0.4` | ✅ `192.168.30.20` | Punto de entrada HTTPS |

### Verificación realizada

```bash
# Verificación desde contenedor temporal en la misma red MACVLAN
docker run --rm --network macvlan_vlan30 alpine \
  wget -qO- --no-check-certificate https://192.168.30.20 | grep "<title>"
# → <title>Odoo</title> ✅
```

### Limitación documentada (comportamiento esperado del kernel Linux)

> ⚠️ El host Debian **no puede hacer ping/curl directamente** a las IPs MACVLAN de sus propios contenedores. Es una limitación conocida del driver `macvlan` en Linux (el tráfico host→contenedor MACVLAN no pasa por la interfaz física). La verificación debe hacerse **desde otro equipo de la red o desde un contenedor temporal** en la misma red MACVLAN.

### Commits

- [`7ee1cd2`](https://github.com/sandrafrv/TFG-Implantacion_Segura_y_Automatizada_de_Odoo/commit/7ee1cd20041014799df1f458f8681bae749d0c25) — `docs: actualizar README con implementación MACVLAN completada`
- MACVLAN promovida de "Mejoras Futuras" a **Fase 3 implementada** en el README

### Entregable para la memoria
Capturar screenshot de `docker network inspect macvlan_vlan30` mostrando `odoo-web` (`.21`) y `nginx-proxy` (`.20`) y guardarlo en `screenshots/fase_B_macvlan/`.


---

## Fase C — Integración LDAP (Autenticación Centralizada en Odoo)

**Objetivo:** Centralizar la autenticación de usuarios de Odoo contra un directorio LDAP, eliminando credenciales locales por usuario.

### Subtarea C.1 — Desplegar OpenLDAP como contenedor

```bash
# Añadir servicio LDAP al docker-compose.yml
cat << 'EOF' >> /opt/erp-odoo/docker/docker-compose.yml

  ldap:
    image: osixia/openldap:1.5.0
    container_name: odoo-ldap
    restart: always
    environment:
      LDAP_ORGANISATION: "TFG ASIR"
      LDAP_DOMAIN: "tfg.com"
      LDAP_ADMIN_PASSWORD: "${LDAP_ADMIN_PASSWORD}"
    volumes:
      - /opt/erp-odoo/data/ldap_data:/var/lib/ldap
      - /opt/erp-odoo/data/ldap_config:/etc/ldap/slapd.d
    networks:
      - odoo_net
EOF

# Añadir variable al .env
echo "LDAP_ADMIN_PASSWORD=<contraseña_segura>" >> /opt/erp-odoo/docker/.env

# Levantar el nuevo servicio
docker compose -f /opt/erp-odoo/docker/docker-compose.yml up -d ldap

# Verificar que está corriendo
docker ps | grep ldap
```

### Subtarea C.2 — Crear usuarios de prueba en LDAP

```bash
# Crear archivo LDIF con usuarios
cat << 'EOF' > /tmp/usuarios_tfg.ldif
dn: ou=usuarios,dc=tfg,dc=com
objectClass: organizationalUnit
ou: usuarios

dn: uid=jdoe,ou=usuarios,dc=tfg,dc=com
objectClass: inetOrgPerson
uid: jdoe
cn: John Doe
sn: Doe
mail: jdoe@tfg.com
userPassword: {SSHA}HASH_AQUI
EOF

# Importar usuarios
docker exec odoo-ldap ldapadd \
  -x -D "cn=admin,dc=tfg,dc=com" \
  -w "${LDAP_ADMIN_PASSWORD}" \
  -f /tmp/usuarios_tfg.ldif

# Verificar que los usuarios existen
docker exec odoo-ldap ldapsearch \
  -x -D "cn=admin,dc=tfg,dc=com" \
  -w "${LDAP_ADMIN_PASSWORD}" \
  -b "dc=tfg,dc=com" "(uid=jdoe)"
```

### Subtarea C.3 — Configurar LDAP en Odoo (interfaz web)

1. En Odoo → **Ajustes → Técnico → Autenticación LDAP → Nuevo servidor LDAP**
2. Rellenar los campos:

| Campo | Valor |
|-------|-------|
| **Servidor LDAP** | `odoo-ldap` (nombre del contenedor en la red Docker) |
| **Puerto** | `389` |
| **TLS** | No (red interna Docker) |
| **DN base** | `ou=usuarios,dc=tfg,dc=com` |
| **Filtro LDAP** | `(uid=%s)` |
| **DN de bind** | `cn=admin,dc=tfg,dc=com` |
| **Contraseña de bind** | `${LDAP_ADMIN_PASSWORD}` |
| **Crear usuario si no existe** | ✅ Sí |

3. Guardar y **Probar conexión**.

### Validación ✅

```bash
# Test de bind LDAP desde el contenedor Odoo
docker exec odoo-web ldapsearch \
  -H ldap://odoo-ldap:389 \
  -x -D "cn=admin,dc=tfg,dc=com" \
  -w "${LDAP_ADMIN_PASSWORD}" \
  -b "dc=tfg,dc=com" "(uid=jdoe)"
```

- [ ] `ldapsearch` devuelve el usuario `jdoe`
- [ ] Login en Odoo con `jdoe` + contraseña LDAP → acceso OK
- [ ] Odoo crea automáticamente el perfil interno del usuario LDAP
- [ ] Audit trigger registra el nuevo usuario en `asir_audit_log`

### Entregable
Screenshot del panel LDAP en Odoo y del login exitoso en `screenshots/fase_C_ldap/`.

---

## Fase D — Debian Headless (Eliminación del Entorno Gráfico)

**Objetivo:** Convertir el servidor Debian de modo gráfico a `multi-user.target` (sin GUI), con acceso únicamente por SSH.

> ⚠️ **Hacer esta fase la última.** Con el sistema gráfico activo es más fácil diagnosticar errores en las fases anteriores.

### Subtarea D.1 — Cambiar el target de arranque

```bash
# Ver el target actual
systemctl get-default
# Resultado actual: graphical.target

# Cambiar a modo texto (sin GUI)
sudo systemctl set-default multi-user.target

# Verificar el cambio
systemctl get-default
# Resultado esperado: multi-user.target
```

### Subtarea D.2 — Eliminar el entorno gráfico

```bash
# Identificar el paquete del entorno gráfico instalado
dpkg -l | grep -E "gnome|kde|xfce|lxde|lxqt|mate"

# Eliminar GNOME (si es el entorno instalado)
sudo apt remove --purge gnome* -y
sudo apt remove --purge x11* xorg* -y
sudo apt autoremove --purge -y
sudo apt clean

# Verificar que no quedan procesos gráficos
ps aux | grep -E "Xorg|gdm|gnome" | grep -v grep
```

### Subtarea D.3 — Endurecer SSH

```bash
sudo nano /etc/ssh/sshd_config
```

Parámetros a verificar/ajustar:

```sshd_config
# Solo IPv4 (reducir superficie de ataque)
AddressFamily inet

# Puerto estándar (o cambiar a un puerto no estándar para el TFG)
Port 22

# Deshabilitar login como root por SSH
PermitRootLogin no

# Deshabilitar autenticación por contraseña (solo clave pública)
PasswordAuthentication no

# Limitar usuarios que pueden conectar por SSH
AllowUsers sandra

# Tiempo máximo sin autenticarse
LoginGraceTime 30

# Máximo de intentos de autenticación por conexión
MaxAuthTries 3

# Deshabilitar reenvío X11 (no hay GUI)
X11Forwarding no
```

```bash
# Recargar SSH con la nueva configuración
sudo systemctl reload sshd

# Verificar que SSH sigue funcionando ANTES de cerrar la sesión actual
ssh -v sandra@192.168.30.10
```

### Subtarea D.4 — Ajustar UFW para el nuevo estado

```bash
# Revisar reglas actuales
sudo ufw status verbose

# Restringir SSH solo desde la subred de administración (VLAN 10)
sudo ufw delete allow 22/tcp
sudo ufw allow from 192.168.10.0/24 to any port 22 proto tcp

# Recargar UFW
sudo ufw reload
sudo ufw status verbose
```

### Subtarea D.5 — Verificación post-headless

```bash
# Reiniciar el servidor y verificar que arranca sin GUI
sudo reboot

# Tras el reinicio, conectar por SSH:
ssh sandra@192.168.30.10

# Verificar que no hay servidor de display
echo $DISPLAY                          # Debe estar vacío
systemctl get-default                  # multi-user.target
systemctl is-active docker             # active
docker compose -f /opt/erp-odoo/docker/docker-compose.yml ps  # todos Up

# Verificar que Odoo sigue accesible desde cliente
curl -k -I https://erp.odoo.tfg.com
```

### Validación ✅

- [ ] `systemctl get-default` → `multi-user.target`
- [ ] Servidor arranca sin pantalla de login gráfica
- [ ] SSH funciona desde VLAN 10 (`192.168.10.x`)
- [ ] SSH denegado desde otras subredes
- [ ] `docker compose ps` muestra los 3 contenedores `Up`
- [ ] `https://erp.odoo.tfg.com` sigue accesible desde el cliente
- [ ] Cockpit sigue accesible en `https://192.168.30.10:9090`

### Entregable
Screenshot de la sesión SSH activa y del dashboard de Cockpit funcionando en `screenshots/fase_D_headless/`.

---

## Resumen de Hitos y Entregables

| Fase | Hito | Validación clave | Estado |
|------|------|-----------------|--------|
| **A** | VLAN aislada y reglas pfSense verificadas | `nc` timed out en 5432/8069 desde VLAN 10 | ✅ **Completada 08/05/2026** |
| **B** | MACVLAN — `nginx-proxy` `.20`, `odoo-web` `.21` | `docker network inspect` muestra IPs asignadas | ✅ **Completada 08/05/2026** |
| **C** | LDAP integrado con login en Odoo | Login con usuario LDAP exitoso | ⏳ Pendiente |
| **D** | Debian headless + SSH endurecido | Arranque sin GUI, SSH OK | ⏳ Pendiente |

> **Orden de ejecución:** A → B ✅ → C → D
