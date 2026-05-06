# Memoria del TFG: Implantación Segura y Automatizada de Odoo

*(Este documento es la plantilla definitiva basada en los requisitos exactos de tu instituto. Debes usar esto como base para redactar tu memoria en Word/PDF).*

---

## 1.- Introducción

### 1.1.- Descripción y contexto del proyecto
El presente proyecto se centra en el diseño, despliegue y automatización de la infraestructura técnica necesaria para alojar un sistema ERP (Enterprise Resource Planning), en este caso Odoo 17. El contexto del proyecto abarca la creación de un entorno seguro mediante segmentación de redes (WAN, LAN y DMZ) con pfSense, y el uso de tecnologías de contenerización (Docker) sobre un servidor GNU/Linux Debian.

### 1.2.- Motivación del proyecto
El proyecto surge de la necesidad que tienen las pequeñas y medianas empresas (PYMES) de digitalizar su gestión empresarial utilizando soluciones Open Source, pero enfrentándose al problema recurrente de instalaciones frágiles, monolíticas y altamente vulnerables. Tradicionalmente, los despliegues se realizan en servidores compartidos sin aislamiento de red, sin políticas de copias de seguridad automatizadas y sin auditoría interna. Este proyecto soluciona ese problema ofreciendo una arquitectura de red "Zero Trust" y un ciclo de vida automatizado basado en prácticas DevOps.

### 1.3.- Beneficios esperados
- **Alta Seguridad:** Aislamiento del servidor en una DMZ gestionada por pfSense, y control local con UFW, minimizando la superficie de ataque.
- **Trazabilidad y Auditoría:** Capacidad de registrar y auditar acciones críticas en la base de datos (PostgreSQL) para evitar la manipulación no autorizada de la información.
- **Resiliencia y Disponibilidad:** Automatización completa de copias de seguridad, rotación de logs y scripts de auto-recuperación ante caídas de servicio.
- **Despliegues ágiles:** Uso de *Infrastructure as Code* (Docker Compose) e Integración Continua (GitHub Actions) para reducir el error humano.

---

## 2.- Objetivo/s generales del proyecto
Desarrollar e implementar una solución de infraestructura automatizada, segura y de alta disponibilidad para alojar el sistema ERP Odoo, contemplando en este proceso todas las etapas de diseño de red, contenerización y políticas de mantenimiento necesarias para su resolución.

---

## 3.- Objetivos específicos
- Identificar los requisitos de red y seguridad para establecer un firewall perimetral (pfSense) segmentando el tráfico en VLANs.
- Contenerizar el ERP, la base de datos y el proxy inverso utilizando Docker Compose para garantizar el aislamiento de procesos.
- Desarrollar un conjunto de scripts en Bash que automaticen el ciclo de vida del servicio (instalación, monitorización, copias de seguridad y restauración).
- Implementar mecanismos de auditoría intrusivos a nivel de base de datos (PL/pgSQL) para asegurar la trazabilidad de los usuarios.
- Planificar y configurar un flujo de despliegue continuo (CI/CD) que valide el código y lo integre en producción automáticamente.

---

## 4.- Contexto actual
**Estado del arte:** Actualmente, el despliegue de aplicaciones empresariales está transicionando desde instalaciones físicas (Bare Metal) hacia infraestructuras en la nube y contenerización. Las PYMES utilizan frecuentemente plataformas SaaS, pero aquellas que requieren el control total de sus datos optan por servidores propios gestionados por herramientas como Docker o Kubernetes. 

**Conceptos clave:**
- **DMZ (Zona Desmilitarizada):** Red local que se ubica entre la red interna de una organización y una red externa.
- **Proxy Inverso:** Servidor que recupera recursos en nombre de un cliente desde uno o más servidores (Nginx).
- **Contenerización:** Virtualización a nivel de sistema operativo para desplegar aplicaciones (Docker).
- **Zero Trust:** Modelo de seguridad de red basado en el principio estricto de "no confiar en nadie por defecto".

---

## 5.- Análisis de requisitos

### 5.1.- Diagrama de casos de uso
*(Aquí debes adjuntar el diagrama UML de casos de uso. Ejemplo visual: Un "Administrador de Sistemas" se relaciona con casos como "Desplegar Infraestructura", "Gestionar Backups", "Monitorizar Recursos". Un "Usuario LAN" se relaciona con "Acceder al ERP vía HTTPS" y "Autenticarse en Odoo").*

### 5.2.- Requisitos funcionales principales
*(Derivados del diagrama UML anterior).*
- El sistema debe permitir el despliegue completo de la infraestructura sin intervención manual mediante un instalador unificado.
- El sistema debe realizar copias de seguridad de la base de datos diariamente y retenerlas durante 7 días.
- El proxy inverso debe interceptar las peticiones HTTP y redirigirlas a HTTPS de forma automática.
- La infraestructura debe auditar y guardar un registro en formato JSONB cada vez que se cree un nuevo usuario en la aplicación.

