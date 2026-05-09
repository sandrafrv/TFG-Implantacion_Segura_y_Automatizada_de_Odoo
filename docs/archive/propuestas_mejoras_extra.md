# Propuestas de Mejora Avanzadas (Nivel "Matrícula de Honor")

Este documento recoge ideas y ampliaciones opcionales para el TFG. Están pensadas para elevar el nivel técnico del proyecto al máximo estándar empresarial actual.

**Solo se implementarán si sobra tiempo tras cumplir los objetivos principales.**

---

### 1. Despliegue Automatizado con Ansible (Infraestructura como Código)
*   **Concepto:** En lugar de instalar dependencias, clonar repositorios y configurar el servidor Debian a mano, se programa un *Playbook* de Ansible.
*   **Cómo funciona:** Desde la máquina del administrador (o cliente), se lanza un comando (`ansible-playbook`). Ansible se conecta por SSH a la máquina Debian limpia y, de forma automática, configura las IPs, instala Docker, instala UFW, levanta los contenedores de Odoo y aplica seguridad.
*   **Veredicto:** Demuestra conocimientos maduros de DevOps e *Infraestructura como Código (IaC)*. Queda espectacular en una defensa presencial.

### 2. Acceso Remoto Seguro (VPN nativa en pfSense)
*   **Concepto:** Ocultar el ERP completamente de la Internet pública.
*   **Cómo funciona:** Se configura un servidor **OpenVPN** o **WireGuard** directamente en el firewall pfSense. Así, Odoo solo sería accesible desde la VLAN 10 interna o para trabajadores externos que previamente hayan establecido un túnel VPN encriptado contra el pfSense.
*   **Veredicto:** Un estándar irrenunciable en la ciberseguridad corporativa actual. Facilísimo de vender como "diseño Zero Trust".

### 3. Stack de Monitorización Visual (Prometheus + Grafana / Uptime Kuma)
*   **Concepto:** Sustituir los scripts de logs de texto por un Panel de Control gráfico.
*   **Cómo funciona:** Se añade un contenedor extra al `docker-compose.yml` (por ejemplo, *Uptime Kuma* o *Grafana*). Este contenedor ofrece una página web privada con gráficas de consumo de RAM, CPU y estado en vivo (UP/DOWN) del ERP y la base de datos PostgreSQL.
*   **Veredicto:** Muy vistoso visualmente. Ayuda a captar la atención del tribunal y demuestra dominio sobre la observabilidad de sistemas.

### 4. Integración de Usuarios con Directorio Activo (LDAP)
*   **Concepto:** Centralizar las credenciales de los trabajadores.
*   **Cómo funciona:** Se levanta una Máquina Virtual extra en la LAN (VLAN 10) con **Windows Server 2022** actuando como Controlador de Dominio (Active Directory). Odoo se configura para buscar los inicios de sesión ahí, por lo que los empleados usan sus usuarios de Windows para entrar al ERP.
*   **Veredicto:** Conecta de forma magistral la rama de sistemas Windows con la rama de sistemas Linux/Servicios, abarcando muchísimo temario de ASIR. Es complejo, pero el resultado es un "10" redondo.

### 5. Resiliencia de Datos (Alta Disponibilidad PostgreSQL)
*   **Concepto:** Tener copias de los datos exactas "al segundo" en otro servidor físico.
*   **Cómo funciona:** Además del backup diario, se levanta otro contenedor PostgreSQL "Esclavo" que replica constantemente las transacciones del "Maestro". Si se destruye el contenedor principal, el esclavo asume el rol instantáneamente.
*   **Veredicto:** Arquitectura Pura de bases de datos. Ideal si en el grupo hay alguien muy fuerte en el módulo de Bases de Datos, aunque consume bastante tiempo de desarrollo y pruebas de recuperación ante desastres (Disaster Recovery).
