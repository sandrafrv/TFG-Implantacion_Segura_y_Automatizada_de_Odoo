# Memoria del TFG: Implantación Segura y Automatizada de Odoo

*(Este documento es la plantilla definitiva basada en los requisitos exactos de tu instituto. Debes usar esto como base para redactar tu memoria en Word/PDF).*

---

## 1.- Introducción

### 1.1.- Descripción y contexto del proyecto
El presente proyecto se centra en el diseño, despliegue y automatización de la infraestructura técnica necesaria para alojar un sistema ERP (Enterprise Resource Planning), en este caso Odoo 17, bajo el nombre de empresa simulada **TechSolutions S.L.** El contexto del proyecto abarca la creación de un entorno seguro mediante segmentación de redes (WAN, LAN, DMZ y red de administración) con pfSense, el uso de tecnologías de contenerización (Docker con MACVLAN) sobre un servidor GNU/Linux Debian, y un directorio centralizado de usuarios basado en OpenLDAP.

### 1.2.- Motivación del proyecto
El proyecto surge de la necesidad que tienen las pequeñas y medianas empresas (PYMES) de digitalizar su gestión empresarial utilizando soluciones Open Source, pero enfrentándose al problema recurrente de instalaciones frágiles, monolíticas y altamente vulnerables. Tradicionalmente, los despliegues se realizan en servidores compartidos sin aislamiento de red, sin políticas de copias de seguridad automatizadas, sin gestión centralizada de identidades y sin auditoría interna. Este proyecto soluciona ese problema ofreciendo una arquitectura de red "Zero Trust" con cuatro redes segmentadas, un directorio LDAP centralizado y un ciclo de vida automatizado basado en prácticas DevOps.

### 1.3.- Beneficios esperados
- **Alta Seguridad:** Aislamiento del servidor en una DMZ gestionada por pfSense, red de administración dedicada (VLAN 40), y control local con UFW, minimizando la superficie de ataque.
- **Gestión Centralizada de Identidades:** Directorio OpenLDAP que unifica las credenciales de acceso al SO (SSSD/PAM) y al ERP (Odoo), de modo que un solo cambio de contraseña propaga a todos los servicios.
- **Trazabilidad y Auditoría:** Capacidad de registrar y auditar acciones críticas en la base de datos (PostgreSQL) para evitar la manipulación no autorizada de la información.
- **Resiliencia y Disponibilidad:** Automatización completa de copias de seguridad, rotación de logs y scripts de auto-recuperación ante caídas de servicio.
- **Despliegues ágiles:** Uso de *Infrastructure as Code* (Docker Compose) e Integración Continua (GitHub Actions) para reducir el error humano.

---

## 2.- Objetivo/s generales del proyecto
Desarrollar e implementar una solución de infraestructura automatizada, segura y de alta disponibilidad para alojar el sistema ERP Odoo 17, contemplando en este proceso todas las etapas de diseño de red (incluyendo segmentación en cuatro VLANs), autenticación centralizada con LDAP, contenerización con MACVLAN y políticas de mantenimiento necesarias para su resolución.

---

## 3.- Objetivos específicos
- Identificar los requisitos de red y seguridad para establecer un firewall perimetral (pfSense) segmentando el tráfico en cuatro VLANs: WAN, VLAN 10 (Clientes), VLAN 30 (DMZ) y VLAN 40 (Administración).
- Contenerizar el ERP, la base de datos, el proxy inverso y el directorio de usuarios (OpenLDAP) utilizando Docker Compose con redes MACVLAN para garantizar el aislamiento de procesos y la asignación de IPs propias a los contenedores.
- Implementar un directorio centralizado de usuarios con OpenLDAP y configurar la autenticación SSSD/PAM en los clientes Linux de VLAN 10, unificando el login del SO y del ERP con una sola credencial.
- Aplicar un modelo de seguridad de **tres capas** (Nginx por IP/VLAN, tipo de usuario Odoo y grupos/roles Odoo) que restrinja el acceso a las rutas de administración únicamente desde VLAN 40.
- Desarrollar un conjunto de scripts en Bash que automaticen el ciclo de vida del servicio (instalación, monitorización, copias de seguridad y restauración).
- Implementar mecanismos de auditoría intrusivos a nivel de base de datos (PL/pgSQL) para asegurar la trazabilidad de los usuarios.
- Planificar y configurar un flujo de despliegue continuo (CI/CD) que valide el código y lo integre en producción automáticamente.