### 5.3.- Requisitos no funcionales
- **Seguridad y Confidencialidad:** El sistema no debe permitir accesos directos a la base de datos desde la red LAN; solo el proxy Nginx puede acceder a Odoo.
- **Disponibilidad:** El sistema debe contar con mecanismos de auto-reinicio de servicios en caso de caída (Healthchecks y scripts de cron).
- **Trazabilidad:** El sistema debe ofrecer trazabilidad completa de las acciones administrativas en PostgreSQL.
- **Usabilidad de Gestión:** Todas las variables de entorno dinámicas deben cargarse automáticamente mediante un archivo `.env` o script interactivo.

### 5.4.- Descripción de los usuarios y sus necesidades
- **Administrador IT (SysAdmin):** Necesita acceso SSH al servidor, visibilidad de los recursos físicos (Cockpit) y comandos rápidos (`erp.sh`) para gestionar el ciclo de vida sin tener que recordar sentencias complejas de Docker.
- **Usuario de Oficina (LAN):** Necesita un acceso web rápido, ininterrumpido y cifrado a Odoo para realizar tareas administrativas sin interrupciones técnicas.

---

## 6.- Diseño de la aplicación

### 6.1.- Mockups o wireframes o prototipos
*(Al ser un proyecto de sistemas, aquí debes incluir las capturas de la interfaz de Odoo (login, dashboard) y quizás el dashboard de Cockpit, mostrando cómo es la "interfaz" con la que interactúan tus usuarios).*

### 6.2.- Arquitectura del sistema
La arquitectura se basa en un modelo segmentado. Un router pfSense actúa como puerta de enlace, derivando el tráfico entrante del puerto 443 hacia la VLAN 30 (DMZ). Dentro de la DMZ, un servidor Debian aloja un entorno Docker. Nginx recibe el tráfico cifrado, realiza la terminación SSL y se comunica internamente mediante una red `bridge` (odoo_net) con el contenedor de la aplicación web (Odoo), el cual finalmente conecta con el contenedor de la base de datos (PostgreSQL).
*(Aquí debes añadir la captura o el PDF de tu diagrama de red)*.

### 6.3.- Diagramas de clases y de entidad-relación
*(Aquí se incluye el modelo Entidad-Relación simplificado de la auditoría: La tabla `res_users` original de Odoo vinculada a tu tabla `asir_audit_log` mediante triggers).*

### 6.4.- Diseño de la base de datos: esquemas y tablas
Se ha diseñado el esquema `asir_audit_log` con los campos: `audit_id` (PK), `action`, `table_name`, `record_id`, `row_data` (tipo JSONB para flexibilidad) y `created_at`.
*(Recuerda: El código SQL de creación va en los anexos).*

---

## 7.- Desarrollo de la aplicación

### 7.1.- Tecnologías y herramientas utilizadas
- **Debian 12:** Elegido como sistema operativo host por su altísima estabilidad, ciclo de soporte largo y su nula inclusión de paquetes propietarios intrusivos, siendo el estándar de producción.
- **Docker & Docker Compose:** Justificados por la modularidad y el aislamiento que aportan. Permiten empaquetar dependencias y levantar toda la infraestructura en segundos.
- **pfSense:** Escogido por ser un firewall Open Source de grado empresarial robusto para la segmentación de VLANs.
- **Nginx:** Elegido como proxy inverso por su extremada rapidez (motor asíncrono) y facilidad para terminación SSL.
- **PostgreSQL:** Base de datos relacional elegida por ser el motor obligatorio de Odoo y soportar funciones avanzadas como JSONB y PL/pgSQL.
- **GitHub & GitHub Actions:** GitHub como repositorio centralizado para control de versiones y Actions para la Integración Continua, evitando despliegues manuales propensos a errores.

### 7.2.- Descripción de las principales funcionalidades implementadas
- **Orquestador Central (`erp.sh`):** Interfaz CLI creada en Bash para abstraer los comandos complejos de Docker. Permite gestionar logs, backups y estados con parámetros simples (`./erp.sh backup`).
*(Ilustrar con un pequeño fragmento de tu script `erp.sh`)*.
- **Auditoría en Base de Datos:** Uso de funciones dinámicas en PL/pgSQL que se disparan (`AFTER INSERT`) cuando Odoo crea un usuario.
*(Ilustrar con el bloque `EXECUTE FORMAT` del trigger)*.
- **Auto-recuperación y Healthchecks:** Implementación nativa en el `docker-compose.yml` para evaluar la salud de Nginx y PostgreSQL antes de arrancar Odoo.

---

## 8.- Planificación del proyecto

