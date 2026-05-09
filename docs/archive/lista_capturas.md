# Lista de Capturas de Pantalla para la Memoria del TFG

Este documento detalla todas las capturas de pantalla esenciales que se deben tomar para ilustrar y validar la implementación técnica del proyecto en la Memoria Final. 

Te recomiendo ir marcando las casillas con `[x]` conforme vayas guardando las imágenes en la carpeta `screenshots/`.

---

## 1. Arquitectura de Red y Seguridad (pfSense)

- [ ] **Asignación de Interfaces:** Pantalla de pfSense (*Interfaces > Assignments*) donde se vean las tres redes configuradas: WAN, LAN, y OPT1 (DMZ).
- [ ] **Reglas de la DMZ:** Pantalla de *Firewall > Rules > OPT1 (DMZ)*. Esto demuestra el enfoque de seguridad *Zero Trust* (bloqueos al principio, permisos específicos de salida y la regla "deny-all" al final).
- [ ] **NAT / Port Forwarding:** Pantalla de *Firewall > NAT* mostrando el mapeo de los puertos 80 y 443 desde la interfaz WAN hacia la IP `192.168.30.10` del servidor Debian.

## 2. Servidor y Automatización (Debian & Bash)

- [ ] **Panel de Cockpit:** Pantalla principal de Cockpit (accediendo a `https://192.168.30.10:9090` desde el cliente) mostrando la monitorización de recursos (CPU/RAM) del servidor Debian.
- [ ] **Ejecución del Script Instalador:** Captura de la terminal SSH del cliente mostrando el final de la ejecución de `sudo ./install.sh` (con los mensajes de éxito en verde).
- [ ] **Orquestador Docker y Healthchecks:** Captura de la terminal ejecutando `./erp.sh status` donde se vean los tres contenedores (`odoo_erp`, `odoo-web`, `nginx-proxy`) en estado `Up (healthy)`.

## 3. Aplicación ERP y Proxy Inverso SSL (Odoo & Nginx)

- [ ] **Acceso Web Seguro (HTTPS):** Pantalla de inicio de sesión de Odoo desde el navegador del cliente de la LAN (`https://erp.techsolutions.local`). Es **importante** que se vea el "candado de seguridad" en la barra de direcciones.
- [ ] **Interfaz Interna del ERP:** Pantalla de Odoo una vez autenticado como administrador (por ejemplo, en "Ajustes"), demostrando que la interfaz fluye correctamente a través del reverse proxy.

## 4. Auditoría Avanzada en Base de Datos (PostgreSQL)

- [ ] **Registro de Auditoría (El Trigger en acción):** Tras crear un usuario en Odoo, captura la terminal de PostgreSQL (`SELECT * FROM v_audit_resumen;`) o la interfaz de DBeaver, mostrando que el evento ha generado una fila de `CREACION_USUARIO` con el JSONB correspondiente. 

## 5. Integración Continua (CI/CD - GitHub Actions)

- [ ] **Runner Activo en el Servidor:** Captura desde GitHub (*Settings > Actions > Runners*) donde tu runner alojado en el servidor Debian aparezca en estado "Idle" o activo.
- [ ] **Pipeline Exitoso:** Pantalla de la pestaña "Actions" del repositorio mostrando un flujo de trabajo (ej. "CD Deploy") con el icono verde de éxito (✅).
