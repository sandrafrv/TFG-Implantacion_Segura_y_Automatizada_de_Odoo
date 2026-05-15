# Implantación Segura y Automatizada de Odoo con pfSense y Docker

**Autores:**

- Javier Córdoba Del Valle
- Mario García García
- Sandra Fradejas Avedillo

**Grado:** ASIR - Administración de Sistemas Informáticos en Red

**Centro:** IES Cañaveral — Departamento de Informática y Comunicaciones

**Fecha:** Curso 2025/2026

---

## 📋 Resumen Ejecutivo

Este repositorio documenta el diseño e implantación de un entorno productivo completo para el ERP/CRM **Odoo**, simulando las necesidades de una empresa ("TechSolutions S.L."). La arquitectura se caracteriza por su enfoque en la seguridad, la contenerización y las buenas prácticas de administración de sistemas.

**Características principales:**

- **Seguridad Perimetral (Firewall 3 capas):** Enrutamiento y políticas restrictivas mediante pfSense (WAN/LAN/DMZ) con reglas explícitas de bloqueo anti-pivoting.
- **Orquestación de Contenedores:** Despliegue de servicios (Nginx y Odoo 17) usando Docker y Docker Compose sobre **Debian 13 Server (Trixie)**. PostgreSQL 16 reside en una **VM externa dedicada** (VLAN 40 — `192.168.40.10`) para aislar completamente la capa de datos.
- **Segmentación de Red:** Soporte de VLANs (10, 30) para aislar el tráfico de clientes internos y servicios públicos.
- **Redes MACVLAN:** Los contenedores Nginx y Odoo-web tienen IPs propias en la VLAN30 (`192.168.30.20` y `192.168.30.21`), visibles directamente por pfSense como hosts independientes.
- **Acceso Seguro (Proxy Inverso):** Publicación del servicio mediante un contenedor Nginx Alpine, con terminación SSL/TLS, limitando el acceso a los puertos 80/443 del host.
- **Automatización y Auditoría:** Scripts en Bash para *backups*, restauración, monitorización y despliegue, junto con *Triggers* (PL/pgSQL) para la auditoría de acciones en la base de datos.
- **Gestión Visual:** Administración del servidor mediante **Cockpit** (interfaz web en puerto 9090).

---

## 🏗️ Arquitectura de Red

La topología divide la red en tres zonas de confianza principales, gestionadas por un firewall pfSense:

- **WAN (Internet):** Acceso externo simulado.
- **DMZ (VLAN 30 - 192.168.30.0/24):** Servidor **Debian 13 Server** que aloja el entorno Docker íntegro (Nginx, Odoo, PostgreSQL). Gestionado visualmente desde **Cockpit** (`https://192.168.40.10:9090`).
- **LAN Clientes (VLAN 10 - 192.168.10.0/24):** Equipos internos de la empresa.
- **LAN Administración (VLAN 40)**: Grupos admin y DBA
```mermaid
graph TD
    GITHUB["☁️ GITHUB"]
    WLAN["☁️ WLAN"]

    GITHUB -.->PFSENSE
    WLAN --> PFSENSE

    PFSENSE(["Pfsense\nFirewall · DHCP "])

    PFSENSE -->|" 192.168.40.0/24"| VLAN40
    PFSENSE -->|" 192.168.30.0/24"| DMZ
    PFSENSE -->|"192.168.10.0/24"| VLAN10

    subgraph VLAN40["VLAN 40 — Administración"]
        ADMIN["🖥️Administrador"]
        DBA["🖥️DBA"]
   end

    subgraph VLAN10["VLAN 10 — Clientes"]
        CLIENT["💻 Empleados"]
        CLIENT["🖥️ Empleados"]
    end


    subgraph DMZ["VLAN 30 DMZ"]
        subgraph Debian [" Server Debian 13 "]
                NGINX["DOCKER · NGINX\nMAC_VLAN: 20"]
                ODOO[" DOCKER · ODOO\nMAC_VLAN: 21"]
                BBDD[" DOCKER · PostgreSQL"]

                NGINX -->|"Reverse Proxy"| ODOO
                ODOO -->|"Consultas"| BBDD
        end
    end

    classDef firewall fill:#BBDEFB,stroke:#1565C0,color:#000
    classDef vlan fill:#FFE0B2,stroke:#E65100,color:#000
    classDef dmznode fill:#CE93D8,stroke:#6A1B9A,color:#000
    classDef client fill:#FFE0B2,stroke:#E65100,color:#000

    class PFSENSE firewall
    class ADMIN,Debian,DBA vlan
    class CLIENT client
    class LDAP,NGINX,ODOO,BBDD dmznode

```

