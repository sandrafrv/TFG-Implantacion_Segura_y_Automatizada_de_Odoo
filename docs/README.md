# Documentación Técnica — TFG ASIR 2025/2026

**Proyecto:** Implantación Segura y Automatizada de Odoo ERP  
**Autora:** Sandra Fradejas Avedillo  
**Centro:** IES Cañaveral · Ciclo ASIR

---

## 🗂️ Índice de Documentos

### Guía Principal *(empieza aquí)*

| Archivo | Descripción |
|:--------|:------------|
| [`INSTALACION_COMPLETA.md`](INSTALACION_COMPLETA.md) | **Punto de entrada único.** Describe las 8 fases de instalación desde cero con resumen de cada módulo, orden de arranque y checklist final |

### Guías de Instalación

Ubicadas en [`guias/`](guias/):

| Archivo | Contenido |
|:--------|:----------|
| [`guias/GUIA_COMPLETA.md`](guias/GUIA_COMPLETA.md) | **Guía técnica unificada:** pfSense (VM, interfaces, DHCP, DNS, NAT, ACLs) + PostgreSQL (VM, instalación, acceso remoto) + Debian + Docker + Odoo (SSL, stack, usuarios, auditoría) + CI/CD + Hardening + Apéndices (Vagrant box, correcciones red, LDAP) |
| [`guias/GUIA_TRABAJO_PASO_A_PASO.md`](guias/GUIA_TRABAJO_PASO_A_PASO.md) | **Cuaderno de trabajo:** Narrativa cronológica del proyecto desde la idea inicial hasta el estado final, mostrando cada decisión, bug y solución |

### Referencia Técnica

| Archivo | Descripción |
|:--------|:------------|
| [`CONTROL_ACCESO.md`](CONTROL_ACCESO.md) | Modelo de seguridad: Nginx (rutas por VLAN) + Odoo (tipo de usuario) |
| [`reglas_pfsense.md`](reglas_pfsense.md) | Referencia completa de todas las reglas de firewall pfSense, NAT y DNS |
| [`diagrama_red.md`](diagrama_red.md) | Diagramas Mermaid de la arquitectura: topología, zonas de seguridad, flujo de autenticación, red Docker |

### Historial y Seguimiento

| Archivo | Descripción |
|:--------|:------------|
| [`HISTORIAL_IMPLEMENTACION.md`](HISTORIAL_IMPLEMENTACION.md) | Cómo se construyó el proyecto: decisiones técnicas, problemas encontrados y cómo se resolvieron |
| [`CHANGELOG.md`](CHANGELOG.md) | Registro de cambios por versión (formato Keep a Changelog) |

### Memoria del TFG

| Archivo | Descripción |
|:--------|:------------|
| [`memoria_tfg_nuevo.md`](memoria_tfg_nuevo.md) | Memoria oficial del TFG en redacción |
| [`memoria_tfg_borrador.md`](memoria_tfg_borrador.md) | Borrador anterior de referencia |

---

## 📁 Estructura de Este Directorio

```
docs/
├── README.md                       ← Este archivo (índice)
├── INSTALACION_COMPLETA.md         ← Guía maestra (entrada principal)
├── CHANGELOG.md                    ← Historial de versiones
├── CONTROL_ACCESO.md               ← Modelo de seguridad
├── HISTORIAL_IMPLEMENTACION.md     ← Historia del desarrollo
├── diagrama_red.md                 ← Diagramas de arquitectura
├── reglas_pfsense.md               ← Referencia de reglas pfSense
├── memoria_tfg_nuevo.md            ← Memoria del TFG
├── memoria_tfg_borrador.md         ← Borrador de la memoria
│
├── guias/                          ← Guías de instalación
│   ├── GUIA_COMPLETA.md          (Guía técnica unificada)
│   └── GUIA_TRABAJO_PASO_A_PASO.md (Cuaderno de trabajo)
│
├── archive/                        ← Documentos históricos de planificación
└── mas_info/                       ← Investigación técnica y comparativa ERP
```

---

## 🔄 Flujo de Trabajo (GitOps)

```
Modificación local → git commit + push → CI valida → CD despliega en servidor
```

> [!IMPORTANT]
> **Nunca editar scripts ni configs directamente en el servidor.**
> Cualquier cambio manual queda sobreescrito en el siguiente `git push`.

### Reglas del flujo

| Regla | Detalle |
|:------|:--------|
| Rama principal | Solo `main` dispara el CD automático |
| CI obligatorio | El CD solo se ejecuta si CI (ShellCheck + YAML + Markdown) pasa |
| Credenciales | `docker/.env` vive en el servidor — **nunca en Git** |
| Documentación | Los cambios en `docs/` también pasan por Markdownlint |

---

## 🛠️ Tareas de Administración Rápida

```bash
# Menú interactivo (recomendado para el día a día)
sudo /opt/erp-odoo/scripts/deploy/erp.sh

# Estado de los contenedores
docker compose -f /opt/erp-odoo/docker/docker-compose.yml ps

# Backup manual
bash /opt/erp-odoo/scripts/mantenimiento/backup.sh

# Restaurar backup
bash /opt/erp-odoo/scripts/mantenimiento/restore.sh /opt/erp-odoo/backups/<archivo>.dump

# Ver logs del contenedor odoo
docker compose -f /opt/erp-odoo/docker/docker-compose.yml logs -f odoo-web
```

