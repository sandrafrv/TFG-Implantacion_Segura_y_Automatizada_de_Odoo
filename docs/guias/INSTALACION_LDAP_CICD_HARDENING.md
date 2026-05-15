# Guía Avanzada — CI/CD + Hardening

**← Volver a:** [`docs/INSTALACION_COMPLETA.md`](../INSTALACION_COMPLETA.md)
**← Fase anterior:** [`guias/INSTALACION_SERVIDOR.md`](INSTALACION_SERVIDOR.md)

---

> [!WARNING]
> **LDAP no está en el despliegue principal.**
> OpenLDAP fue descartado del stack Docker activo por complejidad operativa y para reducir la superficie de ataque.
> Los scripts de LDAP y los ficheros de estructura están disponibles como material de referencia en:
> - `scripts/ldap/` — scripts de configuración y creación de usuarios
> - `extras/ldap/` — fichero LDIF y documentación de reactivación futura
>
> El **Docker stack activo** solo tiene dos contenedores: `odoo-web` y `nginx-proxy`.
> PostgreSQL reside en la **VM externa `vm-postgres`** (`192.168.40.10`, VLAN 40).

---

## PARTE 1 — LDAP: Material de Referencia (No Activo)

### 1.1 Por qué se descartó

OpenLDAP requiere mantener un directorio de usuarios, un fichero LDIF de bootstrap, un usuario `readonly` para Odoo y configuración PAM en cada cliente. Los puntos de fallo adicionales son:

- Si LDAP cae, los usuarios no pueden entrar a Odoo aunque el ERP esté perfectamente operativo.
- La sincronización entre cuentas LDAP y las de Odoo requiere mantenimiento continuo.
- Aumenta la superficie de ataque con un servicio adicional expuesto en la red.

### 1.2 Material disponible

| Recurso | Ubicación | Descripción |
|:--------|:----------|:------------|
| Estructura de directorio | `extras/ldap/estructura.ldif` | OUs y usuarios de ejemplo para TechSolutions S.L. |
| Script de ACLs | `scripts/ldap/ldap_politica_acceso.sh` | Modelo de mínimo privilegio |
| Script de creación de usuarios | `scripts/ldap/ldap_crear_usuarios.sh` | Crea usuarios en OpenLDAP |
| Script de cliente LDAP | `scripts/ldap/configurar_cliente_ldap.sh` | SSSD + PAM + NSS en Debian |
| Guía de reactivación | `extras/ldap/README.md` | Pasos para retomar LDAP en el futuro |

### 1.3 Arquitectura LDAP prevista (referencia)

```
dc=tfg,dc=com
├── ou=usuarios         ← Cuentas personales de empleados
├── ou=grupos           ← Grupos departamentales por VLAN
│   ├── cn=becarios, cn=ventas, cn=rrhh, cn=almacen  (VLAN 10)
│   ├── cn=admin, cn=dba                              (VLAN 40)
└── ou=servicios        ← Cuentas técnicas
    ├── cn=readonly     (Odoo + PAM autentican)
    └── cn=api
```

### 1.4 Cómo reactivar LDAP en el futuro

1. Añadir servicio `ldap` en `docker/docker-compose.yml` con imagen `osixia/openldap:1.5.0`.
2. Montar `extras/ldap/estructura.ldif` como volumen de bootstrap.
3. Configurar Odoo: `Ajustes → Técnico → Autenticación → Servidor LDAP`.
4. (Opcional) Configurar PAM + SSSD en VMs de VLAN 10 con `scripts/ldap/configurar_cliente_ldap.sh`.

Ver `extras/ldap/README.md` para instrucciones completas.

---

## PARTE 2 — CI/CD con GitHub Actions (Despliegue Automático)

### 2.1 Cómo Funciona

```
git push → GitHub CI (ShellCheck + YAML + Docker config) → pasa ✅ → CD (deploy.sh en Debian)
```

| Workflow | Archivo | Qué hace |
|:---------|:--------|:---------|
| CI | `.github/workflows/ci.yml` | `shellcheck` en `scripts/` y `vagrant/`; `yamllint`; `docker compose config -q`; genera y valida `config.xml` de pfSense |
| CD | `.github/workflows/deploy.yml` | Hace pull, rebuild y verifica `odoo-web` + `nginx-proxy` en el servidor |

### 2.2 Obtener Token de Registro

En GitHub: **Settings → Actions → Runners → New self-hosted runner**
→ Linux / x64 → copiar el **token** (válido 1 hora)

### 2.3 Instalar el Runner

```bash
mkdir /opt/actions-runner && cd /opt/actions-runner
curl -O -L https://github.com/actions/runner/releases/download/v2.334.0/actions-runner-linux-x64-2.334.0.tar.gz
tar xzf ./actions-runner-linux-x64-2.334.0.tar.gz
./config.sh --url https://github.com/sandrafrv/TFG-Implantacion_Segura_y_Automatizada_de_Odoo --token <TOKEN>
sudo ./svc.sh install
sudo ./svc.sh start
```

### 2.4 Permisos del `.env` para el Runner

```bash
# El .env debe estar en la raíz del proyecto
sudo chown root:servidor /opt/erp-odoo/.env
sudo chmod 640 /opt/erp-odoo/.env
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

### 2.7 Lo que hace el CD en el servidor

```bash
# Verificar BD externa antes de levantar contenedores
nc -zv 192.168.40.10 5432   # Debe responder

# Pull y rebuild
docker compose -f /opt/erp-odoo/docker/docker-compose.yml pull
docker compose -f /opt/erp-odoo/docker/docker-compose.yml up -d --force-recreate