---

### Tabla de Direccionamiento IP

| Zona | Subred (CIDR) | Gateway (pfSense) | IP del Sistema | Puertos Abiertos | Servicio |
| :--- | :--- | :--- | :--- | :--- | :--- |
| WAN (Exterior) | Red Fija/DHCP | Router físico | IP WAN | 80, 443 (NAT) | Redirección NAT hacia DMZ |
| DMZ (VLAN 30) | `192.168.30.0/24` | `192.168.30.1` | **`192.168.30.10`** | 80, 443, 22, 9090 | Servidor único Debian + Docker + Cockpit |
| DMZ — nginx-proxy | `192.168.30.0/24` | `192.168.30.1` | **`192.168.30.20`** | 80, 443 | Proxy inverso Nginx (MACVLAN) |
| DMZ — odoo-web | `192.168.30.0/24` | `192.168.30.1` | **`192.168.30.21`** | 8069, 8072 | Aplicación Odoo 17 (MACVLAN) |
| LAN Clientes (VLAN 10) | `192.168.10.0/24` | `192.168.10.1` | `192.168.10.x` | — | Equipos de usuarios |

### Reglas Principales de Firewall (pfSense/UFW)

| Origen | Destino | Puertos | Acción | Propósito |
| :--- | :--- | :--- | :--- | :--- |
| WAN | DMZ (192.168.30.20) | 80, 443 | ✅ Permitir | Acceso web al ERP vía NAT → nginx MACVLAN |
| LAN (VLAN 10) | DMZ (192.168.30.20) | 443, 80 | ✅ Permitir | Clientes internos a Odoo |
| Admin LAN | DMZ (192.168.30.10) | 22, 9090 | ✅ Permitir | SSH y Cockpit (solo admin) |
| DMZ | LAN (VLAN 10) | * | ❌ Bloquear | Anti-pivoting |
| DMZ | pfSense (gestión) | 443, 80, 22 | ❌ Bloquear | Proteger panel del firewall |

---

## 🚀 Fases de Implantación

A continuación, se detalla la hoja de ruta seguida para la ejecución del proyecto:

### 1. Preparación de la Infraestructura

- Configuración del hipervisor (VMware/VirtualBox).
- Despliegue de pfSense con sus respectivas interfaces virtuales (Trunk/VLANs).
- Instalación del S.O. anfitrión único (**Debian 13 Server**) en la DMZ con direccionamiento IP estático e instalación de **Cockpit**.

### 2. Contenerización Completa (Docker / Nginx / Odoo)

- Instalación de `docker`, `docker-compose` y securización del daemon.
- Creación del fichero `docker-compose.yml` declarativo para instanciar Nginx, Odoo 17 y PostgreSQL 16 interactuando en su propia red de contenedores (`odoo_net`).
- Configuración de volúmenes persistentes localizados en `./data` y montajes vinculados para la configuración perimetral de `./config_nginx`.
- Inyección segura de credenciales mediante archivo `.env`.

### 3. Redes MACVLAN — Contenedores como Hosts de Red

> ✅ **Implementado en producción** (mayo 2026)

Se creó una red Docker de tipo `macvlan` vinculada a la interfaz física del servidor (`ens18`) en modo `bridge`, dando IPs reales de la VLAN30 a los contenedores expuestos:

```bash
# Creación de la red MACVLAN externa
docker network create \
  --driver macvlan \
  --subnet=192.168.30.0/24 \
  --gateway=192.168.30.1 \
  --opt parent=ens18 \
  macvlan_vlan30
```

**Asignación de IPs MACVLAN en `docker-compose.yml`:**

| Contenedor | Red interna (`odoo_net`) | Red MACVLAN (`macvlan_vlan30`) |
| :--- | :--- | :--- |
| `odoo-web` (Odoo 17) | 172.19.0.3 | `192.168.30.21` |
| `nginx-proxy` (Nginx) | 172.19.0.4 | `192.168.30.20` |

> ⚠️ **PostgreSQL 16** no corre como contenedor Docker. Reside en la **VM `db-server`** (`192.168.40.10`, VLAN 40). Los contenedores se conectan a ella directamente a través de la red interna de la VM Debian.

**Ventaja de seguridad adicional:** La separación física (VM) de la BD garantiza que incluso si el stack Docker se ve comprometido, la base de datos no es accesible desde la red DMZ.

**Ventajas de seguridad:**

