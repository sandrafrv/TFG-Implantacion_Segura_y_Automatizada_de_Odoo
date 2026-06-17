# Anexo F — Guía de Reproducción de Capturas del Sistema

**ASIR 2025/2026 — Implantación Segura y Automatizada de Odoo ERP**
*Sandra Fradejas Avedillo — IES Cañaveral*

> [!IMPORTANT]
> Este documento es la guía operativa para reproducir **todas las capturas del Anexo F**
> desde un entorno limpio (sin VMs previas). Sigue los pasos en el orden indicado.
> Tiempo estimado total: **2–3 horas** (incluyendo aprovisionamiento automático).

---

## Índice

| Figura | Sección | Descripción |
|:---:|:---|:---|
| F.1 | [§ F.1](#f1--advertencia-de-certificado-autofirmado) | Advertencia de certificado autofirmado |
| F.2 | [§ F.2](#f2--pantalla-de-login-de-odoo) | Pantalla de login de Odoo |
| F.3 | [§ F.3](#f3--dashboard-de-odoo-tras-autenticación) | Dashboard de Odoo tras autenticación |
| F.4 | [§ F.4](#f4--panel-principal-de-pfsense) | Panel principal de pfSense |
| F.5 | [§ F.5](#f5--reglas-de-firewall-interfaz-dmz) | Reglas firewall interfaz DMZ |
| F.6 | [§ F.6](#f6--reglas-de-firewall-interfaz-admin) | Reglas firewall interfaz ADMIN |
| F.7 | [§ F.7](#f7--configuración-dns-resolver) | Configuración DNS Resolver |
| F.8 | [§ F.8](#f8--vista-general-del-pipeline-cicd) | Vista general del pipeline CI/CD |
| F.9 | [§ F.9](#f9--detalle-del-workflow-ci) | Detalle del workflow CI |
| F.10 | [§ F.10](#f10--detalle-del-workflow-cd) | Detalle del workflow CD |
| F.11 | [§ F.11](#f11--aprovisionamiento-con-vagrant-up) | Aprovisionamiento con vagrant up |
| F.12 | [§ F.12](#f12--estado-de-los-contenedores-docker) | Estado de los contenedores Docker |
| F.13 | [§ F.13](#f13--conectividad-odoo--postgresql) | Conectividad Odoo → PostgreSQL |
| F.14 | [§ F.14](#f14--proxy-nginx--odoo-puerto-interno) | Proxy Nginx → Odoo (puerto interno) |
| F.15 | [§ F.15](#f15--acceso-https-desde-el-host) | Acceso HTTPS desde el host |
| F.16 | [§ F.16](#f16--generación-del-backup) | Generación del backup |
| F.17 | [§ F.17](#f17--verificación-del-contenido-del-backup) | Verificación del contenido del backup |
| F.18 | [§ F.18](#f18--destrucción-del-entorno) | Destrucción del entorno |
| F.19 | [§ F.19](#f19--reaprovisionamiento-desde-cero) | Reaprovisionamiento desde cero |
| F.20 | [§ F.20](#f20--contenedores-activos-tras-reprovisionamiento) | Contenedores activos tras reprovisionamiento |
| F.21 | [§ F.21](#f21--odoo-accesible-tras-reprovisionamiento) | Odoo accesible tras reprovisionamiento |

---

## Requisitos Previos (antes de empezar)

### Software necesario en el host Windows

```powershell
# 1. Vagrant + plugin VMware
winget install HashiCorp.Vagrant
vagrant plugin install vagrant-vmware-desktop

# 2. VMware Workstation (instalación manual desde vmware.com)
#  Versión mínima: VMware Workstation 17

# 3. Verificar instalación
vagrant --version    # → Vagrant 2.x.x
vmware-netcfg      # → debe abrir la utilidad de red de VMware
```

### Variables de entorno obligatorias

> [!CAUTION]
> Sin estas variables el aprovisionamiento falla. Configúralas en la misma sesión
> de PowerShell desde la que ejecutarás `vagrant up`.

```powershell
# Obtener los runner tokens desde:
# GitHub → Settings → Actions → Runners → New self-hosted runner
# (genera uno para odoo-server y otro para db-server; caducan en 1 hora)

$env:GH_PAT        = "ghp_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"  # scope: repo ← reemplaza con tu token real
$env:GH_RUNNER_TOKEN_ODOO = "BH2TGEUHFZ6YKIGZA6LVQS3KEK7TI"     # token para odoo-server
$env:GH_RUNNER_TOKEN_DB  = "BH2TGEVYZV5MB2JOJVXVD7TKEK7UI"     # token para db-server
$env:POSTGRES_PASSWORD  = "tu_password_seguro_bd"
$env:ODOO_MASTER_PASSWORD = "tu_password_maestro_odoo"
```

### Estado inicial requerido

- pfSense VM **ya configurada** con las 4 interfaces (WAN / LAN 192.168.10.1 / DMZ 192.168.30.1 / ADMIN 192.168.40.1)
 y el archivo `config.xml` importado desde `scripts/deploy/generate_pfsense_config.sh`
 (ver [`docs/INSTALACION_COMPLETA.md`](INSTALACION_COMPLETA.md) — FASE 1).
- Repositorio clonado en el host Windows.
- Redes VMware configuradas: `vmnet2` (DMZ 192.168.30.x) y `vmnet3` (ADMIN 192.168.40.x).

---

## BLOQUE 1 — Aprovisionamiento inicial del entorno

### Preparación: encender pfSense y obtener los runner tokens

```
1. Abrir VMware Workstation → iniciar la VM pfSense
2. Esperar ~60 segundos hasta que las interfaces estén activas
3. Ir a GitHub → Repositorio → Settings → Actions → Runners → New self-hosted runner
  Seleccionar: Linux / x64
  Copiar el token que aparece en la sección "Configure" (empieza por A...)
  Repetir para el segundo runner (uno por VM)
4. Pegar los tokens en las variables $env: de la sesión PowerShell
```

### Lanzar el aprovisionamiento

```powershell
# Navegar al directorio del repositorio
cd "C:\Users\sandra\Desktop\Ante proyecto\-ASIRB"

# Levantar primero db-server (SIEMPRE primero)
vagrant up db-server

# A continuación odoo-server
vagrant up odoo-server
```

> [!NOTE]
> El proceso completo tarda entre 15–30 minutos.
> Vagrant mostrará en tiempo real los logs de aprovisionamiento de ambas VMs.

---

## F.11 — Aprovisionamiento con vagrant up

**¿Qué muestra?** La salida del terminal al finalizar `vagrant up` confirmando que
los scripts de provisioning se ejecutaron sin errores en ambas VMs.

### Cómo obtener la captura

1. Ejecutar `vagrant up` tal como se describe en el bloque anterior.
2. Esperar a que el proceso complete (el prompt de PowerShell vuelve a aparecer).
3. Las últimas líneas de salida mostrarán algo similar a:

```
==> odoo-server: [provision_debian.sh] ✔ Odoo disponible en https://192.168.30.10
==> odoo-server: [provision_debian.sh] ✔ Runner registrado en GitHub Actions
==> odoo-server: Machine booted and ready!
```

4. **Capturar:** hacer scroll hasta ver las últimas 30–40 líneas de salida donde
  aparezca el resumen de ambas VMs (`db-server` y `odoo-server`) sin líneas de error.
5. Asegurarse de que la ventana de PowerShell muestra el directorio del proyecto
  (`-ASIRB`) en el prompt.

> **Nombre del fichero sugerido:** `F11_vagrant_up_finalizado.png`

---

## BLOQUE 2 — Verificación del estado de los contenedores

> [!IMPORTANT]
> `vagrant ssh` **no funciona** una vez deshabilitada la NAT.
> Conectarse siempre por la red ADMIN usando SSH directo:

### Acceder a odoo-server

```powershell
# Desde el host Windows (red ADMIN vmnet3 activa):
ssh vagrant@192.168.40.20
# Contraseña por defecto de Vagrant: vagrant
# (o usa la clave privada del proyecto: .vagrant\machines\odoo-server\vmware_desktop\private_key)
ssh -i .vagrant\machines\odoo-server\vmware_desktop\private_key vagrant@192.168.40.20
```

> [!NOTE]
> El usuario `vagrant` **no tiene permisos sobre el socket Docker** por defecto.
> Todos los comandos `docker` dentro de la VM deben ejecutarse como `root`:
>
> ```bash
> sudo su
> # Ahora el prompt cambia a root@odoo-server:/home/vagrant#
> cd /opt/erp-odoo
> ```

---

## F.12 — Estado de los contenedores Docker

**¿Qué muestra?** `docker compose ps` con `nginx-proxy` y `odoo-web` en estado `running`.

### Cómo obtener la captura

> [!IMPORTANT]
> El script `deploy.sh` levanta los contenedores con el project name `erp-odoo` y
> usando el fichero `.env` en `/opt/erp-odoo/.env`. Sin estos flags, `docker compose ps`
> devuelve una tabla **vacía** aunque los contenedores estén corriendo.
> Usar **siempre** el comando completo:

```bash
# Dentro de la sesión SSH en odoo-server (como root):
cd /opt/erp-odoo
docker compose -p erp-odoo --env-file .env -f docker/docker-compose.yml ps
```

**Salida esperada:**

```
NAME     IMAGE     COMMAND         SERVICE  CREATED     STATUS               PORTS
nginx-proxy  nginx:alpine  "/docker-entrypoint.…"  nginx   17 minutes ago  Up 17 minutes (healthy)      0.0.0.0:80->80/tcp, [::]:80->80/tcp, 0.0.0.0:443->443/tcp, [::]:443->443/tcp
odoo-web   odoo:17    "/entrypoint.sh odoo"  odoo   9 minutes ago  Up 19 seconds (health: starting)  8069/tcp, 8071-8072/tcp
```

Una vez que Odoo termine de iniciar (~2 min), el estado de `odoo-web` cambia a `(healthy)`.

4. **Capturar:** la terminal SSH mostrando el comando completo con `-p erp-odoo` y su
  salida con ambos contenedores en estado `Up` y `(healthy)`.

> [!TIP]
> Si el comando sin flags devuelve una tabla vacía pero `docker ps` sí muestra los
> contenedores, es síntoma de que el project name no coincide. Usar siempre `-p erp-odoo`.

> **Nombre del fichero sugerido:** `F12_docker_compose_ps.png`

---

## F.13 — Conectividad Odoo → PostgreSQL

**¿Qué muestra?** Prueba de conexión desde el contenedor `odoo-web` a PostgreSQL
en `db-server` (192.168.40.10:5432).

### Cómo obtener la captura

```bash
# Dentro de la sesión SSH en odoo-server (como root):

# Opción A — pg_isready (recomendada para la captura, más limpia)
docker exec odoo-web pg_isready -h 192.168.40.10 -p 5432 -U odoo

# Opción B — psql \conninfo (más detallada)
# IMPORTANTE: docker exec no tiene TTY para introducir la contraseña interactivamente.
# Leerla del .env y pasarla con PGPASSWORD:
PGPASS=$(grep -E '^POSTGRES_PASSWORD=' /opt/erp-odoo/.env | cut -d= -f2- | tr -d '"')
docker exec -e PGPASSWORD="$PGPASS" odoo-web \
  psql -h 192.168.40.10 -U odoo -d odoo_erp -c "\conninfo"
```

> [!NOTE]
> Es normal que aparezcan advertencias de locale de Perl al ejecutar comandos
> dentro del contenedor Odoo:
> ```
> perl: warning: Setting locale failed.
> perl: warning: Falling back to the standard locale ("C").
> ```
> Son completamente **inofensivas** — el contenedor no tiene `en_US.UTF-8` generado
> pero funciona correctamente. Lo relevante es la línea de resultado al final.

**Salida esperada (Opción A — pg_isready):**

```
perl: warning: Setting locale failed.    ← ignorar, es normal
perl: warning: Please check that your locale settings...
perl: warning: Falling back to the standard locale ("C").
192.168.40.10:5432 accepting connections  ✅
```

**Salida esperada (Opción B — psql `\conninfo`):**

```
      Connection Information
   Parameter    |     Value
----------------------+------------------------
 Database       | odoo_erp
 Client User     | odoo
 Host         | 192.168.40.10
 Server Port     | 5432
 Protocol Version   | 3.0
 Password Used    | true
 GSSAPI Authenticated | false
 Backend PID     | 27109
 SSL Connection    | true
 SSL Library     | OpenSSL
 SSL Protocol     | TLSv1.3
 SSL Key Bits     | 256
 SSL Cipher      | TLS_AES_256_GCM_SHA384
 SSL Compression   | false
 Superuser      | off
(18 rows)
```

> [!CAUTION]
> Si se usa `docker exec odoo-web psql ...` **sin** `-e PGPASSWORD`, psql pedirá la
> contraseña interactivamente y fallará con `fe_sendauth: no password supplied`.
> Usar siempre el comando con `PGPASSWORD` de la Opción B.

4. **Capturar:** el terminal mostrando el comando y la salida completa.

> [!TIP]
> **Usar la Opción B para la captura del ** — la tabla `\conninfo` muestra
> `SSL Connection: true` y `SSL Protocol: TLSv1.3`, evidenciando que la comunicación
> Odoo → PostgreSQL está **cifrada en tránsito**, lo cual es especialmente relevante
> para un de seguridad. Mucho más informativo que un simple `accepting connections`.

> **Nombre del fichero sugerido:** `F13_conectividad_odoo_postgresql.png`

---

## F.14 — Proxy Nginx → Odoo (puerto interno)

**¿Qué muestra?** Que el contenedor `nginx-proxy` puede alcanzar `odoo-web` a través
de la red Docker interna `odoo_net`, demostrando que el proxy inverso funciona correctamente.

### Cómo obtener la captura

> [!IMPORTANT]
> El puerto 8069 de Odoo **NO está publicado al host VM** — solo existe dentro de la
> red Docker interna `odoo_net`. Ejecutar `curl http://localhost:8069` desde la VM
> siempre dará `Connection refused`. Los comandos correctos usan `docker exec`:

```bash
# Dentro de la sesión SSH en odoo-server (como root):

# Opción A — desde nginx-proxy hacia odoo-web (demuestra el routing interno Docker)
# Esta es la ruta REAL que usa Nginx cuando reenvía peticiones HTTPS al backend Odoo
docker exec nginx-proxy curl -s http://odoo-web:8069/web/health

# Opción B — desde dentro del propio contenedor odoo-web
docker exec odoo-web curl -s http://localhost:8069/web/health
```

**Salida esperada (ambas opciones):**

```json
{"status": "pass"}
```

> [!TIP]
> **Usar la Opción A para la captura del ** — ejecutar el curl desde `nginx-proxy`
> hacia `odoo-web:8069` demuestra visualmente que los dos contenedores se comunican
> por la red interna `odoo_net` usando el nombre de servicio Docker como hostname,
> que es exactamente el mecanismo que usa el proxy inverso.

4. **Capturar:** el terminal mostrando ambos comandos y la respuesta `{"status": "pass"}`.

> **Nombre del fichero sugerido:** `F14_nginx_proxy_odoo_interno.png`

---

## F.15 — Acceso HTTPS desde el host

**¿Qué muestra?** Respuesta HTTPS desde el host Windows a `https://192.168.30.10`
confirmando que Nginx responde con contenido HTML de la página de login de Odoo.

### Cómo obtener la captura

```powershell
# En el host Windows (PowerShell), sin cerrar la sesión SSH:
curl.exe -k -I https://192.168.30.10
```

**Salida esperada:**

```
HTTP/2 200
content-type: text/html; charset=utf-8
server: nginx/1.27.x
set-cookie: session_id=...
```

O para ver contenido HTML:

```powershell
curl.exe -k https://192.168.30.10/web/login | Select-String "Odoo"
```

4. **Capturar:** la ventana de PowerShell del host mostrando el comando y la respuesta
  con `HTTP/2 200` y las cabeceras indicando que es el login de Odoo.

> **Nombre del fichero sugerido:** `F15_acceso_https_host_windows.png`

---

## BLOQUE 3 — Capturas del navegador (Odoo)

> [!NOTE]
> Para estas capturas usar un navegador en el host Windows.
> La VM pfSense debe estar activa y la red VMware configurada.
> Si el host Windows está en la VLAN 10 (o conectado mediante vmnet2),
> navegar directamente a `https://192.168.30.10`.

---

## F.1 — Advertencia de certificado autofirmado

**¿Qué muestra?** La advertencia de seguridad del navegador al acceder a
`https://192.168.30.10` debido al certificado SSL autofirmado.

### Cómo obtener la captura

1. Abrir el navegador (Chrome, Firefox o Edge) en el host Windows.
2. Escribir en la barra de direcciones: `https://192.168.30.10`
3. El navegador mostrará automáticamente la advertencia de seguridad:
  **Chrome/Edge:** "Tu conexión no es privada" / `NET::ERR_CERT_AUTHORITY_INVALID`
  **Firefox:** "Advertencia: Riesgo potencial de seguridad a continuación"
4. **NO hacer clic** en "Continuar" todavía (capturar la advertencia completa).
5. Asegurarse de que la URL `https://192.168.30.10` sea visible en la barra de direcciones.

**Capturar:** la pantalla completa del navegador mostrando la advertencia,
con la URL visible en la barra de direcciones.

> **Nombre del fichero sugerido:** `F01_advertencia_certificado.png`

---

## F.2 — Pantalla de login de Odoo

**¿Qué muestra?** La página de autenticación de Odoo 17 CE con el candado SSL
activo en la barra de direcciones.

### Cómo obtener la captura

1. Desde la pantalla de advertencia (F.1), hacer clic en:
  **Chrome/Edge:** "Configuración avanzada" → "Continuar a 192.168.30.10 (sitio no seguro)"
  **Firefox:** "Aceptar el riesgo y continuar"
2. El navegador cargará la página de login de Odoo.
3. Verificar que la barra de direcciones muestra `https://192.168.30.10` con el
  icono de advertencia/candado (en Chrome aparece el candado con triángulo de advertencia).
4. La página debe mostrar el formulario de login con los campos **Email** y **Password**
  y el logo de Odoo.

**Capturar:** la pantalla completa del navegador con la página de login visible
y la URL `https://192.168.30.10` en la barra de direcciones.

> **Nombre del fichero sugerido:** `F02_login_odoo_https.png`

---

## F.3 — Dashboard de Odoo tras autenticación

**¿Qué muestra?** El dashboard principal de Odoo tras autenticación exitosa
con el usuario administrador.

### Cómo obtener la captura

1. En la pantalla de login (F.2), introducir las credenciales del administrador:
  **Email:** `admin` (o el email configurado durante el aprovisionamiento)
  **Password:** la contraseña del administrador de Odoo
2. Hacer clic en **"Log in"**.
3. Esperar a que cargue el dashboard (puede tardar unos segundos en el primer acceso).
4. El dashboard mostrará los módulos instalados y el menú de navegación superior.

**Capturar:** la pantalla completa del navegador con el dashboard de Odoo visible,
incluyendo el menú superior y los módulos disponibles, con la URL
`https://192.168.30.10/odoo` o similar en la barra de direcciones.

> **Nombre del fichero sugerido:** `F03_dashboard_odoo.png`

---

## BLOQUE 4 — Capturas del panel de pfSense

> [!IMPORTANT]
> El panel de pfSense solo es accesible desde la VLAN 40 (192.168.40.x).
> Para estas capturas se puede usar:
> Un PC físico en la red VLAN 40.
> La VM `db-server` (está en 192.168.40.10 en VMnet3): `vagrant ssh db-server`
>  y luego usar un browser en esa VM (si tiene interfaz gráfica).
> **Más práctico:** desde el host Windows si VMware tiene `vmnet3` configurado
>  y el host tiene una IP en ese rango. Verificar con `ipconfig` si hay un
>  adaptador VMware con IP `192.168.40.x`.
>
> Acceder al panel desde: `https://192.168.40.1`
> Credenciales por defecto: `admin` / `pfsense` (cambiar en primer acceso)

---

## F.4 — Panel principal de pfSense

**¿Qué muestra?** La interfaz web de administración de pfSense con el estado
de las interfaces WAN, LAN, DMZ y ADMIN.

### Cómo obtener la captura

1. Abrir el navegador y navegar a `https://192.168.40.1` (desde la VLAN 40).
2. Aceptar la advertencia de certificado autofirmado (igual que en F.1).
3. Introducir credenciales de pfSense:
  **Username:** `admin`
  **Password:** `pfsense` (o la contraseña configurada)
4. El dashboard de pfSense se cargará mostrando:
  El widget **"Interfaces"** con el estado de WAN, LAN, OPT1 (DMZ) y OPT2 (ADMIN).
  Información del sistema (versión de pfSense, uptime, etc.).

**Capturar:** el dashboard de pfSense completo con el widget de interfaces visible
mostrando las 4 interfaces activas.

> [!TIP]
> Si el widget de interfaces no está visible en el dashboard por defecto,
> ir a `System → Dashboard` y añadir el widget "Interfaces".

> **Nombre del fichero sugerido:** `F04_pfsense_panel_principal.png`

---

## F.5 — Reglas de firewall interfaz DMZ

**¿Qué muestra?** Las reglas de filtrado aplicadas al segmento DMZ (OPT1 / VMnet2).

### Cómo obtener la captura

1. En el panel de pfSense, ir a: **Firewall → Rules → OPT1**
2. La lista de reglas debe mostrar (en orden):
  Block: DMZ → VLAN 10 (anti-pivoting)
  Block: DMZ → pfSense LAN (anti-pivoting)
  Pass: TCP `192.168.30.10` → `192.168.40.10:5432` (Odoo → PostgreSQL)
  Block: DMZ → VLAN 40
  Pass: TCP DMZ → \*:80 (actualizaciones)
  Pass: TCP DMZ → \*:443 (actualizaciones)
  Pass: UDP DMZ → \*:53 (DNS)
  Block: todo lo demás (deny-all)

**Capturar:** la página completa de reglas de la interfaz OPT1 mostrando todas
las reglas con sus acciones (bloqueo/paso), protocolos, origen y destino.

> [!NOTE]
> Si la pantalla no cabe entera, hacer dos capturas solapadas o ampliar el zoom
> del navegador a 80% para que quepan todas las reglas.

> **Nombre del fichero sugerido:** `F05_pfsense_reglas_dmz.png`

---

## F.6 — Reglas de firewall interfaz ADMIN

**¿Qué muestra?** Las reglas de filtrado aplicadas al segmento ADMIN (OPT2 / VMnet3).

### Cómo obtener la captura

1. En el panel de pfSense, ir a: **Firewall → Rules → OPT2**
2. La lista de reglas debe mostrar (en orden):
  Pass: TCP VLAN40 → `This Firewall:443` (panel pfSense)
  Pass: TCP VLAN40 → `192.168.30.10:22` (SSH)
  Pass: TCP VLAN40 → `192.168.30.10:9090` (Cockpit)
  Pass: TCP VLAN40 → `192.168.30.10:443` (Odoo admin)
  Pass: TCP VLAN40 → `192.168.40.10:5432` (PostgreSQL directo)
  Pass: TCP VLAN40 → \*:80/443 (Internet)
  Pass: UDP VLAN40 → \*:53 (DNS)
  Block: VLAN40 → VLAN 10 (anti-pivoting)
  Block: todo lo demás (deny-all)

**Capturar:** la página completa de reglas de la interfaz OPT2.

> **Nombre del fichero sugerido:** `F06_pfsense_reglas_admin.png`

---

## F.7 — Configuración DNS Resolver

**¿Qué muestra?** El registro A en el DNS Resolver de pfSense que resuelve
`erp.odoo.com` a la IP `192.168.30.10`.

### Cómo obtener la captura

1. En el panel de pfSense, ir a: **Services → DNS Resolver → Host Overrides**
  (o en algunas versiones: **Services → DNS Resolver** → desplazarse hasta
  la sección "Host Overrides" al final de la página).
2. Debe aparecer una entrada con:
  **Host:** `erp.odoo`
  **Domain:** `odoo.com`
  **IP Address:** `192.168.30.10`
  **Description:** texto descriptivo del proyecto

**Capturar:** la sección "Host Overrides" del DNS Resolver mostrando la entrada
configurada para `erp.odoo.com`.

> **Nombre del fichero sugerido:** `F07_pfsense_dns_resolver.png`

---

## BLOQUE 5 — Capturas de GitHub Actions (CI/CD)

> [!NOTE]
> Para generar las capturas F.8, F.9 y F.10, es necesario hacer un push
> a la rama `main` del repositorio con los runners activos (ambas VMs
> aprovisionadas y corriendo). Si el pipeline ya se ejecutó durante el
> aprovisionamiento, los logs estarán disponibles en GitHub sin hacer un nuevo push.

---

## F.8 — Vista general del pipeline CI/CD

**¿Qué muestra?** El dashboard de GitHub Actions con los workflows CI y CD
finalizados con éxito.

### Cómo obtener la captura

**Opción A — Usar un run ya existente:**

1. Ir a `https://github.com/sandrafrv/Implantacion_Segura_y_Automatizada_de_Odoo/actions`
2. Localizar el último run exitoso que muestre los dos workflows:
  `CI Validator` (con check verde ✅)
  `CD Deploy` (con check verde ✅)
3. La vista general mostrará ambos workflows encadenados.

**Opción B — Disparar un nuevo run:**

```powershell
# En el host Windows, desde el directorio del repo:
git add .
git commit --allow-empty -m "test: trigger CI/CD para captura Anexo F"
git push origin main
```

Luego esperar a que ambos workflows completen (2–5 minutos) y recargar la página de Actions.

**Capturar:** la página de Actions de GitHub mostrando los dos workflows con
sus badges verdes de éxito, incluyendo el nombre del commit que los disparó.

> **Nombre del fichero sugerido:** `F08_github_actions_general.png`

---

## F.9 — Detalle del workflow CI con todos los pasos

**¿Qué muestra?** El log del workflow `CI Validator` con los cuatro pasos
de validación completados sin errores.

### Cómo obtener la captura

1. En la página de Actions de GitHub, hacer clic en el run del workflow `CI Validator`.
2. Dentro del run, hacer clic en el job que contiene los steps.
3. Expandir todos los pasos para ver:
  ✅ `yamllint` — validación de sintaxis YAML
  ✅ `docker compose config -q` — validación de docker-compose.yml
  ✅ Instalación de ShellCheck
  ✅ Validación de scripts Bash con ShellCheck
4. Verificar que ningún paso muestra errores (todos en verde).

**Capturar:** la vista del job con los cuatro pasos expandidos mostrando
sus outputs y sus marcas de éxito verdes.

> [!TIP]
> Si la pantalla es muy larga, hacer capturas de los pasos individuales
> o usar la función de zoom del navegador al 75% para verlos todos.

> **Nombre del fichero sugerido:** `F09_workflow_ci_detalle.png`

---

## F.10 — Detalle del workflow CD

**¿Qué muestra?** El log del workflow `CD Deploy` ejecutado en el runner
self-hosted de `odoo-server`.

### Cómo obtener la captura

1. En la página de Actions, hacer clic en el run del workflow `CD Deploy`.
2. Dentro del run, hacer clic en el job que se ejecuta en el runner `odoo-runner`.
3. Verificar que aparecen los pasos:
  ✅ `git config --global --add safe.directory` (directorio seguro)
  ✅ `git reset --hard` (sincronización limpia del repo)
  ✅ `docker pull` (actualización de imágenes)
  ✅ Ejecución de `deploy.sh`
  ✅ `docker compose ps` (verificación de contenedores)
4. En la esquina superior del job debe indicar: **Runs on: odoo-runner** (self-hosted).

**Capturar:** el job de CD con los steps expandidos y el label `self-hosted` visible.

> [!NOTE]
> Desde la corrección aplicada hoy, el `deploy.sh` usa `/entrypoint.sh odoo`
> como wrapper para la inicialización de BD, por lo que el step `deploy.sh`
> del pipeline CD incluirá la inicialización automática si la BD está vacía.

> **Nombre del fichero sugerido:** `F10_workflow_cd_detalle.png`

---

## BLOQUE 6 — Verificaciones en la VM odoo-server

> Las capturas F.13 a F.17 se obtienen dentro de la sesión SSH en `odoo-server`.
> Conectarse si no se está ya conectado (SSH directo por la red ADMIN, sin NAT):
>
> ```powershell
> ssh -i .vagrant\machines\odoo-server\vmware_desktop\private_key vagrant@192.168.40.20
> ```
>
> Una vez dentro, elevar a root para tener permisos Docker:
>
> ```bash
> sudo su
> cd /opt/erp-odoo
> ```

---

## F.16 — Generación del backup

**¿Qué muestra?** La ejecución manual de `backup_odoo.sh` y el listado del
directorio `/var/backups/odoo/` con el fichero `.sql.gz` generado.

### Cómo obtener la captura

```bash
# Dentro de la sesión SSH en odoo-server:

# 1. Cargar las variables de entorno del backup
source /etc/backup_odoo.env 2>/dev/null || export POSTGRES_PASSWORD="tu_password_seguro_bd"

# 2. Ejecutar el script de backup manualmente
sudo bash /opt/erp-odoo/scripts/mantenimiento/backup_postgres.sh

# 3. Listar el directorio de backups para confirmar la creación del fichero
ls -lh /backups/postgres/
```

**Salida esperada:**

```
[2026-06-05 13:XX:XX] Iniciando backup de odoo_erp en 192.168.40.10...
[2026-06-05 13:XX:XX] OK: Backup -> odoo_20260605_13XX.sql.gz (2.1M)
[2026-06-05 13:XX:XX] Limpieza de copias >7 dias completada.

-rw-r--r-- 1 root root 2.1M Jun 5 13:XX odoo_20260605_13XX.sql.gz
```

**Capturar:** el terminal mostrando tanto la salida del script de backup
como el listado del directorio con el fichero generado y su tamaño.

> **Nombre del fichero sugerido:** `F16_backup_generado.png`

---

## F.17 — Verificación del contenido del backup

**¿Qué muestra?** La cabecera del fichero de backup descomprimido con `zcat`
mostrando que es un volcado válido de PostgreSQL.

### Cómo obtener la captura

```bash
# Dentro de la sesión SSH en odoo-server:
# (Sustituir el nombre del fichero por el generado en F.16)
zcat /backups/postgres/odoo_20260605_13XX.sql.gz | head -10
```

**Salida esperada:**

```
--
-- PostgreSQL database dump
--

-- Dumped from database version 16.x
-- Dumped by pg_dump version 16.x

SET statement_timeout = 0;
SET lock_timeout = 0;
```

**Capturar:** el terminal mostrando el comando `zcat ... | head -10` y la
salida con el encabezado `-- PostgreSQL database dump`.

> **Nombre del fichero sugerido:** `F17_backup_contenido_verificado.png`

---

## BLOQUE 7 — Ciclo de destrucción y reaprovisionamiento (prueba de regresión)

> [!WARNING]
> Este bloque destruye completamente las VMs `odoo-server` y `db-server`.
> Asegúrate de tener ya todas las capturas de los bloques anteriores antes de continuar.
> **Las capturas F.1, F.2, F.3, F.4 – F.10 deben estar ya guardadas.**

### Obtener nuevos runner tokens ANTES de destruir

> [!CAUTION]
> Los runner tokens caducan en 1 hora. Obtenerlos justo antes de ejecutar `vagrant up`
> en el reaprovisionamiento para evitar que expiren.

```
GitHub → Repositorio → Settings → Actions → Runners → New self-hosted runner
Copiar ambos tokens y actualizar las variables $env: en PowerShell
```

---

## F.18 — Destrucción del entorno

**¿Qué muestra?** La salida de `vagrant destroy -f` con la eliminación completa
de las VMs y el desregistro de los runners de GitHub Actions.

### Cómo obtener la captura

```powershell
# En el host Windows:
cd "C:\Users\sandra\Desktop\Ante proyecto\-ASIRB"

# Destruir ambas VMs de forma forzada
vagrant destroy -f
```

**Salida esperada:**

```
==> odoo-server: [trigger] Desregistrar odoo-runner
==> odoo-server: [OK] odoo-runner eliminado de GitHub
==> odoo-server: Destroying VM and associated drives...
==> db-server: [trigger] Desregistrar db-runner
==> db-server: [OK] db-runner eliminado de GitHub
==> db-server: Destroying VM and associated drives...
```

**Capturar:** el terminal de PowerShell mostrando la salida completa del
`vagrant destroy -f`, incluyendo las líneas de desregistro de los runners
y la confirmación de destrucción de ambas VMs.

> **Nombre del fichero sugerido:** `F18_vagrant_destroy.png`

---

## F.19 — Reaprovisionamiento desde cero

**¿Qué muestra?** La salida final de `vagrant up` tras la destrucción, confirmando
que el entorno se reconstruye íntegramente desde cero.

### Cómo obtener la captura

```powershell
# Asegurarse de que los tokens están actualizados
$env:GH_RUNNER_TOKEN_ODOO = "ANEW_TOKEN_ODOO" # token nuevo de GitHub
$env:GH_RUNNER_TOKEN_DB  = "ANEW_TOKEN_DB"  # token nuevo de GitHub

# Re-aprovisionar en orden
vagrant up db-server
vagrant up odoo-server
```

**Capturar:** al final del proceso, hacer scroll para ver las últimas líneas
de la salida de `vagrant up` con los mensajes de finalización de `odoo-server`,
mostrando que todos los servicios quedaron operativos.

Buscar especialmente las líneas:

```
==> odoo-server: [provision_debian.sh] ✔ Contenedores activos
==> odoo-server: [provision_debian.sh] ✔ Odoo disponible en https://192.168.30.10
==> odoo-server: [provision_debian.sh] ✔ Runner registrado en GitHub Actions
```

> **Nombre del fichero sugerido:** `F19_vagrant_up_reprovisionamiento.png`

---

## F.20 — Contenedores activos tras reprovisionamiento

**¿Qué muestra?** `docker compose ps` tras el ciclo destroy + up, confirmando
que los contenedores vuelven a estar en estado `running`.

### Cómo obtener la captura

```powershell
# Conectar a odoo-server tras el reaprovisionamiento (SSH directo por red ADMIN)
ssh -i .vagrant\machines\odoo-server\vmware_desktop\private_key vagrant@192.168.40.20
```

```bash
# Dentro de la sesión SSH — elevar a root primero:
sudo su
cd /opt/erp-odoo

# Usar el project name correcto (igual que deploy.sh):
docker compose -p erp-odoo --env-file .env -f docker/docker-compose.yml ps
```

**Salida esperada** (idéntica a F.12):

```
NAME     IMAGE     COMMAND         SERVICE  CREATED    STATUS         PORTS
nginx-proxy  nginx:alpine  "/docker-entrypoint.…"  nginx   X min ago   Up X min (healthy)   0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp
odoo-web   odoo:17    "/entrypoint.sh odoo"  odoo   X min ago   Up X min (healthy)   8069/tcp, 8071-8072/tcp
```

**Capturar:** el terminal mostrando el comando completo con `-p erp-odoo` y los
contenedores en estado `Up (healthy)`.

> **Nombre del fichero sugerido:** `F20_docker_compose_ps_reprovisioned.png`

---

## F.21 — Odoo accesible tras reprovisionamiento

**¿Qué muestra?** El navegador mostrando Odoo accesible en `https://192.168.30.10`
tras el ciclo completo de destrucción y reaprovisionamiento.

### Cómo obtener la captura

1. En el host Windows, abrir el navegador.
2. Navegar a `https://192.168.30.10`.
3. Aceptar la advertencia de certificado autofirmado (igual que en F.1).
4. La página de login de Odoo debe cargarse correctamente.
5. Iniciar sesión con las credenciales de administrador.
6. El dashboard de Odoo debe mostrarse completamente funcional.

**Capturar:** el navegador mostrando el dashboard de Odoo (o la página de login
con la URL visible), demostrando que el sistema es accesible tras el ciclo completo.

> [!TIP]
> Esta captura es especialmente importante para demostrar la **idempotencia**
> del sistema de aprovisionamiento automatizado: destruir y recrear el entorno
> produce exactamente el mismo resultado funcional.

> **Nombre del fichero sugerido:** `F21_odoo_accesible_tras_reprovisionamiento.png`

---

## Checklist Final de Capturas

Marcar cada captura cuando esté obtenida y guardada:

```
BLOQUE 1 — Aprovisionamiento inicial
 [ ] F.11 — vagrant up finalizado (ambas VMs sin errores)

BLOQUE 2 — Estado del entorno
 [ ] F.12 — docker compose -p erp-odoo --env-file .env ps (contenedores healthy)
 [ ] F.13 — Conectividad Odoo → PostgreSQL (pg_isready / psql)
 [ ] F.14 — Proxy Nginx → Odoo (curl localhost:8069, respuesta 200/303)
 [ ] F.15 — Acceso HTTPS desde host Windows (curl -k -I https://192.168.30.10)

BLOQUE 3 — Navegador (Odoo)
 [ ] F.01 — Advertencia de certificado autofirmado
 [ ] F.02 — Pantalla de login de Odoo (https://192.168.30.10 con candado)
 [ ] F.03 — Dashboard de Odoo tras autenticación

BLOQUE 4 — Panel pfSense (desde VLAN 40)
 [ ] F.04 — Dashboard principal de pfSense
 [ ] F.05 — Reglas firewall interfaz DMZ (OPT1)
 [ ] F.06 — Reglas firewall interfaz ADMIN (OPT2)
 [ ] F.07 — DNS Resolver — Host Override erp.odoo.com → 192.168.30.10

BLOQUE 5 — GitHub Actions
 [ ] F.08 — Vista general pipeline CI/CD (ambos workflows en verde)
 [ ] F.09 — Detalle workflow CI (4 pasos: yamllint, docker config, ShellCheck)
 [ ] F.10 — Detalle workflow CD (self-hosted runner, deploy.sh, docker ps)

BLOQUE 6 — Backup (dentro de odoo-server vía SSH)
 [ ] F.16 — Ejecución de backup_postgres.sh + listado /backups/postgres/
 [ ] F.17 — zcat dump | head (cabecera -- PostgreSQL database dump)

BLOQUE 7 — Ciclo de regresión (destruir + reaprovisionar)
 [ ] F.18 — vagrant destroy -f (runners desregistrados + VMs destruidas)
 [ ] F.19 — vagrant up reprovisionamiento (salida final sin errores)
 [ ] F.20 — docker compose -p erp-odoo --env-file .env ps (healthy)
 [ ] F.21 — Odoo accesible en navegador tras reprovisión
```

---

## Orden recomendado para una sesión de captura eficiente

```
Sesión de ~3 horas:

 0:00 — Configurar $env: con tokens de GitHub + encender pfSense VM
 0:05 — Lanzar vagrant up db-server
 0:20 — Lanzar vagrant up odoo-server (mientras esperas: capturas F.04 a F.07 en pfSense)
 0:50 — ✅ Entorno listo → capturar F.11 (scroll en PowerShell)
 0:55 — vagrant ssh odoo-server → capturar F.12, F.13, F.14
 1:00 — Desde PowerShell host → capturar F.15
 1:05 — Navegar a https://192.168.30.10 → capturar F.01, F.02, F.03
 1:15 — GitHub Actions: lanzar push vacío si hace falta → esperar → F.08, F.09, F.10
 1:30 — vagrant ssh odoo-server → ejecutar backup → capturar F.16, F.17
 1:40 — ⚠️ Obtener NUEVOS runner tokens antes de destruir
 1:45 — vagrant destroy -f → capturar F.18
 2:00 — Actualizar $env: con nuevos tokens → vagrant up db-server + odoo-server
 2:30 — ✅ Reaprovisionamiento listo → capturar F.19, F.20, F.21
 2:40 — Fin ✅
```

---

## Consejos para las capturas

- **Resolución:** usar resolución de 1920×1080 en el host para capturas nítidas.
- **Zoom del navegador:** 100% para las capturas de Odoo y pfSense (Ctrl+0 para resetear).
- **Terminal:** usar una fuente monoespaciada de tamaño 14px mínimo para legibilidad.
- **Tiempo:** incluir la fecha/hora en el terminal (`echo $(date)` antes de cada comando)
 para demostrar que las capturas se hicieron en la misma sesión.
- **Barra de URL:** siempre visible en capturas del navegador.
- **Nombre de VM:** si el prompt de la terminal SSH muestra `vagrant@odoo-server:~$`,
 dejarlo visible — identifica claramente en qué máquina se ejecuta el comando.

---

*ASIR 2025/2026 — IES Cañaveral*
*Guía de reproducción para el Anexo F — Capturas del sistema en funcionamiento*