# Verificación final
curl -k -I https://localhost/web/health   # → HTTP/2 200 ✅
```

### 2.8 Problemas Comunes CI/CD

| Error | Solución |
|:------|:---------|
| Runner no aparece en GitHub | `sudo systemctl restart actions.runner.*` |
| `dubious ownership` | `git config --global --add safe.directory /opt/erp-odoo` |
| `.env` no legible por runner | `sudo chown root:servidor .env && sudo chmod 640 .env` |
| BD externa no accesible | Verificar regla pfSense VLAN 30 → VLAN 40 puerto 5432 |
| Puertos en uso en re-deploy | `deploy.sh` detecta si `nginx-proxy` ya corre y hace update |

---

## PARTE 3 — Hardening Final

> [!CAUTION]
> **Realizar SIEMPRE AL FINAL.** Es mucho más fácil diagnosticar problemas con acceso completo.
> Una vez en modo headless, el único acceso es SSH (clave pública) o Cockpit.

### 3.1 Configurar UFW

```bash
sudo apt install ufw -y
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP Nginx (redirige a 443)
sudo ufw allow 443/tcp   # HTTPS Nginx
sudo ufw allow 9090/tcp  # Cockpit
sudo ufw enable
sudo ufw status verbose
```

### 3.2 Endurecer SSH

**Primero: copiar clave pública desde el PC de administración (VLAN 40):**

```bash
ssh-keygen -t ed25519 -C "admin-tfg" -f ~/.ssh/tfg_admin
ssh-copy-id -i ~/.ssh/tfg_admin.pub servidor@192.168.30.10
ssh -i ~/.ssh/tfg_admin servidor@192.168.30.10   # Verificar login con clave
```

**Solo después de verificar que la clave funciona — deshabilitar contraseñas:**

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
# Verificar desde OTRA ventana antes de cerrar la actual:
ssh -i ~/.ssh/tfg_admin servidor@192.168.30.10   # ✅
```

> [!CAUTION]
> **NO cierres la sesión SSH actual** hasta confirmar que puedes entrar con la clave.
> Si configuras `PasswordAuthentication no` sin clave copiada, **perderás el acceso**.

### 3.3 Convertir a Modo Headless (Sin GUI)

```bash
sudo systemctl set-default multi-user.target
systemctl get-default   # → multi-user.target

sudo apt remove --purge gnome* -y
sudo apt remove --purge x11* xorg* -y
sudo apt autoremove --purge -y && sudo apt clean
```

### 3.4 Reiniciar y Verificar

```bash
sudo reboot
ssh -i ~/.ssh/tfg_admin servidor@192.168.30.10

systemctl get-default               # → multi-user.target ✅
sudo ufw status                     # → Status: active ✅
systemctl is-active docker          # → active ✅
systemctl is-active cockpit.socket  # → active ✅

# Solo 2 contenedores activos
docker compose -f /opt/erp-odoo/docker/docker-compose.yml ps
# odoo-web    → Up (healthy)
# nginx-proxy → Up (healthy)

# BD externa accesible
nc -zv 192.168.40.10 5432   # ✅

# Odoo respondiendo
curl -k -I https://localhost/web/health   # → HTTP/2 200 ✅
```

### 3.5 Checklist Final del Sistema

```
✅ Red (pfSense)
   ├── 3 interfaces activas: WAN, VLAN 30 (DMZ), VLAN 40 (BD)
   ├── VLAN 10 (Clientes): acceso solo a Nginx por HTTPS
   ├── VLAN 30 → VLAN 40: solo puerto 5432 (Odoo → PostgreSQL)
   ├── VLAN 10 → VLAN 40: BLOQUEADO (usuarios no tocan BD)
   ├── WAN → VLAN 40: BLOQUEADO (BD no expuesta a Internet)
   └── Anti-pivoting activo en todas las VLANs

✅ VM pfSense (vm-pfsense)
   ├── NAT Port Forward: WAN:443 → 192.168.30.20:443
   ├── DHCP activo en VLAN 10 y VLAN 30
   └── DNS Resolver con Host Override para erp.odoo.tfg.com

✅ VM Servidor Debian (vm-odoo, VLAN 30 — 192.168.30.10)
   ├── IP estática 192.168.30.10
   ├── Docker + Cockpit activos
   ├── UFW: solo 22/80/443/9090
   ├── SSH: solo clave pública, sin root
   └── Modo: multi-user.target (headless)

✅ Docker Stack (2 contenedores healthy)
   ├── nginx-proxy → Nginx Alpine (MACVLAN 192.168.30.20)
   └── odoo-web    → Odoo 17 CE  (MACVLAN 192.168.30.21)

✅ VM PostgreSQL (vm-postgres, VLAN 40 — 192.168.40.10)
   ├── PostgreSQL 16 nativo (sin Docker)
   ├── Base de datos: odooerp
   ├── Usuario: odoo (acceso solo desde VLAN 30)
   └── Triggers de auditoría PL/pgSQL activos

✅ Odoo
   ├── Empresa: TechSolutions S.L.
   ├── Módulos: CRM, Ventas, RRHH, Inventario
   ├── Usuarios creados con roles por departamento
   └── Auditoría SQL: trigger activo en res_users

✅ CI/CD
   ├── Runner activo (Idle en GitHub)
   └── Pipeline: git push → CI (shellcheck + yaml + docker) → CD (deploy + healthcheck)

✅ Backups
   ├── Cron cada 4h: pg_dump remoto a 192.168.40.10
   ├── Retención 7 días en /opt/odoo/backups/postgres/
   ├── Log en /var/log/backup_odoo.log
   └── Rotación con logrotate
```

---

**← Volver al índice:** [`docs/INSTALACION_COMPLETA.md`](../INSTALACION_COMPLETA.md)

*TFG ASIR 2025/2026 — IES Cañaveral*
