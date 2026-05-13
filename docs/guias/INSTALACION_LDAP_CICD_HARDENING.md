# Guía Avanzada — LDAP + CI/CD + Hardening

**← Volver a:** [`docs/INSTALACION_COMPLETA.md`](../INSTALACION_COMPLETA.md)
**← Fase anterior:** [`guias/INSTALACION_SERVIDOR.md`](INSTALACION_SERVIDOR.md)

---

## PARTE 1 — OpenLDAP: Directorio Centralizado de Usuarios

### 1.1 Arquitectura del Directorio

```
dc=tfg,dc=com
├── ou=usuarios         ← Cuentas personales de empleados
│   ├── uid=jdoe
│   └── uid=mbrown
├── ou=grupos           ← Grupos departamentales
│   ├── cn=becarios     (VLAN 10)
│   ├── cn=ventas       (VLAN 10)
│   ├── cn=rrhh         (VLAN 10)
│   ├── cn=almacen      (VLAN 10)
│   ├── cn=tecnico      (VLAN 10 — puede cambiar contraseñas)
│   ├── cn=jefe_ventas  (VLAN 10 — aprobaciones)
│   ├── cn=jefe_rrhh    (VLAN 10 — aprobaciones)
│   ├── cn=jefe_almacen (VLAN 10 — aprobaciones)
│   ├── cn=admin        (VLAN 40 — acceso total)
│   └── cn=dba          (VLAN 40 — solo base de datos)
└── ou=servicios        ← Cuentas técnicas
    ├── cn=readonly     (Odoo + PAM autentican con esta)
    └── cn=api
```

> OpenLDAP ya está levantado en el stack Docker (IP MACVLAN `192.168.30.22`).
> Esta parte configura su estructura y ACLs internas.

### 1.2 Verificar el Contenedor OpenLDAP

```bash
docker ps | grep openldap   # → Up (healthy)

# Prueba básica de conectividad
ldapsearch -H ldap://192.168.30.22 -x -b "dc=tfg,dc=com" "(objectClass=*)" dn
# Si ldapsearch no está instalado: sudo apt install ldap-utils -y
```

### 1.3 Aplicar ACLs de Seguridad

```bash
bash /opt/erp-odoo/scripts/ldap/ldap_politica_acceso.sh
```

| Cuenta | Permisos | Uso |
|:-------|:---------|:----|
| `cn=admin,dc=tfg,dc=com` | Escritura total | Administración del directorio |
| `cn=tecnico` (grupo) | `write` solo en `userPassword` de `ou=usuarios` | Técnicos cambian contraseñas |
| `cn=readonly,dc=tfg,dc=com` | Lectura de todo el árbol | Odoo y PAM autentican |
| Anónimo | Solo `auth` en `userPassword` | Bind básico |
| Todos los demás | `deny all` | Seguridad por defecto |

### 1.4 Crear Usuarios en el Directorio LDAP

```bash
bash /opt/erp-odoo/scripts/ldap/ldap_crear_usuarios.sh
```

El script pide interactivamente: uid, nombre, email, contraseña y grupo departamental.

Ejemplo de entrada LDIF generada:

```ldif
dn: uid=jdoe,ou=usuarios,dc=tfg,dc=com
objectClass: inetOrgPerson
objectClass: posixAccount
uid: jdoe
cn: John Doe
sn: Doe
mail: jdoe@techsolutions.local
uidNumber: 2001
gidNumber: 2000
homeDirectory: /home/jdoe
loginShell: /bin/bash
```

### 1.5 Verificar LDAP

```bash
# Ver todos los usuarios
ldapsearch -H ldap://192.168.30.22 \
  -D "cn=readonly,dc=tfg,dc=com" -w "<LDAP_READONLY_PASSWORD>" \
  -b "ou=usuarios,dc=tfg,dc=com" "(objectClass=inetOrgPerson)" uid cn

# Probar autenticación de un usuario
ldapwhoami -H ldap://192.168.30.22 \
  -D "uid=jdoe,ou=usuarios,dc=tfg,dc=com" -W
# Resultado esperado: dn: uid=jdoe,ou=usuarios,dc=tfg,dc=com ✅

# Verificar que readonly NO puede modificar (debe dar error 50)
ldapmodify -H ldap://192.168.30.22 \
  -D "cn=readonly,dc=tfg,dc=com" -w "password" <<EOF
dn: uid=jdoe,ou=usuarios,dc=tfg,dc=com
changetype: modify
replace: cn
cn: Test
EOF
# → ldap_modify: Insufficient access (50) ✅
```

### 1.6 Configurar Login LDAP en PCs Cliente VLAN 10