---

## 4.- Contexto actual
**Estado del arte:** Actualmente, el despliegue de aplicaciones empresariales está transicionando desde instalaciones físicas (Bare Metal) hacia infraestructuras en la nube y contenerización. Las PYMES utilizan frecuentemente plataformas SaaS, pero aquellas que requieren el control total de sus datos optan por servidores propios gestionados por herramientas como Docker o Kubernetes.

**Conceptos clave:**
- **DMZ (Zona Desmilitarizada):** Red local que se ubica entre la red interna de una organización y una red externa.
- **VLAN de Administración:** Red segregada dedicada exclusivamente a los administradores de sistemas y DBAs, con acceso privilegiado a los servicios de gestión (SSH, Cockpit, LDAP admin, panel de base de datos).
- **Proxy Inverso:** Servidor que recupera recursos en nombre de un cliente desde uno o más servidores (Nginx).
- **Contenerización:** Virtualización a nivel de sistema operativo para desplegar aplicaciones (Docker).
- **MACVLAN:** Driver de red Docker que asigna una dirección MAC y una IP física de la red del host a cada contenedor, haciéndolos visibles directamente desde el switch/router.
- **LDAP (Lightweight Directory Access Protocol):** Protocolo estándar para la gestión centralizada de directorios de usuarios, grupos y atributos. En este proyecto se utiliza OpenLDAP.
- **SSSD (System Security Services Daemon):** Servicio que actúa de intermediario entre el sistema operativo Linux y el directorio LDAP, proporcionando caché offline y autenticación PAM.
- **Zero Trust:** Modelo de seguridad de red basado en el principio estricto de "no confiar en nadie por defecto".

---

## 5.- Análisis de requisitos

### 5.1.- Diagrama de casos de uso
*(Aquí debes adjuntar el diagrama UML de casos de uso. Ejemplo visual: Un "Administrador de Sistemas" (VLAN 40) se relaciona con casos como "Desplegar Infraestructura", "Gestionar Backups", "Monitorizar Recursos", "Gestionar Directorio LDAP" y "Administrar pfSense". Un "Usuario LAN" (VLAN 10) se relaciona con "Acceder al ERP vía HTTPS", "Autenticarse en Odoo mediante LDAP" e "Iniciar sesión en el PC con credenciales LDAP").*

### 5.2.- Requisitos funcionales principales
*(Derivados del diagrama UML anterior).*
- El sistema debe permitir el despliegue completo de la infraestructura sin intervención manual mediante un instalador unificado (`install.sh`).
- El sistema debe realizar copias de seguridad de la base de datos diariamente y retenerlas durante 7 días.
- El proxy inverso debe interceptar las peticiones HTTP y redirigirlas a HTTPS de forma automática.
- Las rutas de administración de Odoo (`/web/database`, `/odoo/action-base_setup`, `/web?debug=`) deben ser accesibles únicamente desde la red VLAN 40 (192.168.40.0/24).
- La infraestructura debe auditar y guardar un registro en formato JSONB cada vez que se cree un nuevo usuario en la aplicación.
- El directorio LDAP debe centralizar las cuentas de todos los empleados (VLAN 10) y administradores (VLAN 40), permitiendo un único login para el SO y el ERP.
- Los clientes Linux de VLAN 10 deben poder iniciar sesión en el sistema operativo utilizando sus credenciales LDAP (vía SSSD/PAM).

