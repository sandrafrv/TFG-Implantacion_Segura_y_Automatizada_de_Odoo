# Archivo Histórico del TFG — Material de Trabajo Interno

> [!NOTE]
> Este documento consolida todos los archivos de trabajo interno del proyecto.
> Son notas de desarrollo, planes completados y material de referencia que ya no
> forman parte de la documentación técnica activa. Se conservan aquí por su valor
> histórico y de referencia para la memoria del TFG.
>
> **Documentación activa:** [`../INSTALACION_COMPLETA.md`](../INSTALACION_COMPLETA.md)
> **Registro de cambios:** [`../CHANGELOG.md`](../CHANGELOG.md)

---

## Índice

1. [Lista de Tareas del Proyecto (task.md)](#1-lista-de-tareas-del-proyecto)
2. [Diario de Sesión — 12 Mayo 2026](#2-diario-de-sesión--12-mayo-2026)
3. [Guía de Aislamiento Admin (VLAN 40)](#3-guía-de-aislamiento-admin-vlan-40)
4. [Gestión del Repositorio (obsoleta)](#4-gestión-del-repositorio-obsoleta)
5. [Plantillas de GitHub Issues](#5-plantillas-de-github-issues)
6. [Lista de Capturas para la Memoria](#6-lista-de-capturas-para-la-memoria)
7. [Propuestas de Mejora Avanzadas](#7-propuestas-de-mejora-avanzadas)
8. [Planes de Trabajo Internos](#8-planes-de-trabajo-internos)

---

## 1. Lista de Tareas del Proyecto

> **Última actualización:** 2026-04-30
> Estado al archivar: Fases 0–9 completadas. Fase 10 (Memoria y defensa) pendiente.

### Fase 0: Investigación Técnica y Justificación de Diseño

- [x] **[2026-04-29]** Investigación tecnológica completada: evaluación de Odoo vs Dolibarr vs ERPNext.
- [x] **[2026-04-29]** Decisión de OS documentada: Debian 12 elegido.
- [x] **[2026-04-29]** Arquitectura de red definida: WAN / LAN (192.168.10.0/24) / DMZ (192.168.30.0/24).

### Fase 1: Arquitectura y Red Base (pfSense)

- [x] Configurar 4 adaptadores de red en la VM pfSense (WAN, LAN, DMZ/OPT1, Admin/OPT2).
- [x] Instalar pfSense y asignar interfaces.
- [x] Configurar DHCP en pfSense para VLANs 10 y 40.
- [x] **[2026-04-29]** Reglas WAN, LAN, DMZ (OPT1) y Admin (OPT2) configuradas y documentadas.
- [x] **[2026-04-29]** NAT Port Forwarding 80/443 → nginx-proxy (192.168.30.20).

### Fase 2-4: Despliegue Docker y DevOps

- [x] VM Debian 12 con IP estática 192.168.30.10, Docker, Cockpit.
- [x] Stack Docker levantado: odoo-web + nginx-proxy (PostgreSQL en VM externa VLAN 40).
- [x] Red MACVLAN: nginx-proxy (.20), odoo-web (.21).
- [x] Scripts de mantenimiento: backup_postgres.sh, restore.sh, monitor.sh, update.sh.
- [x] Cron cada 4h para backup automático.

### Fase 5: Auditoría Avanzada de BD (PostgreSQL)

- [x] **[2026-04-29]** `sql/audit_triggers.sql` creado: tabla `asir_audit_log`, función `func_audit_users()`, trigger `trg_audit_new_odoo_user`.
- [x] **[2026-04-29]** Campo JSONB (`row_data`) añadido.
- [x] **[2026-04-29]** Vista `v_audit_resumen` creada.
- [x] **[2026-04-30]** Validación end-to-end: `audit_id=1, CREACION_USUARIO, user@tfg.prueba, 2026-04-30 12:13:57 UTC`.

### Fase 6: UFW

- [x] **[2026-04-30]** UFW configurado: deny incoming, allow 22/80/443/9090, habilitado y persistente.

### Fase 7: Pruebas Globales

- [x] **[2026-04-30]** Acceso al ERP vía `https://erp.odoo.tfg.com` validado desde VLAN 10.
- [x] **[2026-04-30]** Prueba de auto-recuperación: odoo-web parado → vuelve a `healthy`.
- [x] **[2026-04-30]** Backup manual ejecutado correctamente.

### Fase 8: CI/CD GitHub Actions

- [x] `ci.yml` — ShellCheck + YAML lint + validación Docker Compose.
- [x] `deploy.yml` — CD con self-hosted runner.
- [x] **[2026-04-30]** Runner instalado como servicio systemd en `odoo-server`.
  - Errores resueltos: `permission denied` en `.env`, `puertos en uso`, `git safe.directory`.
- [x] **[2026-04-30]** Validación final: 2 contenedores `healthy`, Odoo operativo.

### Fase 9: Mejoras de Automatización

- [x] Orquestador `erp.sh` (menú interactivo).
- [x] `.env.example` y configurador interactivo.
- [x] Healthchecks nativos en Docker.
- [x] Logrotate configurado.

### Fase 10: Documentación y Defensa

- [ ] Redactar la **Memoria del TFG**.
- [ ] Preparar capturas de pantalla para la memoria.
- [ ] Preparar demostración en vivo para la defensa.

### Resumen de Estado

| Fase | Descripción | Estado |
|:---:|:---|:---:|
| 0 | Investigación y diseño | ✅ Completada |
| 1 | Arquitectura pfSense y red | ✅ Completada |
| 2–4 | Despliegue Docker + DevOps | ✅ Completada |
| 5 | Auditoría PostgreSQL | ✅ Completada |
| 6 | UFW Firewall local | ✅ Completada |
| 7 | Pruebas globales | ✅ Completada |
| 8 | CI/CD GitHub Actions | ✅ Completada |
| 9 | Mejoras Automatización | ✅ Completada |
| 10 | Documentación y defensa | ⏳ Pendiente |

---

## 2. Diario de Sesión — 12 Mayo 2026
### Resolución de incidencias: VMware + OpenLDAP

#### 1. Error de arranque VMware Workstation

**Síntoma:** "Failed to connect pipe to virtual machine: Todas las instancias de canalización están en uso"

**Causa:** Procesos VMX anteriores seguían activos.

**Solución:**
```powershell
Get-Process vmware* | Stop-Process -Force
Get-Process vmnetdhcp | Stop-Process -Force
```

#### 2. Arranque ordenado de las VMs

1. **pfSense** (router/firewall)
2. **Debian** (servidor Odoo + Docker)
3. **Lubuntu** (cliente)

#### 3. Contenedor OpenLDAP en estado Restarting

> ⚠️ LDAP fue posteriormente descartado del despliegue principal. Ver `extras/ldap/`.

**3.1** — El stack Docker no estaba levantado → `docker compose up -d`

**3.2** — Fichero LDIF montado como read-only:
```bash
sudo sed -i 's|estructura.ldif:ro|estructura.ldif|g' /opt/erp-odoo/docker/docker-compose.yml
```

**3.3** — TLS habilitado sin certificados → añadir `LDAP_TLS: "false"` al environment.

**3.4** — Volúmenes con estado TLS previo:
```bash
sudo docker stop openldap && sudo docker rm openldap
sudo rm -rf /opt/erp-odoo/ldap_data/* /opt/erp-odoo/ldap_config/*
sudo docker compose up -d
```

**3.5** — Variable `LDAP_READONLY_PASSWORD` no definida → añadir al `.env`.

---

## 3. Guía de Aislamiento Admin (VLAN 40)

> Esta guía fue absorbida en `docs/guias/INSTALACION_RED.md` (sección 11).
> Se conserva aquí para referencia histórica.

### FASE 1: Preparar la nueva red de Administradores (VLAN 40)

1. **Interfaces → Assignments** → añadir `em3` como OPT2.
2. **Interfaces → OPT2** → habilitar, descripción `VLAN_ADMIN_BD`, IP `192.168.40.1/24` → Save.
3. **Services → DHCP Server → OPT2** → habilitar, rango `192.168.40.10–50`, DNS `192.168.40.1`.
4. **Firewall → Rules → OPT2** → regla temporal: Pass, Any, OPT2 subnets → Any.

### FASE 2: Restricción mínima de internet en el servidor (DMZ)

Alias `SERVICIOS_PERMITIDOS_DMZ` con: `github.com`, `api.github.com`, `registry-1.docker.io`, `deb.debian.org`, etc.

Cambiar destino en reglas HTTP/HTTPS del OPT1 de `Any` → al alias.

### FASE 3: Restringir clientes VLAN 10

Solo permitir puertos 80/443 hacia nginx-proxy (192.168.30.20). Bloquear SSH/Cockpit.

### FASE 4: Securizar pfSense con LDAP (Opcional)

> ⚠️ LDAP fue descartado del despliegue principal. Ver `extras/ldap/README.md`.

- **System → User Manager → Authentication Servers** → tipo LDAP, IP `192.168.30.22`.
- Grupo `admin` con privilegio `WebCfg - All pages`.

### FASE 5: Desactivar Anti-Lockout

**System → Advanced → Admin Access** → marcar "Disable webConfigurator anti-lockout rule".
Solo tras confirmar acceso desde VLAN 40.

### FASE 6: Mudanza a la Red de Administración

1. Cambiar la VM del administrador a VMnet3 (VLAN 40).
2. `sudo dhclient -r && sudo dhclient` → debe obtener IP `192.168.40.x`.
3. Acceder a `https://192.168.40.1` → panel pfSense.

---

## 4. Gestión del Repositorio (obsoleta)

> [!WARNING]
> **OBSOLETO.** La estructura descrita ya no refleja el estado actual del repositorio.
> Ver [`../../README.md`](../../README.md) y [`../INSTALACION_COMPLETA.md`](../INSTALACION_COMPLETA.md).

### Flujo de Trabajo (GitOps)

```
1. Editar localmente  →  2. Commit + Push  →  3. CI valida  →  4. CD despliega
     (PC)                  (git push main)      (GitHub)         (Servidor)
```

**Reglas del flujo GitOps:**
- Solo `main` dispara el CD automático.
- El CD solo se ejecuta si el CI pasa sin errores.
- El `.env` con contraseñas reales vive en el servidor, **nunca en Git**.

### Archivos que NUNCA deben ir a Git

```
docker/.env         → Credenciales reales
certs/*.key         → Claves privadas SSL
certs/*.crt         → Certificados SSL
data/               → Datos persistentes de contenedores
ISOs/               → Imágenes de instalación
backups/            → Backups de PostgreSQL
```

---

## 5. Plantillas de GitHub Issues

> Plantillas estandarizadas para gestionar el trabajo mediante GitHub Issues.

### [Infra] Verificación de Aislamiento VLAN y Reglas pfSense

- [ ] Revisar reglas en pfSense → Firewall → Rules → LAN, OPT1 (DMZ), OPT2 (VLAN 40)
- [ ] `nc -zv 192.168.30.10 5432` desde VLAN 10 → **debe fallar**
- [ ] `curl -k -I https://erp.odoo.tfg.com` desde VLAN 10 → **debe devolver 200**
- [ ] `ping 192.168.10.x` desde DMZ → **sin respuesta** (anti-pivoting)
- [ ] Capturar reglas en pfSense → `screenshots/fase_A_vlan/`

### [Docker] Redes MACVLAN

- [ ] `nginx-proxy` → IP `192.168.30.20` en red MACVLAN
- [ ] `odoo-web` → IP `192.168.30.21` en red MACVLAN
- [ ] Verificar: `docker run --rm --network macvlan_vlan30 alpine wget -qO- https://192.168.30.20`

### [SecOps] Hardening SSH y Debian Headless

- [ ] UFW: puertos 22, 80, 443, 9090 abiertos, deny-all el resto
- [ ] `PasswordAuthentication no` y `PermitRootLogin no` en `/etc/ssh/sshd_config`
- [ ] `systemctl set-default multi-user.target`
- [ ] Servidor reiniciado → arranca en modo texto
- [ ] Docker y contenedores activos tras el reinicio

### [DevOps] CI/CD Pipeline con GitHub Actions

- [ ] Workflow `ci.yml` activo: ShellCheck + YAML lint + Markdownlint
- [ ] Self-hosted runner visible en GitHub → Settings → Actions → Runners (Idle)
- [ ] Workflow `deploy.yml`: dispara CD tras CI exitoso en `main`
- [ ] Prueba end-to-end: `git push` → CI ✅ → CD ✅ → contenedores actualizados

### [Control Acceso] Roles en Odoo

- [ ] `/web/database/manager` desde VLAN 10 → **403 Forbidden**
- [ ] Login becario → solo CRM, sin botón Eliminar
- [ ] Login ventas → CRM + Ventas + Facturas
- [ ] Login admin (VLAN 40) → acceso total + panel BD

---

## 6. Lista de Capturas para la Memoria

### Arquitectura de Red y Seguridad (pfSense)

- [ ] **Asignación de Interfaces:** *Interfaces > Assignments* — WAN, LAN, OPT1 (DMZ), OPT2 (Admin).
- [ ] **Reglas DMZ:** *Firewall > Rules > OPT1* — anti-pivoting + regla Odoo→PG + deny-all.
- [ ] **NAT / Port Forwarding:** *Firewall > NAT* — puertos 80/443 → `192.168.30.20`.

### Servidor y Automatización

- [ ] **Panel de Cockpit:** `https://192.168.30.10:9090` — recursos del servidor Debian.
- [ ] **Estado Docker:** `docker compose ps` mostrando `odoo-web` y `nginx-proxy` en `healthy`.

### Aplicación ERP

- [ ] **Acceso HTTPS:** Login de Odoo en el navegador, con candado en la barra de direcciones.
- [ ] **Interfaz ERP:** Panel de Odoo autenticado como administrador.

### Auditoría PostgreSQL

- [ ] **Trigger en acción:** `SELECT * FROM v_audit_resumen;` mostrando `CREACION_USUARIO` con JSONB.

### CI/CD

- [ ] **Runner Activo:** GitHub → Settings > Actions > Runners — estado "Idle".
- [ ] **Pipeline Exitoso:** Pestaña "Actions" con flujo "CD Deploy" con ✅.

---

## 7. Propuestas de Mejora Avanzadas

> Ideas opcionales para elevar el nivel técnico. Solo implementar si sobra tiempo.

### 1. Ansible (IaC completo)
Playbook de Ansible para configurar el servidor Debian desde cero: IPs, Docker, UFW, contenedores.
Demuestra conocimientos maduros de DevOps. Queda espectacular en defensa presencial.

### 2. VPN WireGuard en pfSense (Zero Trust)
Ocultar el ERP de Internet. Solo accesible tras túnel VPN cifrado. Estándar irrenunciable en ciberseguridad corporativa.

### 3. Stack de Monitorización (Prometheus + Grafana / Uptime Kuma)
Sustituir scripts de logs por panel gráfico con métricas de CPU/RAM y estado UP/DOWN. Muy vistoso en la defensa.

### 4. Directorio Activo (Active Directory)
VM con Windows Server 2022 como Controlador de Dominio. Odoo autentica contra AD. Conecta ASIR Windows con Linux.

### 5. Alta Disponibilidad PostgreSQL (Patroni)
Réplica en tiempo real de la BD. Si cae el maestro, el esclavo asume el rol instantáneamente. Arquitectura Disaster Recovery.

---

## 8. Planes de Trabajo Internos

> Resumen compactado de los planes de trabajo que guiaron el desarrollo del proyecto.
> Los documentos originales (`plan_fases_pendientes.md`, `plan_iac_github.md`, `GUIA_DESPLIEGUE.md`) están en el historial de git.

### Decisiones de arquitectura clave tomadas durante el desarrollo

| Decisión | Motivo |
|:---------|:-------|
| PostgreSQL en VM externa (VLAN 40) | Mayor aislamiento: si el stack Docker cae, la BD permanece intacta |
| LDAP descartado del despliegue activo | Reduce superficie de ataque; complejidad no justificada para el TFG |
| VMware Workstation en lugar de VirtualBox | Mejor compatibilidad con vagrant-vmware-desktop y MACVLAN en Windows |
| Debian 12 (Bookworm) en lugar de 13 (Trixie) | Mayor estabilidad; box `bento/debian-12` madura y probada |
| 2 runners (odoo-runner + db-runner) | CI/CD independiente por VM; db-runner para futuros tests de BD |
| MACVLAN para nginx y odoo-web | pfSense aplica reglas por host individual, no por IP del servidor |

---

*Archivado: 2026-05-22 — TFG ASIR 2025/2026 — IES Cañaveral*
