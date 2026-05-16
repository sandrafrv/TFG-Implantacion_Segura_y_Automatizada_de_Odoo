# Guía de Prompts de Respaldo — Actualización de Documentación

> [!WARNING]
> **OBSOLETO:** Este archivo contiene prompts históricos utilizados durante el desarrollo. Ya no es necesario ejecutarlos.

> **Propósito:** Si en algún momento la actualización de documentación falla o se interrumpe,
> usa estos prompts para pedirle al asistente que retome el trabajo desde cualquier punto.
> Están diseñados para ser autosuficientes: cada uno lleva el contexto necesario.

---

## Contexto base (pegar siempre si hay dudas de contexto)

```text
Repositorio: sandrafrv/TFG-Implantacion_Segura_y_Automatizada_de_Odoo
Proyecto: TFG ASIR — Implantación Segura y Automatizada de Odoo 17
Arquitectura ACTUAL (Mayo 2026):
  - 3 VMs orquestadas con Vagrant
  - VM1: pfSense — Firewall/Router — VLAN 10 (192.168.10.0/24), VLAN 30 (192.168.30.0/24), VLAN 40 (192.168.40.0/24)
  - VM2: Debian 13 — Docker con solo 2 contenedores: nginx-proxy (MACVLAN .30.20) y odoo-web (MACVLAN .30.21)
  - VM3: PostgreSQL 16 nativo (sin Docker) — 192.168.40.10, VLAN 40
  - LDAP: RETIRADO del despliegue principal, movido a extras/ldap/ como mejora futura
  - Backups: pg_dump remoto cada 4h, credenciales en /etc/backup_odoo.env (chmod 600)
  - .env: siempre en la RAÍZ del repositorio, sin variables LDAP
  - CI/CD: shellcheck incluye vagrant/, deploy verifica solo odoo-web y nginx-proxy
```

---

## PROMPT 1 — Bloque raíz (3 archivos)

```text
Actualiza los siguientes 3 archivos de la raíz del repositorio
sandrafrv/TFG-Implantacion_Segura_y_Automatizada_de_Odoo:

1. CLAUDE.md — Guía técnica para el asistente IA y colaboradores.
   Debe incluir: comandos Vagrant para las 3 VMs, advertencia de que los servicios
   'db' y 'ldap' ya NO existen en Docker, BD siempre en 192.168.40.10,
   referencia a /etc/backup_odoo.env, convenciones del proyecto actualizadas,
   troubleshooting con los errores más comunes del nuevo esquema.

2. REALIZADO_PDF_PASOS.md — Checklist de progreso del TFG.
   Marca como [x] completados: Vagrantfile, provision_debian.sh, provision_pfsense.sh,
   provision_postgres.sh, eliminación db/ldap del compose, db_host=192.168.40.10,
   deploy.sh con check BD, configure.sh con .env en raíz, erp.sh sin logs pg local,
   install_cron.sh con /etc/backup_odoo.env, backup_postgres.sh (nuevo),
   restore.sh con BD externa, monitor.sh sin odoo_erp/openldap, .env.example sin LDAP,
   extras/ldap/README.md, extras/ldap/estructura.ldif, ci.yml con vagrant/, deploy.yml sin pg/ldap.
   Sección 'En progreso': pruebas e2e, capturas para memoria.
   Sección 'Pendiente': LDAP futuro, HA PostgreSQL, Prometheus+Grafana.

3. README.md — Ya está actualizado, NO modificar.

Documentación muy detallada, técnica y coherente con la arquitectura actual.
```

---

## PROMPT 2 — docs/ parte A (5 archivos críticos)

