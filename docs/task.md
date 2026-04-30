# Lista de Tareas: Implantación Odoo con pfSense y Docker

Este documento sirve para llevar un seguimiento de nuestro progreso a medida que ejecutamos el proyecto.
Marca con `[x]` las tareas a medida que se vayan completando en el entorno real o virtual.

> **Última actualización:** 2026-04-30

---

## Fase 0: Investigación Técnica y Justificación de Diseño

- [x] **[2026-04-29]** Investigación tecnológica completada: evaluación de Odoo vs Dolibarr vs ERPNext.
- [x] **[2026-04-29]** Decisión de OS documentada: Debian 12 elegido sobre Ubuntu/Mint (con entorno gráfico GNOME).
- [x] **[2026-04-29]** Nota técnica sobre macvlan documentada en `implementation_plan.md` y `README.md`.
- [x] **[2026-04-29]** Referencias técnicas (CIS, Odoo deploy, PostgreSQL audit) añadidas al `README.md`.
- [x] **[2026-04-29]** Comparativa ERP añadida al `docs/implementation_plan.md` (Fase 0).
- [x] **[2026-04-29]** Arquitectura de red definida: WAN / LAN (192.168.10.0/24) / DMZ (192.168.30.0/24).

---

## Fase 1: Arquitectura y Red Base (pfSense)

- [x] Descargar ISO de pfSense y crear Máquina Virtual.
- [x] Configurar 3 adaptadores de red en la VM pfSense (WAN, LAN Clientes, DMZ/OPT1).
- [x] Ejecutar la instalación básica de pfSense.
- [x] Asignar interfaces (WAN, LAN y OPT1 para la DMZ).
- [x] Configurar servidor DHCP en pfSense para la VLAN 10 (LAN Clientes).
- [x] Instalar Máquina Virtual de Cliente (Windows 10 o Desktop Linux) en LAN.
- [x] Validar que el Cliente obtiene IP por DHCP y tiene salida a Internet.
- [x] **[2026-04-29]** Reglas WAN configuradas: bloqueo redes privadas/bogon, apertura 80/443 público, SSH y Cockpit restringidos a IP admin (`192.168.163.140`).
- [x] **[2026-04-29]** Reglas LAN configuradas: anti-lockout activa, "allow all" desactivada, reglas específicas hacia DMZ (80/443/8069/8072) y bloqueo de acceso inverso desde DMZ.
- [x] **[2026-04-29]** Reglas DMZ (OPT1) configuradas en orden correcto: bloqueos primero (anti-pivoting hacia LAN y pfSense), luego permisos de salida (HTTP/HTTPS/DNS/SMTP/PostgreSQL), deny-all al final.
- [x] **[2026-04-29]** NAT Port Forwarding configurado: HTTP (80) y HTTPS (443) hacia `192.168.30.10`, SSH y Cockpit restringidos a IP admin.
- [x] **[2026-04-29]** Reglas documentadas en `docs/reglas_pfsense.md` con tablas, diagramas de flujo y puntos clave.
- [x] **[2026-04-29]** Limpiar reglas EasyRule duplicadas en OPT1 (HTTP, HTTPS, DNS repetidos — consolidar en una sola por protocolo).
- [x] **[2026-04-29]** Eliminar o restringir la regla `Passed via EasyRule` con `IPv4 *` (allow all) en OPT1 — es demasiado permisiva.
- [x] **[2026-04-29]** Confirmar que la regla "Bloquear todo lo demás" de WAN está correctamente posicionada como última.
- [x] **[2026-04-29]** Documentar la IP real del administrador (`192.168.163.140`) en el inventario/README del proyecto.

---

## Fase 2 y 3: Configuración Base y Despliegue Docker

> **¡Automatización Completada!** Gracias a las mejoras de la Fase 9, los pasos manuales de instalación de Cockpit, Docker, certificados SSL y primer despliegue se han unificado. Ahora solo debes ejecutar un comando en el servidor.