### 5.3.- Requisitos no funcionales
- **Seguridad y Confidencialidad:** El sistema no debe permitir accesos directos a la base de datos desde la red LAN; solo el proxy Nginx puede acceder a Odoo. El puerto LDAP 636 (LDAPS) estará bloqueado desde VLAN 10 y solo accesible desde VLAN 40.
- **Disponibilidad:** El sistema debe contar con mecanismos de auto-reinicio de servicios en caso de caída (Healthchecks y scripts de cron).
- **Trazabilidad:** El sistema debe ofrecer trazabilidad completa de las acciones administrativas en PostgreSQL.
- **Usabilidad de Gestión:** Todas las variables de entorno dinámicas deben cargarse automáticamente mediante un archivo `.env` o script interactivo.
- **Segregación de administración:** Los administradores y DBAs deben operar exclusivamente desde la VLAN 40; el panel de pfSense, el panel de base de datos de Odoo y la administración del directorio LDAP son inaccesibles desde VLAN 10.

### 5.4.- Descripción de los usuarios y sus necesidades

#### Usuarios de VLAN 10 — Empleados
| Rol | Necesidades |
|-----|-------------|
| **Becario** | Acceso de solo lectura a CRM. Credenciales LDAP para el login del PC y ERP. |
| **Ventas** | Acceso a CRM, Pipeline, Contactos y Facturas. |
| **RRHH** | Gestión de empleados, contratos y nóminas. |
| **Almacén** | Inventario, recepciones y pedidos de compra. |
| **Técnico** | Inventario y soporte. Además puede cambiar contraseñas de empleados en LDAP. |
| **Jefes de departamento** | Acceso completo a su módulo + aprobaciones. |

#### Usuarios de VLAN 40 — Administración
| Rol | Necesidades |
|-----|-------------|
| **Admin (SysAdmin)** | Acceso SSH al servidor, Cockpit, Docker, panel completo de Odoo (tipo Admin 11), gestión total de LDAP y pfSense. Necesita comandos rápidos (`erp.sh`) para gestionar el ciclo de vida sin recordar sentencias complejas de Docker. |
| **DBA** | Acceso a PostgreSQL y herramientas de backup. Sin acceso a la UI de Odoo. Solo pfSense y BD vía herramienta externa. |
| **API** | Solo acceso XML-RPC a Odoo; no tiene menú UI visible. |

---

## 6.- Diseño de la aplicación

### 6.1.- Mockups o wireframes o prototipos
*(Al ser un proyecto de sistemas, aquí debes incluir las capturas de la interfaz de Odoo (login, dashboard, panel de módulos por rol) y el dashboard de Cockpit, mostrando cómo es la "interfaz" con la que interactúan tus usuarios. Incluir también captura del árbol LDAP visto con un cliente como phpLDAPadmin o Apache Directory Studio).*

### 6.2.- Arquitectura del sistema
La arquitectura se basa en un modelo segmentado en cuatro redes. Un router pfSense actúa como puerta de enlace con cuatro interfaces:

```
Internet (WAN)
      │
  [pfSense]
  ├── VLAN 10 (192.168.10.0/24) ── Usuarios/Empleados del ERP
  ├── VLAN 40 (192.168.40.0/24) ── Administradores y DBA
  └── VLAN 30 / DMZ (192.168.30.0/24) ── Servidores
        ├── .10 → Debian 12 Host  (Docker engine, SSH :22, Cockpit :9090)
        ├── .20 → nginx-proxy     (MACVLAN — puerta de entrada HTTPS 80/443)
        ├── .21 → odoo-web        (MACVLAN — aplicación Odoo 17)
        └── .22 → openldap        (MACVLAN — directorio de usuarios LDAP)
```

Dentro del servidor Debian, los contenedores se comunican internamente mediante una red `bridge` (`odoo_net`) y cada uno con IPs propias en la VLAN 30 gracias a MACVLAN. Nginx recibe el tráfico cifrado, realiza la terminación SSL y aplica restricciones de acceso por IP de origen (VLAN); a continuación, pasa el tráfico al contenedor Odoo, que autentica los usuarios consultando el directorio OpenLDAP con el usuario de solo lectura `cn=readonly`.

*(Aquí debes añadir la captura o el PDF de tu diagrama de red).*