```text
Actualiza los siguientes archivos de la carpeta docs/ del repositorio
sandrafrv/TFG-Implantacion_Segura_y_Automatizada_de_Odoo.
Arquitectura actual: 3 VMs Vagrant, PostgreSQL en 192.168.40.10 (VM3 nativa),
LDAP retirado del despliegue, solo 2 contenedores Docker (nginx-proxy + odoo-web).

1. docs/diagrama_red.md — CRÍTICO. Reescribir completamente.
   El diagrama actual muestra PostgreSQL y LDAP como contenedores Docker en la DMZ.
   El nuevo debe mostrar:
   - 3 VMs separadas con sus VLANs
   - VM3 PostgreSQL en VLAN 40 (192.168.40.10), completamente fuera de Docker
   - Solo nginx-proxy (.30.20) y odoo-web (.30.21) como contenedores MACVLAN en VLAN 30
   - Sin contenedor openldap ni odoo_erp en Docker
   - Flecha de Odoo a PostgreSQL cruzando inter-VLAN 30→40
   - Tabla de IPs actualizada (sin openldap .30.22 ni odoo_erp docker)
   - Flujo de autenticación sin LDAP (login nativo Odoo)
   - Nota de LDAP como mejora futura en extras/ldap/

2. docs/CONTROL_ACCESO.md — CRÍTICO. Actualización profunda.
   - Sección de arquitectura: quitar .22 openldap, quitar VM3 como contenedor, añadir VM3 PostgreSQL en VLAN 40
   - Tabla de acceso por VLAN: quitar 'Login SO vía LDAP' de VLAN 10
   - Toda la sección 'Inicio de Sesión en el SO (SSSD+PAM+NSS)' → mover a bloque colapsado
     o marcar claramente como 'NO ACTIVO EN ESTA VERSIÓN — ver extras/ldap/'
   - Sección LDAP completa → mover a bloque con aviso visible: LDAP retirado del despliegue,
     contenido disponible en extras/ldap/, flujos actuales usan autenticación nativa de Odoo
   - Flujo de autenticación actualizado: sin openldap, login directo en Odoo
   - Orden de ejecución: quitar pasos de docker compose up ldap, ldap_politica_acceso.sh, ldap_crear_usuarios.sh
   - Reglas pfSense VLAN 40: quitar regla LDAP :389/:636, añadir regla PostgreSQL :5432
   - Mantener todas las capas A/B/C de Nginx y roles de Odoo (esas siguen igual)

3. docs/reglas_pfsense.md — Actualizar reglas.
   - Añadir regla: VLAN30 (Odoo) → 192.168.40.10 :5432 PASS (nueva, crítica)
   - Añadir regla: VLAN40 (Admin) → 192.168.40.10 :5432 PASS (acceso DBA directo)
   - Añadir regla: VLAN40 (Admin) → 192.168.40.10 SSH :22 PASS (gestión VM3)
   - Eliminar reglas: VLAN10→192.168.30.22 :389, VLAN40→192.168.30.22 :389/:636 (LDAP ya no existe)
   - Tabla de IPs: quitar openldap .30.22, añadir VM3 PostgreSQL .40.10
   - Añadir sección de reglas inter-VLAN 30→40 bien explicada

4. docs/HISTORIAL_IMPLEMENTACION.md — Añadir Fase 6.
   Añadir al final una nueva fase completa:
   Fase 6 — Infraestructura como Código y PostgreSQL Externo (Mayo 2026)
   Contenido: motivación del cambio, decisión de separar PostgreSQL a VM dedicada,
   decisión de retirar LDAP, implementación de Vagrantfile con 3 VMs,
   scripts de aprovisionamiento, migración de datos, nuevos scripts de backup,
   cambios en CI/CD, resultado final y lecciones aprendidas.

5. docs/README.md — Actualizar índice.
   Revisar que todos los archivos listados existan realmente y que las descripciones
   sean coherentes con el estado actual. Añadir referencias a vagrant/README.md,
   sql/README.md, scripts/ldap/README.md, ldap/README.md, extras/ldap/README.md.
```

---

## PROMPT 3 — docs/ parte B (4 archivos)