- [x] Descargar ISO de Debian 12 con entorno gráfico y crear VM en la red de la DMZ.
- [x] Instalar Debian seleccionando **entorno de escritorio GNOME**.
- [x] Configurar IP estática (`192.168.30.10`) en `/etc/network/interfaces`.
- [x] Actualizar repositorios y sistema (`apt update && apt upgrade`).
- [x] Clonar el repositorio temporalmente o subir `install.sh` al servidor.
- [x] **[2026-04-30]** Ejecutar el instalador automático: `sudo ./install.sh`.
- [x] Validar que Cockpit está accesible desde el Cliente en `https://192.168.30.10:9090`.
- [x] **[2026-04-30]** Validar que Odoo está accesible en `https://192.168.30.10`. ¡Inicialización de BD `odoo_erp` completada con éxito!
  - _Qué se hizo:_ Ajuste de volúmenes relativos en Compose, corrección de rutas SSL en Nginx, actualización de parámetros en `odoo.conf` e inicialización manual de la BD base.
  - _Archivos afectados:_ `docker/docker-compose.yml`, `docker/odoo.conf`, `config_nginx/odoo_proxy.conf`
  - _Resultado:_ Acceso funcional al ERP desde el cliente LAN mediante HTTPS.

---

## Fase 4: Activación de Scripts DevOps (Cron y Backups)

> **¡Automatización Completada!** `install.sh` ya da permisos a los scripts e instala las tareas de Cron. Solo queda realizar validaciones manuales.

- [x] `scripts/deploy.sh` — Despliega el stack con verificación de salud activa.
- [x] `scripts/update.sh` — Actualización de imágenes y limpieza.
- [x] `scripts/backup.sh` — Volcado comprimido con política de retención de 7 días.
- [x] `scripts/restore.sh` — Restauración limpia de base de datos.
- [x] `scripts/monitor.sh` — Chequeo de salud con auto-reinicio.
- [x] **[Automatizado]** Permisos de ejecución aplicados por `install.sh`.
- [x] **[Automatizado]** Instalación de tareas cron automáticas por `install.sh`.
- [ ] Validar crontab: ejecutar `crontab -l` en el servidor para comprobar tareas (monitor, backup, update).
- [ ] Testear ciclo completo manual usando el orquestador: `./erp.sh backup` → `./erp.sh logs` → probar caída del servicio.

---

## Fase 5: Auditoría Avanzada de BD (PostgreSQL)

- [x] **[2026-04-29]** `sql/audit_triggers.sql` creado con tabla `asir_audit_log`, función `func_audit_users()` y trigger `trg_audit_new_odoo_user`.
- [x] **[2026-04-29]** Campo **JSONB** (`row_data`) añadido: almacena el estado completo del registro con `row_to_json(NEW)::JSONB`.
- [x] **[2026-04-29]** Vista `v_audit_resumen` creada para consultas rápidas en la defensa (extrae `login` y `name` del JSONB).
- [x] **[2026-04-30]** Script ejecutado en producción: `docker exec -i odoo_erp psql -U odoo -d odoo_erp < sql/audit_triggers.sql`
  - _Qué se hizo:_ Se corrigió el nombre del contenedor (`odoo_erp`, no `odoo-db`) y se ejecutó el script en el contenedor PostgreSQL activo.
  - _Resultado:_ Tabla `asir_audit_log` creada y verificada con `\dt`. Trigger activo sobre `res_users`.
- [x] **[2026-04-30]** Validación end-to-end completada: usuario `user@tfg.prueba` creado desde la UI de Odoo.
  - _Resultado:_ `SELECT * FROM v_audit_resumen` devuelve `audit_id=1, CREACION_USUARIO, res_users, id_registro=8, 2026-04-30 12:13:57 UTC`. Trigger y función PL/pgSQL operativos al 100%.

---

## Fase 6: Seguridad de Capa de Red en Servidor (UFW)

- [x] **[2026-04-30]** Instalar `ufw`: `apt install ufw -y`.
- [x] **[2026-04-30]** Configurar política por defecto: `deny incoming`, `allow outgoing`.
- [x] **[2026-04-30]** Reglas aplicadas: SSH (22/tcp), Cockpit (9090/tcp), HTTP (80/tcp), HTTPS (443/tcp) — IPv4 e IPv6.
- [x] **[2026-04-30]** UFW habilitado: `ufw enable` — activo y persistente en arranque del sistema.
- [x] **[2026-04-30]** Estado verificado con `ufw status verbose`:
  - _Resultado:_ `Status: active`, logging `on (low)`, default `deny (incoming) / allow (outgoing) / deny (routed)`.
  - _Reglas activas:_ 22, 9090, 80, 443 en IPv4 e IPv6. Resto de tráfico entrante bloqueado.

---

## Fase 7: Integración Exterior y Pruebas Globales