### 6.3.- Diagramas de clases y de entidad-relación
*(Aquí se incluye:*
*1. El modelo Entidad-Relación simplificado de la auditoría: La tabla `res_users` original de Odoo vinculada a tu tabla `asir_audit_log` mediante triggers.*
*2. El árbol LDAP con sus OUs y grupos.)*

El árbol LDAP tiene la siguiente estructura:
```
dc=tfg,dc=com
├── ou=usuarios          ← Cuentas personales de empleados
├── ou=grupos            ← Grupos departamentales
│   ├── cn=becarios      (VLAN 10)
│   ├── cn=ventas        (VLAN 10)
│   ├── cn=rrhh          (VLAN 10)
│   ├── cn=almacen       (VLAN 10)
│   ├── cn=tecnico       (VLAN 10) ← puede cambiar contraseñas
│   ├── cn=jefe_ventas   (VLAN 10)
│   ├── cn=jefe_rrhh     (VLAN 10)
│   ├── cn=jefe_almacen  (VLAN 10)
│   ├── cn=admin         (VLAN 40) ← acceso total al servidor
│   └── cn=dba           (VLAN 40) ← solo base de datos
└── ou=servicios         ← Cuentas técnicas (readonly, api)
```

### 6.4.- Diseño de la base de datos: esquemas y tablas
Se ha diseñado el esquema `asir_audit_log` con los campos: `audit_id` (PK), `action`, `table_name`, `record_id`, `row_data` (tipo JSONB para flexibilidad) y `created_at`.
*(Recuerda: El código SQL de creación va en los anexos).*

---

## 7.- Desarrollo de la aplicación

### 7.1.- Tecnologías y herramientas utilizadas
- **Debian 12:** Elegido como sistema operativo host por su altísima estabilidad, ciclo de soporte largo y su nula inclusión de paquetes propietarios intrusivos, siendo el estándar de producción.
- **Docker & Docker Compose:** Justificados por la modularidad y el aislamiento que aportan. Permiten empaquetar dependencias y levantar toda la infraestructura en segundos. Se usa la red **MACVLAN** para que los contenedores tengan IPs propias visibles desde pfSense.
- **pfSense:** Escogido por ser un firewall Open Source de grado empresarial robusto. Gestiona cuatro interfaces: WAN, VLAN 10 (Clientes), VLAN 30 (DMZ) y VLAN 40 (Administración).
- **Nginx:** Elegido como proxy inverso por su extremada rapidez (motor asíncrono) y facilidad para terminación SSL. Además aplica restricciones de acceso por IP/VLAN como primera capa de seguridad.
- **OpenLDAP:** Servidor de directorio Open Source que centraliza la gestión de identidades. Los empleados usan la misma contraseña para el login del SO (SSSD/PAM) y para Odoo ERP.
- **SSSD (System Security Services Daemon):** Intermediario entre los clientes Linux de VLAN 10 y el servidor LDAP. Proporciona caché offline (el usuario puede seguir iniciando sesión aunque el LDAP esté caído temporalmente).
- **PostgreSQL:** Base de datos relacional elegida por ser el motor obligatorio de Odoo y soportar funciones avanzadas como JSONB y PL/pgSQL.
- **GitHub & GitHub Actions:** GitHub como repositorio centralizado para control de versiones y Actions para la Integración Continua, evitando despliegues manuales propensos a errores.

### 7.2.- Descripción de las principales funcionalidades implementadas

#### Orquestador Central (`erp.sh`)
Interfaz CLI creada en Bash para abstraer los comandos complejos de Docker. Permite gestionar logs, backups y estados con parámetros simples (`./erp.sh backup`).
*(Ilustrar con un pequeño fragmento de tu script `erp.sh`).*

#### Directorio de Usuarios OpenLDAP + SSSD
Contenedor `openldap` con IP MACVLAN `192.168.30.22`. Los usuarios se crean con el script `ldap_crear_usuarios.sh`. Las ACLs del directorio se configuran con `ldap_politica_acceso.sh`:

| Cuenta | Permisos en LDAP | Para qué se usa |
|--------|-----------------|-----------------|
| `cn=admin` | Escritura total | Administración del directorio (solo VLAN 40) |
| Grupo `cn=tecnico` | `write` solo en `userPassword` de `ou=usuarios` | Cambio de contraseñas de empleados |
| `cn=readonly` | Lectura de todo el árbol | Odoo autentica usuarios; PAM en máquinas VLAN 10 |
| Anónimo | Solo `auth` en `userPassword` | Verificación de credenciales en login |
| Resto | Ninguno | `deny all` |

Los clientes Linux de VLAN 10 se configuran ejecutando `scripts/configurar_cliente_ldap.sh`, que instala SSSD, PAM y NSS para resolver los usuarios de LDAP como si fueran locales del sistema.

#### Modelo de Seguridad en 3 Capas
Aplicado sobre la ruta de acceso al ERP:

```
[Petición HTTPS del usuario]
           │
    ┌──────▼────────┐
    │  CAPA C: Nginx │  ← Primera barrera: filtra rutas por IP/VLAN
    └──────┬────────┘
           │ (solo rutas permitidas pasan)
    ┌──────▼────────┐
    │  CAPA B: Odoo  │  ← Segunda barrera: tipo de usuario (Portal/Interno/Admin)
    │  Tipo usuario  │
    └──────┬────────┘
           │ (solo tipo correcto accede)
    ┌──────▼────────┐
    │  CAPA A: Odoo  │  ← Tercera barrera: grupos = qué módulos y acciones ve
    │  Grupos/Roles  │
    └───────────────┘
```

**Capa C — Nginx** restringe las rutas de administración por red de origen:

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

**Capa A — Grupos Odoo por rol** (script `odoo_crear_usuarios.sh`): cada empleado tiene asignado automáticamente los XML-IDs de grupos correspondientes a su rol departamental (ver `docs/CONTROL_ACCESO.md`).

#### Auditoría en Base de Datos
Uso de funciones dinámicas en PL/pgSQL que se disparan (`AFTER INSERT`) cuando Odoo crea un usuario. Los registros se almacenan en `asir_audit_log` con tipo JSONB.
*(Ilustrar con el bloque `EXECUTE FORMAT` del trigger).*

#### Auto-recuperación y Healthchecks
Implementación nativa en el `docker-compose.yml` para evaluar la salud de Nginx y PostgreSQL antes de arrancar Odoo.

---

## 8.- Planificación del proyecto

### 8.1.- Acciones
El proyecto se dividió en fases secuenciales:
1. Investigación y diseño de red (cuatro VLANs, diagrama IaC).
2. Despliegue de hipervisor y Firewall (pfSense con VLAN 10, 30 y 40).
3. Instalación de Host Linux y seguridad perimetral local (UFW).
4. Desarrollo de scripts (IaC y automatización: `install.sh`, `deploy.sh`, `erp.sh`).
5. Implementación de OpenLDAP, SSSD y modelo de control de acceso en 3 capas.
6. Auditoría de Base de datos (triggers PL/pgSQL).
7. CI/CD y despliegue continuo (GitHub Actions).

### 8.2.- Temporalización y secuenciación
*(Aquí debes crear y pegar una tabla o diagrama de Gantt indicando cuánto tiempo en semanas te llevó cada fase, por ejemplo: Diseño de red y VLANs 1 semana, Desarrollo Docker + MACVLAN 2 semanas, OpenLDAP + SSSD 1 semana, Bash scripting 1 semana, Pruebas 1 semana).*

---

## 9.- Pruebas y validación

Se ejecutaron los siguientes tipos de pruebas para garantizar la calidad del sistema:

- **Pruebas Funcionales (Unitarias de bash):** Verificación mediante ShellCheck (integrado en GitHub Actions) de que todos los scripts de bash cumplían con los estándares POSIX y no tenían errores de sintaxis antes del despliegue.
- **Pruebas de Integración y Sistema:** Ejecución del flujo completo de despliegue (`deploy.sh`) validando que los cuatro contenedores (Nginx, Odoo, PostgreSQL, OpenLDAP) se comunican entre sí en la red MACVLAN sin colisiones de IPs.
- **Pruebas de Autenticación LDAP:** Verificación de que un empleado de VLAN 10 puede iniciar sesión en su PC Linux con credenciales LDAP (`getent passwd <uid>`, `su - <uid>`) y acceder a Odoo con las mismas credenciales desde el navegador.
- **Pruebas de Aceptación — Control de Acceso en 3 Capas:**

  | Prueba | Comando | Resultado esperado |
  |--------|---------|-------------------|
  | Nginx bloquea panel BD desde VLAN 10 | `curl -k https://erp.odoo.tfg.com/web/database/manager` | `403 Forbidden` |
  | Nginx permite panel BD desde VLAN 40 | Mismo curl desde PC en VLAN 40 | `200 OK` |
  | Nginx bloquea `/web/tests` | `curl -k https://erp.odoo.tfg.com/web/tests` | `403 Forbidden` |
  | Readonly LDAP no puede modificar | `ldapmodify` con `cn=readonly` | `Insufficient access (50)` |
  | Técnico puede cambiar contraseña LDAP | `ldappasswd` con credenciales técnico | Éxito |
  | DBA no tiene UI Odoo | Login con `dba@erp.odoo.tfg.com` | Sin módulos extra |
  | Becario no ve botón Eliminar | Login con `becario@erp.odoo.tfg.com` | Sin botón Eliminar en CRM |

- **Pruebas de Seguridad de Red:** Intentos de conexión SSH desde la LAN (VLAN 10) hacia la DMZ para validar que el firewall pfSense y el UFW local bloquean peticiones no autorizadas. Comprobación de anti-pivoting: la VLAN 40 no puede alcanzar la VLAN 10 (regla Block en OPT2).
- **Pruebas de Disponibilidad y Estrés:** Simulación de caída del servicio parando manualmente el contenedor `odoo-web`. Se validó que el script `monitor.sh` ejecutado por cron detectó la caída y restableció el servicio automáticamente en menos de un minuto.
- **Prueba de resiliencia LDAP offline:** Con `cache_credentials = true` en SSSD, se verificó que un empleado que había iniciado sesión previamente puede seguir haciéndolo aunque el contenedor OpenLDAP esté parado (caché de SSSD activa durante ~1 hora).

---

## 10.- Relación del proyecto con los módulos del ciclo
El proyecto aborda de manera integral las competencias del ciclo de ASIR:
- **Seguridad y Alta Disponibilidad (SAD):** Segmentación de redes en cuatro VLANs, firewalling perimetral con pfSense (VLAN 10, VLAN 30, VLAN 40), cortafuegos local UFW, cifrado SSL/TLS en tránsito y modelo Zero Trust.
- **Servicios de Red e Internet (SRI):** Configuración de un proxy inverso HTTP/HTTPS (Nginx) con restricciones por IP, servicios de resolución local DNS y DHCP, e implementación de OpenLDAP como servicio de directorio.
- **Implantación de Aplicaciones Web (IAW):** Contenerización y despliegue del ERP web Odoo 17 con MACVLAN y gestión de dependencias en Docker Compose.
- **Gestión de Bases de Datos (GBD):** Programación de funciones, triggers y gestión de datos JSONB en PostgreSQL 16, y copias de seguridad automatizadas.
- **Sistemas Operativos en Red (SOR):** Administración avanzada de GNU/Linux Debian, configuración de SSSD/PAM para autenticación LDAP en clientes Linux, automatización de tareas con Cron y scripting complejo en Bash.

---

## 11.- Conclusiones
El proyecto ha demostrado con éxito que es posible implementar un sistema complejo como Odoo en una infraestructura local simulando estándares *Enterprise*, incluyendo gestión centralizada de identidades con OpenLDAP y segregación avanzada de redes con cuatro VLANs.

A nivel técnico, se ha conseguido aislar la carga de trabajo en una red DMZ, separar la administración del sistema en una VLAN dedicada (VLAN 40) previniendo que usuarios internos o atacantes externos alcancen los servicios de gestión, y unificar las credenciales de los empleados en un único directorio LDAP.