```text
Actualiza los siguientes archivos del repositorio
sandrafrv/TFG-Implantacion_Segura_y_Automatizada_de_Odoo.
Arquitectura actual: 3 VMs Vagrant, PostgreSQL en 192.168.40.10, LDAP fuera del despliegue.

1. docs/INSTALACION_COMPLETA.md — Actualizar flujo principal.
   El flujo de instalación ya no es 'clonar + docker compose up'.
   El nuevo flujo principal es: prerequisites (VirtualBox + Vagrant) → clonar repo →
   configurar .env en raíz → vagrant up → verificar 3 VMs → acceder a Odoo.
   Mantener la instalación manual como alternativa secundaria para quien no use Vagrant.
   Quitar cualquier referencia a 'docker compose up db' o 'docker compose up ldap'.
   Añadir sección de verificación post-instalación con comandos para las 3 VMs.

2. docs/memoria_tfg_borrador.md — Actualizar sección de arquitectura.
   Buscar todas las referencias a PostgreSQL como contenedor Docker → cambiar a VM3 nativa.
   Buscar todas las referencias a LDAP como componente activo → cambiar a 'no implementado
   en esta versión, disponible como mejora futura en extras/ldap/'.
   Añadir párrafo sobre la decisión de usar Vagrant para IaC.
   Añadir párrafo sobre la decisión de separar PostgreSQL a VM dedicada y sus ventajas
   de seguridad (aislamiento VLAN 40, superficie de ataque reducida).

3. docs/memoria_tfg_nuevo.md — Actualizar y ampliar.
   Mismos cambios que en borrador, más:
   Añadir subsección 'Decisiones de diseño y justificación técnica' con:
   - Por qué se retiró LDAP: complejidad de integración, reducción de superficie de ataque,
     tiempo disponible, disponible como mejora futura
   - Por qué PostgreSQL en VM separada: aislamiento de red (VLAN 40), independencia
     del ciclo de vida de los contenedores, acceso DBA directo sin pasar por Docker,
     backups remotos más limpios con pg_dump
   - Por qué Vagrant: reproducibilidad, IaC, fácil reset del entorno de pruebas

4. docs/mas_info/informe_erp.md — Actualizar sección técnica.
   Buscar y actualizar: diagrama o descripción de arquitectura que mencione PostgreSQL
   en Docker o LDAP como componente activo. Adaptar a la arquitectura actual de 3 VMs.
   No modificar las secciones teóricas o de investigación que no dependan de la arquitectura.
```

---

## PROMPT 4 — docs/guias/ (3 archivos)

```text
Actualiza las 3 guías de docs/guias/ del repositorio
sandrafrv/TFG-Implantacion_Segura_y_Automatizada_de_Odoo.

1. docs/guias/INSTALACION_RED.md — CRÍTICO. Reescribir topología.
   La guía actual describe pfSense con 2 interfaces (WAN + LAN).
   La nueva debe describir pfSense con 4 interfaces:
   - WAN: acceso a Internet
   - VLAN 10 (OPT1 / LAN): 192.168.10.0/24 — empleados
   - VLAN 30 (OPT2 / DMZ): 192.168.30.0/24 — Odoo + Nginx
   - VLAN 40 (OPT3 / ADMIN+DB): 192.168.40.0/24 — administración + PostgreSQL
   Incluir: asignación de interfaces en pfSense, configuración DHCP por VLAN,
   DNS Resolver con Host Override para erp.odoo.tfg.com → 192.168.30.20,
   reglas inter-VLAN (especialmente VLAN30→VLAN40 :5432 para PostgreSQL),
   reglas NAT Port Forward (WAN:443 → 192.168.30.20:443),
   VPN OpenVPN básica para teletrabajadores.

2. docs/guias/INSTALACION_SERVIDOR.md — Actualizar con Vagrant.
   Añadir sección principal al inicio: 'Instalación automatizada con Vagrant (recomendada)'.
   Pasos: instalar VirtualBox + Vagrant → clonar repo → vagrant up.
   Mantener la instalación manual existente como 'Instalación manual paso a paso (alternativa)'.
   Actualizar cualquier referencia a 'levantar todos los contenedores' para excluir db y ldap.
   Añadir sección de acceso a cada VM: vagrant ssh pfsense/odoo-server/db-server.

3. docs/guias/INSTALACION_LDAP_CICD_HARDENING.md — Reorganizar.
   - Añadir aviso prominente al inicio de la sección LDAP:
     'LDAP NO está activo en el despliegue actual (v1.7+). Ver extras/ldap/README.md
     para retomar la integración en versiones futuras. Los scripts de esta guía se
     conservan como referencia en scripts/ldap/'.
   - Mantener la sección de CI/CD actualizada: shellcheck incluye vagrant/,
     deploy.yml verifica solo odoo-web y nginx-proxy.
   - Mantener la sección de Hardening (SSH, UFW, fail2ban, etc.) sin cambios.
   - Actualizar cualquier referencia al runner/deploy que mencione contenedores de
     PostgreSQL o LDAP.
```

