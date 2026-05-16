# Gestión del Repositorio — TFG ASIR 2025/2026

> [!WARNING]
> **OBSOLETO:** Este documento ha sido archivado y no refleja la organización o arquitectura actual del repositorio (ej. Vagrant, eliminación de LDAP, etc.).

**→ Guía de instalación completa:** [`docs/INSTALACION_COMPLETA.md`](INSTALACION_COMPLETA.md)

---

## 📁 Estructura del Repositorio

```
TFG-ASIRB/
├── .github/workflows/
│   ├── ci.yml              # CI: ShellCheck + YAML lint + Markdownlint
│   └── deploy.yml          # CD: despliegue automático al servidor
├── config/logrotate.d/
│   └── erp-odoo            # Rotación semanal de logs de cron
├── config_nginx/
│   └── odoo_proxy.conf     # Proxy inverso Nginx + SSL + cabeceras seguridad
├── docker/
│   ├── .env                # Credenciales reales (excluido de Git)
│   ├── docker-compose.yml  # 4 servicios: PostgreSQL, Odoo, LDAP, Nginx
│   └── odoo.conf           # Configuración interna de Odoo 17
├── docs/
│   ├── INSTALACION_COMPLETA.md      # ← Punto de entrada principal
│   ├── CONTROL_ACCESO.md            # Modelo de seguridad en 3 capas
│   ├── HISTORIAL_IMPLEMENTACION.md  # Decisiones y problemas del proyecto
│   ├── CHANGELOG.md                 # Registro de cambios por versión
│   ├── GESTION_REPOSITORIO.md       # Este archivo
│   ├── reglas_pfsense.md            # Referencia completa de reglas pfSense
│   ├── GUIA_AISLAMIENTO_ADMIN.md    # Guía VLAN 40 paso a paso
│   ├── diagrama_red.md              # Diagrama de arquitectura de red
│   ├── github_issues.md             # Plantillas de Issues para GitHub
│   ├── guias/                       # Sub-guías de instalación por módulo
│   │   ├── 01_PFSENSE_INSTALACION.md
│   │   ├── 02_DEBIAN_PREPARACION.md
│   │   ├── 03_DOCKER_STACK.md
│   │   ├── 04_ODOO_CONFIGURACION.md
│   │   ├── 05_LDAP_INSTALACION.md
│   │   ├── 07_CICD_GITHUB.md
│   │   └── 08_HARDENING_FINAL.md
│   ├── archive/                     # Documentos históricos de planificación
│   └── mas_info/                    # Investigación técnica e informes ERP
├── ldap/
│   └── estructura.ldif              # Estructura base del directorio LDAP
├── scripts/
│   ├── README.md                    # Índice de scripts con descripción
│   ├── deploy/
│   │   ├── configure.sh             # Configuración interactiva del .env
│   │   ├── deploy.sh                # Levanta el stack con healthcheck
│   │   ├── erp.sh                   # Orquestador central (menú interactivo)
│   │   └── install_cron.sh          # Instala tareas cron y logrotate
│   ├── odoo/
│   │   ├── odoo_setup_wizard.sh     # Post-instalación: empresa + módulos + LDAP
│   │   └── odoo_crear_usuarios.sh   # Crea usuarios Odoo por XML-RPC
│   ├── ldap/
│   │   ├── configurar_cliente_ldap.sh  # Configura SSSD+PAM en PCs cliente
│   │   ├── ldap_crear_usuarios.sh      # Crea usuarios en el directorio LDAP
│   │   └── ldap_politica_acceso.sh     # Aplica ACLs al servidor LDAP
│   └── mantenimiento/
│       ├── backup.sh                # Backup comprimido de PostgreSQL
│       ├── restore.sh               # Restauración desde backup
│       ├── monitor.sh               # Monitor de salud + auto-reinicio
│       └── update.sh                # Actualización de imágenes Docker
├── sql/
│   └── audit_triggers.sql           # Auditoría PL/pgSQL en PostgreSQL
├── .env.example                     # Plantilla pública de variables
├── .gitignore                       # Excluye .env, certs/, data/, ISOs/
├── install.sh                       # Instalador todo-en-uno
└── README.md                        # Documentación principal del proyecto
```

