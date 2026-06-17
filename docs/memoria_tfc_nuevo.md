# Memoria del TFC: Implantación Segura y Automatizada de Odoo

*(Este documento es la plantilla definitiva basada en los requisitos exactos de tu instituto. Debes usarlo como base para redactar tu memoria en Word/PDF).*

---

## 1.- Introducción

### 1.1.- Descripción y contexto del proyecto
El presente proyecto se centra en el diseño, despliegue y automatización de la infraestructura técnica necesaria para alojar un sistema ERP (Enterprise Resource Planning) — concretamente Odoo 17 CE — bajo el nombre de empresa simulada **TechSolutions S.L.** La arquitectura desplegada se basa en tres máquinas virtuales orquestadas con **Vagrant + VirtualBox**: un firewall perimetral pfSense, un servidor Debian 13 con Nginx y Odoo en contenedores Docker y una VM dedicada exclusivamente a PostgreSQL 16 en una VLAN separada. El acceso de los usuarios se gestiona mediante autenticación nativa de Odoo.

### 1.2.- Motivación del proyecto
El proyecto surge de la necesidad que tienen las pequeñas y medianas empresas (PYMES) de digitalizar su gestión empresarial utilizando soluciones Open Source, pero enfrentándose al problema recurrente de instalaciones frágiles, monolíticas y altamente vulnerables. Tradicionalmente, los despliegues se realizan en servidores compartidos sin aislamiento de red, sin políticas de copias de seguridad automatizadas y sin auditoría interna. Este proyecto soluciona ese problema ofreciendo una arquitectura "Zero Trust" con cuatro redes segmentadas, base de datos aislada en VM separada y un ciclo de vida completamente automatizado basado en prácticas DevOps e Infraestructura como Código (Vagrant).

### 1.3.- Decisión de diseño: LDAP fuera del despliegue principal

> [!NOTE]
> **¿Por qué LDAP no está activo en el despliegue principal?**
>
> Durante el desarrollo del TFC se implementó y probó OpenLDAP con éxito, pero se tomó la decisión razonada de retirarlo del stack principal por los siguientes motivos:
> 1. **Superficie de ataque:** Un contenedor `openldap` expuesto en la DMZ amplía el perímetro de ataque (puertos 389/636, gestión de ACLs, etc.).
> 2. **Complejidad de mantenimiento:** La sincronización entre `auth_ldap` de Odoo, SSSD/PAM en los clientes y la gestión del árbol LDAP introduce puntos de fallo que dificultan el mantenimiento en el contexto de un TFC.
> 3. **Suficiencia del sistema actual:** La autenticación nativa de Odoo, combinada con el modelo de control de acceso en 3 capas (Nginx + tipo usuario + grupos/roles), cubre todos los requisitos de seguridad del proyecto.
>
> Todo el material LDAP (estructura LDIF, scripts, guía) está disponible en `extras/ldap/` como **mejora futura** documentada.

### 1.4.- Beneficios esperados
- **Alta Seguridad:** Aislamiento de la BD en VLAN 40 separada de la DMZ; firewall pfSense con reglas anti-pivoting; UFW local; control de acceso en 3 capas (Nginx + Odoo).
- **Base de Datos Aislada:** PostgreSQL en VM independiente (`192.168.40.10`), completamente separada de los contenedores Docker. Un ataque al stack de aplicación no compromete directamente la BD.
- **Trazabilidad y Auditoría:** Triggers PL/pgSQL en PostgreSQL registran cada nuevo usuario creado en Odoo en la tabla `asir_audit_log` (formato JSONB).
- **Resiliencia y Disponibilidad:** Automatización completa de copias de seguridad remotas (`pg_dump` a 192.168.40.10), rotación de logs y scripts de auto-recuperación ante caídas de servicio.
- **Despliegues Reproducibles:** Infraestructura como Código completa con Vagrant: `vagrant up` levanta las 3 VMs con toda la configuración de red y software.

---