---

## PROMPT 5 — scripts/, vagrant/, extras/, ldap/, sql/ (7 archivos nuevos o actualizados)

```text
Realiza los siguientes cambios en el repositorio
sandrafrv/TFG-Implantacion_Segura_y_Automatizada_de_Odoo:

1. ACTUALIZAR scripts/README.md
   - Añadir scripts/mantenimiento/backup_postgres.sh a la tabla de scripts (es NUEVO en v1.7)
   - Marcar scripts/ldap/ con etiqueta ⚠️ DEPRECADO — no forma parte del despliegue activo
   - Añadir scripts/repomix_lite.py a la lista de utilidades
   - Actualizar cualquier referencia a contenedores de PostgreSQL o LDAP

2. CREAR scripts/ldap/README.md
   Contenido: aviso claro de que estos scripts (configurar_cliente_ldap.sh,
   ldap_crear_usuarios.sh, ldap_politica_acceso.sh) ya NO se usan en el despliegue
   actual v1.7+. Indicar que LDAP fue retirado por complejidad. Referenciar
   extras/ldap/README.md para retomarlo en el futuro. Incluir qué hacía cada script.

3. CREAR vagrant/README.md
   Documentar la carpeta vagrant/ completa:
   - Propósito: aprovisionar automáticamente las 3 VMs del proyecto
   - Orden de ejecución: vagrant up (levanta las 3 en orden)
   - provision_pfsense.sh: qué hace, cuándo ejecutarlo
   - provision_debian.sh: qué hace (Docker, Nginx, SSL, macvlan, deploy)
   - provision_postgres.sh: qué hace (PostgreSQL 16 nativo, pg_hba, listen_addresses)
   - Explicacion_provision_postgres.md: remitir a él para detalles de VM3
   - Troubleshooting: errores comunes al hacer vagrant up

4. ACTUALIZAR extras/ldap/README.md
   Revisar y mejorar el contenido existente:
   - Añadir referencia a scripts/ldap/ como scripts de apoyo
   - Añadir referencia a extras/ldap/estructura.ldif
   - Añadir sección 'Pasos para retomar la integración' con los puntos concretos:
     añadir servicio ldap al docker-compose.yml, restaurar variables en .env,
     ejecutar scripts/ldap/ en orden, habilitar autenticación LDAP en Odoo

5. CREAR ldap/README.md
   Aviso claro: esta carpeta contiene material LEGACY de LDAP.
   El archivo estructura.ldif es un backup de la estructura de usuarios.
   El contenido activo y documentación para uso futuro está en extras/ldap/.
   No ejecutar nada de esta carpeta directamente.

6. CREAR sql/README.md
   Documentar audit_triggers.sql:
   - Qué hace: crea tabla asir_audit_log, función audit_function() y trigger
     trg_audit_new_odoo_user que registra altas de usuarios en Odoo
   - Cuándo ejecutarlo: una sola vez, después de instalar y arrancar Odoo
   - Cómo ejecutarlo: psql -h 192.168.40.10 -U odoo -d odooerp -f sql/audit_triggers.sql
   - Cómo verificar: SELECT * FROM asir_audit_log; desde psql
   - Nota: apunta a la BD en 192.168.40.10 (VM3), no a localhost

7. ACTUALIZAR docs/README.md
   Revisar el índice y añadir referencias a:
   - vagrant/README.md
   - sql/README.md
   - scripts/ldap/README.md
   - ldap/README.md
   - extras/ldap/README.md
   Actualizar descripciones de archivos que hayan cambiado.
```

---

## PROMPT 6 — Verificación y auditoría final