A nivel metodológico, la inversión de tiempo en planificar la infraestructura como código (Docker + MACVLAN) y automatizar el ciclo de vida (Bash/Cron) ha reducido drásticamente los errores de despliegue en comparación con una instalación manual.

Uno de los mayores desafíos técnicos ha sido la implementación de un filtrado de salida estricto (*Egress Filtering*) para la DMZ. Se intentó implementar filtrado de salida basado en ASN mediante pfBlockerNG-devel, configurando los sistemas autónomos AS36459 (GitHub) y AS8075 (Microsoft/Azure). Sin embargo, la solución requiere un token de API externo de IPinfo.io para resolver los rangos CIDR de cada ASN, lo que introduce una dependencia de un servicio de terceros. Por ello, se ha decidido posponer esta medida como una mejora futura para una fase de producción real, manteniendo provisionalmente una regla de salida permisiva por puerto 443 pero documentando la viabilidad técnica del bloqueo por ASN.

---

## 12.- Proyectos futuros
- **Integración de Active Directory (Samba 4):** Para permitir que los equipos Windows se unan al dominio y utilicen las cuentas de red para el inicio de sesión del SO. OpenLDAP estándar no permite el login nativo en Windows; Samba 4 AD DC ofrece compatibilidad completa con Active Directory, Kerberos y DNS.
- **Monitorización Avanzada:** Despliegue de un stack de Prometheus y Grafana para extraer métricas en tiempo real del uso de CPU/RAM de los contenedores y los tiempos de consulta de PostgreSQL.
- **Alta Disponibilidad de BD:** Creación de un clúster *Master-Slave* de PostgreSQL para garantizar continuidad de negocio ante el fallo crítico del servidor.
- **Filtrado Avanzado con pfBlockerNG:** Implementación definitiva del filtrado por ASN una vez se disponga de las claves de API necesarias, eliminando por completo la regla permisiva del puerto 443.

---

## 13.- Bibliografía/Webgrafía
*(Recuerda mantener el formato APA).* Ejemplos:
- Docker Inc., (2024), "Docker Documentation — Networking overview (MACVLAN)", https://docs.docker.com/network/drivers/macvlan/
- Netgate, (2024), "pfSense Documentation — VLAN Configuration", https://docs.netgate.com/pfsense/en/latest/vlan/configuration.html
- Odoo S.A., (2024), "Odoo 17 Developer Documentation", https://www.odoo.com/documentation/17.0/
- OpenLDAP Foundation, (2024), "OpenLDAP Software 2.6 Administrator's Guide", https://www.openldap.org/doc/admin26/
- Red Hat, (2024), "SSSD Configuration Guide", https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/integrating_rhel_systems_directly_with_windows_active_directory/
- PostgreSQL Global Development Group, (2024), "PostgreSQL 16 Documentation — PL/pgSQL", https://www.postgresql.org/docs/16/plpgsql.html

---

## 14.- Anexos

**Anexo I: Scripts de Automatización Bash**
*(Puedes poner el código fuente de `install.sh`, `erp.sh`, `ldap_crear_usuarios.sh`, `ldap_politica_acceso.sh`, `odoo_crear_usuarios.sh` y `configurar_cliente_ldap.sh`).*

**Anexo II: Reglas de Firewall y Seguridad**
*(Tablas de reglas exportadas de pfSense para las interfaces WAN, LAN/VLAN 10, DMZ/VLAN 30 y Admin/VLAN 40. Ver `docs/reglas_pfsense.md`).*

**Anexo III: Funciones y Triggers SQL**
*(El código SQL de `audit_triggers.sql` y las sentencias DDL para la creación de la tabla `asir_audit_log`).*

**Anexo IV: Estructura LDAP (ldap/estructura.ldif)**
*(El archivo LDIF que inicializa el árbol del directorio con las OUs `usuarios`, `grupos` y `servicios`, incluyendo todos los grupos departamentales de VLAN 10 y VLAN 40).*

**Anexo V: Configuración Nginx (Control de Acceso por IP/VLAN)**
*(El archivo `config_nginx/odoo_proxy.conf` con los bloques `allow`/`deny` por bloque CIDR para las rutas de administración).*
