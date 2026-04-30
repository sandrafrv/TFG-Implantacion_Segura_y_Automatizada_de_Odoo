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
- [x] **[2026-04-29]** Limpiar reglas EasyRule duplicadas en OPT1.
- [x] **[2026-04-29]** Eliminar o restringir la regla `Passed via EasyRule` con `IPv4 *` (allow all) en OPT1.
- [x] **[2026-04-29]** Confirmar que la regla "Bloquear todo lo demás" de WAN está correctamente posicionada como última.
- [x] **[2026-04-29]** Documentar la IP real del administrador (`192.168.163.140`) en el inventario/README del proyecto.

---

## Fase 2 y 3: Configuración Base y Despliegue Docker

- [x] Descargar ISO de Debian 12 con entorno gráfico y crear VM en la red de la DMZ.
- [x] Instalar Debian seleccionando **entorno de escritorio GNOME**.
- [x] Configurar IP estática (`192.168.30.10`) en `/etc/network/interfaces`.
- [x] Actualizar repositorios y sistema (`apt update && apt upgrade`).
- [x] Clonar el repositorio temporalmente o subir `install.sh` al servidor.
- [x] **[2026-04-30]** Ejecutar el instalador automático: `sudo ./install.sh`.
- [x] Validar que Cockpit está accesible desde el Cliente en `https://192.168.30.10:9090`.
- [x] **[2026-04-30]** Validar que Odoo está accesible en `https://192.168.30.10`. ¡Inicialización de BD `odoo_erp` completada con éxito!

---

## Fase 4: Activación de Scripts DevOps (Cron y Backups)

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
- [x] **[2026-04-29]** Campo **JSONB** (`row_data`) añadido.
- [x] **[2026-04-29]** Vista `v_audit_resumen` creada.
- [x] **[2026-04-30]** Script ejecutado en producción sobre contenedor `odoo_erp`.
- [x] **[2026-04-30]** Validación end-to-end: `audit_id=1, CREACION_USUARIO, user@tfg.prueba, 2026-04-30 12:13:57 UTC`.

---

## Fase 6: Seguridad de Capa de Red en Servidor (UFW)

- [x] **[2026-04-30]** Instalar `ufw`: `apt install ufw -y`.
- [x] **[2026-04-30]** Configurar política por defecto: `deny incoming`, `allow outgoing`.
- [x] **[2026-04-30]** Reglas aplicadas: SSH (22/tcp), Cockpit (9090/tcp), HTTP (80/tcp), HTTPS (443/tcp) — IPv4 e IPv6.
- [x] **[2026-04-30]** UFW habilitado y persistente en arranque del sistema.
- [x] **[2026-04-30]** Estado verificado: `Status: active`, default `deny incoming / allow outgoing / deny routed`.

---

## Fase 7: Integración Exterior y Pruebas Globales

- [x] **[2026-04-30]** DNS interno configurado en cliente Ubuntu LAN: `erp.techsolutions.local` → `192.168.30.10` en `/etc/hosts`.
- [x] **[2026-04-30]** Acceso al ERP vía `https://erp.techsolutions.local` validado desde el cliente.
- [x] **[2026-04-30]** Logs de acceso Nginx verificados: peticiones reales desde `192.168.10.101` con redirección HTTP→HTTPS (301) registradas.
- [x] **[2026-04-30]** Auditoría end-to-end validada desde la UI web: `user@tfg.prueba` registrado en `asir_audit_log`.
- [x] **[2026-04-30]** Prueba de auto-recuperación: `odoo-web` parado manualmente → vuelve a estado `healthy` automáticamente (Up 41s tras parada).
- [x] **[2026-04-30]** Backup manual ejecutado correctamente con nombre de contenedor corregido (`odoo_erp`): `backup_20260430_151554.dump` (1.38 MB).
  - _Corrección aplicada:_ `scripts/backup.sh`, `scripts/restore.sh` y `scripts/monitor.sh` tenían `odoo-db` en lugar de `odoo_erp`. Corregido en commit `b0022e4`.

---

## Fase 8: Pipeline CI/CD Completo (GitHub Actions)

- [x] **[2026-04-29]** `.github/workflows/ci.yml` — Pipeline CI con ShellCheck y validación Docker Compose.
- [x] **[2026-04-29]** `.github/workflows/deploy.yml` — Pipeline CD con self-hosted runner.
- [x] **[2026-04-29]** `scripts/setup_runner.sh` — Registra el servidor Debian como runner de GitHub.
- [x] **[2026-04-30]** Descarga manual del agente GitHub Actions v2.334.0 iniciada en `/opt/actions-runner`.
  - _Qué se hizo:_ `curl -o actions-runner-linux-x64-2.334.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.334.0/...` ejecutado en el servidor Debian como usuario `server`.
  - _Archivos afectados:_ `/opt/actions-runner/` (directorio en el servidor, fuera del repo)
  - _Resultado:_ Descarga completada. Pendiente: extracción (`tar xzf`) y configuración interactiva (`./config.sh`).
- [ ] Obtener token en: GitHub → Repositorio → Settings → Actions → Runners → "New self-hosted runner".
- [ ] Ejecutar `tar xzf ./actions-runner-linux-x64-2.334.0.tar.gz` y luego `./config.sh` con la URL del repo y el token.
- [ ] Verificar que el runner aparece como **"Idle"** en GitHub → Settings → Actions → Runners.
- [ ] Hacer un `git push` a `main` y comprobar que el workflow **"CD Deploy"** se activa.
- [ ] Validar que los contenedores se levantan correctamente tras el despliegue automático.

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
| 2-4 | Despliegue Automatizado (Docker+DevOps) | ✅ Completada |
| 5 | Auditoría PostgreSQL | ✅ Completada |
| 6 | UFW Firewall local | ✅ Completada |
| 7 | Pruebas globales | ✅ Completada |
| 8 | CI/CD GitHub Actions | 🔄 Runner en configuración (descarga completada) |
| 9 | Mejoras Automatización | ✅ Completada |
| 10 | Documentación y defensa | ⏳ Pendiente |