```text
Haz una auditoría de consistencia de la documentación del repositorio
sandrafrv/TFG-Implantacion_Segura_y_Automatizada_de_Odoo.

Busca y corrige:
1. Cualquier archivo que mencione PostgreSQL como contenedor Docker (ya es VM3 nativa en 192.168.40.10)
2. Cualquier archivo que mencione LDAP/OpenLDAP como componente activo del despliegue
3. Cualquier referencia a docker-compose con servicio 'db' o 'ldap'
4. Cualquier referencia a 'docker/.env' — el .env está en la RAÍZ
5. Cualquier referencia a 4 contenedores activos — solo hay 2: odoo-web y nginx-proxy
6. Cualquier diagrama que muestre openldap en .30.22 o PostgreSQL en red Docker
7. Cualquier script de instalación que ejecute 'docker compose up' sin especificar servicios
8. Referencias a contenedor 'odoo_erp' como activo en monitor.sh o deploy.yml

Para cada incoherencia encontrada: indica el archivo, la línea/sección y la corrección.
Aplica las correcciones directamente en el repositorio.
```

---

## PROMPT 7 — Reconstrucción de un archivo específico

Si un archivo concreto quedó mal, usa este prompt sustituyendo `[ARCHIVO]`:

```text
Reescribe completamente el archivo [ARCHIVO] del repositorio
sandrafrv/TFG-Implantacion_Segura_y_Automatizada_de_Odoo.

Arquitectura actual (Mayo 2026):
- 3 VMs: pfSense (VM1), Debian+Docker (VM2, 192.168.30.10), PostgreSQL nativo (VM3, 192.168.40.10)
- VLANs: 10 (empleados), 30 (DMZ), 40 (admin+BD)
- Docker: solo nginx-proxy (192.168.30.20 MACVLAN) y odoo-web (192.168.30.21 MACVLAN)
- LDAP: retirado, en extras/ldap/ como mejora futura
- Backups: pg_dump remoto cada 4h, /etc/backup_odoo.env (chmod 600)
- .env: en raíz, sin variables LDAP

El archivo debe ser muy detallado, técnico, con ejemplos de comandos reales,
coherente con el resto de la documentación del repositorio.
```

---

## Lista de verificación — 22 archivos

Usa esta lista para marcar qué archivos ya están actualizados:

### Raíz
- [ ] `README.md` — ✅ Ya actualizado (no modificar)
- [ ] `CLAUDE.md` — pendiente
- [ ] `REALIZADO_PDF_PASOS.md` — pendiente

### docs/
- [ ] `docs/README.md` — pendiente
- [ ] `docs/CHANGELOG.md` — ✅ Ya actualizado (no modificar)
- [ ] `docs/diagrama_red.md` — pendiente ⚠️ CRÍTICO
- [ ] `docs/CONTROL_ACCESO.md` — pendiente ⚠️ CRÍTICO
- [ ] `docs/HISTORIAL_IMPLEMENTACION.md` — pendiente
- [ ] `docs/INSTALACION_COMPLETA.md` — pendiente
- [ ] `docs/reglas_pfsense.md` — pendiente ⚠️ CRÍTICO
- [ ] `docs/memoria_tfg_borrador.md` — pendiente
- [ ] `docs/memoria_tfg_nuevo.md` — pendiente

### docs/guias/
- [ ] `docs/guias/INSTALACION_RED.md` — pendiente ⚠️ CRÍTICO
- [ ] `docs/guias/INSTALACION_SERVIDOR.md` — pendiente
- [ ] `docs/guias/INSTALACION_LDAP_CICD_HARDENING.md` — pendiente

### docs/mas_info/
- [ ] `docs/mas_info/informe_erp.md` — pendiente

### scripts/
- [ ] `scripts/README.md` — pendiente
- [ ] `scripts/ldap/README.md` — CREAR NUEVO

### vagrant/
- [ ] `vagrant/README.md` — CREAR NUEVO

### extras/ldap/
- [ ] `extras/ldap/README.md` — pendiente

### ldap/
- [ ] `ldap/README.md` — CREAR NUEVO

### sql/
- [ ] `sql/README.md` — CREAR NUEVO

---

*Generado automáticamente el 15-05-2026 — TFG ASIR 2025/2026*
