Informe de Investigación y Viabilidad Tecnológica

Proyecto: Implantación Segura y Automatizada de Odoo ERP
Preparado para: Antigrabity
Contexto: Trabajo de Fin de Grado (ASIR) - IES Cañaveral

1. Resumen Amplio del Estado del Arte Tecnológico

Este informe consolida la investigación técnica orientada a diseñar y ejecutar el despliegue del ERP Odoo 17 y PostgreSQL 16. Tras evaluar el paradigma actual de la administración de sistemas, se ha determinado que el enfoque tradicional de "servidor monolítico" es insuficiente. Por tanto, el proyecto adopta una arquitectura basada en Infraestructura Inmutable y DevSecOps, dividida en las siguientes capas estratégicas:

Seguridad Perimetral y Redes (pfSense): El diseño se aleja de las redes planas. Se proyecta una topología segmentada mediante VLANs (IEEE 802.1Q) administradas por un cortafuegos pfSense. Se creará una Zona Desmilitarizada (DMZ) estricta con políticas de "denegación por defecto" (default deny) para aislar los servicios expuestos a internet de la red local corporativa.

Bastionado del Sistema (Linux Hardening): El sistema operativo anfitrión (Linux Mint 22 / base Ubuntu) será sometido a un endurecimiento profundo basado en los estándares internacionales CIS (Center for Internet Security). Esto incluye restricción de permisos (umask 027), deshabilitación de accesos root por SSH, uso de criptografía de curva elíptica (Ed25519) e implementación de Fail2Ban y UFW.

Contenerización y Orquestación (Docker): Para garantizar la portabilidad y la independencia de las dependencias de Python, el ERP y la base de datos se desplegarán mediante Docker Compose. Se ha investigado cómo sortear las limitaciones del GIL (Global Interpreter Lock) de Python ajustando los workers multiproceso de Odoo según los núcleos de CPU disponibles.

Criptografía y Proxy Inverso (Nginx): Nunca se expondrá el puerto nativo de Odoo (8069). Todo el tráfico pasará por un proxy inverso (Nginx / Nginx Proxy Manager) alojado en la DMZ, el cual realizará la terminación SSL/TLS (HTTPS mediante Let's Encrypt), ofuscará la topología interna y gestionará los túneles WebSocket necesarios para el funcionamiento en tiempo real del ERP.

Auditoría y Persistencia de Datos (PostgreSQL): La base de datos operará bajo un estricto escrutinio. Se diseñarán "Triggers" (disparadores) nativos en PL/pgSQL que interceptarán cualquier manipulación de datos (INSERT, UPDATE, DELETE), registrando el usuario, la hora y el estado anterior/nuevo en formato JSONB. Paralelamente, se automatizarán las copias de seguridad lógicas (pg_dump) y del filestore mediante tareas Cron.

2. ¿En qué va a ayudar esta investigación para hacer el TFG?

Esta batería de recursos y análisis técnico aporta un valor incalculable al desarrollo del Trabajo de Fin de Grado, impactando directamente en la calidad del resultado y en las competencias de los módulos de ASIR:

Aceleración de la Fase de Implementación: Las guías analizadas proporcionan la sintaxis exacta (manifiestos YAML, configuraciones de odoo.conf, reglas de Nginx) para evitar errores comunes de bloqueo, ahorrando semanas de resolución de problemas de integración (troubleshooting).

Resolución de Obstáculos Arquitectónicos Complejos: La investigación aborda y soluciona un problema clásico: la conexión de un contenedor Docker a una DMZ ruteada por pfSense. Se emplearán redes macvlan para dotar a los contenedores de identidades de red completas (MAC/IP) transparentes para el cortafuegos.

Alineación Curricular y Calidad Académica: * SAD (Seguridad y Alta Disponibilidad): Justifica la topología de red, el endurecimiento CIS y los simulacros de Disaster Recovery.

IAW (Implantación de Aplicaciones Web): Aplica el uso avanzado de proxies, balanceo de carga interno y certificados SSL.

GBD (Gestión de Bases de Datos): Eleva el nivel técnico al incluir programación de bases de datos mediante PL/pgSQL para auditorías inmutables, en lugar de simples consultas CRUD.

Soporte Documental para la Memoria: Todos los enlaces y referencias recopilados permitirán redactar una memoria final con un fuerte rigor académico, demostrando que las decisiones de diseño no son arbitrarias, sino basadas en las mejores prácticas de la industria corporativa.

3. Direcciones URL Válidas y Recursos Estratégicos

Para validar la arquitectura propuesta ante el tribunal o equipo supervisor, a continuación se presentan los recursos normativos y técnicos de referencia que guiarán la ejecución del proyecto:

Redes y Perímetro (pfSense)

Documentación Oficial de Netgate (Configuración VLAN): https://docs.netgate.com/pfsense/en/latest/vlan/configuration.html
Utilidad: Referencia principal para estructurar el tráfico de Capa 2 y la interconexión con los hipervisores.

Docker Macvlan Network en Entornos DMZ:
https://vegard.blog.engen.priv.no/?p=364
Utilidad: Solución técnica para eludir el NAT de Docker y exponer los contenedores directamente al cortafuegos.

Infraestructura y Hardening

Lista de Verificación de Endurecimiento Linux en Producción (2026):
https://hostperl.com/blog/linux-server-hardening-checklist-essential-security-controls-production-2026
Utilidad: Base para los scripts de configuración de llaves SSH (Ed25519), UFW y Fail2Ban.

CIS Benchmark Validation (Ejemplo Normativo):
https://www.scribd.com/document/946643717/CIS-Linux-Mint-22-Benchmark-v1-0-0
Utilidad: Aporta la normativa de cumplimiento estándar para auditar el servidor anfitrión.

Despliegue de Aplicación (Odoo y Nginx)

Documentación Odoo: Despliegue en Producción y Multiprocesamiento:
https://www.odoo.com/documentation/19.0/administration/on_premise/deploy.html
Utilidad: Fundamental para calcular la RAM necesaria, los tiempos límite de CPU y la configuración de los workers.

Proxy Inverso y Configuración SSL para Odoo:
https://oec.sh/guides/odoo-nginx-config
Utilidad: Proporciona los bloques de configuración de servidor necesarios para ofuscar cabeceras y permitir el tráfico WebSocket (LiveChat/Discuss de Odoo).

Bases de Datos y Auditoría (PostgreSQL)

Wiki Oficial PostgreSQL: Generic Audit Trigger (PL/pgSQL):
https://wiki.postgresql.org/wiki/Audit_trigger
Utilidad: Código fuente algorítmico sobre el que se basarán los disparadores para fiscalizar las operaciones de los usuarios del ERP.

Estrategias Completas de Backup y Recuperación (DR) en Odoo:
https://oec.sh/guides/odoo-backup-recovery
Utilidad: Documentación metodológica para programar los scripts Bash (backup.sh y restore.sh), uniendo los volcados de base de datos (pg_dump) con la persistencia del filestore.