## 2.- Objetivo/s generales del proyecto
Desarrollar e implementar una solución de infraestructura automatizada, segura y reproducible para alojar el sistema ERP Odoo 17, contemplando todas las etapas de diseño de red (segmentación en cuatro VLANs), base de datos aislada en VM dedicada, contenerización con Docker Compose, orquestación con Vagrant e Integración Continua con GitHub Actions.

---

## 3.- Objetivos específicos
- Identificar los requisitos de red y seguridad para establecer un firewall perimetral (pfSense) segmentando el tráfico en cuatro VLANs: WAN, VLAN 10 (Clientes), VLAN 30 (DMZ) y VLAN 40 (Administración/BD).
- Contenerizar el ERP y el proxy inverso (Nginx + Odoo 17) utilizando Docker Compose, garantizando el aislamiento de procesos y la comunicación segura entre contenedores mediante redes internas de Docker.
- Desplegar PostgreSQL 16 en una VM dedicada (VLAN 40), completamente separada del stack Docker, comunicada con Odoo únicamente por regla explícita de firewall.
- Aplicar un modelo de seguridad de **tres capas** (Nginx por IP/VLAN, tipo de usuario Odoo y grupos/roles Odoo) que restrinja el acceso a las rutas de administración únicamente desde VLAN 40.
- Desarrollar un conjunto de scripts en Bash que automaticen el ciclo de vida del servicio (instalación, backup remoto `pg_dump`, monitorización y restauración).
- Implementar mecanismos de auditoría a nivel de base de datos (PL/pgSQL) para asegurar la trazabilidad de los usuarios creados en Odoo.
- Orquestar el despliegue completo de las 3 VMs mediante Vagrant, permitiendo reproducir el entorno desde cero con un solo comando.
- Planificar y configurar un flujo de Integración Continua (GitHub Actions) que valide ShellCheck, YAML y la configuración Docker antes de cualquier despliegue.

---

## 4.- Contexto actual
**Estado del arte:** Actualmente, el despliegue de aplicaciones empresariales está transicionando desde instalaciones físicas (Bare Metal) hacia infraestructuras en la nube y contenerización. Las PYMES que requieren control total de sus datos optan por servidores propios gestionados con Docker o Kubernetes, complementados con herramientas IaC como Vagrant o Ansible.

**Conceptos clave:**
- **DMZ (Zona Desmilitarizada):** Red local entre la red interna de una organización y una red externa; aloja servicios accesibles desde el exterior con exposición controlada.
- **VLAN de Administración (VLAN 40):** Red segregada dedicada a administradores del sistema y DBAs, con acceso privilegiado a SSH, Cockpit, PostgreSQL y panel de pfSense.
- **Proxy Inverso:** Servidor que recupera recursos en nombre de un cliente desde uno o más servidores. Nginx actúa como primera barrera de seguridad (terminación SSL + restricción de rutas por IP/VLAN).
- **Contenerización:** Virtualización a nivel de SO para desplegar aplicaciones de forma aislada (Docker).
- **Red interna Docker:** Mecanismo de red virtual que permite la comunicación aislada entre contenedores dentro del mismo host, sin exponer los servicios directamente a la red física. Nginx actúa como único punto de entrada desde el exterior.
- **Infraestructura como Código (IaC):** Práctica de definir y aprovisionar infraestructura mediante archivos de configuración versionados. En este proyecto se usa Vagrant.
- **Zero Trust:** Modelo de seguridad basado en el principio estricto de "no confiar en nadie por defecto" — cada acceso requiere autenticación y autorización explícita.

---

## 5.- Análisis de requisitos