Permite que los empleados usen **la misma contraseña LDAP** para login en su PC y en Odoo.

```bash
# Ejecutar EN CADA PC CLIENTE (no en el servidor)
sudo bash /opt/erp-odoo/scripts/ldap/configurar_cliente_ldap.sh
```

El script pide interactivamente:
```
URI del servidor LDAP → ldap://192.168.30.22
Base DN              → dc=tfg,dc=com
Contraseña readonly  → <LDAP_READONLY_PASSWORD>
Grupo de acceso      → ventas  (opcional — restringe qué grupo puede entrar en este PC)
```

Instala y configura:

| Componente | Función |
|:-----------|:--------|
| **SSSD** | Intermediario SO ↔ LDAP, con caché offline |
| **PAM** (`pam_sss.so`) | Intercepta el login del SO y valida contra LDAP |
| **NSS** | El SO resuelve usuarios LDAP como si fueran locales |
| **pam_mkhomedir** | Crea `/home/<uid>` automáticamente en el primer login |

**Verificar en el PC cliente:**
```bash
getent passwd jdoe       # → jdoe:x:2001:2000:John Doe:/home/jdoe:/bin/bash ✅
su - jdoe                # → Pide contraseña LDAP, abre shell ✅
journalctl -u sssd -f    # Logs de SSSD en tiempo real (para depurar)
```

### 1.7 Operaciones de Mantenimiento LDAP

```bash
# Cambiar contraseña (técnico tiene permiso)
ldappasswd -H ldap://192.168.30.22 \
  -D "uid=tecnico,ou=usuarios,dc=tfg,dc=com" -W \
  -S "uid=jdoe,ou=usuarios,dc=tfg,dc=com"

# Cambiar contraseña como admin
ldappasswd -H ldap://192.168.30.22 \
  -D "cn=admin,dc=tfg,dc=com" -W \
  -S "uid=jdoe,ou=usuarios,dc=tfg,dc=com"

# Eliminar un usuario
ldapdelete -H ldap://192.168.30.22 \
  -D "cn=admin,dc=tfg,dc=com" -W \
  "uid=jdoe,ou=usuarios,dc=tfg,dc=com"

# Estado SSSD (en PC cliente)
sssctl domain-status tfg.com
sss_cache -E && systemctl restart sssd   # Forzar reconexión
```

### 1.8 Límites de Compatibilidad

> [!TIP]
> **Windows no es compatible como cliente nativo de OpenLDAP** para login del SO.
> Los PCs Windows de VLAN 10 hacen login local en Windows pero **sí se autentican con LDAP en Odoo** vía navegador.
>
> Para soportar Windows en el dominio, la mejora futura sería reemplazar OpenLDAP por **Samba 4 AD DC**.

---

## PARTE 2 — CI/CD con GitHub Actions (Despliegue Automático)

### 2.1 Cómo Funciona

```
git push → GitHub CI (ShellCheck + YAML + Markdown) → pasa ✅ → CD (deploy.sh en Debian)
```

### 2.2 Obtener Token de Registro

En GitHub: **Settings → Actions → Runners → New self-hosted runner**
→ Linux / x64 → copiar el **token** (válido 1 hora)

### 2.3 Instalar el Runner

```bash
chmod +x /opt/erp-odoo/scripts/deploy/setup_runner.sh
/opt/erp-odoo/scripts/deploy/setup_runner.sh
```

El script pide:
1. URL del repositorio
2. Token de registro

Instala el agente en `/opt/actions-runner` como servicio systemd.

### 2.4 Permisos del `.env` para el Runner

```bash
sudo chown root:servidor /opt/erp-odoo/docker/.env
sudo chmod 640 /opt/erp-odoo/docker/.env
```

### 2.5 Verificar

```bash
sudo systemctl is-active actions.runner.*   # → active ✅
# En GitHub → Settings → Actions → Runners → estado: Idle ✅
```

### 2.6 Probar el Pipeline

```bash
git commit --allow-empty -m "test: verificar CI/CD"
git push origin main
# GitHub → Actions → CI ✅ → CD ✅
```

### 2.7 Problemas Comunes CI/CD

| Error | Solución |
|:------|:---------|
| Runner no aparece en GitHub | `sudo systemctl restart actions.runner.*` |
| `dubious ownership` | `git config --global --add safe.directory /opt/erp-odoo` |
| `.env` no legible | `sudo chown root:servidor docker/.env && sudo chmod 640 docker/.env` |
| Puertos en uso en re-deploy | `deploy.sh` detecta si `nginx-proxy` ya corre y hace update en lugar de nuevo deploy |