- [ ] Validar Port Forwarding pfSense: desde fuera de la LAN, acceder a `https://[IP-WAN]` y que responda Nginx/Odoo.
- [ ] Desde el PC Cliente (LAN), añadir entrada en `/etc/hosts` o DNS interno para `erp.techsolutions.local` → `192.168.30.10`.
- [ ] Acceder al ERP vía `https://erp.techsolutions.local` desde el Cliente y validar carga completa.
- [ ] Verificar que los triggers de auditoría funcionan desde la capa web (crear usuario desde UI → comprobar log).
- [ ] Revisar logs de acceso de Nginx: `docker exec nginx cat /var/log/nginx/access.log`.
- [ ] (Opcional) Exportar logs de Nginx y adjuntarlos en la memoria del proyecto.
- [ ] Prueba de recuperación ante fallos: parar el contenedor `odoo` → verificar que `monitor.sh` lo reinicia automáticamente.

---

## Fase 8: Pipeline CI/CD Completo (GitHub Actions)

- [x] **[2026-04-29]** `.github/workflows/ci.yml` — Pipeline CI: lint de shell scripts con `shellcheck` y validación del `docker-compose.yml`.
- [x] **[2026-04-29]** `.github/workflows/deploy.yml` — Pipeline CD con self-hosted runner.
- [x] **[2026-04-29]** `scripts/setup_runner.sh` — Registra e instala el servidor Debian como runner de GitHub con systemd.
- [ ] En el servidor Debian: editar `scripts/setup_runner.sh` con la URL del repo y el token de GitHub.
- [ ] Obtener token en: GitHub → Repositorio → Settings → Actions → Runners → "New self-hosted runner".
- [ ] Ejecutar en el servidor: `chmod +x scripts/setup_runner.sh && sudo ./scripts/setup_runner.sh`.
- [ ] Verificar que el runner aparece como **"Idle"** en GitHub → Settings → Actions → Runners.
- [ ] Hacer un `git push` a `main` y comprobar que el workflow **"CD Deploy"** se activa en la pestaña Actions.
- [ ] Validar que los contenedores se levantan correctamente en el servidor tras el despliegue automático.

## Fase 9: Mejoras de Automatización Avanzada (Scripting y Docker)

- [x] **[2026-04-30]** Crear script `install.sh` (instalador todo-en-uno).
- [x] **[2026-04-30]** Crear plantilla `.env.example` y configurador.
- [x] **[2026-04-30]** Añadir `healthcheck` nativos en Docker.
- [x] **[2026-04-30]** Mejorar `monitor.sh` y añadir Logrotate.
- [x] **[2026-04-30]** Crear orquestador `erp.sh` y pre-checks.
- [x] **[2026-04-30]** Actualizar CI de GitHub Actions.

---

## Fase 10: Documentación Final y Defensa

- [ ] Revisar y completar `docs/implementation_plan.md` con todas las decisiones técnicas tomadas.
- [ ] Actualizar `CHANGELOG.md` con los cambios de cada sesión de trabajo.
- [ ] Redactar la **Memoria del TFG** con estructura formal: introducción, objetivos, arquitectura, implementación, pruebas y conclusiones.
- [ ] Preparar capturas de pantalla para la memoria: Cockpit, pfSense, Odoo funcionando, GitHub Actions.
- [ ] Preparar demostración en vivo para la defensa: ciclo completo deploy → backup → restore → auditoría.
- [ ] Revisar el `README.md` para que sirva como guía de despliegue rápida del proyecto.
- [ ] (Opcional) Exportar el proyecto como imagen OVA/OVF para entrega o repositorio.

---

## Resumen de Estado

| Fase | Descripción | Estado |
|:---:|:---|:---:|
| 0 | Investigación y diseño | ✅ Completada |
| 1 | Arquitectura pfSense y red | ✅ Completada |
| 2-4 | Despliegue Automatizado (Docker+DevOps) | ✅ Unificado en `install.sh` (Validación pdte) |
| 5 | Auditoría PostgreSQL | ✅ Completada |
| 6 | UFW Firewall local | ✅ Completada |
| 7 | Pruebas globales | ⏳ Pendiente |
| 8 | CI/CD GitHub Actions | 🔄 Workflows listos, runner pendiente |
| 9 | Mejoras Automatización | ✅ Completada |
| 10 | Documentación y defensa | ⏳ Pendiente |