Referencia completa de scripts: [`../scripts/README.md`](../scripts/README.md)

---

## 📋 Plantillas para GitHub Issues

Copiar el bloque de descripción al crear un Issue en GitHub.

### [Infra] Verificación de Aislamiento VLAN

**Labels:** `infraestructura`, `seguridad`, `pfSense`

**Objetivo:** Verificar que la segmentación entre VLAN 10 (clientes) y VLAN 30 (DMZ) funciona correctamente.

- [ ] `nc -zv 192.168.30.10 5432` desde VLAN 10 → **timeout** ✅
- [ ] `nc -zv 192.168.30.10 8069` desde VLAN 10 → **timeout** ✅
- [ ] `nc -zv 192.168.30.10 22` desde VLAN 10 → **timeout** ✅
- [ ] `curl -k -I https://erp.odoo.tfg.com` desde VLAN 10 → **200** ✅
- [ ] `ping 192.168.10.x` desde DMZ → **sin respuesta** ✅
- [ ] Panel pfSense desde VLAN 10 → **no accesible** ✅
- [ ] Captura → `screenshots/fase_A_vlan/`

---

### [Docker] Red MACVLAN

**Labels:** `docker`, `red`

**Objetivo:** Asignar IPs físicas de la DMZ a los contenedores para que pfSense aplique reglas por host.

- [ ] `nginx-proxy` → IP `192.168.30.20` en MACVLAN
- [ ] `odoo-web` → IP `192.168.30.21` en MACVLAN
- [ ] `odoo_erp` → sin IP MACVLAN (solo red interna)
- [ ] `docker run --rm --network macvlan_vlan30 alpine wget -qO- https://192.168.30.20` → `<title>Odoo</title>`
- [ ] Captura de `docker network inspect macvlan_vlan30` → `screenshots/fase_B_macvlan/`



### [SecOps] Hardening SSH + Headless

**Labels:** `hardening`, `seguridad`, `debian`

**Objetivo:** Reducir superficie de ataque eliminando GUI y asegurando acceso solo por clave SSH.

- [ ] UFW activo: 22/80/443/9090 abiertos, deny-all el resto
- [ ] Clave SSH copiada al servidor (`ssh-copy-id`)
- [ ] Login SSH con clave verificado desde VLAN 40
- [ ] `PasswordAuthentication no` + `PermitRootLogin no` en sshd_config
- [ ] `systemctl set-default multi-user.target`
- [ ] Paquetes GNOME + X11 eliminados
- [ ] Reinicio → arranque en modo texto ✅
- [ ] Docker + 4 contenedores activos tras reinicio ✅
- [ ] Odoo accesible `https://erp.odoo.tfg.com` ✅
- [ ] Captura → `screenshots/fase_D_headless/`

---

### [DevOps] Pipeline CI/CD con GitHub Actions

**Labels:** `ci-cd`, `devops`

**Objetivo:** `git push` → CI valida → CD despliega automáticamente en el servidor.

- [ ] Runner instalado como servicio systemd
- [ ] Runner visible en GitHub → Idle (verde)
- [ ] Permisos `.env`: `640`, propietario `root:servidor`
- [ ] CI: ShellCheck + YAML lint + Markdownlint pasan ✅
- [ ] CD: `git reset --hard origin/main` + `docker compose pull` + `deploy.sh`
- [ ] Test end-to-end: commit vacío → push → CI ✅ → CD ✅
- [ ] Captura → `screenshots/fase_E_cicd/`

---

### [SecOps] Aislamiento VLAN 40 y Panel pfSense

**Labels:** `pfSense`, `seguridad`, `vlan40`

**Objetivo:** Panel pfSense solo accesible desde VLAN 40, autenticado con LDAP.

- [ ] OPT2 (VLAN 40): IP `192.168.40.1/24`, DHCP `40.10–50`
- [ ] Regla OPT2: `VLAN40 → This Firewall :443 → PASS`
- [ ] Acceso panel desde VLAN 40: `https://192.168.40.1` → OK
- [ ] Anti-Lockout desactivado (System → Advanced → Admin Access)
- [ ] Panel desde VLAN 10 → **no accesible** ✅

---

## ⚠️ Archivos que NUNCA van a Git

```bash
# Verificar antes de cada commit:
git status

# Los siguientes NUNCA deben aparecer en la lista:
# docker/.env       → Credenciales reales
# certs/*.key       → Claves privadas SSL
# certs/*.crt       → Certificados
# data/             → Datos persistentes
# ISOs/             → Imágenes de instalación
# backups/          → Backups de PostgreSQL
```

---

## 📷 Nomenclatura de Capturas

```
screenshots/
├── fase_A_vlan/       → Reglas pfSense, nc timeout, curl 200
├── fase_B_macvlan/    → docker network inspect, IPs .20/.21
├── fase_D_headless/   → SSH activo, Cockpit, sin GUI
└── fase_E_cicd/       → Pipeline GitHub Actions ejecutándose
```

---

*TFG ASIR 2025/2026 — Sandra Fradejas Avedillo — IES Cañaveral*