---

## PARTE 3 — Hardening Final

> [!CAUTION]
> **Realizar SIEMPRE AL FINAL.** Con GNOME es mucho más fácil diagnosticar problemas.
> Una vez sin GUI, el único acceso es SSH o Cockpit.

### 3.1 Configurar UFW

```bash
sudo apt install ufw -y
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP Nginx
sudo ufw allow 443/tcp   # HTTPS Nginx
sudo ufw allow 9090/tcp  # Cockpit
sudo ufw enable
sudo ufw status verbose
```

### 3.2 Endurecer SSH

**Primero: copiar clave pública desde PC de administración (VLAN 40):**
```bash
ssh-keygen -t ed25519 -C "admin-tfg" -f ~/.ssh/tfg_admin
ssh-copy-id -i ~/.ssh/tfg_admin.pub servidor@192.168.30.10
ssh -i ~/.ssh/tfg_admin servidor@192.168.30.10   # Verificar login
```

**Luego: deshabilitar contraseñas (solo tras verificar que la clave funciona):**
```bash
sudo nano /etc/ssh/sshd_config
```

```ini
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
ChallengeResponseAuthentication no
LoginGraceTime 30
AllowUsers servidor
X11Forwarding no
MaxAuthTries 3
```

```bash
sudo systemctl restart sshd
# Verificar desde OTRA ventana de terminal antes de cerrar la actual:
ssh -i ~/.ssh/tfg_admin servidor@192.168.30.10   # ✅
```

> [!CAUTION]
> **NO cierres la sesión SSH actual** hasta confirmar que puedes entrar con la clave.
> Si configuras `PasswordAuthentication no` sin tener la clave copiada, **perderás el acceso**.

### 3.3 Convertir a Modo Headless (Sin GUI)

```bash
# Cambiar target de arranque
sudo systemctl set-default multi-user.target
systemctl get-default   # → multi-user.target

# Eliminar GNOME y X11
sudo apt remove --purge gnome* -y
sudo apt remove --purge x11* xorg* -y
sudo apt autoremove --purge -y
sudo apt clean
```

### 3.4 Reiniciar y Verificar

```bash
sudo reboot
# Reconectar por SSH:
ssh -i ~/.ssh/tfg_admin servidor@192.168.30.10

systemctl get-default          # → multi-user.target ✅
sudo ufw status                # → Status: active ✅
systemctl is-active docker     # → active ✅
systemctl is-active cockpit.socket  # → active ✅

# Los 4 contenedores deben estar Up automáticamente (restart: always)
docker compose -f /opt/erp-odoo/docker/docker-compose.yml ps

# Odoo accesible
curl -k -I https://erp.odoo.tfg.com   # → HTTP/2 200 ✅
```

### 3.5 Checklist Final Completo del Sistema

```
✅ Red (pfSense)
   ├── 4 interfaces activas
   ├── Reglas por VLAN (bloqueos primero)
   ├── Anti-Lockout desactivado
   └── LDAP auth panel pfSense

✅ Servidor Debian (VLAN 30)
   ├── IP estática 192.168.30.10
   ├── Docker + Cockpit activos
   ├── UFW: solo 22/80/443/9090
   ├── SSH: solo clave pública, sin root
   └── Modo: multi-user.target (headless)

✅ Docker Stack (4 contenedores healthy)
   ├── odoo_erp    → PostgreSQL 16 (solo red interna)
   ├── odoo-web    → Odoo 17 CE (MACVLAN .21)
   ├── openldap    → OpenLDAP 1.5.0 (MACVLAN .22)
   └── nginx-proxy → Nginx Alpine (MACVLAN .20)

✅ Odoo
   ├── Empresa: TechSolutions S.L.
   ├── Módulos: CRM, Ventas, RRHH, Inventario, auth_ldap
   ├── Usuarios: 10 creados con roles
   └── Auditoría SQL: trigger en res_users

✅ LDAP
   ├── ACLs aplicadas (mínimo privilegio)
   ├── Usuarios de empleados creados
   ├── Login Odoo con credencial LDAP ✅
   └── Login PCs VLAN 10 con credencial LDAP ✅

✅ CI/CD
   ├── Runner activo (Idle en GitHub)
   └── Pipeline: git push → CI → CD → contenedores actualizados

✅ Mantenimiento
   ├── Backup diario 02:00
   ├── Monitor cada 15 min
   └── Update imágenes domingos 03:00
```

---

**← Volver al índice:** [`docs/INSTALACION_COMPLETA.md`](../INSTALACION_COMPLETA.md)

*TFG ASIR 2025/2026 — IES Cañaveral*