### 8.1.- Acciones
El proyecto se dividió en fases secuenciales:
1. Investigación y diseño de red.
2. Despliegue de hipervisor y Firewall (pfSense).
3. Instalación de Host Linux y seguridad perimetral local (UFW).
4. Desarrollo de scripts (IaC y automatización).
5. Auditoría de Base de datos.
6. CI/CD y despliegue continuo.

### 8.2.- Temporalización y secuenciación
*(Aquí debes crear y pegar una tabla o diagrama de Gantt indicando cuánto tiempo en semanas te llevó cada fase, por ejemplo: Diseño 1 semana, Desarrollo Docker 2 semanas, Bash scripting 1 semana, Pruebas 1 semana).*

---

## 9.- Pruebas y validación

Se ejecutaron los siguientes tipos de pruebas para garantizar la calidad del sistema:
- **Pruebas Funcionales (Unitarias de bash):** Verificación mediante ShellCheck (integrado en GitHub Actions) de que todos los scripts de bash cumplían con los estándares POSIX y no tenían errores de sintaxis antes del despliegue.
- **Pruebas de Integración y Sistema:** Ejecución del flujo completo de despliegue (`deploy.sh`) validando que los tres contenedores se comunican entre sí en la red bridge sin colisiones de puertos.
- **Pruebas de Aceptación (Seguridad):** Intentos de conexión SSH desde la LAN hacia la DMZ para validar que el firewall pfSense y el UFW local bloquean peticiones no autorizadas.
- **Pruebas de Disponibilidad y Estrés:** Simulación de caída del servicio parando manualmente el contenedor `odoo-web`. Se validó que el script `monitor.sh` ejecutado por cron detectó la caída y restableció el servicio automáticamente en menos de un minuto.

---

## 10.- Relación del proyecto con los módulos del ciclo
El proyecto aborda de manera integral las competencias del ciclo de ASIR:
- **Seguridad y Alta Disponibilidad (SAD):** Segmentación de redes, firewalling perimetral con pfSense, cortafuegos local UFW y cifrado SSL/TLS en tránsito.
- **Servicios de Red e Internet (SRI):** Configuración de un proxy inverso HTTP/HTTPS (Nginx) y servicios de resolución local DNS y DHCP.
- **Implantación de Aplicaciones Web (IAW):** Contenerización y despliegue del ERP web Odoo gestionando sus dependencias en Docker.
- **Gestión de Bases de Datos (GBD):** Programación de funciones, triggers y gestión de datos JSONB en PostgreSQL 16.
- **Sistemas Operativos en Red (SOR):** Administración avanzada de GNU/Linux Debian, automatización de tareas con Cron y scripting complejo en Bash.

---

## 11.- Conclusiones
El proyecto ha demostrado con éxito que es posible implementar un sistema complejo como Odoo en una infraestructura local simulando estándares *Enterprise*. 
A nivel técnico, se ha conseguido aislar la carga de trabajo en una red DMZ, previniendo riesgos de seguridad perimetral.
A nivel metodológico, la inversión de tiempo en planificar la infraestructura como código (Docker) y automatizar el ciclo de vida (Bash/Cron) ha reducido drásticamente los errores de despliegue en comparación con una instalación manual. 
*(Añade aquí tu propia reflexión personal sobre lo que más te ha costado o lo que más has aprendido, por ejemplo, la dificultad de gestionar volúmenes de Docker o el aprendizaje sobre los triggers en Bases de Datos).*

---

## 12.- Proyectos futuros
- **Implementación de Macvlan:** Mejorar la arquitectura de red permitiendo que cada contenedor Docker obtenga su propia IP física (VLAN 30) desde el pfSense, en lugar de enmascararse detrás del host Debian.
- **Monitorización Avanzada:** Despliegue de un stack de Prometheus y Grafana para extraer métricas en tiempo real del uso de CPU/RAM de los contenedores y los tiempos de consulta de PostgreSQL.
- **Alta Disponibilidad de BD:** Creación de un clúster *Master-Slave* de PostgreSQL para garantizar continuidad de negocio ante el fallo crítico del servidor.

---

## 13.- Bibliografía/Webgrafía
*(Recuerda mantener el formato APA)*. Ejemplos:
- Docker Inc., (2024), "Docker Documentation", https://docs.docker.com/
- Netgate, (2024), "pfSense Documentation - VLAN Configuration", https://docs.netgate.com/pfsense/en/latest/vlan/configuration.html
- Odoo S.A., (2024), "Odoo 17 Developer Documentation", https://www.odoo.com/documentation/17.0/

---

## 14.- Anexos
**Anexo I: Scripts de Automatización Bash**
*(Puedes poner el código fuente de `install.sh` y `erp.sh`)*.

**Anexo II: Reglas de Firewall y Seguridad**
*(Tablas de reglas exportadas de pfSense).*

**Anexo III: Funciones y Triggers SQL**
*(El código SQL de `audit_triggers.sql` y las sentencias DDL para la creación de la tabla).*