### 5.1.- Diagrama de casos de uso
*(Aquí debes adjuntar el diagrama UML de casos de uso. Ejemplo visual: Un "Administrador de Sistemas" (VLAN 40) se relaciona con casos como "Desplegar Infraestructura", "Gestionar Backups", "Monitorizar Recursos" y "Administrar pfSense". Un "Usuario LAN" (VLAN 10) se relaciona con "Acceder al ERP vía HTTPS" e "Iniciar sesión en Odoo".*

### 5.2.- Requisitos funcionales principales
*(Derivados del diagrama UML anterior).*
- El sistema debe permitir el despliegue completo de la infraestructura sin intervención manual mediante Vagrant (`vagrant up`).
- El sistema debe realizar copias de seguridad de la base de datos (`pg_dump` remoto) automáticamente y retenerlas durante 7 días.
- El proxy inverso debe interceptar las peticiones HTTP y redirigirlas a HTTPS de forma automática.
- Las rutas de administración de Odoo (`/web/database`, `/odoo/action-base_setup`, `/web?debug=`) deben ser accesibles únicamente desde VLAN 40 (`192.168.40.0/24`).
- La infraestructura debe auditar y guardar un registro en formato JSONB cada vez que se cree un nuevo usuario en Odoo.
- PostgreSQL debe correr en una VM independiente (VLAN 40), accesible solo desde Odoo (VLAN 30) y los admins (VLAN 40).

### 5.3.- Requisitos no funcionales
- **Seguridad y Confidencialidad:** El sistema no debe permitir accesos directos a la base de datos desde la red LAN; solo el contenedor `odoo-web` puede conectarse a `192.168.40.10:5432`.
- **Disponibilidad:** El sistema debe contar con mecanismos de auto-reinicio de servicios en caso de caída (Healthchecks en Docker Compose y cron de monitorización).
- **Trazabilidad:** El sistema debe ofrecer trazabilidad completa de los usuarios creados en Odoo mediante triggers PL/pgSQL en PostgreSQL.
- **Reproducibilidad:** El entorno completo debe poder levantarse desde cero con `vagrant up` sin pasos manuales adicionales.
- **Segregación de administración:** Los administradores y DBAs deben operar exclusivamente desde la VLAN 40; el panel de pfSense y la BD de Odoo son inaccesibles desde VLAN 10.

### 5.4.- Descripción de los usuarios y sus necesidades

#### Usuarios de VLAN 10 — Empleados
| Rol | Necesidades |
|-----|-------------|
| **Becario** | Acceso de solo lectura a CRM. Credenciales nativas de Odoo. |
| **Ventas** | Acceso a CRM, Pipeline, Contactos y Facturas. |
| **RRHH** | Gestión de empleados, contratos y nóminas. |
| **Almacén** | Inventario, recepciones y pedidos de compra. |
| **Técnico** | Inventario y soporte técnico. |
| **Jefes de departamento** | Acceso completo a su módulo + aprobaciones. |

#### Usuarios de VLAN 40 — Administración
| Rol | Necesidades |
|-----|-------------|
| **Admin (SysAdmin)** | Acceso SSH al servidor, Cockpit, Docker, panel completo de Odoo (tipo Admin 11), pfSense y PostgreSQL vía psql. Comandos rápidos con `erp.sh`. |
| **DBA** | Acceso a PostgreSQL (`192.168.40.10`) y herramientas de backup. Sin acceso a la UI de Odoo. |
| **API** | Solo acceso XML-RPC a Odoo; no tiene menú UI visible. |

---

## 6.- Diseño de la aplicación

### 6.1.- Mockups o wireframes o prototipos
*(Al ser un proyecto de sistemas, aquí debes incluir las capturas de la interfaz de Odoo (login, dashboard, panel de módulos por rol) y el dashboard de Cockpit. Ver `docs/diagrama_red.md` para los diagramas de arquitectura).*

### 6.2.- Arquitectura del sistema

La arquitectura se basa en un modelo segmentado en cuatro redes gestionadas por pfSense, con **tres máquinas virtuales** orquestadas por Vagrant:

```
Internet (WAN)
      │
  [ pfSense — vm-pfsense ]
  ├── VLAN 10 (192.168.10.0/24) ── Usuarios/Empleados del ERP
  ├── VLAN 30 / DMZ (192.168.30.0/24) ── Servidores
  │       └── vm-odoo (192.168.30.10) — Debian 13, Docker engine
  │                 ├── nginx-proxy  (:80/:443)
  │                 └── odoo-web     (:8069/:8072)
  │                             │ TCP :5432
  └── VLAN 40 (192.168.40.0/24) ── Administración + BD
          ├── vm-postgres (192.168.40.10) — PostgreSQL 16 nativo
          └── Admins/DBAs (192.168.40.20–50)
```

**Decisiones de diseño clave:**

| Decisión | Justificación |
|---|---|
| PostgreSQL en VM separada (VLAN 40) | Aislamiento máximo: si el stack Docker se compromete, la BD permanece inaccesible desde la DMZ sin regla explícita de firewall |
| Docker Compose con red interna | Los contenedores se comunican por red interna de Docker; Nginx actúa como único punto de entrada expuesto en la DMZ |
| Vagrant como IaC | Reproducibilidad: el entorno completo se regenera desde cero con `vagrant up` |
| LDAP fuera del despliegue principal | Reducción de superficie de ataque y complejidad operativa; autenticación nativa de Odoo es suficiente para el TFC |
| SSL autofirmado (OpenSSL) | Cifrado en tránsito sin dependencia de CA externa para entorno de laboratorio |

### 6.3.- Diagramas de clases y de entidad-relación
*(Aquí se incluye el modelo Entidad-Relación simplificado de la auditoría: la tabla `res_users` de Odoo vinculada a `asir_audit_log` mediante triggers PL/pgSQL.)*

### 6.4.- Diseño de la base de datos: esquemas y tablas
Se ha diseñado el esquema de auditoría con los campos: `audit_id` (PK serial), `action`, `table_name`, `record_id`, `row_data` (tipo JSONB para flexibilidad futura) y `created_at`.
La vista `v_audit_resumen` permite consultas rápidas sobre los últimos usuarios creados.
*(El código SQL completo está en `sql/audit_triggers.sql` — ver Anexo III).*

---

## 7.- Desarrollo de la aplicación

### 7.1.- Tecnologías y herramientas utilizadas

| Tecnología | Rol | Justificación |
|---|---|---|
| **Debian 13 (Trixie)** | SO del servidor Odoo | Alta estabilidad, ciclo de soporte largo, estándar de producción |
| **Vagrant + VirtualBox** | Infraestructura como Código | Reproducibilidad total del entorno: `vagrant up` = entorno completo |
| **Docker + Docker Compose** | Orquestación de contenedores | Modularidad y aislamiento; red interna para comunicación segura entre Nginx y Odoo |
| **pfSense** | Firewall perimetral | Open Source de grado empresarial; gestiona 4 interfaces/VLANs |
| **Nginx Alpine** | Proxy inverso | Extremadamente ligero, terminación SSL, restricción de rutas por IP |
| **Odoo 17 CE** | ERP/CRM | Modular, API XML-RPC potente, comunidad muy activa |
| **PostgreSQL 16 (nativo)** | Base de datos | Motor obligatorio de Odoo; soporte JSONB y PL/pgSQL para auditoría |
| **OpenSSL** | Certificados SSL | Cifrado en tránsito sin dependencia de CA externa |
| **GitHub + GitHub Actions** | CI/CD | Validación automática de ShellCheck, YAML y Docker Compose |
| **Cockpit** | Administración web | Interfaz visual en puerto 9090 para gestión del servidor |

### 7.2.- Descripción de las principales funcionalidades implementadas

#### Orquestador Central (`erp.sh`)
Interfaz CLI creada en Bash para abstraer los comandos complejos de Docker y gestión del servicio. Permite gestionar logs, backups y estados con parámetros simples (`./erp.sh backup`).
*(Ilustrar con un pequeño fragmento del script `erp.sh`).*

#### Infraestructura como Código — Vagrant
Tres `Vagrantfile`s que aprovisionan automáticamente:
- `vm-pfsense`: reglas de firewall, interfaces de red
- `vm-odoo`: Docker, SSL, Nginx, Odoo
- `vm-postgres`: PostgreSQL 16, usuario `odoo`, `pg_hba.conf`

Esto garantiza que cualquier miembro del equipo puede reproducir el entorno en un equipo de laboratorio con `vagrant up`.

#### Backup Remoto Automatizado
El script `scripts/mantenimiento/backup_postgres.sh` realiza un `pg_dump` remoto a `192.168.40.10`, comprime el volcado y aplica una política de retención de 7 días. Un cron ejecutado en `vm-odoo` lo lanza cada 4 horas.

```bash
# Resumen del flujo:
pg_dump -h 192.168.40.10 -U odoo odooerp | gzip \
  > /opt/odoo/backups/postgres/odoo_$(date +%Y%m%d_%H%M).sql.gz
# Retención: borrar backups > 7 días
find /opt/odoo/backups/postgres/ -name '*.sql.gz' -mtime +7 -delete
```

#### Modelo de Seguridad en 3 Capas
Aplicado sobre la ruta de acceso al ERP:

```
[Petición HTTPS del usuario]
           │
    ┌──────▼────────┐
    │  CAPA C: Nginx │  ← Primera barrera: filtra rutas por IP/VLAN
    └──────┬────────┘
           │
    ┌──────▼────────┐
    │  CAPA B: Odoo  │  ← Segunda barrera: tipo usuario (Portal/Interno/Admin)
    └──────┬────────┘
           │
    ┌──────▼────────┐
    │  CAPA A: Odoo  │  ← Tercera barrera: grupos = módulos y acciones visibles
    └───────────────┘
```

**Capa C — Nginx** (archivo `config_nginx/odoo_proxy.conf`):

| Ruta | Permitido desde | Bloqueado para |
|------|----------------|----------------|
| `/web/database/manager` | Solo VLAN 40 | VLAN 10 + WAN |
| `/web/database/selector` | Solo VLAN 40 | VLAN 10 + WAN |
| `/odoo/action-base_setup` | Solo VLAN 40 | VLAN 10 + WAN |
| `/web/tests` | Nadie | Todos |
| `/web?debug=` | Solo VLAN 40 | VLAN 10 + WAN |

**Capa B — Tipo de usuario Odoo:**

| Valor | Tipo | Quién lo usa |
|-------|------|-------------|
| `1` | Portal | Clientes externos |
| `10` | Interno | Todos los empleados de VLAN 10 |
| `11` | Admin | Administrador del sistema (VLAN 40) |

**Capa A — Grupos Odoo por rol** (script `odoo_crear_usuarios.sh`): cada empleado tiene asignado automáticamente los XML-IDs de grupos correspondientes a su rol. Ver `docs/CONTROL_ACCESO.md` para la tabla completa.

#### Auditoría en Base de Datos
Función y trigger PL/pgSQL (`sql/audit_triggers.sql`) que se dispara `AFTER INSERT` en `res_users`. Registra en `asir_audit_log` el snapshot JSONB del nuevo usuario con timestamp.
*(Ver código fuente completo en Anexo III).*

#### Auto-recuperación y Healthchecks
El `docker-compose.yml` define healthchecks nativos para `nginx-proxy` y `odoo-web`. El script `monitor.sh` ejecutado por cron detecta caídas y reinicia los contenedores automáticamente.

---

## 8.- Planificación del proyecto

### 8.1.- Acciones
El proyecto se dividió en fases secuenciales:
1. Investigación y diseño de red (cuatro VLANs, diagrama, tabla de IPs).
2. Despliegue de pfSense y configuración de VLANs, DHCP, DNS y NAT.
3. Instalación de vm-postgres: PostgreSQL 16 nativo, usuario odoo, pg_hba.conf.
4. Instalación de vm-odoo: Debian 13, Docker, Nginx, SSL, Odoo.
5. Desarrollo de scripts (Vagrant IaC, deploy, erp.sh, backup_postgres.sh).
6. Modelo de control de acceso en 3 capas (Nginx + tipos usuario + grupos Odoo).
7. Auditoría de base de datos (triggers PL/pgSQL).
8. CI/CD y hardening (GitHub Actions, UFW, SSH por clave).

### 8.2.- Temporalización y secuenciación
*(Aquí debes crear y pegar una tabla o diagrama de Gantt indicando cuánto tiempo en semanas te llevó cada fase. Ejemplo orientativo: Diseño de red y VLANs — 1 semana; pfSense y networking — 1 semana; PostgreSQL VM + Vagrant — 1 semana; Docker + Odoo — 2 semanas; Bash scripting y backups — 1 semana; Auditoría SQL + control acceso — 1 semana; CI/CD + hardening — 1 semana; Documentación — 1 semana).*

---

## 9.- Pruebas y validación

Se ejecutaron los siguientes tipos de pruebas para garantizar la calidad del sistema:

- **Pruebas Funcionales (ShellCheck):** Verificación de que todos los scripts Bash cumplen estándares POSIX sin errores de sintaxis. Integrado en GitHub Actions (`.github/workflows/ci.yml`).
- **Pruebas de Integración:** Ejecución del flujo completo con `vagrant up` verificando que las 3 VMs se crean, se comunican y los servicios quedan `healthy`.
- **Pruebas de Conectividad BD:** Verificación desde `vm-odoo` de que `nc -zv 192.168.40.10 5432` responde y que `psql -h 192.168.40.10 -U odoo -d odooerp` conecta.
- **Pruebas de Aceptación — Control de Acceso en 3 Capas:**

  | Prueba | Comando | Resultado esperado |
  |--------|---------|-------------------|
  | Nginx bloquea panel BD desde VLAN 10 | `curl -k https://erp.odoo.tfc.com/web/database/manager` | `403 Forbidden` |
  | Nginx permite panel BD desde VLAN 40 | Mismo curl desde PC en VLAN 40 | `200 OK` |
  | Nginx bloquea `/web/tests` | `curl -k https://erp.odoo.tfc.com/web/tests` | `403 Forbidden` |
  | DBA no tiene UI Odoo | Login con `dba@erp.odoo.tfc.com` | Sin módulos extra |
  | Becario no ve botón Eliminar | Login con `becario@erp.odoo.tfc.com` | Sin botón Eliminar en CRM |
  | VLAN 10 no accede a PostgreSQL | `nc -zv 192.168.40.10 5432` desde VLAN 10 | Timeout |
  | BD no expuesta a Internet | `nmap -p 5432 <IP_WAN>` | Puerto filtrado |

- **Pruebas de Backup:** Ejecución manual de `backup_postgres.sh`, verificando que se genera el fichero `.sql.gz` y que la restauración con `restore.sh` recupera los datos correctamente.
- **Pruebas de Seguridad de Red:** Intentos de conexión SSH desde VLAN 10 hacia la DMZ para validar que pfSense y UFW bloquean peticiones no autorizadas. Comprobación de anti-pivoting: VLAN 30 no puede alcanzar VLAN 10.
- **Pruebas de Disponibilidad:** Simulación de caída del servicio parando manualmente el contenedor `odoo-web`. Se validó que `monitor.sh` detecta la caída y reinicia el contenedor automáticamente en menos de un minuto.

---

## 10.- Relación del proyecto con los módulos del ciclo
El proyecto aborda de manera integral las competencias del ciclo de ASIR:
- **Seguridad y Alta Disponibilidad (SAD):** Segmentación en cuatro VLANs, firewalling perimetral con pfSense, cortafuegos local UFW, cifrado SSL/TLS y modelo Zero Trust. Backups automáticos con retención.
- **Servicios de Red e Internet (SRI):** Proxy inverso HTTP/HTTPS con Nginx (restricciones por IP), DHCP y DNS con pfSense.
- **Implantación de Aplicaciones Web (IAW):** Contenerización y despliegue del ERP web Odoo 17 con Docker Compose.
- **Gestión de Bases de Datos (GBD):** Triggers PL/pgSQL, datos JSONB y `pg_dump` remoto en PostgreSQL 16 en VM externa.
- **Sistemas Operativos en Red (SOR):** Administración GNU/Linux Debian, automatización con Bash y Cron, Cockpit para gestión visual, Vagrant para IaC.

---

## 11.- Conclusiones
El proyecto ha demostrado con éxito que es posible implementar un sistema complejo como Odoo en una infraestructura local simulando estándares *Enterprise*, incluyendo base de datos aislada en VM dedicada, contenerización del servicio y orquestación completa con Vagrant.

A nivel técnico, se ha conseguido aislar la carga de trabajo en una DMZ, separar la base de datos en una VLAN dedicada (VLAN 40) impidiendo que usuarios internos o atacantes accedan directamente a PostgreSQL, y reproducir el entorno completo con un único comando (`vagrant up`).

A nivel metodológico, la inversión de tiempo en planificar la infraestructura como código (Vagrant + Docker) y automatizar el ciclo de vida (Bash/Cron) ha reducido drásticamente los errores de despliegue en comparación con una instalación manual.

**Lección aprendida sobre LDAP:** Durante el proyecto se implementó y probó OpenLDAP con éxito, pero se tomó la decisión de retirarlo del despliegue activo tras evaluar la relación coste/beneficio: la autenticación nativa de Odoo cubre los requisitos del TFC con menor complejidad y menor superficie de ataque. Esta decisión refleja un criterio de ingeniería real: no añadir complejidad sin una necesidad clara que la justifique.

Uno de los principales aprendizajes del proyecto fue priorizar soluciones viables y mantenibles dentro del tiempo disponible, descartando alternativas más complejas que no aportaban una mejora proporcional al objetivo final del TFC.

---

## 12.- Proyectos futuros
- **Integración LDAP / Active Directory:** Centralizar credenciales usando el material disponible en `extras/ldap/`. Para Windows, Samba 4 AD DC ofrece compatibilidad completa con Active Directory y Kerberos.
- **Monitorización Avanzada:** Prometheus + Grafana para métricas en tiempo real de CPU/RAM de contenedores y tiempos de consulta de PostgreSQL.
- **Alta Disponibilidad de BD:** Clúster Patroni con replicación Master-Slave para PostgreSQL.
- **Filtrado Avanzado con pfBlockerNG:** Implementación de filtrado por ASN (AS36459 GitHub, AS8075 Azure) una vez se disponga de las claves API de IPinfo.io necesarias.
- **Ansible:** Sustituir los scripts de aprovisionamiento Vagrant por Playbooks de Ansible para mayor modularidad y reutilización.

---

## 13.- Bibliografía/Webgrafía
*(Recuerda mantener el formato APA).* Ejemplos:
- Netgate, (2024), "pfSense Documentation — VLAN Configuration", https://docs.netgate.com/pfsense/en/latest/vlan/configuration.html
- Odoo S.A., (2024), "Odoo 17 Developer Documentation", https://www.odoo.com/documentation/17.0/
- HashiCorp, (2024), "Vagrant Documentation", https://developer.hashicorp.com/vagrant/docs
- PostgreSQL Global Development Group, (2024), "PostgreSQL 16 Documentation — PL/pgSQL", https://www.postgresql.org/docs/16/plpgsql.html
- Docker Inc., (2024), "Docker Documentation — Networking overview", https://docs.docker.com/network/

---

## 14.- Anexos

**Anexo I: Scripts de Automatización Bash**
*(Código fuente de `vagrant/provision_debian.sh`, `vagrant/provision_postgres.sh`, `scripts/deploy/erp.sh`, `scripts/mantenimiento/backup_postgres.sh` y `scripts/odoo/odoo_crear_usuarios.sh`).*

**Anexo II: Reglas de Firewall y Seguridad**
*(Tablas de reglas exportadas de pfSense para WAN, LAN/VLAN 10, DMZ/VLAN 30 y Admin/VLAN 40. Ver `docs/reglas_pfsense.md`).*

**Anexo III: Funciones y Triggers SQL**
*(Código SQL de `sql/audit_triggers.sql` con la tabla `asir_audit_log`, el trigger `trg_audit_new_odoo_user` y la vista `v_audit_resumen`).*

**Anexo IV: Vagrantfiles**
*(Los tres ficheros `Vagrantfile` y los scripts `provision_debian.sh`, `provision_postgres.sh` y `provision_pfsense.sh`).*

**Anexo V: Configuración Nginx**
*(El archivo `config_nginx/odoo_proxy.conf` con los bloques `allow`/`deny` por CIDR para las rutas de administración).*

**Anexo VI: Material LDAP (referencia futura)**
*(Contenido de `extras/ldap/`: estructura LDIF, scripts de creación de usuarios y ACLs. Documentado como mejora futura no activa en el despliegue principal).*