- PostgreSQL en VM externa → **completamente aislada** de la DMZ vía VLAN 40.
- pfSense puede aplicar reglas individuales por contenedor (granularidad de host).
- El host Debian actúa de servidor, no de NAT/gateway para el tráfico de los contenedores.

> **Nota técnica:** Con el driver `macvlan`, el host Debian **no puede comunicarse directamente** con las IPs MACVLAN de sus propios contenedores (limitación del kernel Linux). Para verificar conectividad desde el host se usa un contenedor temporal:
> `docker run --rm --network macvlan_vlan30 alpine wget -qO- https://192.168.30.20`

### 4. Automatización y Monitorización (DevOps)

- Desarrollo de *scripts* Bash para el ciclo de vida del ERP:
  - `install.sh` / `erp.sh`: Instalador todo-en-uno y orquestador centralizado de administración.
  - `deploy.sh`: Levantamiento automático de la infraestructura.
  - `backup.sh`: Volcados comprimidos seguros de PostgreSQL (`pg_dump -F c`).
  - `restore.sh`: Recuperación rápida ante desastres simulados.
  - `update.sh`: Carga de nuevas imágenes Docker y limpieza (`prune`) automatizada.
  - `monitor.sh`: Chequeo de salud de contenedores y detección de caídas.
- Programación de funciones PL/pgSQL y disparadores (`Triggers`) para auditar la creación de usuarios en la tabla `res_users` de Odoo, registrando eventos en `asir_audit_log`.

### 5. Capa de Presentación Segura (Nginx en Docker)

- Despliegue de Nginx como un contenedor Alpine dentro del stack en lugar de una instalación nativa en la DMZ.
- Configuración de proxy dinámico enviando tráfico HTTP/HTTPS hacia el contenedor backend de Odoo.
- Implementación de certificados SSL (autofirmados con OpenSSL) montados mediante volúmenes.
- Cabeceras de seguridad: WebSocket *upgrade*, `X-Forwarded-Proto`, `X-Real-IP`, `X-Forwarded-For`.

---

## 🧰 Stack Tecnológico

| Capa | Tecnología |
| :--- | :--- |
| Redes/Seguridad | pfSense (FreeBSD), UFW |
| Virtualización/Orquestación | Docker Engine, Docker Compose |
| Sistema Operativo Base | **Debian 13 Server (Trixie)** con Cockpit |
| Proxy Inverso | Nginx (Alpine Linux) — contenedor Docker con MACVLAN |
| ERP/CRM | Odoo 17 CE — contenedor Docker con MACVLAN |
| Base de Datos | PostgreSQL 16 — **VM externa** (VLAN 40, `192.168.40.10`) |
| Certificados | OpenSSL (autofirmados TLS) |
| Scripting | GNU Bash, ANSI SQL & PL/pgSQL |
| Control de Versiones | Git + GitHub |
| Integración Continua | GitHub Actions |

---

## 📚 Estructura de este Repositorio

> **🚀 Instalación desde cero: [`docs/INSTALACION_COMPLETA.md`](docs/INSTALACION_COMPLETA.md)**

| Directorio / Archivo | Descripción |
|:---------------------|:------------|
| `/docker/` | `docker-compose.yml`, `odoo.conf` y `.env` (excluido de Git) |
| `/scripts/` | Scripts Bash por categoría: `deploy/`, `odoo/`, `ldap/`, `mantenimiento/` |
| `/sql/` | Triggers PL/pgSQL para auditoría de base de datos |
| `/config_nginx/` | Configuración del proxy inverso Nginx con SSL y cabeceras de seguridad |
| `/ldap/` | Estructura base del directorio LDAP (`estructura.ldif`) |
| `/docs/` | Documentación técnica completa |
| `/docs/guias/` | Sub-guías por módulo: pfSense, Debian, Docker, Odoo, LDAP, CI/CD, Hardening |
| `/ISOs/` | Imágenes de instalación (Debian 13, pfSense 2.7.x) |
| `install.sh` | Instalador todo-en-uno |

---

## 👥 Reparto de Roles

| Integrante | Especialización |
| :--- | :--- |
| **Sandra Fradejas Avedillo** | Sistemas y Orquestación |
| **Mario García García** | Redes y Seguridad Perimetral |
| **Javier Córdoba Del Valle** | Bases de Datos y Automatización |

---

## ❓ ¿Por qué Odoo y no otra alternativa?

Antes de definir la arquitectura, se evaluó comparativamente con otras soluciones ERP de código abierto:

| Criterio | **Odoo 17** | Dolibarr | ERPNext |
| :--- | :--- | :--- | :--- |
| **Facilidad de uso** | ✅ Alta — interfaz moderna e intuitiva | Media — sencillo pero básico | Media — muy completo pero abrumador |
| **Flexibilidad de API** | ✅ Muy alta — XML-RPC y JSON-RPC | Limitada | Alta (API REST) pero compleja |
| **Consumo de recursos** | Moderado (requiere VM decente) | ✅ Muy ligero | Pesado |
| **Cobertura funcional** | ✅ CRM, Ventas, RRHH, Inventario, Proyectos | Básico | Muy completo |
| **Comunidad y soporte** | ✅ Muy activa, documentación extensa | Activa (menor escala) | Activa |
| **Idoneidad para el TFG** | ✅ **Elegido** | Descartado | Descartado |

**Conclusión**: Odoo es la opción que mejor equilibra facilidad de despliegue, cobertura funcional y capacidad de integración para el escenario de la empresa simulada "TechSolutions S.L."

---

## 🎓 Módulos Académicos Cubiertos (ASIR)

| Módulo | Contenido aplicado en este TFG |
| :--- | :--- |
| **Seguridad y Alta Disponibilidad** | Topología DMZ con pfSense, UFW en host, reglas de firewall, política default-deny, backups automatizados con retención |
| **Gestión de Bases de Datos** | Triggers PL/pgSQL con auditoría en formato JSONB, función `func_audit_users()`, tabla `asir_audit_log`, vista `v_audit_resumen` |
| **Servicios de Red** | Cabeceras de seguridad HTTP, DHCP en pfSense, NAT/Port Forwarding, DNS interno |
| **Redes** | Configuracion de VLANs (10/30), monitorizacion de la red y los paquetes, topologia de red|
| **Arquitectura de la Nube** | Creacion y uso de Dockers, proxy inverso Nginx con terminación SSL/TLS, redes MACVLAN Docker |
| **Administracion de Sistemas Operativos e Implementacion de sistemas operativos** | Creacion y gestion de servidor LDAP, creacion y uso de scripts bash para despliegue, backup, restauración y monitorización |

---

## 📖 Investigación y Bases Técnicas

El diseño de este proyecto se apoya en los siguientes recursos técnicos de referencia:

**Redes y Perímetro (pfSense)**

- Documentación Oficial de Netgate — Configuración VLAN: <https://docs.netgate.com/pfsense/en/latest/vlan/configuration.html>
- Docker Macvlan Network en Entornos DMZ: <https://vegard.blog.engen.priv.no/?p=364>

**Infraestructura y Hardening del Servidor**

- Lista de Verificación de Endurecimiento Linux en Producción (2026): <https://hostperl.com/blog/linux-server-hardening-checklist-essential-security-controls-production-2026>
- CIS Benchmark Validation (Linux Mint 22, base aplicable a Debian): <https://www.scribd.com/document/946643717/CIS-Linux-Mint-22-Benchmark-v1-0-0>

**Despliegue de Odoo y Nginx**

- Documentación Odoo 17 — Despliegue en Producción y Multiprocesamiento: <https://www.odoo.com/documentation/19.0/administration/on_premise/deploy.html>
- Proxy Inverso y Configuración SSL para Odoo: <https://oec.sh/guides/odoo-nginx-config>

**Bases de Datos y Auditoría (PostgreSQL)**

- Wiki Oficial PostgreSQL — Generic Audit Trigger (PL/pgSQL): <https://wiki.postgresql.org/wiki/Audit_trigger>
- Estrategias Completas de Backup y Recuperación (DR) en Odoo: <https://oec.sh/guides/odoo-backup-recovery>

---

## 🔮 Mejoras Futuras

Estas mejoras quedan fuera del alcance del TFG pero se documentan para demostrar conocimiento avanzado:

| Mejora | Descripción |
| :--- | :--- |
| **Ansible (IaC)** | Automatizar toda la configuración del servidor Debian con un Playbook de Ansible, eliminando la configuración manual. |
| **VPN WireGuard en pfSense** | Ocultar el ERP de Internet público, accesible solo desde la VLAN interna o a través de un túnel VPN cifrado. Diseño "Zero Trust". |
| **Stack de Monitorización** | Sustituir los scripts de log por Prometheus + Grafana o Uptime Kuma con panel gráfico de estado en tiempo real. |
| **Ldap / Active Directory** | Centralizar credenciales de usuarios usando Windows Server 2022 y LDAP como Controlador de Dominio, integrando Odoo con AD. |