---

## 🔄 Flujo de Trabajo (GitOps)

El repositorio es la **fuente de verdad** del sistema. El flujo de trabajo es:

```
1. Editar localmente  →  2. Commit + Push  →  3. CI valida  →  4. CD despliega
     (PC)                  (git push main)      (GitHub)         (Servidor)
```

> [!IMPORTANT]
> **Nunca edites scripts o archivos de configuración directamente en el servidor de producción.**
> Cualquier cambio manual será sobreescrito por el siguiente `git push`.

### Reglas del flujo GitOps

| Regla | Descripción |
|:------|:------------|
| Rama principal | Solo `main` dispara el CD automático |
| CI obligatorio | El CD solo se ejecuta si el CI pasa sin errores |
| Credenciales | El `.env` con contraseñas reales vive en el servidor, **nunca en Git** |
| Documentación | Los cambios de docs también pasan por CI (Markdownlint) |

---

## 🛠️ Tareas de Administración Diaria

```bash
# Menú interactivo completo (recomendado)
sudo /opt/erp-odoo/scripts/deploy/erp.sh

# Operaciones directas
bash scripts/mantenimiento/backup.sh       # Backup manual
bash scripts/mantenimiento/restore.sh      # Restaurar backup
bash scripts/mantenimiento/monitor.sh      # Chequeo de salud
bash scripts/mantenimiento/update.sh       # Actualizar imágenes Docker
bash scripts/ldap/ldap_crear_usuarios.sh   # Añadir usuario LDAP

# Ver logs en tiempo real
docker compose -f docker/docker-compose.yml logs -f

# Estado de los contenedores
docker compose -f docker/docker-compose.yml ps
```

Para la referencia completa de cada script, ver [`scripts/README.md`](../scripts/README.md).

---

## 📝 Mantenimiento de la Documentación

| Documento | Cuándo actualizarlo |
|:----------|:--------------------|
| `CHANGELOG.md` | En cada versión o cambio funcional relevante |
| `README.md` | Solo si cambia la arquitectura (nuevo contenedor, nueva VLAN, etc.) |
| `INSTALACION_COMPLETA.md` | Si cambian los pasos de instalación |
| `guias/` | Al añadir o modificar un módulo de la infraestructura |
| `reglas_pfsense.md` | Al modificar reglas de firewall |
| `HISTORIAL_IMPLEMENTACION.md` | Al resolver problemas significativos o tomar decisiones técnicas |

### Capturas de pantalla

Guardar en `screenshots/` con la nomenclatura:

```
screenshots/
├── fase_A_vlan/        → Verificación VLAN y reglas pfSense
├── fase_B_macvlan/     → Red MACVLAN y IPs de contenedores
├── fase_C_ldap/        → Login LDAP en Odoo y en PCs
├── fase_D_headless/    → SSH activo, Cockpit, sin GUI
└── fase_E_cicd/        → Pipeline CI/CD ejecutándose
```

---

## ⚠️ Archivos que NUNCA deben ir a Git

```bash
# Verificar que .gitignore los excluye correctamente:
git status

# Los siguientes NUNCA deben aparecer en git status:
# docker/.env         → Credenciales reales
# certs/*.key         → Claves privadas SSL
# certs/*.crt         → Certificados SSL
# data/               → Datos persistentes de contenedores
# ISOs/               → Imágenes de instalación (son muy pesadas)
# backups/            → Backups de PostgreSQL
```

---

*Para el flujo de CI/CD detallado, ver [`docs/guias/07_CICD_GITHUB.md`](guias/07_CICD_GITHUB.md)*
