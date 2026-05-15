# Repository Analysis: TFG-ASIRB

## Directory Structure
```text
./
    .env.example
    .gitignore
    .markdownlint.json
    CLAUDE.md
    install.sh
    LICENSE
    README.md
    REALIZADO_PDF_PASOS.md
    SECURITY
    .github/
        workflows/
            ci.yml
            deploy.yml
    config/
        logrotate.d/
            erp-odoo
    config_nginx/
        odoo_proxy.conf
    docker/
        .env
        docker-compose.yml
        odoo.conf
    docs/
        05
        CHANGELOG.md
        CONTROL_ACCESO.md
        diagrama_red.md
        github_actions_ips.txt
        HISTORIAL_IMPLEMENTACION.md
        INSTALACION_COMPLETA.md
        memoria_tfg_borrador.md
        memoria_tfg_nuevo.md
        README.md
        reglas_pfsense.md
        archive/
            GESTION_REPOSITORIO.md
            github_issues.md
            GUIA_AISLAMIENTO_ADMIN.md
            GUIA_DESPLIEGUE.md
            lista_capturas.md
            plan_fases_pendientes.md
            PLAN_HISTORICO_DETALLADO.md
            plan_iac_github.md
            propuestas_mejoras_extra.md
            task.md
        guias/
            INSTALACION_LDAP_CICD_HARDENING.md
            INSTALACION_RED.md
            INSTALACION_SERVIDOR.md
        mas_info/
            informe_erp.md
            investigacion.md
    ISOs/
        .gitkeep
    ldap/
        estructura.ldif
    screenshots/
    scripts/
        README.md
        repomix_lite.py
        deploy/
            configure.sh
            deploy.sh
            erp.sh
            generate_pfsense_config.sh
            install_cron.sh
        ldap/
            configurar_cliente_ldap.sh
            ldap_crear_usuarios.sh
            ldap_politica_acceso.sh
        mantenimiento/
            backup.sh
            monitor.sh
            restore.sh
            update.sh
        odoo/
            odoo_crear_usuarios.sh
            odoo_setup_wizard.sh
    sql/
        audit_triggers.sql
    vagrant/
        Explicacion_provision_postgres.md
        provision_postgres.sh
    web-dashboard/
```

## File Contents

### File: .\.env.example
```example
# ============================================================
# ARCHIVO: .env.example (Plantilla de Variables de Entorno)
# DESCRIPCIÓN: Plantilla de configuración con valores falsos.
#              Sirve como guía para saber qué variables necesita el
#              proyecto antes de arrancar.
# ============================================================
# --- CREDENCIALES DE POSTGRESQL ---
# Usuario administrador de la base de datos de Odoo
POSTGRES_USER=odoo
# Contraseña del usuario de base de datos.
POSTGRES_PASSWORD=password_ejemplo_db
# Nombre de la base de datos que PostgreSQL creará
POSTGRES_DB=odoo_erp
# --- CREDENCIALES DE ODOO ---
# Contraseña maestra de Odoo (Master Password).
# Se usa para poder crear, eliminar o restaurar bases de datos.
ODOO_MASTER_PASSWORD=password_ejemplo_master
```

### File: .\.gitignore
```text
# ==========================================
# .gitignore - TFG ASIR
# Archivos a EXCLUIR del repositorio GitHub
# ==========================================
# El archivo de secretos NUNCA debe subirse
docker/.env
.env
# .env.example (eliminado de gitignore para permitir subir la plantilla)
# Archivos de datos generados (demasiado grandes para GitHub)
docker/data/
data/
# Config generado de pfSense (se genera con el script, no commitear)
config/pfsense_config.xml
# Copias de seguridad locales
backups/
# Certificados SSL generados (privados)
certs/*.key
certs/*.crt
# Archivos de sistema
.DS_Store
Thumbs.db
# ISOs no deben subirse a GitHub (son demasiado grandes)
ISOs/
CLAUDE.md
docs/mas info/*
```

### File: .\.markdownlint.json
```json
{
  "default": false
}
```

### File: .\CLAUDE.md
```md
# CLAUDE.md — Skill de Documentación Automática del TFG
Este archivo define cómo Claude debe comportarse en este repositorio.
Se carga automáticamente en cada sesión de Claude Code.
---
## Contexto del Proyecto
**Proyecto:** TFG — Implantación Segura y Automatizada de Odoo
**Autora:** Sandra Fradejas
**Descripción:** Entorno productivo completo para el ERP Odoo con enfoque en seguridad, contenerización (Docker) y buenas prácticas de administración de sistemas. Incluye pfSense como firewall, Nginx como reverse proxy, y automatización de scripts Bash.
### Estructura del Repositorio
```
TFG-Implantacion_Segura_y_Automatizada_de_Odoo/
├── docker/          # docker-compose.yml y configuración de contenedores
├── config_nginx/    # Configuración de Nginx (reverse proxy + SSL)
├── scripts/         # Scripts Bash de automatización e instalación
├── sql/             # Scripts SQL (backups, init, usuarios)
├── ISOs/            # Referencias a ISOs utilizadas
├── docs/            # Documentación técnica del proyecto
│   ├── implementation_plan.md    # Plan de implementación por fases
│   ├── task.md                   # Tareas pendientes y completadas
│   ├── github_issues.md          # Registro de issues de GitHub
│   ├── reglas_pfsense.md         # Reglas de firewall pfSense
│   └── propuestas_mejoras_extra.md # Ideas y mejoras futuras
└── CLAUDE.md        # Este archivo
```
---
## Skill: Auto-Documentación de Cambios
### Propósito
Cada vez que realices o asistas en un cambio técnico en este repositorio, debes **documentar automáticamente** lo que se hizo, por qué, y cómo afecta al sistema — sin que Sandra tenga que pedírtelo explícitamente.
---
### Cuándo Activar la Documentación
Documenta automáticamente cuando:
- Se **crea o modifica** cualquier archivo en `docker/`, `config_nginx/`, `scripts/`, `sql/`
- Se **añade una regla** de pfSense o se modifica la arquitectura de red
- Se **resuelve un issue** o se completa una tarea del `docs/task.md`
- Se **instala, actualiza o elimina** un servicio o dependencia
- Se **cambia una variable de entorno** o configuración sensible (sin revelar valores reales)
- Se **corrige un error** o problema de seguridad
---
### Qué Documentar y Dónde
#### 1. `docs/task.md` — Registro de Tareas
Actualiza este archivo marcando tareas completadas y añadiendo nuevas si procede.
**Formato de entrada completada:**
```markdown
- [x] **[YYYY-MM-DD]** Descripción breve de la tarea completada
  - _Qué se hizo:_ Explicación técnica concisa
  - _Archivos afectados:_ `ruta/al/archivo.ext`
  - _Resultado:_ Comportamiento esperado después del cambio
```
**Formato de tarea nueva detectada:**
```markdown
- [ ] **[PENDIENTE]** Descripción de la tarea detectada
  - _Motivo:_ Por qué es necesaria
  - _Prioridad:_ Alta / Media / Baja
```
---
#### 2. `docs/implementation_plan.md` — Plan de Implementación
Si el cambio afecta a una fase del plan, actualiza el estado de esa fase.
Cuando una fase se complete, añade al final de su sección:
```markdown
> ✅ **Completado [YYYY-MM-DD]:** Resumen de cómo quedó implementada esta fase.
```
---
#### 3. `docs/reglas_pfsense.md` — Reglas de Firewall
Si el cambio implica nuevas reglas o modificación de las existentes, añade una entrada en formato tabla:
```markdown
| Fecha      | Interfaz | Acción | Protocolo | Origen → Destino | Puerto | Descripción |
|------------|----------|--------|-----------|------------------|--------|-------------|
| YYYY-MM-DD | LAN/WAN  | Pass/Block | TCP/UDP | IP → IP       | XXXX   | Motivo      |
```
---
#### 4. `docs/CHANGELOG.md` — Historial de Cambios *(crear si no existe)*
Mantén un CHANGELOG siguiendo [Keep a Changelog](https://keepachangelog.com/es/1.1.0/).
**Formato:**
```markdown
## [Sin publicar]
### Añadido
- Descripción del nuevo elemento añadido
### Modificado
- Descripción de cambio en funcionalidad existente
### Corregido
- Descripción del bug o problema resuelto
### Seguridad
- Descripción de vulnerabilidad corregida o mejora de seguridad
```
Cuando se hace un commit o se cierra un issue, mueve las entradas de `[Sin publicar]` a una nueva sección con versión o fecha:
```markdown
## [v1.x — YYYY-MM-DD]
```
---
### Reglas de Escritura para la Documentación
1. **Idioma:** Siempre en español (es el TFG de Sandra).
2. **Tono:** Técnico pero claro, como si lo leyera el tutor del TFG.
3. **Nunca incluir:** contraseñas, tokens, IPs privadas reales, ni secretos. Usar `<VALOR_OCULTO>` o `<IP_INTERNA>` como placeholder.
4. **Siempre incluir:** fecha del cambio, archivo(s) afectado(s), y el motivo técnico del cambio.
5. **Máximo 3 líneas por entrada** en `task.md`. Si necesitas más detalle, crea un archivo dedicado en `docs/`.
---
### Flujo de Trabajo Estándar
Cuando Sandra te pida hacer un cambio, sigue este orden:
```
1. Analiza el cambio solicitado
2. Implementa el cambio técnico (modifica el archivo correspondiente)
3. Actualiza docs/task.md con lo que se hizo
4. Actualiza docs/CHANGELOG.md con la entrada apropiada
5. Si aplica: actualiza implementation_plan.md o reglas_pfsense.md
6. Informa a Sandra: "✅ Cambio realizado y documentado en docs/"
```
---
### Comandos Útiles que Puedes Sugerir
Cuando corresponda, sugiere estos comandos para verificar el entorno:
```bash
# Verificar estado de contenedores
docker compose -f docker/docker-compose.yml ps
# Ver logs de Odoo
docker compose -f docker/docker-compose.yml logs odoo --tail=50
# Verificar configuración de Nginx
nginx -t -c /ruta/config_nginx/nginx.conf
# Backup manual de base de datos
bash scripts/backup_db.sh
```
---
### Detección Automática de Problemas de Seguridad
Siempre que revises o modifiques archivos, alerta si detectas:
- 🔴 **CRÍTICO:** Contraseñas o tokens hardcodeados en código fuente
- 🟠 **ADVERTENCIA:** Puertos expuestos innecesariamente en docker-compose
- 🟡 **AVISO:** Variables de entorno sensibles sin usar `.env` o secrets
- 🔵 **INFO:** Configuración mejorable pero no crítica
Formato de alerta:
```
⚠️ [NIVEL] Archivo: `ruta/archivo` — Descripción del problema — Recomendación
```
---
## Notas Finales
- Este es un **TFG académico** de ASIR/SMR. La documentación es parte de la evaluación.
- Prioriza documentación **clara y pedagógica**: explica el "por qué" además del "qué".
- Cuando tengas dudas sobre dónde documentar algo, consulta a Sandra antes de proceder.
```

### File: .\install.sh
```sh
set -e
PROJECT_DIR="/opt/erp-odoo"
REPO_URL="https://github.com/sandrafrv/TFG-Implantacion_Segura_y_Automatizada_de_Odoo.git" 
if [ "$(id -u)" -ne 0 ]; then
    echo "[ERROR] Este script debe ejecutarse como root (sudo ./install.sh)"
    exit 1
fi
echo "=== Iniciando instalación de Odoo ERP ==="
echo "[1/6] Instalando dependencias del sistema..."
apt-get update
apt-get install -y git curl openssl cockpit docker.io docker-compose
systemctl enable --now cockpit.socket
systemctl enable --now docker
echo "[2/6] Preparando el directorio del proyecto..."
if [ ! -d "$PROJECT_DIR/.git" ]; then
    echo "Clonando repositorio en $PROJECT_DIR..."
    git clone "$REPO_URL" "${PROJECT_DIR}_temp"
    cp -rn "${PROJECT_DIR}_temp/." "$PROJECT_DIR/"
    rm -rf "${PROJECT_DIR}_temp"
    cd "$PROJECT_DIR"
else
    echo "El repositorio ya existe en $PROJECT_DIR. Actualizando..."
    cd "$PROJECT_DIR"
    git fetch --all
    git reset --hard origin/main
fi
cd "$PROJECT_DIR"
echo "[3/6] Creando estructura de directorios..."
mkdir -p data/postgres data/odoo_addons data/odoo_web backups certs docker
chmod -R 777 data/ backups/
chmod +x scripts/*/*.sh
echo "[4/6] Configurando certificados SSL..."
if [ ! -f "certs/server.crt" ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout certs/server.key -out certs/server.crt \
        -subj "/C=ES/ST=Madrid/L=Madrid/O=TechSolutions/OU=IT/CN=erp.techsolutions.local"
    echo "Certificados autofirmados generados en certs/"
else
    echo "Los certificados ya existen. Omitiendo."
fi
echo "[5/6] Configurando entorno (.env)..."
./scripts/deploy/configure.sh
echo "[6/6] Desplegando Docker e instalando tareas programadas..."
./scripts/deploy/deploy.sh
./scripts/deploy/install_cron.sh
echo "=== Instalación completada con éxito ==="
echo "Accede a Cockpit en: https://[IP_SERVIDOR]:9090"
echo "Accede a Odoo en: https://[IP_SERVIDOR]"
```

### File: .\LICENSE
```text
                    GNU AFFERO GENERAL PUBLIC LICENSE
                       Version 3, 19 November 2007
 Copyright (C) 2007 Free Software Foundation, Inc. <https://fsf.org/>
 Everyone is permitted to copy and distribute verbatim copies
 of this license document, but changing it is not allowed.
                            Preamble
  The GNU Affero General Public License is a free, copyleft license for
software and other kinds of works, specifically designed to ensure
cooperation with the community in the case of network server software.
  The licenses for most software and other practical works are designed
to take away your freedom to share and change the works.  By contrast,
our General Public Licenses are intended to guarantee your freedom to
share and change all versions of a program--to make sure it remains free
software for all its users.
  When we speak of free software, we are referring to freedom, not
price.  Our General Public Licenses are designed to make sure that you
have the freedom to distribute copies of free software (and charge for
them if you wish), that you receive source code or can get it if you
want it, that you can change the software or use pieces of it in new
free programs, and that you know you can do these things.
  Developers that use our General Public Licenses protect your rights
with two steps: (1) assert copyright on the software, and (2) offer
you this License which gives you legal permission to copy, distribute
and/or modify the software.
  A secondary benefit of defending all users' freedom is that
improvements made in alternate versions of the program, if they
receive widespread use, become available for other developers to
incorporate.  Many developers of free software are heartened and
encouraged by the resulting cooperation.  However, in the case of
software used on network servers, this result may fail to come about.
The GNU General Public License permits making a modified version and
letting the public access it on a server without ever releasing its
source code to the public.
  The GNU Affero General Public License is designed specifically to
ensure that, in such cases, the modified source code becomes available
to the community.  It requires the operator of a network server to
provide the source code of the modified version running there to the
users of that server.  Therefore, public use of a modified version, on
a publicly accessible server, gives the public access to the source
code of the modified version.
  An older license, called the Affero General Public License and
published by Affero, was designed to accomplish similar goals.  This is
a different license, not a version of the Affero GPL, but Affero has
released a new version of the Affero GPL which permits relicensing under
this license.
  The precise terms and conditions for copying, distribution and
modification follow.
                       TERMS AND CONDITIONS
  0. Definitions.
  "This License" refers to version 3 of the GNU Affero General Public License.
  "Copyright" also means copyright-like laws that apply to other kinds of
works, such as semiconductor masks.
  "The Program" refers to any copyrightable work licensed under this
License.  Each licensee is addressed as "you".  "Licensees" and
"recipients" may be individuals or organizations.
  To "modify" a work means to copy from or adapt all or part of the work
in a fashion requiring copyright permission, other than the making of an
exact copy.  The resulting work is called a "modified version" of the
earlier work or a work "based on" the earlier work.
  A "covered work" means either the unmodified Program or a work based
on the Program.
  To "propagate" a work means to do anything with it that, without
permission, would make you directly or secondarily liable for
infringement under applicable copyright law, except executing it on a
computer or modifying a private copy.  Propagation includes copying,
distribution (with or without modification), making available to the
public, and in some countries other activities as well.
  To "convey" a work means any kind of propagation that enables other
parties to make or receive copies.  Mere interaction with a user through
a computer network, with no transfer of a copy, is not conveying.
  An interactive user interface displays "Appropriate Legal Notices"
to the extent that it includes a convenient and prominently visible
feature that (1) displays an appropriate copyright notice, and (2)
tells the user that there is no warranty for the work (except to the
extent that warranties are provided), that licensees may convey the
work under this License, and how to view a copy of this License.  If
the interface presents a list of user commands or options, such as a
menu, a prominent item in the list meets this criterion.
  1. Source Code.
  The "source code" for a work means the preferred form of the work
for making modifications to it.  "Object code" means any non-source
form of a work.
  A "Standard Interface" means an interface that either is an official
standard defined by a recognized standards body, or, in the case of
interfaces specified for a particular programming language, one that
is widely used among developers working in that language.
  The "System Libraries" of an executable work include anything, other
than the work as a whole, that (a) is included in the normal form of
packaging a Major Component, but which is not part of that Major
Component, and (b) serves only to enable use of the work with that
Major Component, or to implement a Standard Interface for which an
implementation is available to the public in source code form.  A
"Major Component", in this context, means a major essential component
(kernel, window system, and so on) of the specific operating system
(if any) on which the executable work runs, or a compiler used to
produce the work, or an object code interpreter used to run it.
  The "Corresponding Source" for a work in object code form means all
the source code needed to generate, install, and (for an executable
work) run the object code and to modify the work, including scripts to
control those activities.  However, it does not include the work's
System Libraries, or general-purpose tools or generally available free
programs which are used unmodified in performing those activities but
which are not part of the work.  For example, Corresponding Source
includes interface definition files associated with source files for
the work, and the source code for shared libraries and dynamically
linked subprograms that the work is specifically designed to require,
such as by intimate data communication or control flow between those
subprograms and other parts of the work.
  The Corresponding Source need not include anything that users
can regenerate automatically from other parts of the Corresponding
Source.
  The Corresponding Source for a work in source code form is that
same work.
  2. Basic Permissions.
  All rights granted under this License are granted for the term of
copyright on the Program, and are irrevocable provided the stated
conditions are met.  This License explicitly affirms your unlimited
permission to run the unmodified Program.  The output from running a
covered work is covered by this License only if the output, given its
content, constitutes a covered work.  This License acknowledges your
rights of fair use or other equivalent, as provided by copyright law.
  You may make, run and propagate covered works that you do not
convey, without conditions so long as your license otherwise remains
in force.  You may convey covered works to others for the sole purpose
of having them make modifications exclusively for you, or provide you
with facilities for running those works, provided that you comply with
the terms of this License in conveying all material for which you do
not control copyright.  Those thus making or running the covered works
for you must do so exclusively on your behalf, under your direction
and control, on terms that prohibit them from making any copies of
your copyrighted material outside their relationship with you.
  Conveying under any other circumstances is permitted solely under
the conditions stated below.  Sublicensing is not allowed; section 10
makes it unnecessary.
  3. Protecting Users' Legal Rights From Anti-Circumvention Law.
  No covered work shall be deemed part of an effective technological
measure under any applicable law fulfilling obligations under article
11 of the WIPO copyright treaty adopted on 20 December 1996, or
similar laws prohibiting or restricting circumvention of such
measures.
  When you convey a covered work, you waive any legal power to forbid
circumvention of technological measures to the extent such circumvention
is effected by exercising rights under this License with respect to
the covered work, and you disclaim any intention to limit operation or
modification of the work as a means of enforcing, against the work's
users, your or third parties' legal rights to forbid circumvention of
technological measures.
  4. Conveying Verbatim Copies.
  You may convey verbatim copies of the Program's source code as you
receive it, in any medium, provided that you conspicuously and
appropriately publish on each copy an appropriate copyright notice;
keep intact all notices stating that this License and any
non-permissive terms added in accord with section 7 apply to the code;
keep intact all notices of the absence of any warranty; and give all
recipients a copy of this License along with the Program.
  You may charge any price or no price for each copy that you convey,
and you may offer support or warranty protection for a fee.
  5. Conveying Modified Source Versions.
  You may convey a work based on the Program, or the modifications to
produce it from the Program, in the form of source code under the
terms of section 4, provided that you also meet all of these conditions:
    a) The work must carry prominent notices stating that you modified
    it, and giving a relevant date.
    b) The work must carry prominent notices stating that it is
    released under this License and any conditions added under section
    7.  This requirement modifies the requirement in section 4 to
    "keep intact all notices".
    c) You must license the entire work, as a whole, under this
    License to anyone who comes into possession of a copy.  This
    License will therefore apply, along with any applicable section 7
    additional terms, to the whole of the work, and all its parts,
    regardless of how they are packaged.  This License gives no
    permission to license the work in any other way, but it does not
    invalidate such permission if you have separately received it.
    d) If the work has interactive user interfaces, each must display
    Appropriate Legal Notices; however, if the Program has interactive
    interfaces that do not display Appropriate Legal Notices, your
    work need not make them do so.
  A compilation of a covered work with other separate and independent
works, which are not by their nature extensions of the covered work,
and which are not combined with it such as to form a larger program,
in or on a volume of a storage or distribution medium, is called an
"aggregate" if the compilation and its resulting copyright are not
used to limit the access or legal rights of the compilation's users
beyond what the individual works permit.  Inclusion of a covered work
in an aggregate does not cause this License to apply to the other
parts of the aggregate.
  6. Conveying Non-Source Forms.
  You may convey a covered work in object code form under the terms
of sections 4 and 5, provided that you also convey the
machine-readable Corresponding Source under the terms of this License,
in one of these ways:
    a) Convey the object code in, or embodied in, a physical product
    (including a physical distribution medium), accompanied by the
    Corresponding Source fixed on a durable physical medium
    customarily used for software interchange.
    b) Convey the object code in, or embodied in, a physical product
    (including a physical distribution medium), accompanied by a
    written offer, valid for at least three years and valid for as
    long as you offer spare parts or customer support for that product
    model, to give anyone who possesses the object code either (1) a
    copy of the Corresponding Source for all the software in the
    product that is covered by this License, on a durable physical
    medium customarily used for software interchange, for a price no
    more than your reasonable cost of physically performing this
    conveying of source, or (2) access to copy the
    Corresponding Source from a network server at no charge.
    c) Convey individual copies of the object code with a copy of the
    written offer to provide the Corresponding Source.  This
    alternative is allowed only occasionally and noncommercially, and
    only if you received the object code with such an offer, in accord
    with subsection 6b.
    d) Convey the object code by offering access from a designated
    place (gratis or for a charge), and offer equivalent access to the
    Corresponding Source in the same way through the same place at no
    further charge.  You need not require recipients to copy the
    Corresponding Source along with the object code.  If the place to
    copy the object code is a network server, the Corresponding Source
    may be on a different server (operated by you or a third party)
    that supports equivalent copying facilities, provided you maintain
    clear directions next to the object code saying where to find the
    Corresponding Source.  Regardless of what server hosts the
    Corresponding Source, you remain obligated to ensure that it is
    available for as long as needed to satisfy these requirements.
    e) Convey the object code using peer-to-peer transmission, provided
    you inform other peers where the object code and Corresponding
    Source of the work are being offered to the general public at no
    charge under subsection 6d.
  A separable portion of the object code, whose source code is excluded
from the Corresponding Source as a System Library, need not be
included in conveying the object code work.
  A "User Product" is either (1) a "consumer product", which means any
tangible personal property which is normally used for personal, family,
or household purposes, or (2) anything designed or sold for incorporation
into a dwelling.  In determining whether a product is a consumer product,
doubtful cases shall be resolved in favor of coverage.  For a particular
product received by a particular user, "normally used" refers to a
typical or common use of that class of product, regardless of the status
of the particular user or of the way in which the particular user
actually uses, or expects or is expected to use, the product.  A product
is a consumer product regardless of whether the product has substantial
commercial, industrial or non-consumer uses, unless such uses represent
the only significant mode of use of the product.
  "Installation Information" for a User Product means any methods,
procedures, authorization keys, or other information required to install
and execute modified versions of a covered work in that User Product from
a modified version of its Corresponding Source.  The information must
suffice to ensure that the continued functioning of the modified object
code is in no case prevented or interfered with solely because
modification has been made.
  If you convey an object code work under this section in, or with, or
specifically for use in, a User Product, and the conveying occurs as
part of a transaction in which the right of possession and use of the
User Product is transferred to the recipient in perpetuity or for a
fixed term (regardless of how the transaction is characterized), the
Corresponding Source conveyed under this section must be accompanied
by the Installation Information.  But this requirement does not apply
if neither you nor any third party retains the ability to install
modified object code on the User Product (for example, the work has
been installed in ROM).
  The requirement to provide Installation Information does not include a
requirement to continue to provide support service, warranty, or updates
for a work that has been modified or installed by the recipient, or for
the User Product in which it has been modified or installed.  Access to a
network may be denied when the modification itself materially and
adversely affects the operation of the network or violates the rules and
protocols for communication across the network.
  Corresponding Source conveyed, and Installation Information provided,
in accord with this section must be in a format that is publicly
documented (and with an implementation available to the public in
source code form), and must require no special password or key for
unpacking, reading or copying.
  7. Additional Terms.
  "Additional permissions" are terms that supplement the terms of this
License by making exceptions from one or more of its conditions.
Additional permissions that are applicable to the entire Program shall
be treated as though they were included in this License, to the extent
that they are valid under applicable law.  If additional permissions
apply only to part of the Program, that part may be used separately
under those permissions, but the entire Program remains governed by
this License without regard to the additional permissions.
  When you convey a copy of a covered work, you may at your option
remove any additional permissions from that copy, or from any part of
it.  (Additional permissions may be written to require their own
removal in certain cases when you modify the work.)  You may place
additional permissions on material, added by you to a covered work,
for which you have or can give appropriate copyright permission.
  Notwithstanding any other provision of this License, for material you
add to a covered work, you may (if authorized by the copyright holders of
that material) supplement the terms of this License with terms:
    a) Disclaiming warranty or limiting liability differently from the
    terms of sections 15 and 16 of this License; or
    b) Requiring preservation of specified reasonable legal notices or
    author attributions in that material or in the Appropriate Legal
    Notices displayed by works containing it; or
    c) Prohibiting misrepresentation of the origin of that material, or
    requiring that modified versions of such material be marked in
    reasonable ways as different from the original version; or
    d) Limiting the use for publicity purposes of names of licensors or
    authors of the material; or
    e) Declining to grant rights under trademark law for use of some
    trade names, trademarks, or service marks; or
    f) Requiring indemnification of licensors and authors of that
    material by anyone who conveys the material (or modified versions of
    it) with contractual assumptions of liability to the recipient, for
    any liability that these contractual assumptions directly impose on
    those licensors and authors.
  All other non-permissive additional terms are considered "further
restrictions" within the meaning of section 10.  If the Program as you
received it, or any part of it, contains a notice stating that it is
governed by this License along with a term that is a further
restriction, you may remove that term.  If a license document contains
a further restriction but permits relicensing or conveying under this
License, you may add to a covered work material governed by the terms
of that license document, provided that the further restriction does
not survive such relicensing or conveying.
  If you add terms to a covered work in accord with this section, you
must place, in the relevant source files, a statement of the
additional terms that apply to those files, or a notice indicating
where to find the applicable terms.
  Additional terms, permissive or non-permissive, may be stated in the
form of a separately written license, or stated as exceptions;
the above requirements apply either way.
  8. Termination.
  You may not propagate or modify a covered work except as expressly
provided under this License.  Any attempt otherwise to propagate or
modify it is void, and will automatically terminate your rights under
this License (including any patent licenses granted under the third
paragraph of section 11).
  However, if you cease all violation of this License, then your
license from a particular copyright holder is reinstated (a)
provisionally, unless and until the copyright holder explicitly and
finally terminates your license, and (b) permanently, if the copyright
holder fails to notify you of the violation by some reasonable means
prior to 60 days after the cessation.
  Moreover, your license from a particular copyright holder is
reinstated permanently if the copyright holder notifies you of the
violation by some reasonable means, this is the first time you have
received notice of violation of this License (for any work) from that
copyright holder, and you cure the violation prior to 30 days after
your receipt of the notice.
  Termination of your rights under this section does not terminate the
licenses of parties who have received copies or rights from you under
this License.  If your rights have been terminated and not permanently
reinstated, you do not qualify to receive new licenses for the same
material under section 10.
  9. Acceptance Not Required for Having Copies.
  You are not required to accept this License in order to receive or
run a copy of the Program.  Ancillary propagation of a covered work
occurring solely as a consequence of using peer-to-peer transmission
to receive a copy likewise does not require acceptance.  However,
nothing other than this License grants you permission to propagate or
modify any covered work.  These actions infringe copyright if you do
not accept this License.  Therefore, by modifying or propagating a
covered work, you indicate your acceptance of this License to do so.
  10. Automatic Licensing of Downstream Recipients.
  Each time you convey a covered work, the recipient automatically
receives a license from the original licensors, to run, modify and
propagate that work, subject to this License.  You are not responsible
for enforcing compliance by third parties with this License.
  An "entity transaction" is a transaction transferring control of an
organization, or substantially all assets of one, or subdividing an
organization, or merging organizations.  If propagation of a covered
work results from an entity transaction, each party to that
transaction who receives a copy of the work also receives whatever
licenses to the work the party's predecessor in interest had or could
give under the previous paragraph, plus a right to possession of the
Corresponding Source of the work from the predecessor in interest, if
the predecessor has it or can get it with reasonable efforts.
  You may not impose any further restrictions on the exercise of the
rights granted or affirmed under this License.  For example, you may
not impose a license fee, royalty, or other charge for exercise of
rights granted under this License, and you may not initiate litigation
(including a cross-claim or counterclaim in a lawsuit) alleging that
any patent claim is infringed by making, using, selling, offering for
sale, or importing the Program or any portion of it.
  11. Patents.
  A "contributor" is a copyright holder who authorizes use under this
License of the Program or a work on which the Program is based.  The
work thus licensed is called the contributor's "contributor version".
  A contributor's "essential patent claims" are all patent claims
owned or controlled by the contributor, whether already acquired or
hereafter acquired, that would be infringed by some manner, permitted
by this License, of making, using, or selling its contributor version,
but do not include claims that would be infringed only as a
consequence of further modification of the contributor version.  For
purposes of this definition, "control" includes the right to grant
patent sublicenses in a manner consistent with the requirements of
this License.
  Each contributor grants you a non-exclusive, worldwide, royalty-free
patent license under the contributor's essential patent claims, to
make, use, sell, offer for sale, import and otherwise run, modify and
propagate the contents of its contributor version.
  In the following three paragraphs, a "patent license" is any express
agreement or commitment, however denominated, not to enforce a patent
(such as an express permission to practice a patent or covenant not to
sue for patent infringement).  To "grant" such a patent license to a
party means to make such an agreement or commitment not to enforce a
patent against the party.
  If you convey a covered work, knowingly relying on a patent license,
and the Corresponding Source of the work is not available for anyone
to copy, free of charge and under the terms of this License, through a
publicly available network server or other readily accessible means,
then you must either (1) cause the Corresponding Source to be so
available, or (2) arrange to deprive yourself of the benefit of the
patent license for this particular work, or (3) arrange, in a manner
consistent with the requirements of this License, to extend the patent
license to downstream recipients.  "Knowingly relying" means you have
actual knowledge that, but for the patent license, your conveying the
covered work in a country, or your recipient's use of the covered work
in a country, would infringe one or more identifiable patents in that
country that you have reason to believe are valid.
  If, pursuant to or in connection with a single transaction or
arrangement, you convey, or propagate by procuring conveyance of, a
covered work, and grant a patent license to some of the parties
receiving the covered work authorizing them to use, propagate, modify
or convey a specific copy of the covered work, then the patent license
you grant is automatically extended to all recipients of the covered
work and works based on it.
  A patent license is "discriminatory" if it does not include within
the scope of its coverage, prohibits the exercise of, or is
conditioned on the non-exercise of one or more of the rights that are
specifically granted under this License.  You may not convey a covered
work if you are a party to an arrangement with a third party that is
in the business of distributing software, under which you make payment
to the third party based on the extent of your activity of conveying
the work, and under which the third party grants, to any of the
parties who would receive the covered work from you, a discriminatory
patent license (a) in connection with copies of the covered work
conveyed by you (or copies made from those copies), or (b) primarily
for and in connection with specific products or compilations that
contain the covered work, unless you entered into that arrangement,
or that patent license was granted, prior to 28 March 2007.
  Nothing in this License shall be construed as excluding or limiting
any implied license or other defenses to infringement that may
otherwise be available to you under applicable patent law.
  12. No Surrender of Others' Freedom.
  If conditions are imposed on you (whether by court order, agreement or
otherwise) that contradict the conditions of this License, they do not
excuse you from the conditions of this License.  If you cannot convey a
covered work so as to satisfy simultaneously your obligations under this
License and any other pertinent obligations, then as a consequence you may
not convey it at all.  For example, if you agree to terms that obligate you
to collect a royalty for further conveying from those to whom you convey
the Program, the only way you could satisfy both those terms and this
License would be to refrain entirely from conveying the Program.
  13. Remote Network Interaction; Use with the GNU General Public License.
  Notwithstanding any other provision of this License, if you modify the
Program, your modified version must prominently offer all users
interacting with it remotely through a computer network (if your version
supports such interaction) an opportunity to receive the Corresponding
Source of your version by providing access to the Corresponding Source
from a network server at no charge, through some standard or customary
means of facilitating copying of software.  This Corresponding Source
shall include the Corresponding Source for any work covered by version 3
of the GNU General Public License that is incorporated pursuant to the
following paragraph.
  Notwithstanding any other provision of this License, you have
permission to link or combine any covered work with a work licensed
under version 3 of the GNU General Public License into a single
combined work, and to convey the resulting work.  The terms of this
License will continue to apply to the part which is the covered work,
but the work with which it is combined will remain governed by version
3 of the GNU General Public License.
  14. Revised Versions of this License.
  The Free Software Foundation may publish revised and/or new versions of
the GNU Affero General Public License from time to time.  Such new versions
will be similar in spirit to the present version, but may differ in detail to
address new problems or concerns.
  Each version is given a distinguishing version number.  If the
Program specifies that a certain numbered version of the GNU Affero General
Public License "or any later version" applies to it, you have the
option of following the terms and conditions either of that numbered
version or of any later version published by the Free Software
Foundation.  If the Program does not specify a version number of the
GNU Affero General Public License, you may choose any version ever published
by the Free Software Foundation.
  If the Program specifies that a proxy can decide which future
versions of the GNU Affero General Public License can be used, that proxy's
public statement of acceptance of a version permanently authorizes you
to choose that version for the Program.
  Later license versions may give you additional or different
permissions.  However, no additional obligations are imposed on any
author or copyright holder as a result of your choosing to follow a
later version.
  15. Disclaimer of Warranty.
  THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.
  16. Limitation of Liability.
  IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
  17. Interpretation of Sections 15 and 16.
  If the disclaimer of warranty and limitation of liability provided
above cannot be given local legal effect according to their terms,
reviewing courts shall apply local law that most closely approximates
an absolute waiver of all civil liability in connection with the
Program, unless a warranty or assumption of liability accompanies a
copy of the Program in return for a fee.
                     END OF TERMS AND CONDITIONS
            How to Apply These Terms to Your New Programs
  If you develop a new program, and you want it to be of the greatest
possible use to the public, the best way to achieve this is to make it
free software which everyone can redistribute and change under these terms.
  To do so, attach the following notices to the program.  It is safest
to attach them to the start of each source file to most effectively
state the exclusion of warranty; and each file should have at least
the "copyright" line and a pointer to where the full notice is found.
    <one line to give the program's name and a brief idea of what it does.>
    Copyright (C) <year>  <name of author>
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.
    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
Also add information on how to contact you by electronic and paper mail.
  If your software can interact with users remotely through a computer
network, you should also make sure that it provides a way for users to
get its source.  For example, if your program is a web application, its
interface could display a "Source" link that leads users to an archive
of the code.  There are many ways you could offer source, and different
solutions will be better for different programs; see section 13 for the
specific requirements.
  You should also get your employer (if you work as a programmer) or school,
if any, to sign a "copyright disclaimer" for the program, if necessary.
For more information on this, and how to apply and follow the GNU AGPL, see
<https://www.gnu.org/licenses/>.
```

### File: .\README.md
```md
# Implantación Segura y Automatizada de Odoo con pfSense y Docker
**Autores:**
- Javier Córdoba Del Valle
- Mario García García
- Sandra Fradejas Avedillo
**Grado:** ASIR - Administración de Sistemas Informáticos en Red
**Centro:** IES Cañaveral — Departamento de Informática y Comunicaciones
**Fecha:** Curso 2025/2026
---
## 📋 Resumen Ejecutivo
Este repositorio documenta el diseño e implantación de un entorno productivo completo para el ERP/CRM **Odoo**, simulando las necesidades de una empresa ("TechSolutions S.L."). La arquitectura se caracteriza por su enfoque en la seguridad, la contenerización y las buenas prácticas de administración de sistemas.
**Características principales:**
- **Seguridad Perimetral (Firewall 3 capas):** Enrutamiento y políticas restrictivas mediante pfSense (WAN/LAN/DMZ) con reglas explícitas de bloqueo anti-pivoting.
- **Orquestación de Contenedores:** Despliegue de servicios (Nginx, Odoo 17 y PostgreSQL 16) usando Docker y Docker Compose sobre **Debian 13 Server (Trixie)**.
- **Segmentación de Red:** Soporte de VLANs (10, 30) para aislar el tráfico de clientes internos y servicios públicos.
- **Redes MACVLAN:** Los contenedores Nginx y Odoo-web tienen IPs propias en la VLAN30 (`192.168.30.20` y `192.168.30.21`), visibles directamente por pfSense como hosts independientes.
- **Acceso Seguro (Proxy Inverso):** Publicación del servicio mediante un contenedor Nginx Alpine, con terminación SSL/TLS, limitando el acceso a los puertos 80/443 del host.
- **Automatización y Auditoría:** Scripts en Bash para *backups*, restauración, monitorización y despliegue, junto con *Triggers* (PL/pgSQL) para la auditoría de acciones en la base de datos.
- **Gestión Visual:** Administración del servidor mediante **Cockpit** (interfaz web en puerto 9090).
---
## 🏗️ Arquitectura de Red
La topología divide la red en tres zonas de confianza principales, gestionadas por un firewall pfSense:
- **WAN (Internet):** Acceso externo simulado.
- **DMZ (VLAN 30 - 192.168.30.0/24):** Servidor **Debian 13 Server** que aloja el entorno Docker íntegro (Nginx, Odoo, PostgreSQL). Gestionado visualmente desde **Cockpit** (`https://192.168.40.10:9090`).
- **LAN Clientes (VLAN 10 - 192.168.10.0/24):** Equipos internos de la empresa.
- **LAN Administración (VLAN 40)**: Grupos admin y DBA
```mermaid
graph TD
    GITHUB["☁️ GITHUB"]
    WLAN["☁️ WLAN"]
    GITHUB -.->PFSENSE
    WLAN --> PFSENSE
    PFSENSE(["Pfsense\nFirewall · DHCP "])
    PFSENSE -->|" 192.168.40.0/24"| VLAN40
    PFSENSE -->|" 192.168.30.0/24"| DMZ
    PFSENSE -->|"192.168.10.0/24"| VLAN10
    subgraph VLAN40["VLAN 40 — Administración"]
        ADMIN["🖥️Administrador"]
        DBA["🖥️DBA"]
   end
    subgraph VLAN10["VLAN 10 — Clientes"]
        CLIENT["💻 Empleados"]
        CLIENT["🖥️ Empleados"]
    end
    subgraph DMZ["VLAN 30 DMZ"]
        subgraph Debian [" Server Debian 13 "]
                NGINX["DOCKER · NGINX\nMAC_VLAN: 20"]
                ODOO[" DOCKER · ODOO\nMAC_VLAN: 21"]
                BBDD[" DOCKER · PostgreSQL"]
                NGINX -->|"Reverse Proxy"| ODOO
                ODOO -->|"Consultas"| BBDD
        end
    end
    classDef firewall fill:#BBDEFB,stroke:#1565C0,color:#000
    classDef vlan fill:#FFE0B2,stroke:#E65100,color:#000
    classDef dmznode fill:#CE93D8,stroke:#6A1B9A,color:#000
    classDef client fill:#FFE0B2,stroke:#E65100,color:#000
    class PFSENSE firewall
    class ADMIN,Debian,DBA vlan
    class CLIENT client
    class LDAP,NGINX,ODOO,BBDD dmznode
```
---
### Tabla de Direccionamiento IP
| Zona | Subred (CIDR) | Gateway (pfSense) | IP del Sistema | Puertos Abiertos | Servicio |
| :--- | :--- | :--- | :--- | :--- | :--- |
| WAN (Exterior) | Red Fija/DHCP | Router físico | IP WAN | 80, 443 (NAT) | Redirección NAT hacia DMZ |
| DMZ (VLAN 30) | `192.168.30.0/24` | `192.168.30.1` | **`192.168.30.10`** | 80, 443, 22, 9090 | Servidor único Debian + Docker + Cockpit |
| DMZ — nginx-proxy | `192.168.30.0/24` | `192.168.30.1` | **`192.168.30.20`** | 80, 443 | Proxy inverso Nginx (MACVLAN) |
| DMZ — odoo-web | `192.168.30.0/24` | `192.168.30.1` | **`192.168.30.21`** | 8069, 8072 | Aplicación Odoo 17 (MACVLAN) |
| LAN Clientes (VLAN 10) | `192.168.10.0/24` | `192.168.10.1` | `192.168.10.x` | — | Equipos de usuarios |
### Reglas Principales de Firewall (pfSense/UFW)
| Origen | Destino | Puertos | Acción | Propósito |
| :--- | :--- | :--- | :--- | :--- |
| WAN | DMZ (192.168.30.20) | 80, 443 | ✅ Permitir | Acceso web al ERP vía NAT → nginx MACVLAN |
| LAN (VLAN 10) | DMZ (192.168.30.20) | 443, 80 | ✅ Permitir | Clientes internos a Odoo |
| Admin LAN | DMZ (192.168.30.10) | 22, 9090 | ✅ Permitir | SSH y Cockpit (solo admin) |
| DMZ | LAN (VLAN 10) | * | ❌ Bloquear | Anti-pivoting |
| DMZ | pfSense (gestión) | 443, 80, 22 | ❌ Bloquear | Proteger panel del firewall |
---
## 🚀 Fases de Implantación
A continuación, se detalla la hoja de ruta seguida para la ejecución del proyecto:
### 1. Preparación de la Infraestructura
- Configuración del hipervisor (VMware/VirtualBox).
- Despliegue de pfSense con sus respectivas interfaces virtuales (Trunk/VLANs).
- Instalación del S.O. anfitrión único (**Debian 13 Server**) en la DMZ con direccionamiento IP estático e instalación de **Cockpit**.
### 2. Contenerización Completa (Docker / Nginx / Odoo)
- Instalación de `docker`, `docker-compose` y securización del daemon.
- Creación del fichero `docker-compose.yml` declarativo para instanciar Nginx, Odoo 17 y PostgreSQL 16 interactuando en su propia red de contenedores (`odoo_net`).
- Configuración de volúmenes persistentes localizados en `./data` y montajes vinculados para la configuración perimetral de `./config_nginx`.
- Inyección segura de credenciales mediante archivo `.env`.
### 3. Redes MACVLAN — Contenedores como Hosts de Red
> ✅ **Implementado en producción** (mayo 2026)
Se creó una red Docker de tipo `macvlan` vinculada a la interfaz física del servidor (`ens18`) en modo `bridge`, dando IPs reales de la VLAN30 a los contenedores expuestos:
```bash
# Creación de la red MACVLAN externa
docker network create \
  --driver macvlan \
  --subnet=192.168.30.0/24 \
  --gateway=192.168.30.1 \
  --opt parent=ens18 \
  macvlan_vlan30
```
**Asignación de IPs MACVLAN en `docker-compose.yml`:**
| Contenedor | Red interna (`odoo_net`) | Red MACVLAN (`macvlan_vlan30`) |
| :--- | :--- | :--- |
| `odoo_erp` (PostgreSQL) | 172.19.0.x | ❌ No expuesto (seguridad) |
| `odoo-web` (Odoo 17) | 172.19.0.3 | `192.168.30.21` |
| `nginx-proxy` (Nginx) | 172.19.0.4 | `192.168.30.20` |
**Ventajas de seguridad:**
- PostgreSQL **no tiene IP pública** → inaccesible desde pfSense o la LAN.
- pfSense puede aplicar reglas individuales por contenedor (granularidad de host).
- El host Debian actúa de servidor, no de NAT/gateway para el tráfico de los contenedores.
> **Nota técnica:** Con el driver `macvlan`, el host Debian **no puede comunicarse directamente** con las IPs MACVLAN de sus propios contenedores (limitación del kernel Linux). Para verificar conectividad desde el host se usa un contenedor temporal:
> `docker run --rm --network macvlan_vlan30 alpine wget -qO- https://192.168.30.20`
### 4. Automatización y Monitorización (DevOps)
- Desarrollo de *scripts* Bash para el ciclo de vida del ERP:
  - `install.sh` / `erp.sh`: Instalador todo-en-uno y orquestador centralizado de administración.
  - `deploy.sh`: Levantamiento automático de la infraestructura.
  - `backup.sh`: Volcados comprimidos seguros de PostgreSQL (`pg_dump -F c`).
  - `restore.sh`: Recuperación rápida ante desastres simulados.
  - `update.sh`: Carga de nuevas imágenes Docker y limpieza (`prune`) automatizada.
  - `monitor.sh`: Chequeo de salud de contenedores y detección de caídas.
- Programación de funciones PL/pgSQL y disparadores (`Triggers`) para auditar la creación de usuarios en la tabla `res_users` de Odoo, registrando eventos en `asir_audit_log`.
### 5. Capa de Presentación Segura (Nginx en Docker)
- Despliegue de Nginx como un contenedor Alpine dentro del stack en lugar de una instalación nativa en la DMZ.
- Configuración de proxy dinámico enviando tráfico HTTP/HTTPS hacia el contenedor backend de Odoo.
- Implementación de certificados SSL (autofirmados con OpenSSL) montados mediante volúmenes.
- Cabeceras de seguridad: WebSocket *upgrade*, `X-Forwarded-Proto`, `X-Real-IP`, `X-Forwarded-For`.
---
## 🧰 Stack Tecnológico
| Capa | Tecnología |
| :--- | :--- |
| Redes/Seguridad | pfSense (FreeBSD), UFW |
| Virtualización/Orquestación | Docker Engine, Docker Compose |
| Sistema Operativo Base | **Debian 13 Server (Trixie)** con Cockpit |
| Proxy Inverso | Nginx (Alpine Linux) — contenedor Docker con MACVLAN |
| ERP/CRM | Odoo 17 CE — contenedor Docker con MACVLAN |
| Base de Datos | PostgreSQL 16 — contenedor Docker (solo red interna) |
| Certificados | OpenSSL (autofirmados TLS) |
| Scripting | GNU Bash, ANSI SQL & PL/pgSQL |
| Control de Versiones | Git + GitHub |
| Integración Continua | GitHub Actions |
---
## 📚 Estructura de este Repositorio
> **🚀 Instalación desde cero: [`docs/INSTALACION_COMPLETA.md`](docs/INSTALACION_COMPLETA.md)**
| Directorio / Archivo | Descripción |
|:---------------------|:------------|
| `/docker/` | `docker-compose.yml`, `odoo.conf` y `.env` (excluido de Git) |
| `/scripts/` | Scripts Bash por categoría: `deploy/`, `odoo/`, `ldap/`, `mantenimiento/` |
| `/sql/` | Triggers PL/pgSQL para auditoría de base de datos |
| `/config_nginx/` | Configuración del proxy inverso Nginx con SSL y cabeceras de seguridad |
| `/ldap/` | Estructura base del directorio LDAP (`estructura.ldif`) |
| `/docs/` | Documentación técnica completa |
| `/docs/guias/` | Sub-guías por módulo: pfSense, Debian, Docker, Odoo, LDAP, CI/CD, Hardening |
| `/ISOs/` | Imágenes de instalación (Debian 13, pfSense 2.7.x) |
| `install.sh` | Instalador todo-en-uno |
---
## 👥 Reparto de Roles
| Integrante | Especialización |
| :--- | :--- |
| **Sandra Fradejas Avedillo** | Sistemas y Orquestación |
| **Mario García García** | Redes y Seguridad Perimetral |
| **Javier Córdoba Del Valle** | Bases de Datos y Automatización |
---
## ❓ ¿Por qué Odoo y no otra alternativa?
Antes de definir la arquitectura, se evaluó comparativamente con otras soluciones ERP de código abierto:
| Criterio | **Odoo 17** | Dolibarr | ERPNext |
| :--- | :--- | :--- | :--- |
| **Facilidad de uso** | ✅ Alta — interfaz moderna e intuitiva | Media — sencillo pero básico | Media — muy completo pero abrumador |
| **Flexibilidad de API** | ✅ Muy alta — XML-RPC y JSON-RPC | Limitada | Alta (API REST) pero compleja |
| **Consumo de recursos** | Moderado (requiere VM decente) | ✅ Muy ligero | Pesado |
| **Cobertura funcional** | ✅ CRM, Ventas, RRHH, Inventario, Proyectos | Básico | Muy completo |
| **Comunidad y soporte** | ✅ Muy activa, documentación extensa | Activa (menor escala) | Activa |
| **Idoneidad para el TFG** | ✅ **Elegido** | Descartado | Descartado |
**Conclusión**: Odoo es la opción que mejor equilibra facilidad de despliegue, cobertura funcional y capacidad de integración para el escenario de la empresa simulada "TechSolutions S.L."
---
## 🎓 Módulos Académicos Cubiertos (ASIR)
| Módulo | Contenido aplicado en este TFG |
| :--- | :--- |
| **Seguridad y Alta Disponibilidad** | Topología DMZ con pfSense, UFW en host, reglas de firewall, política default-deny, backups automatizados con retención |
| **Gestión de Bases de Datos** | Triggers PL/pgSQL con auditoría en formato JSONB, función `func_audit_users()`, tabla `asir_audit_log`, vista `v_audit_resumen` |
| **Servicios de Red** | Cabeceras de seguridad HTTP, DHCP en pfSense, NAT/Port Forwarding, DNS interno |
| **Redes** | Configuracion de VLANs (10/30), monitorizacion de la red y los paquetes, topologia de red|
| **Arquitectura de la Nube** | Creacion y uso de Dockers, proxy inverso Nginx con terminación SSL/TLS, redes MACVLAN Docker |
| **Administracion de Sistemas Operativos e Implementacion de sistemas operativos** | Creacion y gestion de servidor LDAP, creacion y uso de scripts bash para despliegue, backup, restauración y monitorización |
---
## 📖 Investigación y Bases Técnicas
El diseño de este proyecto se apoya en los siguientes recursos técnicos de referencia:
**Redes y Perímetro (pfSense)**
- Documentación Oficial de Netgate — Configuración VLAN: <https://docs.netgate.com/pfsense/en/latest/vlan/configuration.html>
- Docker Macvlan Network en Entornos DMZ: <https://vegard.blog.engen.priv.no/?p=364>
**Infraestructura y Hardening del Servidor**
- Lista de Verificación de Endurecimiento Linux en Producción (2026): <https://hostperl.com/blog/linux-server-hardening-checklist-essential-security-controls-production-2026>
- CIS Benchmark Validation (Linux Mint 22, base aplicable a Debian): <https://www.scribd.com/document/946643717/CIS-Linux-Mint-22-Benchmark-v1-0-0>
**Despliegue de Odoo y Nginx**
- Documentación Odoo 17 — Despliegue en Producción y Multiprocesamiento: <https://www.odoo.com/documentation/19.0/administration/on_premise/deploy.html>
- Proxy Inverso y Configuración SSL para Odoo: <https://oec.sh/guides/odoo-nginx-config>
**Bases de Datos y Auditoría (PostgreSQL)**
- Wiki Oficial PostgreSQL — Generic Audit Trigger (PL/pgSQL): <https://wiki.postgresql.org/wiki/Audit_trigger>
- Estrategias Completas de Backup y Recuperación (DR) en Odoo: <https://oec.sh/guides/odoo-backup-recovery>
---
## 🔮 Mejoras Futuras
Estas mejoras quedan fuera del alcance del TFG pero se documentan para demostrar conocimiento avanzado:
| Mejora | Descripción |
| :--- | :--- |
| **Ansible (IaC)** | Automatizar toda la configuración del servidor Debian con un Playbook de Ansible, eliminando la configuración manual. |
| **VPN WireGuard en pfSense** | Ocultar el ERP de Internet público, accesible solo desde la VLAN interna o a través de un túnel VPN cifrado. Diseño "Zero Trust". |
| **Stack de Monitorización** | Sustituir los scripts de log por Prometheus + Grafana o Uptime Kuma con panel gráfico de estado en tiempo real. |
| **Ldap / Active Directory** | Centralizar credenciales de usuarios usando Windows Server 2022 y LDAP como Controlador de Dominio, integrando Odoo con AD. |
```

### File: .\REALIZADO_PDF_PASOS.md
```md
REHALIZADO 
----------------------------------------------
- Acabar PDF
- Comprobar que todo lo del PDF funciona
- Hacer que los scripts los ejecute el GitHub
- GitHub compruebe si estan ejecutando o si se han ejecutado
----------------------------------------------
4. PASO A PASO
NO 	PASO 1 - Quitar LDAP del proyecto
SI --------- PASO 1A — docker/docker-compose.yml — eliminar el bloque completo de LDAP
SI --------- PASO 1B — .env.example — eliminar las variables de LDAP
NO ---------PASO 1C — Mover la carpeta ldap/
NO	PASO 2 - Separar PostgreSQL en VM propia (VLAN 40)
SI --------- PASO 2A - modificar docker/docker-compose.yml para que Odoo apunte a BDD externa 
SI --------- PASO 2B - Crear vagrant/provision_postgres.sh (para la VM de BDD)
NO	--------- PASO 2C -  Reglas en pfSense
NO	PASO 3 - Abrir accesos esterbos HTTPS
NO	PASO 4 - VPN para teletrabajo (OpenVPN en pfSense)
NO --------- PASO 4A - Crear la Autoridad Certi cadora
NO --------- PASO 4B - Crear el certi cado del servidor VPN
NO --------- PASO 4C -  Crear el servidor OpenVPN
NO --------- PASO 4D -  Regla de rewall para OpenVPN
NO --------- PASO 4E -  Crear un usuario VPN
NO --------- PASO 4F -  Exportar el fichero .ovpn
NO	PASO 5 - Automatizar VMs con Vagrant
NO --------- PASO 5A - Instalar en el PC (PowerShell como administrador)
NO --------- PASO 5B - Crear Vagrantfile en la raíz del repositorio
NO --------- PASO 5C -  Crear vagrant/provision_debian.sh
NO --------- PASO 5D -  Crear vagrant/provision_pfsense.sh
NO	PASO 6 - Activar CI/CD (instalar self-hosted runner)
NO --------- PASO 6A - Obtener token en GitHub
NO --------- PASO 6B - Ejecutar en el servidor Debian (servidor Odoo)
NO --------- PASO 6C -  Verifcar que el runner está conectado
NO --------- PASO 6D -  Probar el pipeline completo
NO	PASO 7 - Backups automáticos de PostgreSQL
NO --------- PASO 7A - Crear scripts/mantenimiento/backup_postgres.sh [Falta dar permisos con chmod +x]
NO --------- PASO 7B - Instalar el cron en el servidor
NO  PASO 8 — Veri cación nal completa
```

### File: .\SECURITY
```text
# 🛡️ Política de Seguridad
La seguridad es una prioridad en este proyecto de **Implantación Segura y Automatizada de Odoo**. Como este proyecto tiene un enfoque académico (TFG) y de pruebas de concepto (PoC) sobre automatización y hardening, me tomo muy en serio cualquier reporte sobre posibles vulnerabilidades en la configuración o en los scripts de despliegue.
## Versiones Soportadas
Actualmente, solo la rama principal (`main`) y las versiones etiquetadas más recientes reciben actualizaciones de seguridad.
| Versión | Soportada |
| ------- | ------------------ |
| v1.0.x  | ✅ Sí              |
| < v1.0  | ❌ No              |
## 🚨 Cómo reportar una vulnerabilidad
**Por favor, NO abras un "Issue" público para reportar fallos de seguridad.** Si descubres cualquier vulnerabilidad relacionada con la configuración de Docker, exposición de puertos, manejo de credenciales o cualquier otro vector de ataque dentro de este repositorio, te ruego que sigas este proceso:
1. Envía un correo electrónico directamente a: **sandrafradejas@gmail.com**.
2. En el asunto, incluye la etiqueta `[REPORTE DE SEGURIDAD - TFG Odoo]`.
3. Proporciona una descripción clara del problema, los pasos para reproducirlo y, si es posible, una sugerencia de mitigación.
### Tiempos de respuesta
Al ser un proyecto personal e individual, intentaré acusar recibo de tu correo en un plazo de **48 a 72 horas**. 
Una vez verificado el fallo, trabajaré en un parche (fix) y te daré el crédito correspondiente en las notas de la versión cuando la vulnerabilidad sea solucionada y publicada de forma segura.
¡Gracias por contribuir a mantener este entorno más seguro! 👩‍💻
```

### File: .\.github\workflows\ci.yml
```yml
name: CI Validator 
on:
  push:
    branches: [ "main" ]  
  pull_request:
    branches: [ "main" ]  
env:
  FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: true
jobs:
  validate:
    name: Syntax & Code Validation 
    runs-on: ubuntu-latest         
    steps:
      - name: Descargar el código
        uses: actions/checkout@v4 
      - name: Validar Sintaxis YAML de Docker
        run: |
          sudo apt-get install -y yamllint
          yamllint -d "{extends: relaxed, rules: {line-length: disable}}" docker/docker-compose.yml
        continue-on-error: true 
      - name: Validar Docker Compose estructuralmente
        run: |
          docker compose -f docker/docker-compose.yml config -q
      - name: Instalar ShellCheck
        run: sudo apt-get install -y shellcheck
      - name: Validar Scripts con ShellCheck
        run: |
          echo "Analizando todos los scripts de la carpeta scripts/ y la raíz..."
          shellcheck scripts/*/*.sh *.sh
      - name: Generar config.xml de pfSense
        run: |
          echo "Generando configuración pfSense desde el script..."
          bash scripts/deploy/generate_pfsense_config.sh
      - name: Validar XML de pfSense (xmllint)
        run: |
          sudo apt-get install -y libxml2-utils
          echo "Validando estructura XML..."
          xmllint --noout config/pfsense_config.xml
          echo "[OK] El config.xml de pfSense es válido."
      - name: Subir config.xml como artefacto
        uses: actions/upload-artifact@v4
        with:
          name: pfsense-config
          path: config/pfsense_config.xml
          retention-days: 30
      - name: Validar Markdown (Limpieza de sintaxis)
        uses: DavidAnson/markdownlint-cli2-action@v16 
        with:
          globs: "**/*.md"    
        continue-on-error: true 
```

### File: .\.github\workflows\deploy.yml
```yml
name: CD Deploy (Self-Hosted)
on:
  workflow_run:
    workflows: ["CI Validator"]
    types:
      - completed
    branches:
      - main
jobs:
  deploy:
    name: Desplegar Stack en Servidor Debian
    if: ${{ github.event.workflow_run.conclusion == 'success' }}
    runs-on: self-hosted
    steps:
      - name: Verificar entorno del servidor
        run: |
          echo "============================================="
          echo " Iniciando despliegue automático"
          echo " Servidor: $(hostname)"
          echo " Fecha:    $(date '+%Y-%m-%d %H:%M:%S')"
          echo " Docker:   $(docker --version)"
          echo "============================================="
      - name: Marcar directorio del proyecto como seguro para Git
        run: git config --global --add safe.directory /opt/erp-odoo
      - name: Sincronizar repositorio en el servidor (git pull)
        working-directory: /opt/erp-odoo
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          echo "Sincronizando repositorio con origin/main..."
          git remote set-url origin https://x-access-token:${GH_TOKEN}@github.com/${{ github.repository }}.git
          git fetch origin
          git reset --hard origin/main
          echo "Repositorio actualizado al commit: $(git rev-parse --short HEAD)"
      - name: Descargar imágenes Docker (docker pull)
        run: |
          echo "[1/3] Descargando imagen de PostgreSQL 16..."
          docker pull postgres:16 || echo "  [Aviso] No se pudo descargar postgres:16 (¿Firewall activo?). Se usará la imagen local."
          echo "[2/3] Descargando imagen de Odoo 17..."
          docker pull odoo:17 || echo "  [Aviso] No se pudo descargar odoo:17. Se usará la imagen local."
          echo "[3/3] Descargando imagen de Nginx Alpine..."
          docker pull nginx:alpine || echo "  [Aviso] No se pudo descargar nginx:alpine. Se usará la imagen local."
          echo "Todas las imágenes están actualizadas."
      - name: Ejecutar deploy.sh
        working-directory: /opt/erp-odoo
        run: |
          echo "Ejecutando script de despliegue..."
          bash scripts/deploy/deploy.sh
      - name: Verificar contenedores y levantar si están caídos
        working-directory: /opt/erp-odoo
        run: |
          echo "============================================="
          echo " Comprobando estado de los contenedores..."
          echo "============================================="
          COMPOSE_FILE="docker/docker-compose.yml"
          CONTENEDORES=("odoo_erp" "odoo-web" "nginx-proxy")
          ALGUNO_CAIDO=false
          for CONTENEDOR in "${CONTENEDORES[@]}"; do
            STATUS=$(docker inspect --format='{{.State.Status}}' "$CONTENEDOR" 2>/dev/null || echo "no_existe")
            if [ "$STATUS" = "running" ]; then
              echo "  [OK]     $CONTENEDOR → running"
            elif [ "$STATUS" = "no_existe" ]; then
              echo "  [FALTA]  $CONTENEDOR → no existe"
              ALGUNO_CAIDO=true
            else
              echo "  [CAÍDO]  $CONTENEDOR → $STATUS"
              ALGUNO_CAIDO=true
            fi
          done
          if [ "$ALGUNO_CAIDO" = "true" ]; then
            echo ""
            echo "  Contenedores caídos o ausentes detectados."
            echo "  Levantando stack completo con docker compose up..."
            docker compose -f "$COMPOSE_FILE" up -d
            echo ""
            echo "  Esperando 15 segundos para que los servicios arranquen..."
            sleep 15
            echo ""
            echo "  Segunda verificación tras el arranque:"
            for CONTENEDOR in "${CONTENEDORES[@]}"; do
              STATUS=$(docker inspect --format='{{.State.Status}}' "$CONTENEDOR" 2>/dev/null || echo "no_existe")
              if [ "$STATUS" = "running" ]; then
                echo "  [OK]     $CONTENEDOR → running"
              else
                echo "  [ERROR]  $CONTENEDOR → $STATUS  ← revisar logs"
              fi
            done
          else
            echo ""
            echo "  Todos los contenedores están corriendo. No se necesita acción."
          fi
      - name: Estado final del stack
        working-directory: /opt/erp-odoo
        run: |
          echo "============================================="
          echo " Estado final de los contenedores:"
          echo "============================================="
          docker compose -f docker/docker-compose.yml ps
          echo ""
          echo "  Health check de Odoo:"
          curl -sk https://localhost/web/health 2>/dev/null \
            && echo "  [OK] Odoo responde correctamente" \
            || echo "  [AVISO] Odoo aún no responde (puede necesitar más tiempo)"
          echo ""
          echo "[OK] Despliegue completado."
```

### File: .\config\logrotate.d\erp-odoo
```text
/var/log/erp_*.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
    create 0750 root root
}
```

### File: .\config_nginx\odoo_proxy.conf
```conf
server {
    listen 80;                         
    server_name erp.odoo.tfg.com;
    return 301 https://$host$request_uri;
}
server {
    listen 443 ssl;                     
    server_name erp.odoo.tfg.com;
    ssl_certificate /etc/ssl/certs_local/server.crt;
    ssl_certificate_key /etc/ssl/certs_local/server.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers HIGH:!aNULL:!MD5;
    access_log /var/log/nginx/odoo_access.log;
    error_log /var/log/nginx/odoo_error.log;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options SAMEORIGIN always;
    add_header X-Content-Type-Options nosniff always;
    add_header Referrer-Policy "strict-origin" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; font-src 'self' data:; connect-src 'self' wss:; frame-ancestors 'self';" always;
    client_max_body_size 100M;
    location ~* ^/web/database {
        allow 192.168.40.0/24;
        deny all;
        proxy_pass http://odoo-web:8069;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 720s;
    }
    location ~* ^/odoo/action-base_setup {
        allow 192.168.40.0/24;
        deny all;
        proxy_pass http://odoo-web:8069;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 720s;
    }
    location /web/tests {
        deny all;
        return 403 "Acceso restringido.";
    }
    location ~* /web\?debug= {
        allow 192.168.40.0/24;
        deny all;
        proxy_pass http://odoo-web:8069;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    location / {
        proxy_pass http://odoo-web:8069;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 720s;   
        proxy_connect_timeout 720s;
        proxy_send_timeout 720s;   
    }
    location /longpolling/ {
        proxy_pass http://odoo-web:8072;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### File: .\docker\.env
```text
# ============================================================
# ARCHIVO: .env (Archivo de Variables de Entorno Secretas)
# DESCRIPCIÓN: Guarda todas las contraseñas y configuraciones
#              sensibles del proyecto FUERA del código fuente.
#
# ⚠️  ADVERTENCIA CRÍTICA DE SEGURIDAD:
#    Este archivo NUNCA debe subirse a GitHub.
#    Está incluido en el .gitignore para protegerlo.
#    Si alguien lo consigue podría acceder a la base de datos.
#
# CÓMO FUNCIONA: Docker Compose lee este archivo automáticamente
#    si está en la misma carpeta que el docker-compose.yml.
#    Las variables se inyectan en los contenedores en el arranque.
# ============================================================
# --- CREDENCIALES DE POSTGRESQL ---
# Usuario administrador de la base de datos de Odoo
POSTGRES_USER=odoo
# Contraseña del usuario de base de datos.
# En producción real, cambiar por una contraseña de alta entropía (ej: generada con: openssl rand -base64 32)
POSTGRES_PASSWORD=SuperSecretAdminPassword123
# Nombre de la base de datos que PostgreSQL creará automáticamente al arrancar por primera vez
POSTGRES_DB=odoo_erp
# --- CREDENCIALES DE ODOO ---
# Contraseña maestra de Odoo (Master Password).
# Se usa para poder crear, eliminar o restaurar bases de datos desde el navegador web.
# Si alguien la conoce, puede borrar toda la BD desde la interfaz gráfica.
ODOO_MASTER_PASSWORD=MasterSuperSecretPassword123
```

### File: .\docker\docker-compose.yml
```yml
services:
  odoo:
    image: odoo:17
    container_name: odoo-web
    restart: always
    environment:
      - HOST=192.168.40.10 
      - USER=odoo
      - PASSWORD=${POSTGRES_PASSWORD}
    user: "101:101"
    volumes:
      - ../addons:/mnt/extra-addons
      - ../odoo-data:/var/lib/odoo
      - ./odoo.conf:/etc/odoo/odoo.conf
      - ../odoo_sessions:/tmp/odoo
    healthcheck:
      test: [ "CMD", "curl", "-f", "http://localhost:8069/web/health" ]
      interval: 30s
      timeout: 10s
      retries: 6
      start_period: 90s
    networks:
      odoo_net:
      macvlan_vlan30:
        ipv4_address: 192.168.30.21
  nginx:
    image: nginx:alpine
    container_name: nginx-proxy
    restart: always
    depends_on:
      - odoo
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ../config_nginx:/etc/nginx/conf.d
      - ../certs:/etc/ssl/certs_local
    healthcheck:
      test: [ "CMD-SHELL", "nginx -t" ]
      interval: 30s
      timeout: 5s
      retries: 3
    networks:
      odoo_net:
      macvlan_vlan30:
        ipv4_address: 192.168.30.20
networks:
  odoo_net:
    driver: bridge
  macvlan_vlan30:
    external: true
```

### File: .\docker\odoo.conf
```conf
[options]
; ============================================================
; ARCHIVO DE CONFIGURACIÓN DE ODOO (odoo.conf)
; DESCRIPCIÓN: Ajustes del servidor Odoo. Este archivo se
;              monta dentro del contenedor "odoo-web" mediante
;              un volumen definido en docker-compose.yml.
; ============================================================
; --- SECCIÓN 1: CONEXIÓN A LA BASE DE DATOS ---
; La configuración de conexión a la base de datos (host, puerto, usuario y contraseña)
; se pasa a través de las variables de entorno en docker-compose.yml
; (HOST, USER, PASSWORD) para que sea más seguro y no esté hardcodeado aquí.
db_host = db
db_user = odoo
addons_path = /usr/lib/python3/dist-packages/odoo/addons,/mnt/extra-addons
session_dir = /var/lib/odoo/sessions
; --- SECCIÓN 2: MODO PROXY (EL AJUSTE MÁS IMPORTANTE) ---
; proxy_mode = True le dice a Odoo que hay un Proxy Inverso (Nginx) delante de él.
; Sin esta opción, Odoo genera URLs internas con "http://" en lugar de "https://"
; lo que causa errores de "contenido mixto" en el navegador del usuario.
; ¡Con Nginx como proxy SSL, esta línea es OBLIGATORIA para que Odoo funcione!
proxy_mode = True
; --- SECCIÓN 3: LÍMITES DE RENDIMIENTO (Para el Servidor Virtual) ---
; Máxima memoria RAM que puede usar un proceso de Odoo antes de ser terminado (hard limit)
; Valor: 2.5 GB en bytes (2684354560 = 2.5 * 1024 * 1024 * 1024)
limit_memory_hard = 2684354560
; Memoria sugerida para que un proceso de Odoo libere memoria voluntariamente (soft limit)
; Valor: 2 GB en bytes
limit_memory_soft = 2147483648
; Número máximo de peticiones que un proceso worker puede atender antes de reiniciarse
; (Sirve para prevenir fugas de memoria lentas en Odoo)
limit_request = 8192
; Tiempo máximo de CPU (en segundos) que puede consumir una sola petición
; Evita que un informe o cálculo pesado bloquee el servidor
limit_time_cpu = 600
; Tiempo máximo real (en segundos) para completar una petición de cliente
; Si es mayor que esto, Odoo devuelve un error de timeout en lugar de congelarse
limit_time_real = 1200
; Número de procesos worker que Odoo lanza para atender peticiones en paralelo.
; Fórmula recomendada por la documentación oficial de Odoo 17 (producción):
;   workers = (núcleos_CPU × 2) + 1
; Para una VM del TFG con 2 cores: workers = (2 × 2) + 1 = 5
; En entornos con poca RAM, se puede bajar a 2 si hay problemas de memoria.
; Fuente: https://www.odoo.com/documentation/17.0/administration/on_premise/deploy.html
workers = 2
; Puerto interno para conexiones de Longpolling (chat en tiempo real, LiveChat y Discuss).
; Nginx reenvía las peticiones /longpolling/ a este puerto (ver config_nginx/odoo_proxy.conf).
; Sin esta opción, el chat en tiempo real no funcionaría correctamente.
gevent_port = 8072
; Número máximo de hilos dedicados a tareas programadas (cron jobs de Odoo).
; Con 1 thread se evita que los cron jobs compitan con los workers de peticiones web.
max_cron_threads = 1
```

### File: .\docs\05
```text
# Diario de Sesión — 12 Mayo 2026
## Resolución de incidencias: VMware + OpenLDAP
---
## 1. Error de arranque VMware Workstation
**Síntoma:** Al intentar iniciar las VMs aparecía el error:
> "Failed to connect pipe to virtual machine: Todas las instancias de canalización están en uso"
**Causa:** Procesos VMX anteriores seguían activos ocupando los pipes.
**Solución:** Ejecutar en PowerShell como administrador:
```powershell
Get-Process vmware* | Stop-Process -Force
Get-Process vmnetdhcp | Stop-Process -Force
```
Resultado: VMware abrió correctamente y las VMs aparecieron en estado suspendido.
---
## 2. Arranque ordenado de las VMs
Orden correcto de arranque:
1. **pfSense** (router/firewall)
2. **Debian** (servidor Odoo + Docker)
3. **Lubuntu** (cliente)
---
## 3. Contenedor OpenLDAP en estado Restarting
**Síntoma:** `sudo docker ps` mostraba `openldap` en `Restarting (1)`.
**Causa raíz detectada progresivamente:**
### 3.1 — El stack de Docker no estaba levantado
```bash
cd /opt/erp-odoo/docker
sudo docker compose up -d
```
### 3.2 — Fichero LDIF montado como read-only
**Error en logs:**
chown: changing ownership of '/container/service/slapd/assets/config/bootstrap/ldif/custom/estructura.ldif': Read-only file system
text
**Causa:** El `docker-compose.yml` montaba el fichero con `:ro`.
**Solución:** Eliminar `:ro` del volumen:
```yaml
# Antes:
- ../ldap/estructura.ldif:/container/service/.../estructura.ldif:ro
# Después:
- ../ldap/estructura.ldif:/container/service/.../estructura.ldif
```
Comando usado para editar:
```bash
sudo sed -i 's|estructura.ldif:ro|estructura.ldif|g' /opt/erp-odoo/docker/docker-compose.yml
```
### 3.3 — TLS habilitado sin certificados
**Error en logs:**
sed: can't read /container/service/slapd/assets/config/tls/tls-enable.ldif: No such file or directory
text
**Solución:** Añadir `LDAP_TLS: "false"` al `environment` del servicio en `docker-compose.yml`.
### 3.4 — Volúmenes con estado TLS previo (bloqueando LDAP_TLS=false)
**Error en logs:**
WARNING: LDAP_TLS=false but the container was previously started with LDAP_TLS=true. TLS can't be disabled once added.
text
**Solución:** Limpiar los volúmenes persistentes y reiniciar desde cero:
```bash
sudo docker stop openldap && sudo docker rm openldap
sudo rm -rf /opt/erp-odoo/ldap_data/* /opt/erp-odoo/ldap_config/*
sudo docker compose -f /opt/erp-odoo/docker/docker-compose.yml up -d
```
> ⚠️ Los datos LDAP se recrean automáticamente desde `estructura.ldif` al arrancar.
### 3.5 — Variable LDAP_READONLY_PASSWORD no definida
**Síntoma:** Warning al hacer `docker compose up`:
WARN: The "LDAP_READONLY_PASSWORD" variable is not set. Defaulting to a blank string.
text
**Solución:**
```bash
echo "LDAP_READONLY_PASSWORD=ReadOnly123" >> /opt/erp-odoo/docker/.env
```
---
## Estado final de la sesión
| Contenedor     | Estado  |
|----------------|---------|
| `odoo_erp`     | Healthy |
| `odoo-web`     | Healthy |
| `nginx-proxy`  | Healthy |
| `openldap`     | **Up** ✅ |
---
## Próximos pasos pendientes
- [ ] Verificar que LDAP responde con `ldapsearch`
- [ ] Configurar servidor LDAP en pfSense (System > User Manager > Authentication Servers)
- [ ] Probar autenticación en **Diagnostics > Authentication**
- [ ] Confirmar que pfSense muestra `member of groups: admin`
```

### File: .\docs\CHANGELOG.md
```md
# Changelog
Todos los cambios notables del proyecto se documentan en este archivo.
Formato: [Keep a Changelog](https://keepachangelog.com/es/1.1.0/).
---
## [Sin publicar]
### En progreso
- Hardening final: Debian headless + SSH por clave pública
- Capturas de pantalla para la memoria del TFG
- Redacción de la memoria del TFG
### Añadido
- **Automatización de la configuración de pfSense** (`scripts/deploy/generate_pfsense_config.sh`):
  Script Bash que genera un `config.xml` completo con todas las interfaces (WAN, LAN, OPT1/DMZ,
  OPT2/VLAN_ADMIN), DHCP, DNS Resolver con Host Override, NAT Port Forward, aliases y las 30+
  reglas de firewall del proyecto. Importable vía **Diagnostics → Backup/Restore**.
- **Integración CI para pfSense** (`.github/workflows/ci.yml`):
  El pipeline ahora genera el `config.xml`, lo valida con `xmllint` y lo sube como **artefacto
  descargable** desde GitHub Actions (retención 30 días). Permite obtener una configuración
  validada sin ejecutar nada localmente.
### Modificado
- **Sistema operativo del servidor:** Cambiado de **Debian 12 (Bookworm)** a **Debian 13 (Trixie)**.
  - La instalación de Docker cambia de `docker.io` (paquete Debian) al repositorio oficial de Docker CE (`docker-ce`, `containerd.io`, `docker-compose-plugin`).
  - La codename del repositorio de Docker pasa de `bookworm` a `trixie`.
  - Configuración de red compatible: `systemd-networkd` (por defecto en Trixie) o `NetworkManager` (`nmcli`/`nmtui`).
  - El resto de la infraestructura (pfSense, Docker stack, LDAP, Nginx) **no cambia**.
---
## [v1.6 — 2026-05-13]
### Añadido
- **Guía maestra de instalación desde cero** (`docs/INSTALACION_COMPLETA.md`):
  Punto de entrada único que documenta las 8 fases de instalación con secciones de resumen,
  comandos clave, checklist de verificación final y orden de arranque.
- **Sub-guías por módulo** en `docs/guias/`:
  - `01_PFSENSE_INSTALACION.md` — VM, interfaces, DHCP, DNS, NAT, todas las reglas de firewall, LDAP auth en panel
  - `02_DEBIAN_PREPARACION.md` — IP estática, Docker, Cockpit, clonación del repo, `.env`
  - `03_DOCKER_STACK.md` — Red MACVLAN, SSL, `docker compose up`, troubleshooting
  - `04_ODOO_CONFIGURACION.md` — Post-instalación, módulos, conexión LDAP, usuarios por rol, auditoría SQL
  - `05_LDAP_INSTALACION.md` — Estructura LDAP, ACLs, usuarios, SSSD+PAM en clientes Linux
  - `07_CICD_GITHUB.md` — Self-hosted runner, pipeline CI/CD, permisos `.env`
  - `08_HARDENING_FINAL.md` — UFW, SSH con claves, headless, checklist final
- **`docs/diagrama_red.md`** completamente reescrito con:
  - Diagrama Mermaid actualizado con VLAN 40, MACVLAN e IPs reales
  - Tabla de direccionamiento IP completa
  - Diagrama de zonas de seguridad y anti-pivoting
  - Flujo de autenticación de un empleado
  - Esquema de la red Docker interna
- **`docs/GESTION_REPOSITORIO.md`** actualizado con:
  - Árbol de estructura real del repositorio
  - Flujo GitOps con reglas claras
  - Tabla de cuándo actualizar cada documento
  - Nomenclatura para capturas de pantalla
- **`docs/github_issues.md`** ampliado con:
  - Issue para control de acceso por roles (3 capas)
  - Issue para securización del panel pfSense con LDAP
  - Referencias a los nuevos documentos en cada plantilla
  - Separación clara de labels sugeridos
### Modificado
- `docs/GUIA_DESPLIEGUE.md` — Añadido redirect prominente a `INSTALACION_COMPLETA.md`
---
## [v1.5 — 2026-05-09]
### Añadido
- **Archivado de documentación histórica:** Documentos de planificación original
  movidos a `docs/archive/` para mantener la raíz limpia.
- **Historial consolidado:** Planes pendientes e IaC fusionados en `HISTORIAL_IMPLEMENTACION.md`.
- **Organización de scripts:** Subcarpetas `deploy/`, `odoo/`, `ldap/`, `mantenimiento/`
  creadas en `scripts/` e indexadas en `scripts/README.md`.
- **Plantillas GitHub Issues** actualizadas para los hitos finales de infraestructura.
- **VLAN 40 (red de administración):** Configurada en pfSense (OPT2, `192.168.40.1/24`).
  Reglas: panel pfSense + SSH + Cockpit + LDAP admin + Odoo admin, sin acceso a VLAN 10.
- **LDAP como autenticador del panel pfSense:** Solo el grupo `admin` tiene privilegio
  `WebCfg - All pages`. El usuario `dba` es rechazado.
- **SSSD + PAM en clientes VLAN 10:** Script `configurar_cliente_ldap.sh` —
  login en PC Linux con credencial LDAP centralizada.
- **ACLs LDAP:** Script `ldap_politica_acceso.sh` — modelo de mínimo privilegio.
  Técnico solo puede cambiar contraseñas; readonly solo puede leer.
- **Control de acceso en 3 capas:** Nginx (rutas por VLAN) + Odoo tipo usuario + Odoo grupos por rol.
  Documentado en `CONTROL_ACCESO.md`.
---
## [v1.4 — 2026-05-06]
### Corregido
- **Pipeline CD — base de datos Odoo no inicializada:**
  El job `Desplegar Stack en Servidor Debian` fallaba de forma repetida (5+ ejecuciones).
  **Causa raíz:** El archivo `.env` no existía en el servidor. Sin variables de entorno,
  Odoo no podía conectarse a PostgreSQL y la base de datos quedaba sin inicializar.
  Error en cascada:
  ```
  ERROR: relation "ir_module_module" does not exist
  KeyError: 'ir.http'
  GET /web/health HTTP/1.1" 500
  ```
  **Solución:**
  1. `docker compose down`
  2. `sudo rm -rf postgres-data/pgdata` y `sudo rm -rf odoo-data/filestore`
  3. Recrear `.env` con credenciales correctas
  4. `docker compose up -d` → primer healthcheck 200 OK a las 18:08:12 UTC ✅
  **Prevención:** El `.env` debe crearse manualmente durante la instalación inicial
  (ver `.env.example` y `docs/guias/02_DEBIAN_PREPARACION.md`).
---
## [v1.3 — 2026-04-30]
### Añadido
- **Pipeline CI/CD completamente operativo** en el servidor Debian de la DMZ:
  - Runner `debian` instalado como servicio systemd en `/opt/actions-runner`
  - Versión del agente: `2.334.0` (SHA256 verificado)
  - Servicio: `actions.runner.sandrafrv-...debian.service` (enabled en systemd)
  - Stack Docker desplegado automáticamente tras push a `main`
  - 4 contenedores (`odoo_erp`, `odoo-web`, `openldap`, `nginx-proxy`) en estado `healthy`
### Corregido
- **`deploy.sh` — comprobación de puertos 80/443:**
  `ss -tlnp` sin root no muestra el proceso propietario. El script fallaba
  aunque los puertos fueran del propio `nginx-proxy`.
  **Solución:** Comprobar con `docker ps` si `nginx-proxy` está corriendo antes de
  considerar que hay un conflicto real de puertos.
- **`deploy.sh` — permisos de `.env`:**
  `.env` con permisos `600` (solo root) — el runner como usuario `server` no podía leerlo.
  **Solución:** `sudo chown root:server docker/.env && sudo chmod 640 docker/.env`
- **`deploy.yml` — `dubious ownership` en git:**
  `/opt/erp-odoo` creado por `root` pero el runner corre como `server`.
  **Solución:** `git config --global --add safe.directory /opt/erp-odoo`
  + `sudo chown -R server:server /opt/erp-odoo`
---
## [v1.2 — 2026-04-30]
### Añadido
- **Auditoría PL/pgSQL ejecutada y validada en producción:**
  - Tabla `asir_audit_log` con campo JSONB `row_data`
  - Vista `v_audit_resumen` con `login` y `name` extraídos del JSONB
  - Validación: creación de usuario en Odoo → `audit_id=1, CREACION_USUARIO, res_users, id=8` ✅
### Corregido
- Nombre del contenedor PostgreSQL: `odoo-db` → `odoo_erp` (real en `docker-compose.yml`).
  Corregido en `backup.sh`, `restore.sh`, `monitor.sh` y documentación.
---
## [v1.1 — 2026-04-30]
### Añadido
- `install.sh` — Instalador todo-en-uno (dependencias + Docker + Cockpit + SSL + cron)
- `.env.example` + `scripts/deploy/configure.sh` — Plantilla pública y configurador interactivo
- `scripts/deploy/erp.sh` — Orquestador central con menú interactivo
- `config/logrotate.d/erp-odoo` — Rotación semanal de logs
- `scripts/deploy/install_cron.sh` — Instalador de tareas cron automatizadas
### Modificado
- `docker/docker-compose.yml` — Healthchecks nativos para PostgreSQL, Odoo y Nginx.
  `depends_on` con condición `service_healthy`. Rutas de volúmenes corregidas a `../`.
- `docker/odoo.conf` — `longpolling_port` → `gevent_port` (deprecado en Odoo 17)
- `config_nginx/odoo_proxy.conf` — Rutas de certificados SSL sincronizadas con `install.sh`
### Corregido
- `Permission denied` en `/var/lib/odoo/.local` → rutas de volúmenes relativas corregidas
- Bucle de reinicio en Nginx → nombres de certificados SSL sincronizados
- Error de inicialización de Odoo → primer arranque con `docker compose run --rm`
---
## [v1.0 — 2026-04-29]
### Añadido
- `docker/docker-compose.yml` — Stack inicial: `odoo_erp` (PostgreSQL 16), `odoo-web` (Odoo 17 CE),
  `nginx-proxy` (Nginx Alpine). Red bridge `odoo_net`. Solo Nginx expone puertos.
- `docker/odoo.conf` — `proxy_mode = True`, `workers = 2`, `gevent_port = 8072`, `limit_time_real = 1200`
- `config_nginx/odoo_proxy.conf` — Proxy inverso HTTPS con TLSv1.2/1.3, HSTS, X-Frame-Options,
  timeouts 720s y bloque `/longpolling/` para WebSocket
- `scripts/deploy/deploy.sh` — Despliegue con espera de healthcheck
- `scripts/mantenimiento/backup.sh` — `pg_dump -F c` con retención 7 días
- `scripts/mantenimiento/restore.sh` — Restauración limpia con borrado previo de BD
- `scripts/mantenimiento/update.sh` — `docker compose pull` + `image prune`
- `scripts/mantenimiento/monitor.sh` — Chequeo de contenedores con auto-reinicio
- `sql/audit_triggers.sql` — Tabla `asir_audit_log`, función `func_audit_users()`,
  trigger `trg_audit_new_odoo_user` en `res_users`
- `.github/workflows/ci.yml` — CI: ShellCheck + YAML lint + Markdownlint
- `docs/reglas_pfsense.md` — Documentación de reglas pfSense
- `docs/github_issues.md` — Plantillas de GitHub Issues
- `CLAUDE.md` — Skill de documentación para el asistente IA
```

### File: .\docs\CONTROL_ACCESO.md
```md
# Control de Acceso por Roles — TFG ASIR 2025/2026
**TechSolutions S.L.** | Modelo de seguridad en 3 capas + LDAP centralizado
---
## Arquitectura de Red y Acceso
```
Internet / WAN
      │
  [pfSense]
  ├── VLAN 10 (192.168.10.0/24) ── Usuarios del ERP
  ├── VLAN 40 (192.168.40.0/24) ── Admin + DBA (gestión del servidor)
  └── VLAN 30 (192.168.30.0/24) ── DMZ
        ├── .10 → Debian 13 Host  (Docker engine, SSH, Cockpit :9090)
        ├── .20 → nginx-proxy     (MACVLAN — puerta de entrada HTTPS)
        ├── .21 → odoo-web        (MACVLAN — aplicación Odoo 17)
        └── .22 → openldap        (MACVLAN — directorio de usuarios)
```
### Principio de acceso por VLAN
| VLAN | Quién | Puede acceder a |
|------|-------|-----------------|
| **VLAN 10** | Usuarios/empleados de TechSolutions | PC de trabajo (login SO vía LDAP) + Odoo ERP (vía nginx .20) |
| **VLAN 40** | Administradores del sistema, DBAs | Servidor (SSH :22, Cockpit :9090), panel BD Odoo, LDAP admin |
| **WAN** | Internet público | Solo login Odoo (HTTPS 443) |
---
## Inicio de Sesión en el Sistema Operativo (SSSD + PAM + NSS)
Script: `scripts/configurar_cliente_ldap.sh` — **ejecutar en cada PC de VLAN 10**
### Qué permite esto
Que un empleado use **el mismo usuario y contraseña LDAP** para:
1. Iniciar sesión en su PC (login de escritorio Linux)
2. Entrar a Odoo desde el navegador
Una sola cuenta centralizada → un cambio de contraseña en LDAP actualiza ambos accesos.
### Tecnología: SSSD
**SSSD** (System Security Services Daemon) es el intermediario entre el sistema operativo y el servidor LDAP. Reemplaza los paquetes antiguos `libnss-ldap` + `libpam-ldap` con ventajas importantes:
| Característica | SSSD |
|----------------|------|
| **Caché offline** | ✅ El usuario puede iniciar sesión aunque el LDAP esté caído temporalmente |
| **NSS** | ✅ Resuelve `getent passwd`, `getent group` desde LDAP |
| **PAM** | ✅ Gestiona autenticación en login, sudo, screensaver, etc. |
| **Home automático** | ✅ Crea `/home/<uid>` en el primer inicio de sesión |
| **Seguridad** | ✅ Las credenciales no viajan en claro internamente |
### Flujo completo de login en el PC
```
Empleado escribe uid + contraseña en el login del PC
                │
    ┌───────────▼──────────────┐
    │  PAM (pam_sss.so)        │  ← Intercepta el intento de login
    └───────────┬──────────────┘
                │ Pregunta a SSSD
    ┌───────────▼──────────────┐
    │  SSSD                    │  ← ¿Tengo la respuesta en caché?
    │  (System Security Svc)   │       SÍ → responde directamente
    └───────────┬──────────────┘       NO → consulta al LDAP
                │ Consulta (ldap://192.168.30.22:389)
    ┌───────────▼──────────────┐
    │  OpenLDAP (.22)          │  ← Verifica uid + contraseña
    │  cn=readonly busca user  │      en ou=usuarios,dc=tfg,dc=com
    └───────────┬──────────────┘
                │ Respuesta: OK / FAIL
    ┌───────────▼──────────────┐
    │  SSSD → PAM → Login      │  ← Si OK: abre sesión
    │  pam_mkhomedir           │      crea /home/<uid> si no existe
    └──────────────────────────┘
```
### Instalación en un cliente (una sola vez por máquina)
```bash
# Ejecutar como root en el PC de VLAN 10
sudo bash /opt/erp-odoo/scripts/configurar_cliente_ldap.sh
# El script pide:
#   1. URI del servidor LDAP (defecto: ldap://192.168.30.22)
#   2. Base DN (defecto: dc=tfg,dc=com)
#   3. Contraseña del usuario readonly
#   4. (Opcional) Grupo LDAP que puede iniciar sesión en este PC
```
### Restricción de acceso por grupo (opcional)
Se puede limitar qué grupo LDAP puede iniciar sesión en un PC concreto:
```bash
# Solo el grupo "ventas" puede iniciar sesión en los PCs de ventas
# (el script pregunta esto durante la instalación)
Grupo de acceso: ventas
# En /etc/sssd/sssd.conf queda:
ldap_access_filter = (&(objectClass=posixAccount)(memberOf=cn=ventas,ou=grupos,dc=tfg,dc=com))
```
Esto permite, por ejemplo:
- Los PCs del almacén solo los usa el grupo `almacen` y `jefe_almacen`
- Los PCs de dirección los usa solo `jefe_ventas`, `jefe_rrhh`, `jefe_almacen`
- Los becarios solo pueden entrar en los PCs designados para ellos
### Permisos Linux de cada grupo en el PC
Una vez dentro del sistema, los permisos locales del PC se controlan con grupos POSIX. Para que un grupo LDAP tenga `sudo` en una máquina, añadir en `/etc/sudoers.d/ldap_grupos`:
```bash
# Solo el grupo admin de LDAP puede hacer sudo completo
%admin ALL=(ALL:ALL) ALL
# El grupo tecnico puede reiniciar servicios sin contraseña
%tecnico ALL=(ALL) NOPASSWD: /bin/systemctl restart *, /bin/systemctl status *
```
### Verificar que funciona
```bash
# Ver si el sistema resuelve usuarios de LDAP
getent passwd <uid_del_usuario>
# Resultado esperado: uid:x:2001:2000:Nombre Completo:/home/uid:/bin/bash
# Probar autenticación sin hacer login gráfico
su - <uid_del_usuario>
# Pedirá la contraseña LDAP y abrirá una shell
# Ver los grupos LDAP disponibles en el sistema
getent group
# Ver logs de SSSD en tiempo real (útil para depurar)
journalctl -u sssd -f
# Forzar a SSSD a limpiar su caché y reconectar con el LDAP
sss_cache -E && systemctl restart sssd
```
### Qué pasa si el servidor LDAP cae
Con `cache_credentials = true` en SSSD:
- Si el usuario ya inició sesión antes → puede seguir iniciando sesión hasta que expire la caché (1 hora por defecto)
- Si nunca inició sesión → no puede entrar hasta que el LDAP vuelva
```bash
# Ver cuánto tiempo lleva SSSD sin contactar el servidor
sssctl domain-status tfg.com
```
### Limitación actual: Equipos Windows
El diseño actual con **OpenLDAP estándar** permite el inicio de sesión nativo en clientes Linux (mediante SSSD). Sin embargo, **Windows no admite OpenLDAP directamente** para el inicio de sesión del sistema operativo. 
En la infraestructura actual, si se conecta un PC Windows a la VLAN 10:
- El inicio de sesión en el PC Windows debe realizarse con una **cuenta local**.
- El acceso al ERP (`https://erp.odoo.tfg.com`) en el navegador **sí** utilizará las credenciales de LDAP.
> [!TIP]
> **Mejora Futura: Integración de Active Directory (Samba 4)**
> Para permitir que los equipos Windows se unan al dominio y utilicen las cuentas de red para el inicio de sesión del sistema operativo, se propone como futura mejora **sustituir OpenLDAP por Samba 4 AD DC**. 
> Samba 4 proporciona compatibilidad nativa con Active Directory, lo que permite centralizar completamente la gestión tanto de clientes Linux (SSSD con el proveedor `ad`) como de clientes Windows, además de proporcionar servicios de DNS requeridos por AD y autenticación mediante Kerberos.
---
## Las 3 Capas de Seguridad
El modelo aplica **defensa en profundidad**: aunque una capa falle, las otras siguen protegiendo.
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
---
## Capa C — Nginx: Restricción de Rutas por VLAN
Archivo: `config_nginx/odoo_proxy.conf`
### Rutas restringidas
| Ruta | Permitido desde | Bloqueado para | Riesgo sin restricción |
|------|----------------|----------------|----------------------|
| `/web/database/manager` | Solo VLAN 40 | VLAN 10 + WAN | Borrar/crear bases de datos |
| `/web/database/selector` | Solo VLAN 40 | VLAN 10 + WAN | Exposición de nombres de BD |
| `/odoo/action-base_setup` | Solo VLAN 40 | VLAN 10 + WAN | Reconfigurar Odoo desde cero |
| `/web/tests` | Nadie | Todos | Exposición de estructura interna |
| `/web?debug=` | Solo VLAN 40 | VLAN 10 + WAN | Información técnica del sistema |
### Verificar desde línea de comandos
```bash
# Desde VLAN 10 — debe devolver 403 Forbidden
curl -k https://erp.odoo.tfg.com/web/database/manager
# Resultado esperado: 403 Forbidden
# Desde VLAN 40 — debe cargar el panel
curl -k https://erp.odoo.tfg.com/web/database/manager
# Resultado esperado: 200 OK (panel de administración de BD)
# Tests: siempre bloqueado
curl -k https://erp.odoo.tfg.com/web/tests
# Resultado esperado: 403 Forbidden
```
---
## Capa B — Odoo: Tipo de Usuario
Campo `sel_groups_1_10_11` en `res.users`:
| Valor | Tipo | Quién lo usa |
|-------|------|--------------|
| `1` | **Portal** | Clientes externos (acceso solo a `/my/` — portal público) |
| `10` | **Interno** | Todos los empleados de VLAN 10 |
| `11` | **Admin** | Administrador del sistema (VLAN 40) |
> [!NOTE]
> El tipo "Portal" se reserva para clientes de TechSolutions que accedan al portal de pedidos/facturas de Odoo (`/my/`). No se usa para empleados internos.
---
## Capa A — Odoo: Grupos por Rol (Módulos accesibles)
Script: `scripts/odoo_crear_usuarios.sh`
### VLAN 10 — Usuarios del ERP
| Rol | Módulos visibles | Puede eliminar | Tipo Odoo |
|-----|-----------------|----------------|-----------|
| **Becario** | Solo CRM (lectura), sin botones de creación/eliminación | ❌ Nunca | Interno (10) |
| **Ventas** | CRM, Pipeline, Contactos, Facturas de cliente | ✅ Solo sus registros | Interno (10) |
| **RRHH** | Empleados, Contratos, Nóminas | ✅ Solo su departamento | Interno (10) |
| **Almacén** | Inventario, Recepciones, Pedidos de compra | ✅ Solo su área | Interno (10) |
| **Técnico** | Inventario, Soporte técnico | ✅ Solo tickets asignados | Interno (10) |
| **Jefe Ventas** | CRM + Ventas completo + aprobaciones de equipo | ✅ Dentro de su dpto. | Interno (10) |
| **Jefe RRHH** | RRHH completo + aprobaciones de contratos | ✅ Dentro de su dpto. | Interno (10) |
| **Jefe Almacén** | Inventario + Compras completo + aprobaciones | ✅ Dentro de su dpto. | Interno (10) |
### VLAN 40 — Gestión del servidor
| Rol | Acceso en Odoo | Acceso al servidor | Tipo Odoo |
|-----|---------------|-------------------|-----------|
| **Admin** | Administrador total (todos los módulos + ajustes) | SSH, Cockpit, Docker, pfSense | Admin (11) |
| **DBA** | Sin acceso UI Odoo (solo BD vía herramienta externa) | Solo PostgreSQL + backups | Interno (10) |
| **API** | Solo XML-RPC (sin menú UI visible) | Solo curl/scripts | Interno (10) |
### Grupos Odoo asignados por rol
| Rol | XML-IDs de grupos Odoo |
|-----|----------------------|
| `becario` | `base.group_user` |
| `ventas` | `base.group_user`, `crm.group_crm_salesperson`, `sales_team.group_sale_salesman`, `account.group_account_invoice` |
| `rrhh` | `base.group_user`, `hr.group_hr_user` |
| `almacen` | `base.group_user`, `stock.group_stock_user`, `purchase.group_purchase_user` |
| `tecnico` | `base.group_user`, `stock.group_stock_user` |
| `jefe_ventas` | `base.group_user`, `crm.group_crm_manager`, `sales_team.group_sale_manager`, `account.group_account_invoice` |
| `jefe_rrhh` | `base.group_user`, `hr.group_hr_manager` |
| `jefe_almacen` | `base.group_user`, `stock.group_stock_manager`, `purchase.group_purchase_manager` |
| `api` | `base.group_user` |
---
## LDAP — Directorio Centralizado de Usuarios
Contenedor: `openldap` (IP MACVLAN: `192.168.30.22`)
### Estructura del árbol LDAP
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
### ACLs de LDAP (configuradas por `ldap_politica_acceso.sh`)
| Cuenta | Permisos | Para qué se usa |
|--------|----------|-----------------|
| `cn=admin` | Escritura total | Administración del directorio (solo VLAN 40) |
| `cn=tecnico` (grupo) | `write` solo en `userPassword` de `ou=usuarios` | Cambio de contraseñas de empleados VLAN 10 |
| `cn=readonly` | Lectura de todo el árbol | Odoo autentica usuarios; PAM en máquinas VLAN 10 |
| Anónimo | Solo `auth` en `userPassword` | Verificación de credenciales en login |
| Resto | Ninguno | `deny all` |
> [!IMPORTANT]
> El técnico **puede cambiar contraseñas** de los empleados de VLAN 10 usando `ldappasswd`, pero **no puede crear, modificar ni eliminar** entradas de usuario. Esta restricción la aplica la ACL número 3 del script `ldap_politica_acceso.sh`.
### Verificar autenticación LDAP
```bash
# Probar autenticación de un usuario de VLAN 10
ldapwhoami -H ldap://192.168.30.22 \
  -D "uid=empleado,ou=usuarios,dc=tfg,dc=com" -W
# Técnico cambia contraseña de un empleado (tiene permiso)
ldappasswd -H ldap://192.168.30.22 \
  -D "uid=tecnico,ou=usuarios,dc=tfg,dc=com" -W \
  -S "uid=becario,ou=usuarios,dc=tfg,dc=com"
# Readonly no puede modificar (debe fallar con Insufficient Access)
ldapmodify -H ldap://192.168.30.22 \
  -D "cn=readonly,dc=tfg,dc=com" -w "password" <<EOF
dn: uid=test,ou=usuarios,dc=tfg,dc=com
changetype: modify
replace: cn
cn: Test
EOF
# Resultado esperado: ldap_modify: Insufficient access (50)
```
---
## Reglas pfSense para VLAN 40
Interfaz `OPT2` (VLAN 40 — Red de Administración):
| Prioridad | Acción | Protocolo | Origen | Destino | Puerto | Descripción |
|-----------|--------|-----------|--------|---------|--------|-------------|
| 1 | ✅ Pass | TCP | VLAN 40 | 192.168.30.10 | 22 | SSH al servidor Debian |
| 2 | ✅ Pass | TCP | VLAN 40 | 192.168.30.10 | 9090 | Cockpit (gestión visual) |
| 3 | ✅ Pass | TCP | VLAN 40 | 192.168.30.20 | 443 | Odoo admin completo (sin restricciones Nginx) |
| 4 | ✅ Pass | TCP | VLAN 40 | 192.168.30.22 | 389, 636 | LDAP admin (lectura + escritura) |
| 5 | ✅ Pass | TCP | VLAN 40 | * | 80, 443 | Actualizaciones internet |
| 6 | ❌ Block | * | VLAN 40 | 192.168.10.0/24 | * | Anti-pivoting a VLAN 10 |
| 7 | ❌ Block | * | VLAN 40 | * | * | Deny all |
Restricciones adicionales desde **VLAN 10** hacia LDAP:
| Prioridad | Acción | Protocolo | Origen | Destino | Puerto | Descripción |
|-----------|--------|-----------|--------|---------|--------|-------------|
| + | ✅ Pass | TCP | VLAN 10 | 192.168.30.22 | 389 | LDAP autenticación (solo lectura vía cn=readonly) |
| + | ❌ Block | TCP | VLAN 10 | 192.168.30.22 | 636 | LDAPS admin bloqueado desde VLAN 10 |
---
## Flujo completo de autenticación de un empleado
```
Empleado (VLAN 10, 192.168.10.x)
    │
    │  1. Abre https://erp.odoo.tfg.com en el navegador
    │     DNS → 192.168.30.20 (pfSense DNS Resolver)
    │
    ▼
[pfSense — VLAN 10 → DMZ]
    │  Regla: VLAN 10 → .20 :443 → PASS
    │
    ▼
[Nginx — 192.168.30.20:443]   ← CAPA C
    │  Ruta /web/database → 403 (VLAN 10 bloqueada)
    │  Ruta / → proxy_pass a odoo-web:8069
    │
    ▼
[Odoo 17 — odoo-web:8069]
    │  2. Login: usuario LDAP (ej: uid=jdoe)
    │
    ▼
[LDAP — 192.168.30.22:389]
    │  Odoo usa cn=readonly para verificar la contraseña
    │  Bind: uid=jdoe, password OK → autenticado
    │
    ▼
[Odoo — Sesión iniciada]        ← CAPA B + CAPA A
    │  Tipo: Interno (10)
    │  Grupos: según su rol (ventas → CRM + Ventas + Facturas)
    │  Menús visibles: solo los de su rol
    │
    ▼
Usuario ve su panel personalizado según su departamento ✅
```
---
## Orden de ejecución para aplicar el control de acceso
```bash
# 1. Actualizar docker/.env con las nuevas variables LDAP
#    (LDAP_ADMIN_PASSWORD y LDAP_READONLY_PASSWORD)
nano docker/.env
# 2. Levantar el contenedor OpenLDAP
docker compose -f docker/docker-compose.yml up -d ldap
# 3. Crear la estructura LDAP (OUs y grupos)
#    El LDIF se carga automáticamente al arrancar el contenedor
# 4. Configurar las ACLs de LDAP
bash scripts/ldap_politica_acceso.sh
# 5. Crear usuarios en LDAP con sus grupos
bash scripts/ldap_crear_usuarios.sh
# 6. Recargar Nginx con los nuevos bloques de restricción
docker exec nginx-proxy nginx -s reload
docker exec nginx-proxy nginx -t   # Verificar sintaxis
# 7. Crear usuarios en Odoo con sus roles
bash scripts/odoo_crear_usuarios.sh
# 8. Verificar restricciones
curl -k https://erp.odoo.tfg.com/web/database/manager  # → 403
curl -k https://erp.odoo.tfg.com/web/tests             # → 403
```
---
## Checklist de verificación
| Prueba | Comando/Acción | Resultado esperado |
|--------|---------------|-------------------|
| Nginx bloquea panel BD desde VLAN 10 | `curl -k https://erp.odoo.tfg.com/web/database/manager` | `403 Forbidden` |
| Nginx permite panel BD desde VLAN 40 | Mismo curl desde PC en VLAN 40 | `200 OK` (formulario) |
| Nginx bloquea `/web/tests` | `curl -k https://erp.odoo.tfg.com/web/tests` | `403 Forbidden` |
| Becario no ve botón Eliminar | Login con `becario@erp.odoo.tfg.com` | Sin botón Eliminar en CRM |
| Becario no ve módulo Ventas | Login con `becario@erp.odoo.tfg.com` | Solo menú CRM visible |
| Ventas ve sus módulos | Login con `ventas@erp.odoo.tfg.com` | CRM + Ventas + Facturas |
| Jefe Ventas tiene aprobaciones | Login con `jefe.ventas@erp.odoo.tfg.com` | Botones de aprobación visibles |
| Técnico puede cambiar contraseña LDAP | `ldappasswd` con credenciales técnico | Éxito |
| Readonly no puede modificar LDAP | `ldapmodify` con credenciales readonly | `Insufficient access (50)` |
| DBA no tiene UI Odoo | Login con `dba@erp.odoo.tfg.com` | Solo CRM base, sin módulos extra |
```

### File: .\docs\diagrama_red.md
```md
# Diagrama de Red — Arquitectura Completa
**TFG ASIR 2025/2026 — TechSolutions S.L.**
---
## Diagrama de Topología General
```mermaid
graph TD
    WAN["☁️ Internet / WAN"]
    GITHUB["☁️ GitHub\n(Repositorio + CI/CD)"]
    WAN -->|"NAT 80/443"| PFSENSE
    GITHUB -->|"Self-hosted runner"| DEBIAN
    PFSENSE(["🔷 pfSense\nFirewall · DHCP · DNS · Router\nIP WAN: dinámica (NAT)"])
    PFSENSE -->|"VLAN 10 · 192.168.10.1/24"| VLAN10
    PFSENSE -->|"VLAN 30 · 192.168.30.1/24"| DMZ
    PFSENSE -->|"VLAN 40 · 192.168.40.1/24"| VLAN40
    subgraph VLAN10["🟧 VLAN 10 — Clientes / Empleados"]
        CLIENT["🖥️ PC Empleado\n192.168.10.x\nLogin: LDAP (SSSD+PAM)"]
    end
    subgraph VLAN40["🟥 VLAN 40 — Administración"]
        ADMIN["👤 Admin / DBA\n192.168.40.x\nAcceso: SSH · Cockpit · pfSense"]
    end
    subgraph DMZ["🟩 Debian 13 · DMZ — VLAN 30"]
        DEBIAN["🖧 Host Debian 13\n192.168.30.10\nSSH :22 · Cockpit :9090"]
        NGINX["🐳 nginx-proxy\nMACV: 192.168.30.20\n:80 :443"]
        ODOO["🐳 odoo-web\nMACV: 192.168.30.21\n:8069 :8072"]
        POSTGRES["🐳 odoo_erp (PostgreSQL)\nSolo red interna\n:5432"]
        LDAP["🐳 openldap\nMACV: 192.168.30.22\n:389 :636"]
        NGINX -->|"reverse proxy :8069"| ODOO
        ODOO -->|"SQL :5432"| POSTGRES
    end
    CLIENT -->|"HTTPS :443"| NGINX
    CLIENT -->|"LDAP auth :389"| LDAP
    ADMIN -->|"HTTPS :443"| NGINX
    ADMIN -->|"SSH :22"| DEBIAN
    ADMIN -->|"Cockpit :9090"| DEBIAN
    ADMIN -->|"LDAP admin :389/:636"| LDAP
    classDef firewall fill:#BBDEFB,stroke:#1565C0,color:#000
    classDef vlan10 fill:#FFE0B2,stroke:#E65100,color:#000
    classDef vlan40 fill:#FFCDD2,stroke:#B71C1C,color:#000
    classDef dmzhost fill:#E8F5E9,stroke:#2E7D32,color:#000
    classDef container fill:#CE93D8,stroke:#6A1B9A,color:#000
    class PFSENSE firewall
    class CLIENT vlan10
    class ADMIN vlan40
    class DEBIAN dmzhost
    class NGINX,ODOO,POSTGRES,LDAP container
```
---
## Tabla de Direccionamiento IP Completa
| Componente | Zona | IP | Puerto(s) | Acceso desde |
|:-----------|:-----|:---|:---------|:-------------|
| pfSense — gateway LAN | VLAN 10 | `192.168.10.1` | 443 (panel) | Solo VLAN 40 |
| pfSense — gateway DMZ | VLAN 30 | `192.168.30.1` | — | — |
| pfSense — gateway Admin | VLAN 40 | `192.168.40.1` | 443 (panel) | Solo VLAN 40 |
| **Debian 13 host** | DMZ | `192.168.30.10` | 22, 9090 | Solo VLAN 40 |
| **nginx-proxy** (MACVLAN) | DMZ | `192.168.30.20` | 80, 443 | VLAN 10 + VLAN 40 + WAN |
| **odoo-web** (MACVLAN) | DMZ | `192.168.30.21` | 8069, 8072 (solo interno) | Solo via Nginx |
| **openldap** (MACVLAN) | DMZ | `192.168.30.22` | 389 (readonly), 636 (admin) | VLAN 10 (:389), VLAN 40 (:389/:636) |
| **odoo_erp** (PostgreSQL) | Red Docker | `172.19.0.x` | 5432 (solo interno) | Solo contenedor Odoo |
| Clientes empleados | VLAN 10 | `192.168.10.100–200` | — | DHCP |
| PCs administradores | VLAN 40 | `192.168.40.10–50` | — | DHCP |
---
## Zonas de Seguridad y Políticas de Acceso
```
┌─────────────────────────────────────────────────────────────────────┐
│  INTERNET (WAN)                                                     │
│  Solo puertos 80/443 redirigidos por NAT al nginx-proxy             │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                          [ pfSense ]
                               │
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
   VLAN 10                VLAN 30 (DMZ)          VLAN 40
 (Clientes)              (Servidor)           (Admin)
192.168.10.0/24         192.168.30.0/24     192.168.40.0/24
        │                      │                      │
  PCs empleados       Debian + Docker          Admins/DBAs
  Login LDAP          Nginx/Odoo/LDAP         SSH/Cockpit/pfSense
        │                      │
        └──── solo HTTPS ──────┘  (pfSense regla: VLAN10→DMZ :443 ✅)
        └──── PostgreSQL ──── ❌   (pfSense regla: VLAN10→DMZ :5432 ✗)
        └──── SSH/Cockpit ─── ❌   (pfSense regla: VLAN10→DMZ :22/:9090 ✗)
```
### Principio de anti-pivoting
| Origen | Destino | Estado |
|:-------|:--------|:------:|
| DMZ → VLAN 10 | Cualquier puerto | ❌ Bloqueado |
| DMZ → VLAN 40 | Cualquier puerto | ❌ Bloqueado |
| DMZ → pfSense LAN | Cualquier puerto | ❌ Bloqueado |
| VLAN 10 → VLAN 40 | Cualquier puerto | ❌ Bloqueado |
| VLAN 40 → VLAN 10 | Cualquier puerto | ❌ Bloqueado |
---
## Flujo de Autenticación de un Empleado
```
Empleado (VLAN 10) abre https://erp.odoo.tfg.com
         │
         ▼  DNS → pfSense DNS Resolver
         │  Host Override: erp.odoo.tfg.com → 192.168.30.10
         │
         ▼  pfSense: VLAN10→DMZ:443 → PASS ✅
         │
    [ nginx-proxy — 192.168.30.20:443 ]   ← CAPA C: filtra rutas por IP
         │  /web/database → 403 (VLAN 10 bloqueada)
         │  / → proxy_pass a odoo-web:8069
         │
    [ odoo-web — 192.168.30.21:8069 ]    ← CAPA B: tipo de usuario
         │  Login LDAP → consulta a cn=readonly
         │
    [ openldap — 192.168.30.22:389 ]
         │  uid=jdoe, password OK → ✅
         │
    [ Odoo — Sesión iniciada ]            ← CAPA A: grupos y módulos
         │  Tipo: Interno
         │  Grupos: ventas → CRM + Ventas + Facturas
         ▼
    Panel personalizado según rol ✅
```
---
## Red Docker Interna
```
┌──────────────────────────────────────────────────────┐
│  Red Docker: odoo_net (bridge — 172.19.0.0/16)       │
│                                                      │
│  nginx-proxy ──────► odoo-web ──────► odoo_erp       │
│  (172.19.0.4)        (172.19.0.3)    (172.19.0.2)   │
│  + macvlan .20       + macvlan .21   (sin MACVLAN)  │
│                                                      │
│  openldap                                            │
│  (172.19.0.5)                                        │
│  + macvlan .22                                       │
└──────────────────────────────────────────────────────┘
```
> [!NOTE]
> PostgreSQL (`odoo_erp`) no tiene IP MACVLAN intencionalmente: solo es accesible desde dentro de la
> red Docker interna. pfSense y los clientes de la LAN no pueden alcanzarlo directamente.
---
*Referencia de reglas detalladas: [`docs/reglas_pfsense.md`](reglas_pfsense.md)*
*Guía de instalación: [`docs/INSTALACION_COMPLETA.md`](INSTALACION_COMPLETA.md)*
```

### File: .\docs\github_actions_ips.txt
```txt
4.148.0.0/16
4.149.0.0/18
4.149.64.0/19
4.149.96.0/19
4.149.128.0/17
4.150.0.0/18
4.150.64.0/18
4.150.128.0/18
4.150.192.0/19
4.150.224.0/19
4.151.0.0/16
4.152.0.0/15
4.154.0.0/15
4.156.0.0/15
4.172.0.0/15
4.174.0.0/16
4.175.0.0/16
4.180.0.0/16
4.204.0.0/15
4.206.0.0/16
4.207.0.0/16
4.208.0.0/15
4.210.0.0/17
4.210.128.0/17
4.227.0.0/17
4.227.128.0/17
4.229.0.0/17
4.229.128.0/17
4.231.0.0/17
4.231.128.0/17
4.236.0.0/17
4.236.128.0/17
4.239.0.0/17
4.239.128.0/17
4.242.0.0/17
4.242.128.0/17
4.245.0.0/17
4.245.128.0/17
4.246.0.0/17
4.246.128.0/17
4.248.0.0/17
4.248.128.0/17
4.249.0.0/17
4.249.128.0/17
4.255.0.0/17
4.255.128.0/17
9.163.0.0/16
9.169.0.0/17
9.169.128.0/17
9.234.0.0/17
9.234.128.0/17
13.64.0.0/16
13.65.0.0/16
13.66.0.0/17
13.66.128.0/17
13.67.128.0/20
13.67.144.0/21
13.67.152.0/24
13.67.153.0/28
13.67.153.32/27
13.67.153.64/26
13.67.153.128/25
13.67.155.0/24
13.67.156.0/22
13.67.160.0/19
13.67.192.0/18
13.68.0.0/17
13.68.128.0/17
13.69.0.0/17
13.69.128.0/17
13.70.192.0/18
13.71.160.0/19
13.71.192.0/18
13.72.64.0/18
13.73.32.0/19
13.73.128.0/18
13.73.224.0/21
13.73.240.0/20
13.74.0.0/16
13.77.64.0/18
13.77.128.0/18
13.77.192.0/19
13.78.128.0/17
13.79.0.0/16
13.80.0.0/15
13.82.0.0/16
13.83.0.0/16
13.84.0.0/15
13.86.0.0/17
13.86.128.0/17
13.87.128.0/17
13.88.0.0/17
13.88.128.0/18
13.88.200.0/21
13.88.224.0/19
13.89.0.0/16
13.90.0.0/16
13.91.0.0/16
13.92.0.0/16
13.93.0.0/17
13.93.128.0/17
13.94.64.0/18
13.94.128.0/17
13.95.0.0/16
13.104.129.64/26
13.104.144.64/27
13.104.144.128/27
13.104.144.192/27
13.104.145.0/26
13.104.145.64/26
13.104.145.192/26
13.104.146.0/26
13.104.146.128/25
13.104.147.0/25
13.104.147.128/25
13.104.148.0/25
13.104.149.128/25
13.104.150.0/25
13.104.151.192/26
13.104.152.0/25
13.104.152.128/25
13.104.154.128/25
13.104.158.16/28
13.104.158.64/26
13.104.158.176/28
13.104.173.128/28
13.104.192.0/21
13.104.208.64/27
13.104.208.96/27
13.104.208.128/27
13.104.208.160/28
13.104.208.176/28
13.104.208.192/26
13.104.209.0/24
13.104.210.0/24
13.104.211.0/25
13.104.212.192/26
13.104.213.0/25
13.104.214.0/25
13.104.214.128/25
13.104.215.0/25
13.104.215.128/25
13.104.217.0/25
13.104.218.128/25
13.104.219.0/25
13.104.219.128/25
13.104.220.0/25
13.104.220.128/25
13.104.222.0/24
13.104.223.0/25
13.104.223.192/26
13.105.14.0/25
13.105.14.128/26
13.105.17.0/26
13.105.17.64/26
13.105.17.128/26
13.105.17.192/26
13.105.18.0/26
13.105.18.128/27
13.105.18.160/27
13.105.18.192/26
13.105.19.0/25
13.105.19.128/25
13.105.20.192/26
13.105.21.0/24
13.105.22.0/24
13.105.23.0/26
13.105.23.64/26
13.105.23.128/25
13.105.24.0/24
13.105.25.0/24
13.105.26.0/24
13.105.27.0/25
13.105.27.192/27
13.105.28.0/28
13.105.28.16/28
13.105.28.32/28
13.105.28.48/28
13.105.28.64/26
13.105.28.128/25
13.105.29.0/25
13.105.29.128/25
13.105.30.0/25
13.105.30.128/26
13.105.31.96/28
13.105.36.0/27
13.105.36.32/28
13.105.36.64/27
13.105.36.128/26
13.105.36.192/26
13.105.37.0/26
13.105.37.64/26
13.105.37.128/26
13.105.37.192/26
13.105.49.0/24
13.105.53.0/25
13.105.53.192/26
13.105.60.0/27
13.105.60.32/28
13.105.60.48/28
13.105.60.64/27
13.105.60.96/27
13.105.60.128/27
13.105.60.192/26
13.105.66.32/27
13.105.66.64/26
13.105.66.128/28
13.105.66.144/28
13.105.66.160/27
13.105.66.192/26
13.105.67.0/25
13.105.67.128/25
13.105.74.0/27
13.105.74.32/28
13.105.74.48/28
13.105.74.64/27
13.105.74.128/26
13.105.75.0/27
13.105.75.32/28
13.105.75.64/27
13.105.96.64/27
13.105.96.96/28
13.105.96.128/25
13.105.97.0/27
13.105.98.48/28
13.105.98.96/27
13.105.98.128/27
13.105.98.160/27
13.105.98.192/28
13.105.98.224/27
13.105.101.32/28
13.105.101.48/28
13.105.101.64/26
13.105.101.176/28
13.105.102.16/28
13.105.102.64/26
13.105.102.224/27
13.105.103.0/28
13.105.103.32/27
13.105.103.128/27
13.105.103.160/28
13.105.103.192/27
13.105.104.32/27
13.105.104.64/28
13.105.104.96/27
13.105.104.240/28
13.105.105.32/27
13.105.105.64/27
13.105.105.96/27
13.105.105.128/28
13.105.105.160/27
13.105.106.0/27
13.105.106.32/28
13.105.106.64/27
13.105.107.112/28
13.105.107.160/27
13.105.107.192/27
13.105.107.224/27
13.105.108.0/28
13.105.108.32/27
13.105.117.0/24
13.105.220.0/25
13.105.220.128/27
13.105.220.160/28
13.105.220.176/29
13.105.220.184/30
13.105.220.188/31
13.105.220.210/31
20.1.128.0/17
20.3.0.0/16
20.4.0.0/16
20.7.0.0/16
20.8.0.0/16
20.9.0.0/17
20.9.128.0/17
20.10.0.0/16
20.12.0.0/17
20.12.128.0/17
20.13.0.0/17
20.13.128.0/17
20.14.0.0/17
20.14.128.0/17
20.15.0.0/17
20.15.128.0/17
20.16.0.0/16
20.17.72.0/21
20.18.184.0/21
20.20.53.32/27
20.20.53.64/26
20.20.55.0/27
20.20.76.0/22
20.20.92.0/23
20.20.94.0/24
20.20.95.0/26
20.20.95.64/28
20.20.95.80/29
20.20.95.88/30
20.20.100.0/24
20.20.101.0/25
20.20.101.128/29
20.20.101.136/30
20.20.101.144/28
20.20.101.160/27
20.20.101.192/26
20.20.102.0/26
20.20.102.64/28
20.20.102.80/29
20.20.102.90/31
20.20.102.92/31
20.20.102.96/27
20.20.102.128/25
20.20.103.0/24
20.20.108.0/22
20.20.128.0/24
20.20.129.0/24
20.20.130.0/24
20.20.131.0/24
20.20.132.0/23
20.20.134.0/24
20.20.135.0/24
20.20.137.0/24
20.20.138.0/24
20.20.139.0/24
20.20.140.0/24
20.20.141.0/24
20.20.144.0/24
20.20.145.0/24
20.20.190.0/23
20.22.0.0/16
20.23.0.0/16
20.25.0.0/17
20.25.128.0/18
20.25.192.0/18
20.29.0.0/17
20.29.128.0/17
20.31.0.0/16
20.33.0.0/24
20.33.1.0/24
20.33.2.0/24
20.33.3.0/24
20.33.4.0/24
20.33.6.0/24
20.33.8.0/24
20.33.12.0/24
20.33.13.0/24
20.33.14.0/24
20.33.15.0/24
20.33.17.0/24
20.33.20.0/24
20.33.21.0/24
20.33.22.0/24
20.33.25.0/24
20.33.26.0/24
20.33.27.0/24
20.33.29.0/24
20.33.30.0/24
20.33.31.0/24
20.33.32.0/24
20.33.33.0/24
20.33.36.0/24
20.33.37.0/24
20.33.39.0/24
20.33.40.0/24
20.33.41.0/24
20.33.42.0/24
20.33.44.0/24
20.33.45.0/24
20.33.46.0/24
20.33.48.0/24
20.33.49.0/24
20.33.51.0/24
20.33.53.0/24
20.33.55.0/24
20.33.57.0/24
20.33.59.0/24
20.33.61.0/24
20.33.66.0/24
20.33.67.0/24
20.33.68.0/24
20.33.69.0/24
20.33.72.0/24
20.33.73.0/24
20.33.75.0/24
20.33.76.0/24
20.33.77.0/24
20.33.78.0/24
20.33.79.0/24
20.33.81.0/24
20.33.86.0/24
20.33.88.0/24
20.33.92.0/24
20.33.97.0/24
20.33.104.0/24
20.33.105.0/24
20.33.107.0/24
20.33.110.0/24
20.33.114.0/24
20.33.115.0/24
20.33.116.0/24
20.33.123.0/24
20.33.126.0/24
20.33.127.0/24
20.33.133.0/24
20.33.135.0/24
20.33.138.0/24
20.33.143.0/24
20.33.144.0/24
20.33.145.0/24
20.33.147.0/24
20.33.149.0/24
20.33.150.0/24
20.33.151.0/24
20.33.156.0/24
20.33.157.0/24
20.33.159.0/24
20.33.160.0/24
20.33.163.0/24
20.33.164.0/24
20.33.165.0/24
20.33.167.0/24
20.33.178.0/24
20.33.185.0/24
20.33.186.0/24
20.33.187.0/24
20.33.189.0/24
20.33.191.0/24
20.33.192.0/24
20.33.197.0/24
20.33.198.0/24
20.33.201.0/24
20.33.205.0/24
20.33.206.0/24
20.33.207.0/24
20.33.208.0/24
20.33.209.0/24
20.33.211.0/24
20.33.213.0/24
20.33.216.0/24
20.33.217.0/24
20.33.218.0/24
20.33.222.0/23
20.33.224.0/23
20.33.226.0/23
20.33.228.0/23
20.33.230.0/24
20.33.232.0/24
20.33.241.0/24
20.33.243.0/24
20.33.244.0/24
20.33.246.0/24
20.33.247.0/24
20.33.248.0/22
20.33.252.0/24
20.33.253.0/24
20.33.254.0/24
20.33.255.0/24
20.36.0.0/19
20.36.96.0/21
20.36.128.0/17
20.37.128.0/18
20.38.0.0/20
20.38.32.0/20
20.38.64.0/19
20.38.96.0/23
20.38.98.0/24
20.38.99.0/24
20.38.100.0/23
20.38.102.0/23
20.38.104.0/23
20.38.108.0/23
20.38.114.0/25
20.38.121.128/25
20.38.122.0/23
20.38.144.0/21
20.38.160.0/20
20.38.176.0/21
20.38.200.0/22
20.38.208.0/22
20.39.32.0/19
20.39.128.0/20
20.40.24.0/21
20.40.192.0/18
20.41.0.0/18
20.41.128.0/18
20.42.0.0/17
20.42.128.0/19
20.42.160.0/23
20.42.168.0/21
20.42.176.0/20
20.43.0.0/19
20.43.192.0/18
20.44.8.0/21
20.44.16.0/21
20.44.64.0/18
20.45.0.0/18
20.45.120.0/21
20.46.224.0/19
20.47.0.0/24
20.47.1.0/24
20.47.2.0/24
20.47.3.0/24
20.47.4.0/24
20.47.7.0/24
20.47.8.0/24
20.47.15.0/24
20.47.16.0/23
20.47.18.0/23
20.47.20.0/23
20.47.22.0/23
20.47.24.0/23
20.47.29.0/24
20.47.30.0/24
20.47.31.0/24
20.47.32.0/24
20.47.40.0/24
20.47.41.0/24
20.47.58.0/23
20.47.60.0/23
20.47.62.0/23
20.47.69.0/24
20.47.70.0/24
20.47.76.0/23
20.47.78.0/23
20.47.87.0/24
20.47.88.0/24
20.47.96.0/23
20.47.100.0/24
20.47.104.0/24
20.47.107.0/24
20.47.108.0/23
20.47.110.0/24
20.47.111.0/24
20.47.113.0/24
20.47.115.0/24
20.47.116.0/24
20.47.117.0/24
20.47.118.0/24
20.47.119.0/24
20.47.120.0/23
20.48.128.0/18
20.48.192.0/20
20.48.208.0/21
20.48.224.0/19
20.49.0.0/18
20.49.88.0/21
20.49.96.0/21
20.49.104.0/21
20.49.112.0/21
20.49.120.0/21
20.50.0.0/18
20.50.64.0/20
20.50.80.0/21
20.50.88.0/21
20.50.128.0/17
20.51.0.0/21
20.51.8.0/21
20.51.32.0/19
20.51.64.0/18
20.51.128.0/17
20.54.0.0/17
20.54.128.0/17
20.55.0.0/17
20.55.128.0/18
20.55.192.0/18
20.56.0.0/16
20.57.0.0/17
20.57.128.0/18
20.57.192.0/19
20.57.224.0/19
20.59.0.0/18
20.59.64.0/18
20.59.128.0/18
20.59.192.0/18
20.60.0.0/24
20.60.1.0/24
20.60.2.0/23
20.60.4.0/24
20.60.6.0/23
20.60.14.0/24
20.60.18.0/24
20.60.19.0/24
20.60.20.0/24
20.60.26.0/23
20.60.28.0/23
20.60.30.0/23
20.60.34.0/23
20.60.38.0/23
20.60.40.0/23
20.60.42.0/23
20.60.44.128/25
20.60.48.0/22
20.60.52.0/23
20.60.56.0/22
20.60.60.0/22
20.60.64.0/22
20.60.68.0/22
20.60.80.0/23
20.60.82.0/23
20.60.88.0/22
20.60.119.0/24
20.60.120.0/23
20.60.122.0/24
20.60.128.0/23
20.60.130.0/24
20.60.132.0/23
20.60.134.0/23
20.60.137.0/24
20.60.140.0/23
20.60.142.0/23
20.60.144.0/23
20.60.146.0/23
20.60.148.0/23
20.60.150.0/23
20.60.152.0/23
20.60.160.0/23
20.60.162.0/23
20.60.168.0/23
20.60.178.0/23
20.60.180.0/23
20.60.194.0/23
20.60.196.0/23
20.60.204.0/23
20.60.218.0/23
20.60.220.0/23
20.60.222.0/23
20.60.224.0/23
20.60.228.0/23
20.60.230.0/23
20.60.232.0/23
20.60.236.0/23
20.60.240.0/23
20.60.242.0/23
20.60.244.0/23
20.60.246.0/23
20.60.250.0/23
20.61.0.0/16
20.62.0.0/17
20.62.128.0/17
20.63.0.0/17
20.64.0.0/17
20.64.128.0/17
20.65.0.0/17
20.65.128.0/17
20.66.0.0/17
20.66.128.0/17
20.67.0.0/17
20.67.128.0/17
20.69.0.0/18
20.69.64.0/18
20.69.128.0/18
20.69.192.0/18
20.71.0.0/16
20.72.32.0/19
20.72.64.0/18
20.72.128.0/18
20.72.192.0/18
20.73.0.0/16
20.75.0.0/17
20.75.128.0/17
20.76.0.0/16
20.80.0.0/18
20.80.64.0/18
20.80.128.0/18
20.80.192.0/18
20.81.0.0/17
20.81.128.0/17
20.82.0.0/17
20.82.128.0/17
20.83.0.0/18
20.83.64.0/18
20.83.128.0/18
20.83.192.0/18
20.84.0.0/17
20.84.128.0/17
20.85.0.0/17
20.85.128.0/17
20.86.0.0/16
20.88.0.0/18
20.88.96.0/19
20.88.128.0/18
20.88.192.0/18
20.93.0.0/17
20.93.128.0/17
20.94.0.0/17
20.94.128.0/18
20.94.192.0/18
20.95.0.0/24
20.95.1.0/24
20.95.2.0/24
20.95.3.0/24
20.95.4.0/24
20.95.5.0/24
20.95.6.0/24
20.95.7.0/24
20.95.8.0/21
20.95.16.0/24
20.95.17.0/24
20.95.18.0/24
20.95.19.0/24
20.95.20.0/24
20.95.21.0/24
20.95.22.0/24
20.95.23.0/24
20.95.24.0/24
20.95.25.0/24
20.95.26.0/24
20.95.27.0/24
20.95.28.0/24
20.95.29.0/24
20.95.30.0/24
20.95.31.0/24
20.95.32.0/24
20.95.33.0/24
20.95.34.0/24
20.95.35.0/24
20.95.36.0/24
20.95.37.0/24
20.95.38.0/23
20.95.40.0/21
20.95.48.0/24
20.95.49.0/24
20.95.50.0/24
20.95.51.0/24
20.95.52.0/24
20.95.53.0/24
20.95.54.0/24
20.95.55.0/24
20.95.56.0/24
20.95.57.0/24
20.95.58.0/24
20.95.59.0/24
20.95.60.0/24
20.95.61.0/24
20.95.62.0/24
20.95.63.0/24
20.95.64.0/24
20.95.66.0/24
20.95.68.0/23
20.95.72.0/23
20.95.76.0/23
20.95.81.0/24
20.95.88.0/21
20.95.98.0/24
20.95.103.0/24
20.95.107.0/24
20.95.121.0/24
20.95.122.0/24
20.95.126.0/24
20.95.248.0/24
20.95.249.0/24
20.95.250.0/24
20.95.251.0/24
20.95.255.0/29
20.96.0.0/16
20.97.0.0/17
20.97.128.0/17
20.98.0.0/18
20.98.64.0/18
20.98.128.0/18
20.98.192.0/18
20.99.128.0/17
20.101.0.0/16
20.102.0.0/17
20.102.192.0/18
20.103.0.0/16
20.104.0.0/17
20.104.128.0/18
20.104.192.0/18
20.105.0.0/17
20.105.128.0/17
20.106.0.0/18
20.106.64.0/18
20.106.128.0/17
20.107.0.0/17
20.107.128.0/17
20.109.0.0/17
20.109.128.0/18
20.109.192.0/18
20.110.0.0/16
20.112.0.0/17
20.112.160.0/20
20.112.176.0/21
20.112.184.0/21
20.112.192.0/18
20.114.0.0/18
20.114.64.0/18
20.114.128.0/17
20.115.0.0/17
20.115.128.0/17
20.116.0.0/16
20.118.0.0/18
20.118.64.0/18
20.118.128.0/18
20.118.192.0/18
20.119.0.0/17
20.119.128.0/17
20.120.0.0/17
20.120.128.0/17
20.121.0.0/16
20.122.0.0/16
20.123.0.0/17
20.123.128.0/17
20.124.0.0/16
20.125.0.0/18
20.125.64.0/18
20.125.128.0/19
20.125.160.0/19
20.125.192.0/19
20.125.224.0/20
20.125.240.0/20
20.126.0.0/16
20.127.0.0/16
20.135.0.0/22
20.135.4.0/23
20.135.6.0/23
20.135.8.0/22
20.135.12.0/22
20.135.16.0/23
20.135.18.0/23
20.135.20.0/23
20.135.22.0/23
20.135.24.0/23
20.135.66.0/23
20.135.70.0/23
20.135.72.0/23
20.135.74.0/23
20.135.134.0/23
20.135.136.0/22
20.135.140.0/22
20.135.144.0/23
20.135.182.0/23
20.135.184.0/22
20.135.188.0/22
20.135.192.0/23
20.135.194.0/23
20.135.196.0/22
20.135.200.0/22
20.135.204.0/23
20.135.216.0/22
20.135.220.0/23
20.135.222.0/23
20.135.224.0/22
20.135.228.0/22
20.135.232.0/23
20.135.254.0/23
20.136.0.0/25
20.136.0.128/25
20.136.1.0/24
20.136.2.0/24
20.136.3.0/25
20.136.3.128/25
20.136.4.0/24
20.136.5.0/24
20.136.7.0/25
20.143.0.0/24
20.143.1.0/24
20.143.2.0/24
20.143.3.0/24
20.143.4.0/24
20.143.5.0/24
20.143.8.0/23
20.143.10.0/23
20.143.12.0/24
20.143.13.0/24
20.143.32.0/23
20.143.34.0/23
20.143.38.0/24
20.143.39.0/24
20.143.46.0/23
20.143.50.0/23
20.143.52.0/23
20.143.64.0/23
20.143.66.0/23
20.143.68.0/22
20.143.72.0/23
20.143.74.0/23
20.143.76.0/22
20.143.80.0/22
20.143.84.0/22
20.143.88.0/23
20.143.90.0/23
20.143.114.0/23
20.143.118.0/23
20.143.124.0/23
20.143.126.0/23
20.143.136.0/23
20.143.146.0/23
20.143.164.0/23
20.143.170.0/23
20.143.172.0/23
20.143.178.0/23
20.143.182.0/23
20.143.186.0/23
20.143.188.0/23
20.150.1.0/25
20.150.8.0/23
20.150.16.0/24
20.150.17.0/25
20.150.20.128/25
20.150.25.0/24
20.150.26.0/24
20.150.29.0/24
20.150.30.0/24
20.150.31.0/24
20.150.32.0/23
20.150.34.0/23
20.150.36.0/24
20.150.37.0/24
20.150.38.0/23
20.150.40.128/25
20.150.42.0/24
20.150.43.128/25
20.150.47.128/25
20.150.48.0/24
20.150.49.0/24
20.150.50.0/23
20.150.58.0/24
20.150.63.0/24
20.150.67.0/24
20.150.68.0/24
20.150.70.0/24
20.150.71.0/24
20.150.72.0/24
20.150.74.0/24
20.150.75.0/24
20.150.76.0/24
20.150.77.0/24
20.150.78.0/24
20.150.79.0/24
20.150.81.0/24
20.150.82.0/24
20.150.83.0/24
20.150.84.0/24
20.150.87.0/24
20.150.88.0/24
20.150.89.0/24
20.150.90.0/24
20.150.91.0/24
20.150.93.0/24
20.150.94.0/24
20.150.95.0/24
20.150.98.0/24
20.150.100.0/24
20.150.102.0/24
20.150.104.0/24
20.150.107.0/24
20.150.113.0/24
20.150.122.0/24
20.150.126.0/24
20.150.128.0/17
20.151.0.0/16
20.152.0.0/23
20.152.2.0/23
20.152.4.0/23
20.152.6.0/23
20.152.16.0/22
20.152.28.0/23
20.152.36.0/22
20.152.40.0/22
20.152.44.0/23
20.152.46.0/23
20.152.66.0/23
20.152.68.0/23
20.152.74.0/23
20.152.76.0/22
20.152.80.0/23
20.152.82.0/23
20.152.84.0/23
20.152.86.0/23
20.152.88.0/23
20.152.90.0/23
20.152.92.0/23
20.152.96.0/23
20.152.98.0/23
20.152.100.0/23
20.152.102.0/23
20.152.104.0/23
20.152.106.0/23
20.152.108.0/23
20.152.110.0/23
20.152.112.0/23
20.153.0.0/24
20.153.1.0/24
20.153.2.0/24
20.153.3.0/24
20.153.4.0/24
20.153.5.0/24
20.153.12.0/24
20.153.13.0/24
20.153.15.0/24
20.153.17.0/24
20.153.18.0/24
20.153.22.0/24
20.153.24.0/24
20.153.25.0/24
20.153.29.0/24
20.153.30.0/24
20.153.31.0/24
20.153.32.0/24
20.153.34.0/24
20.153.35.0/24
20.153.36.0/24
20.153.40.0/24
20.153.41.0/24
20.153.47.0/24
20.153.49.0/24
20.153.50.0/24
20.153.51.0/24
20.153.55.0/24
20.153.57.0/24
20.153.61.0/24
20.153.63.0/24
20.153.64.0/24
20.153.65.0/24
20.153.66.0/25
20.153.66.128/25
20.153.67.0/24
20.153.68.0/24
20.153.69.0/25
20.153.69.128/26
20.153.71.0/24
20.153.72.0/23
20.153.74.0/24
20.153.75.0/24
20.153.76.0/24
20.153.78.0/24
20.153.79.0/24
20.153.81.0/24
20.153.84.0/23
20.153.86.0/24
20.153.87.0/24
20.153.88.0/24
20.153.89.0/24
20.153.90.0/24
20.153.95.0/24
20.153.97.0/24
20.153.98.0/24
20.153.99.0/24
20.153.105.0/24
20.153.106.0/24
20.153.107.0/24
20.153.108.0/24
20.153.110.0/24
20.153.113.0/24
20.153.115.0/24
20.153.117.0/24
20.153.118.0/24
20.153.124.0/24
20.153.125.0/24
20.153.126.0/24
20.153.127.0/24
20.153.130.0/24
20.153.134.0/24
20.153.135.0/24
20.153.136.0/24
20.153.137.0/24
20.153.141.0/24
20.153.144.0/24
20.153.145.0/24
20.153.146.0/24
20.153.150.0/23
20.153.152.0/24
20.153.154.0/24
20.153.155.0/24
20.153.156.0/24
20.153.157.0/24
20.153.159.0/24
20.153.160.0/22
20.153.164.0/24
20.153.165.0/24
20.153.166.0/23
20.153.168.0/21
20.153.176.0/22
20.153.180.0/24
20.153.188.0/23
20.153.190.0/24
20.153.206.0/23
20.153.208.0/22
20.153.212.0/23
20.153.214.0/24
20.153.222.0/23
20.153.224.0/23
20.157.4.0/23
20.157.6.0/23
20.157.8.0/22
20.157.17.0/24
20.157.18.0/24
20.157.19.0/24
20.157.21.0/24
20.157.22.0/24
20.157.24.0/24
20.157.25.0/24
20.157.26.0/24
20.157.27.0/24
20.157.29.0/24
20.157.30.0/24
20.157.32.0/24
20.157.33.0/24
20.157.34.0/23
20.157.36.0/23
20.157.39.0/24
20.157.40.0/24
20.157.41.0/24
20.157.43.0/24
20.157.47.0/24
20.157.48.0/23
20.157.50.0/23
20.157.52.0/24
20.157.54.0/24
20.157.57.0/24
20.157.59.0/24
20.157.60.0/24
20.157.61.0/24
20.157.62.0/23
20.157.64.0/21
20.157.72.0/24
20.157.73.0/24
20.157.76.0/22
20.157.80.0/22
20.157.84.0/24
20.157.86.0/24
20.157.87.0/24
20.157.88.0/24
20.157.90.0/24
20.157.91.0/24
20.157.93.0/24
20.157.95.0/24
20.157.97.0/24
20.157.99.0/24
20.157.100.0/24
20.157.104.0/24
20.157.105.0/24
20.157.106.0/24
20.157.109.0/24
20.157.110.0/24
20.157.111.0/24
20.157.113.0/24
20.157.114.0/24
20.157.115.0/24
20.157.116.0/24
20.157.118.0/24
20.157.119.0/24
20.157.121.0/24
20.157.122.0/24
20.157.123.0/24
20.157.124.0/24
20.157.125.0/24
20.157.127.0/24
20.157.130.0/24
20.157.132.0/24
20.157.134.0/24
20.157.142.0/23
20.157.145.0/24
20.157.146.0/24
20.157.147.0/24
20.157.148.0/24
20.157.158.0/24
20.157.159.0/24
20.157.161.0/24
20.157.163.0/24
20.157.164.0/24
20.157.166.0/24
20.157.167.0/24
20.157.170.0/24
20.157.171.0/24
20.157.172.0/24
20.157.179.0/24
20.157.180.0/24
20.157.181.0/24
20.157.184.0/24
20.157.185.0/24
20.157.186.0/24
20.157.191.0/24
20.157.194.0/24
20.157.209.0/24
20.157.212.0/24
20.157.215.0/24
20.157.216.0/24
20.157.217.0/24
20.157.221.0/24
20.157.223.0/24
20.157.230.0/24
20.157.231.0/24
20.157.236.0/24
20.157.239.0/24
20.157.240.0/24
20.157.244.0/24
20.157.245.0/24
20.157.247.0/24
20.157.248.0/24
20.157.249.0/24
20.157.250.0/24
20.157.251.0/24
20.157.252.0/24
20.157.253.0/24
20.160.0.0/16
20.161.0.0/16
20.163.0.0/17
20.163.128.0/17
20.165.0.0/17
20.165.128.0/17
20.166.0.0/16
20.168.0.0/17
20.168.128.0/19
20.168.160.0/21
20.168.176.0/20
20.168.192.0/18
20.169.0.0/17
20.169.128.0/17
20.171.0.0/16
20.172.0.0/17
20.172.128.0/17
20.175.0.0/17
20.175.128.0/17
20.184.64.0/18
20.184.128.0/17
20.185.0.0/16
20.186.0.0/17
20.186.128.0/18
20.186.192.0/18
20.187.0.0/18
20.188.64.0/19
20.189.0.0/18
20.189.128.0/18
20.190.0.0/18
20.190.128.0/24
20.190.129.0/24
20.190.130.0/24
20.190.131.0/24
20.190.132.0/24
20.190.133.0/24
20.190.134.0/24
20.190.135.0/24
20.190.136.0/24
20.190.137.0/24
20.190.139.0/25
20.190.139.128/25
20.190.151.0/24
20.190.152.0/24
20.190.153.0/24
20.190.154.0/24
20.190.155.0/24
20.190.156.0/24
20.190.157.0/24
20.190.158.0/24
20.190.159.0/24
20.190.160.0/24
20.190.161.0/24
20.190.162.0/24
20.190.190.128/25
20.190.192.0/18
20.191.0.0/18
20.191.64.0/18
20.200.0.0/18
20.200.64.0/18
20.201.135.0/24
20.201.136.0/24
20.201.147.0/24
20.201.148.0/24
20.201.162.0/23
20.201.165.0/24
20.201.178.0/24
20.201.179.0/24
20.201.190.0/24
20.201.192.0/21
20.201.200.0/22
20.201.204.0/24
20.201.205.0/24
20.201.206.0/24
20.201.207.0/24
20.201.216.0/24
20.201.217.0/24
20.201.220.0/24
20.201.221.0/24
20.201.223.0/24
20.201.224.0/22
20.201.228.0/23
20.201.230.0/24
20.201.231.0/24
20.202.1.0/24
20.202.2.0/24
20.202.12.0/22
20.202.16.0/22
20.202.20.0/24
20.202.21.0/24
20.202.22.0/24
20.202.23.0/24
20.202.24.0/24
20.202.25.0/24
20.202.26.0/23
20.202.28.0/23
20.202.30.0/24
20.202.31.0/24
20.202.32.0/23
20.202.34.0/24
20.202.35.0/24
20.202.36.0/23
20.202.38.0/24
20.202.39.0/24
20.202.84.0/24
20.202.85.0/24
20.202.89.0/24
20.202.90.0/24
20.202.93.0/24
20.202.94.0/24
20.202.97.0/24
20.202.98.0/24
20.202.105.0/24
20.202.106.0/24
20.202.109.0/24
20.202.110.0/24
20.202.113.0/24
20.202.114.0/24
20.202.117.0/24
20.202.118.0/24
20.202.119.0/24
20.202.120.0/22
20.202.124.0/24
20.202.125.0/24
20.202.126.0/24
20.202.129.0/24
20.202.130.0/24
20.202.133.0/24
20.202.134.0/24
20.202.137.0/24
20.202.138.0/24
20.202.140.0/24
20.202.141.0/24
20.202.142.0/23
20.202.144.0/22
20.202.148.0/23
20.202.150.0/24
20.202.151.0/24
20.202.152.0/24
20.202.153.0/24
20.202.154.0/24
20.202.155.0/24
20.202.156.0/24
20.202.157.0/24
20.202.158.0/24
20.202.159.0/24
20.202.160.0/24
20.202.161.0/24
20.202.162.0/24
20.202.163.0/24
20.202.164.0/24
20.202.165.0/24
20.202.166.0/24
20.202.167.0/24
20.202.168.0/24
20.202.184.0/21
20.202.192.0/23
20.202.194.0/23
20.202.196.0/22
20.202.200.0/23
20.202.202.0/23
20.202.204.0/22
20.202.208.0/24
20.202.209.0/24
20.202.210.0/24
20.202.226.0/24
20.202.227.0/24
20.202.228.0/24
20.202.236.0/24
20.202.248.0/24
20.202.249.0/24
20.202.250.0/23
20.209.0.0/23
20.209.4.0/23
20.209.10.0/23
20.209.14.0/23
20.209.18.0/23
20.209.26.0/23
20.209.34.0/23
20.209.36.0/23
20.209.38.0/23
20.209.40.0/23
20.209.48.0/23
20.209.52.0/23
20.209.58.0/23
20.209.62.0/23
20.209.64.0/23
20.209.68.0/23
20.209.70.0/23
20.209.72.0/23
20.209.74.0/23
20.209.76.0/23
20.209.84.0/23
20.209.90.0/23
20.209.92.0/23
20.209.96.0/23
20.209.98.0/23
20.209.100.0/23
20.209.102.0/23
20.209.104.0/23
20.209.106.0/23
20.209.108.0/23
20.209.110.0/23
20.209.112.0/23
20.209.114.0/23
20.209.116.0/23
20.209.138.0/23
20.209.142.0/23
20.209.146.0/23
20.209.154.0/23
20.209.160.0/23
20.209.162.0/23
20.209.168.0/23
20.209.178.0/23
20.209.180.0/23
20.209.184.0/23
20.209.186.0/23
20.209.190.0/23
20.209.192.0/23
20.209.194.0/23
20.209.196.0/23
20.209.218.0/24
20.209.220.0/23
20.209.224.0/23
20.209.226.0/23
20.209.230.0/23
20.209.244.0/23
20.220.0.0/18
20.220.64.0/18
20.220.128.0/17
20.221.0.0/17
20.221.192.0/18
20.223.0.0/16
20.224.0.0/16
20.225.0.0/16
20.228.64.0/18
20.228.128.0/17
20.229.0.0/16
20.230.0.0/17
20.230.128.0/17
20.231.0.0/17
20.231.149.160/27
20.231.149.192/26
20.231.151.128/27
20.231.192.0/18
20.232.0.0/16
20.234.0.0/17
20.234.128.0/17
20.236.0.0/18
20.236.64.0/18
20.236.128.0/18
20.236.192.0/18
20.237.0.0/17
20.237.128.0/17
20.238.0.0/17
20.238.128.0/17
20.241.0.0/17
20.241.128.0/17
20.242.0.0/17
20.242.128.0/17
20.245.0.0/16
20.246.0.0/17
20.246.128.0/17
20.252.0.0/17
20.253.0.0/17
20.253.128.0/17
23.96.0.0/17
23.96.128.0/17
23.97.128.0/17
23.98.45.0/24
23.98.46.0/24
23.98.47.0/24
23.98.48.0/21
23.98.128.0/17
23.99.0.0/18
23.99.64.0/19
23.99.128.0/17
23.100.0.0/20
23.100.16.0/20
23.100.32.0/20
23.100.48.0/20
23.100.64.0/21
23.100.72.0/21
23.100.80.0/21
23.100.120.0/21
23.100.128.0/18
23.100.224.0/20
23.100.240.0/20
23.101.32.0/21
23.101.48.0/20
23.101.64.0/20
23.101.80.0/21
23.101.112.0/20
23.101.128.0/20
23.101.144.0/20
23.101.160.0/20
23.101.176.0/20
23.101.192.0/20
23.102.0.0/18
23.102.96.0/19
23.102.128.0/18
23.102.192.0/21
23.102.202.0/24
23.102.203.0/24
23.102.204.0/22
23.102.208.0/20
40.64.64.0/18
40.64.128.0/21
40.64.144.0/27
40.64.144.32/27
40.64.144.64/27
40.64.144.192/29
40.64.145.0/28
40.64.145.48/28
40.64.145.128/28
40.64.145.160/28
40.64.145.176/28
40.64.145.208/28
40.64.146.80/28
40.64.146.96/28
40.64.146.160/28
40.64.146.176/28
40.64.146.192/28
40.64.146.208/28
40.64.147.64/28
40.64.148.32/27
40.64.149.64/27
40.64.149.96/27
40.64.149.160/27
40.64.150.160/27
40.64.150.192/27
40.64.151.64/27
40.64.151.96/27
40.64.151.128/27
40.64.151.160/27
40.64.161.128/25
40.64.162.0/25
40.64.163.0/25
40.64.164.128/25
40.64.165.0/25
40.64.168.128/25
40.64.169.0/25
40.64.169.128/25
40.64.172.0/25
40.64.172.128/25
40.64.173.128/25
40.64.174.0/25
40.64.184.0/25
40.65.0.0/18
40.65.64.0/18
40.65.192.0/18
40.67.120.0/21
40.67.128.0/19
40.67.160.0/19
40.67.192.0/19
40.67.224.0/19
40.68.0.0/16
40.69.0.0/18
40.69.64.0/19
40.69.96.0/19
40.69.128.0/18
40.69.192.0/19
40.70.0.0/18
40.70.64.0/20
40.70.80.0/21
40.70.128.0/17
40.71.0.0/16
40.74.0.0/18
40.74.160.0/19
40.74.192.0/18
40.75.0.0/19
40.75.64.0/18
40.75.128.0/17
40.76.0.0/16
40.77.0.0/17
40.77.128.0/25
40.77.128.128/25
40.77.129.0/24
40.77.130.0/25
40.77.130.128/26
40.77.130.192/26
40.77.131.0/25
40.77.131.128/26
40.77.131.192/27
40.77.131.224/28
40.77.131.240/28
40.77.132.0/24
40.77.133.0/24
40.77.135.0/24
40.77.136.0/28
40.77.136.32/28
40.77.136.48/28
40.77.136.64/28
40.77.136.80/28
40.77.136.96/28
40.77.136.128/25
40.77.137.0/25
40.77.137.128/26
40.77.137.192/27
40.77.138.0/25
40.77.138.128/25
40.77.139.0/25
40.77.139.128/25
40.77.160.0/27
40.77.161.64/26
40.77.162.0/24
40.77.163.0/24
40.77.164.0/24
40.77.165.0/24
40.77.166.0/25
40.77.166.128/28
40.77.166.160/27
40.77.166.192/26
40.77.167.0/24
40.77.168.0/24
40.77.169.0/24
40.77.170.0/24
40.77.171.0/24
40.77.172.0/24
40.77.173.0/24
40.77.174.0/24
40.77.175.0/27
40.77.175.32/27
40.77.175.64/27
40.77.175.96/27
40.77.175.160/27
40.77.175.192/27
40.77.175.240/28
40.77.176.0/24
40.77.177.0/24
40.77.178.0/23
40.77.180.0/23
40.77.182.0/28
40.77.182.16/28
40.77.182.32/27
40.77.182.64/27
40.77.182.96/27
40.77.182.128/27
40.77.182.160/27
40.77.182.192/26
40.77.183.0/24
40.77.184.0/25
40.77.184.128/25
40.77.185.0/25
40.77.185.128/25
40.77.186.0/23
40.77.188.0/22
40.77.196.0/24
40.77.197.0/24
40.77.198.0/26
40.77.198.64/26
40.77.198.128/25
40.77.199.0/25
40.77.199.128/26
40.77.199.192/26
40.77.200.0/25
40.77.200.128/25
40.77.202.0/24
40.77.224.0/28
40.77.224.16/28
40.77.224.32/27
40.77.224.64/27
40.77.224.96/27
40.77.224.128/25
40.77.225.0/24
40.77.226.128/25
40.77.227.0/24
40.77.228.0/24
40.77.229.0/24
40.77.230.0/24
40.77.231.0/24
40.77.232.0/25
40.77.232.128/25
40.77.233.0/24
40.77.234.0/25
40.77.234.160/27
40.77.234.192/27
40.77.234.224/27
40.77.235.0/24
40.77.236.0/27
40.77.236.32/27
40.77.236.80/28
40.77.236.96/27
40.77.236.128/27
40.77.236.160/28
40.77.236.176/28
40.77.237.0/26
40.77.237.64/26
40.77.240.0/25
40.77.240.128/25
40.77.241.0/24
40.77.242.0/23
40.77.244.0/25
40.77.245.0/24
40.77.246.0/24
40.77.247.0/24
40.77.248.0/25
40.77.248.128/25
40.77.249.0/24
40.77.250.0/24
40.77.251.0/24
40.77.254.0/26
40.77.254.128/25
40.77.255.0/25
40.77.255.128/26
40.77.255.192/26
40.78.0.0/17
40.78.128.0/18
40.78.208.32/30
40.78.208.48/28
40.78.208.64/28
40.78.210.0/24
40.78.211.0/24
40.78.214.0/24
40.78.216.0/24
40.78.217.0/24
40.78.218.0/24
40.78.219.0/24
40.78.220.0/24
40.78.221.0/24
40.78.222.0/24
40.78.224.0/21
40.78.240.0/20
40.79.0.0/21
40.79.8.0/27
40.79.8.32/28
40.79.8.64/27
40.79.8.96/28
40.79.9.0/24
40.79.16.0/20
40.79.32.0/20
40.79.48.0/27
40.79.48.32/28
40.79.49.0/24
40.79.56.0/21
40.79.64.0/20
40.79.80.0/21
40.79.90.0/24
40.79.91.0/28
40.79.92.0/24
40.79.93.0/28
40.79.94.0/24
40.79.95.0/28
40.79.152.0/21
40.79.204.0/27
40.79.204.32/28
40.79.204.48/28
40.79.204.64/27
40.79.204.96/27
40.79.204.128/27
40.79.204.160/27
40.79.205.64/28
40.79.205.96/27
40.79.205.192/27
40.79.205.224/28
40.79.205.240/28
40.79.206.0/27
40.79.206.64/27
40.79.206.128/27
40.79.206.160/27
40.79.206.192/27
40.79.206.224/27
40.79.207.0/27
40.79.207.80/28
40.79.207.128/25
40.79.216.0/24
40.79.217.0/24
40.79.240.0/20
40.80.40.0/22
40.80.44.0/22
40.80.144.0/21
40.80.152.0/21
40.80.160.0/24
40.80.161.2/31
40.80.161.4/30
40.80.161.8/29
40.80.184.0/21
40.80.192.0/19
40.80.240.0/20
40.81.0.0/20
40.81.32.0/20
40.82.4.0/22
40.82.16.0/22
40.82.24.0/22
40.82.36.0/22
40.82.44.0/22
40.82.60.0/22
40.82.92.0/22
40.82.96.0/22
40.82.160.0/19
40.82.248.0/21
40.83.0.0/20
40.83.16.0/21
40.83.24.0/26
40.83.24.64/27
40.83.24.128/25
40.83.25.0/24
40.83.26.0/23
40.83.28.0/22
40.83.32.0/19
40.83.128.0/17
40.84.0.0/17
40.84.128.0/17
40.85.0.0/17
40.85.128.0/20
40.85.144.0/20
40.85.160.0/19
40.85.192.0/18
40.86.0.0/17
40.86.128.0/19
40.86.160.0/19
40.86.192.0/18
40.87.0.0/17
40.87.128.0/19
40.87.160.0/22
40.87.164.0/22
40.87.168.0/30
40.87.168.8/29
40.87.168.16/28
40.87.168.32/29
40.87.168.48/28
40.87.168.64/30
40.87.168.70/31
40.87.168.72/29
40.87.168.80/28
40.87.168.96/27
40.87.168.128/26
40.87.168.192/28
40.87.168.210/31
40.87.168.212/30
40.87.168.216/29
40.87.168.224/27
40.87.169.0/27
40.87.169.32/29
40.87.169.40/31
40.87.169.44/30
40.87.169.48/29
40.87.169.56/31
40.87.169.60/30
40.87.169.64/27
40.87.169.96/31
40.87.169.102/31
40.87.169.104/29
40.87.169.112/28
40.87.169.128/29
40.87.169.136/31
40.87.169.140/30
40.87.169.160/27
40.87.169.192/26
40.87.170.0/25
40.87.170.128/28
40.87.170.144/31
40.87.170.152/29
40.87.170.160/28
40.87.170.176/29
40.87.170.184/30
40.87.170.194/31
40.87.170.196/30
40.87.170.202/31
40.87.170.204/30
40.87.170.208/30
40.87.170.214/31
40.87.170.216/30
40.87.170.228/30
40.87.170.232/29
40.87.170.240/29
40.87.170.248/30
40.87.171.2/31
40.87.171.4/30
40.87.171.8/29
40.87.171.16/28
40.87.171.32/31
40.87.171.36/30
40.87.171.40/31
40.87.171.58/31
40.87.171.64/31
40.87.171.72/29
40.87.171.80/28
40.87.171.96/27
40.87.171.128/27
40.87.171.160/31
40.87.171.166/31
40.87.171.168/29
40.87.171.176/28
40.87.171.192/27
40.87.171.224/28
40.87.171.240/29
40.87.171.248/31
40.87.172.0/22
40.87.176.0/25
40.87.176.128/27
40.87.176.160/29
40.87.176.174/31
40.87.176.184/30
40.87.176.192/28
40.87.176.214/31
40.87.176.216/29
40.87.176.224/29
40.87.176.232/31
40.87.176.238/31
40.87.176.240/28
40.87.177.16/28
40.87.177.32/27
40.87.177.64/27
40.87.177.96/28
40.87.177.112/29
40.87.177.120/31
40.87.177.124/30
40.87.177.128/28
40.87.177.144/29
40.87.177.152/31
40.87.177.156/30
40.87.177.160/27
40.87.177.192/29
40.87.177.200/30
40.87.177.204/31
40.87.177.212/30
40.87.177.216/29
40.87.177.224/27
40.87.178.0/24
40.87.179.0/25
40.87.179.128/26
40.87.179.192/31
40.87.179.196/30
40.87.179.200/29
40.87.179.208/28
40.87.179.224/27
40.87.180.0/29
40.87.180.8/30
40.87.180.14/31
40.87.180.16/29
40.87.180.24/31
40.87.180.28/30
40.87.180.32/29
40.87.180.42/31
40.87.180.44/30
40.87.180.48/28
40.87.180.64/30
40.87.180.74/31
40.87.180.76/30
40.87.180.80/28
40.87.180.96/27
40.87.180.128/26
40.87.180.192/30
40.87.180.202/31
40.87.180.204/30
40.87.180.208/28
40.87.180.224/28
40.87.180.240/29
40.87.180.248/30
40.87.181.4/30
40.87.181.8/29
40.87.181.16/28
40.87.181.32/27
40.87.181.64/26
40.87.181.128/28
40.87.181.144/29
40.87.181.152/31
40.87.181.156/31
40.87.181.162/31
40.87.181.164/30
40.87.181.168/29
40.87.181.176/28
40.87.181.192/26
40.87.182.4/30
40.87.182.8/29
40.87.182.24/29
40.87.182.32/28
40.87.182.48/29
40.87.182.56/30
40.87.182.62/31
40.87.182.64/26
40.87.182.128/25
40.87.183.0/28
40.87.183.16/29
40.87.183.24/30
40.87.183.32/29
40.87.183.42/31
40.87.183.44/30
40.87.183.50/31
40.87.183.54/31
40.87.183.56/29
40.87.183.64/26
40.87.183.144/28
40.87.183.160/27
40.87.183.192/27
40.87.183.224/29
40.87.183.232/30
40.87.183.236/31
40.87.183.244/30
40.87.183.248/29
40.87.184.0/22
40.87.188.0/22
40.87.232.0/21
40.88.0.0/16
40.89.0.0/19
40.89.224.0/19
40.90.8.0/21
40.90.16.0/27
40.90.16.128/27
40.90.16.192/26
40.90.17.64/27
40.90.17.96/27
40.90.17.128/28
40.90.17.144/28
40.90.17.192/27
40.90.18.64/26
40.90.18.128/26
40.90.18.192/26
40.90.19.64/26
40.90.19.128/25
40.90.20.0/25
40.90.20.128/25
40.90.21.0/25
40.90.21.128/25
40.90.22.0/25
40.90.22.128/25
40.90.23.0/25
40.90.23.128/25
40.90.24.128/25
40.90.25.0/26
40.90.25.64/26
40.90.25.128/26
40.90.25.192/26
40.90.26.128/25
40.90.27.64/26
40.90.27.128/26
40.90.28.64/26
40.90.28.128/26
40.90.30.160/27
40.90.30.192/26
40.90.31.128/25
40.90.128.0/28
40.90.128.16/28
40.90.128.128/28
40.90.128.224/28
40.90.129.128/26
40.90.129.192/27
40.90.129.224/27
40.90.130.0/27
40.90.130.64/28
40.90.130.96/28
40.90.130.160/27
40.90.130.192/28
40.90.130.224/28
40.90.131.0/27
40.90.131.32/27
40.90.131.192/27
40.90.131.224/27
40.90.132.48/28
40.90.132.96/27
40.90.132.128/26
40.90.132.192/26
40.90.133.0/27
40.90.133.64/27
40.90.133.96/28
40.90.133.112/28
40.90.133.128/28
40.90.134.64/26
40.90.134.128/26
40.90.134.192/26
40.90.135.0/26
40.90.135.64/26
40.90.135.128/25
40.90.136.0/28
40.90.136.16/28
40.90.136.32/27
40.90.136.160/28
40.90.136.176/28
40.90.136.224/27
40.90.137.96/27
40.90.137.192/27
40.90.137.224/27
40.90.138.0/27
40.90.138.32/27
40.90.138.64/27
40.90.138.160/27
40.90.138.192/28
40.90.138.208/28
40.90.139.0/27
40.90.139.32/27
40.90.139.192/27
40.90.139.224/27
40.90.140.64/27
40.90.140.96/27
40.90.140.128/27
40.90.140.160/27
40.90.140.192/27
40.90.140.224/27
40.90.141.0/27
40.90.141.32/27
40.90.141.96/27
40.90.141.128/27
40.90.141.160/27
40.90.142.128/27
40.90.142.224/28
40.90.142.240/28
40.90.143.0/27
40.90.143.96/27
40.90.143.160/27
40.90.143.192/26
40.90.144.0/27
40.90.144.32/27
40.90.144.64/26
40.90.144.128/26
40.90.144.192/27
40.90.145.0/27
40.90.145.32/27
40.90.145.64/27
40.90.145.160/27
40.90.145.192/27
40.90.145.224/27
40.90.146.0/28
40.90.146.16/28
40.90.146.32/27
40.90.146.64/26
40.90.146.128/27
40.90.147.0/27
40.90.147.96/27
40.90.148.0/26
40.90.148.64/27
40.90.148.96/27
40.90.148.128/27
40.90.148.160/28
40.90.148.176/28
40.90.148.192/27
40.90.149.96/27
40.90.149.128/25
40.90.150.32/27
40.90.150.128/25
40.90.151.0/26
40.90.151.96/27
40.90.151.128/28
40.90.151.144/28
40.90.152.0/25
40.90.152.160/27
40.90.153.0/26
40.90.153.96/27
40.90.153.128/25
40.90.154.64/26
40.90.155.0/26
40.90.155.128/26
40.90.155.192/26
40.90.156.96/27
40.90.156.128/26
40.90.156.192/26
40.90.157.64/26
40.90.157.128/26
40.90.158.64/26
40.90.158.128/25
40.90.159.0/24
40.90.192.0/19
40.90.224.0/19
40.91.0.0/22
40.91.4.0/22
40.91.12.16/28
40.91.12.48/28
40.91.12.64/26
40.91.12.128/28
40.91.12.160/27
40.91.12.208/28
40.91.12.240/28
40.91.13.64/27
40.91.13.96/28
40.91.13.128/27
40.91.13.240/28
40.91.14.0/24
40.91.16.0/22
40.91.20.0/22
40.91.24.0/22
40.91.28.0/22
40.91.32.0/22
40.91.64.0/18
40.91.160.0/19
40.91.192.0/18
40.93.0.0/23
40.93.2.0/24
40.93.4.0/24
40.93.5.0/24
40.93.6.0/24
40.93.7.0/24
40.93.8.0/24
40.93.9.0/24
40.93.10.0/24
40.93.11.0/24
40.93.12.0/24
40.93.13.0/24
40.93.14.0/24
40.93.15.0/24
40.93.18.0/24
40.93.19.0/24
40.93.20.0/24
40.93.23.0/24
40.93.64.0/24
40.93.65.0/24
40.93.192.0/24
40.93.193.0/24
40.93.194.0/23
40.93.196.0/23
40.93.198.0/23
40.93.200.0/23
40.93.202.0/24
40.96.50.0/24
40.96.61.0/24
40.96.63.0/24
40.96.255.0/24
40.97.4.0/24
40.97.5.0/24
40.97.6.0/24
40.97.7.0/24
40.97.12.0/24
40.97.13.0/24
40.97.14.0/26
40.97.20.0/24
40.97.21.0/26
40.97.21.64/26
40.97.21.128/25
40.97.22.0/23
40.97.32.0/22
40.97.44.0/24
40.97.45.0/26
40.97.45.64/26
40.97.45.128/25
40.97.46.0/25
40.97.46.128/26
40.97.46.192/26
40.97.47.0/25
40.97.47.128/25
40.97.52.0/26
40.97.53.0/25
40.97.53.128/26
40.97.53.192/26
40.97.54.0/25
40.97.55.64/26
40.97.55.128/25
40.97.61.0/25
40.97.61.128/26
40.97.61.192/26
40.97.62.0/25
40.97.63.128/25
40.97.72.0/26
40.97.73.0/25
40.97.73.128/26
40.98.0.0/26
40.101.2.0/25
40.101.2.128/26
40.101.2.192/26
40.101.3.0/25
40.101.20.64/26
40.101.20.128/25
40.101.21.0/25
40.101.21.128/26
40.107.192.0/23
40.107.194.0/24
40.107.195.0/24
40.107.197.0/24
40.107.198.0/24
40.107.199.0/24
40.107.200.0/23
40.107.208.0/23
40.107.210.0/24
40.112.36.0/25
40.112.36.128/25
40.112.37.0/26
40.112.37.64/26
40.112.38.192/26
40.112.48.0/20
40.112.64.0/19
40.112.96.0/19
40.112.128.0/17
40.113.0.0/18
40.113.64.0/19
40.113.96.0/19
40.113.128.0/18
40.113.192.0/18
40.114.0.0/17
40.114.128.0/17
40.115.0.0/18
40.115.96.0/19
40.116.0.0/16
40.117.32.0/19
40.117.64.0/18
40.117.128.0/17
40.118.0.0/17
40.118.128.0/17
40.119.0.0/18
40.119.88.0/22
40.119.128.0/19
40.120.148.0/22
40.120.152.0/22
40.120.156.0/28
40.120.156.16/29
40.120.156.24/30
40.120.156.28/31
40.120.156.40/30
40.120.156.48/29
40.120.156.56/30
40.120.156.72/29
40.120.156.80/28
40.120.156.96/31
40.120.156.102/31
40.120.156.104/29
40.120.156.112/30
40.120.156.116/31
40.120.156.120/29
40.120.156.128/25
40.120.157.0/24
40.120.158.0/26
40.120.158.64/28
40.120.158.80/30
40.120.158.86/31
40.120.158.88/29
40.120.158.96/31
40.120.158.100/30
40.120.158.104/30
40.120.158.124/30
40.120.158.128/26
40.120.158.192/27
40.120.158.224/28
40.120.158.240/29
40.120.158.248/30
40.120.158.254/31
40.120.159.0/29
40.120.159.10/31
40.120.159.12/30
40.120.159.18/31
40.120.159.20/30
40.120.159.24/29
40.120.159.32/27
40.120.159.64/29
40.120.159.74/31
40.120.159.76/30
40.120.159.80/28
40.120.159.96/31
40.120.159.106/31
40.120.159.108/30
40.120.159.112/28
40.120.159.128/27
40.120.159.160/31
40.120.159.176/29
40.120.159.196/30
40.120.159.200/29
40.120.159.208/29
40.120.159.220/30
40.120.159.224/27
40.120.160.0/22
40.120.164.2/31
40.120.164.4/30
40.120.164.8/29
40.120.164.16/29
40.120.164.24/30
40.120.164.36/30
40.120.164.40/29
40.120.164.48/29
40.120.164.56/31
40.120.164.66/31
40.120.164.68/30
40.120.164.72/30
40.120.164.76/31
40.120.164.80/28
40.120.164.98/31
40.120.164.100/30
40.120.164.104/29
40.120.164.112/30
40.120.164.118/31
40.120.164.120/29
40.120.164.128/27
40.120.164.160/28
40.120.164.176/31
40.120.164.180/30
40.120.164.184/30
40.120.164.188/31
40.120.164.196/30
40.120.164.200/29
40.120.164.208/28
40.120.164.224/31
40.120.164.228/30
40.120.164.232/30
40.120.164.236/31
40.120.164.240/29
40.120.164.250/31
40.120.164.252/30
40.120.165.0/25
40.120.165.128/26
40.120.165.192/27
40.120.165.224/28
40.120.165.240/31
40.120.165.244/30
40.120.165.248/29
40.120.166.0/27
40.120.166.32/30
40.120.166.40/29
40.120.166.48/28
40.120.166.64/31
40.120.166.68/30
40.120.166.72/29
40.120.166.80/28
40.120.166.96/27
40.120.166.128/26
40.120.166.192/27
40.120.166.224/30
40.120.166.230/31
40.120.166.232/29
40.120.166.240/28
40.120.167.0/26
40.120.167.64/29
40.120.167.72/30
40.120.167.108/30
40.120.167.112/28
40.120.167.128/28
40.120.167.144/30
40.120.167.150/31
40.120.167.152/29
40.120.167.160/27
40.120.167.192/26
40.120.184.0/23
40.120.186.0/25
40.120.186.128/29
40.120.188.0/22
40.121.0.0/16
40.122.16.0/20
40.122.32.0/19
40.122.64.0/18
40.122.128.0/17
40.123.0.0/17
40.123.132.0/22
40.123.136.0/24
40.123.140.0/22
40.123.144.0/26
40.123.144.64/29
40.123.144.82/31
40.123.144.86/31
40.123.144.104/29
40.123.144.112/28
40.123.144.128/28
40.123.144.144/29
40.123.144.154/31
40.123.144.156/30
40.123.144.160/27
40.123.144.192/27
40.123.144.224/28
40.123.144.240/29
40.123.144.248/30
40.123.144.252/31
40.123.145.6/31
40.123.145.8/30
40.123.145.12/31
40.123.145.22/31
40.123.145.24/29
40.123.145.32/28
40.123.145.48/29
40.123.145.56/30
40.123.145.68/30
40.123.145.72/29
40.123.145.80/28
40.123.145.96/27
40.123.145.128/27
40.123.145.160/30
40.123.145.166/31
40.123.145.168/29
40.123.145.176/28
40.123.145.192/28
40.123.145.208/30
40.123.145.212/31
40.123.145.222/31
40.123.145.224/27
40.123.146.0/27
40.123.146.36/31
40.123.146.42/31
40.123.146.44/30
40.123.146.48/31
40.123.146.54/31
40.123.146.56/29
40.123.146.64/26
40.123.146.128/27
40.123.146.160/30
40.123.146.164/31
40.123.146.176/31
40.123.146.182/31
40.123.146.184/29
40.123.146.192/29
40.123.146.200/30
40.123.146.204/31
40.123.146.210/31
40.123.146.212/30
40.123.146.216/29
40.123.146.224/27
40.123.147.0/27
40.123.147.32/31
40.123.147.36/30
40.123.147.40/29
40.123.147.48/28
40.123.147.64/28
40.123.147.80/30
40.123.147.84/31
40.123.147.104/29
40.123.147.112/29
40.123.147.122/31
40.123.147.124/31
40.123.147.138/31
40.123.147.140/30
40.123.147.144/31
40.123.147.148/30
40.123.147.152/29
40.123.147.160/28
40.123.147.176/30
40.123.147.180/31
40.123.147.184/29
40.123.147.192/26
40.123.152.0/22
40.123.156.0/22
40.123.160.0/22
40.123.164.0/25
40.123.164.128/29
40.123.164.136/31
40.123.164.144/28
40.123.164.160/27
40.123.164.192/26
40.123.165.4/30
40.123.165.8/29
40.123.165.16/29
40.123.165.24/30
40.123.165.30/31
40.123.165.32/28
40.123.165.48/29
40.123.165.56/30
40.123.165.60/31
40.123.165.68/30
40.123.165.72/29
40.123.165.80/28
40.123.165.96/27
40.123.165.128/28
40.123.165.144/29
40.123.165.154/31
40.123.165.156/30
40.123.165.160/27
40.123.165.192/26
40.123.166.0/25
40.123.166.128/28
40.123.166.144/30
40.123.166.150/31
40.123.166.152/29
40.123.166.160/27
40.123.166.192/26
40.123.167.0/24
40.123.168.0/24
40.123.169.0/30
40.123.169.6/31
40.123.169.8/29
40.123.169.16/28
40.123.169.32/27
40.123.169.64/27
40.123.169.96/29
40.123.169.104/31
40.123.169.108/30
40.123.169.112/28
40.123.169.140/30
40.123.169.144/28
40.123.169.160/27
40.123.169.192/26
40.123.170.0/29
40.123.170.8/30
40.123.170.12/31
40.123.170.22/31
40.123.170.24/29
40.123.170.32/28
40.123.170.52/30
40.123.170.56/31
40.123.170.70/31
40.123.170.72/30
40.123.170.76/31
40.123.170.84/30
40.123.170.88/29
40.123.170.96/29
40.123.170.104/30
40.123.170.108/31
40.123.170.116/30
40.123.170.120/29
40.123.170.130/31
40.123.170.132/30
40.123.170.136/29
40.123.170.144/28
40.123.170.160/28
40.123.170.176/29
40.123.170.184/30
40.123.170.192/31
40.123.170.196/30
40.123.170.200/29
40.123.170.208/29
40.123.170.216/30
40.123.170.220/31
40.123.170.224/27
40.123.171.0/24
40.123.176.0/22
40.123.180.0/22
40.123.184.0/26
40.123.184.64/28
40.123.184.80/29
40.123.184.88/31
40.123.184.98/31
40.123.184.100/30
40.123.184.104/29
40.123.184.112/28
40.123.184.128/27
40.123.184.168/29
40.123.184.176/29
40.123.184.184/31
40.123.184.194/31
40.123.184.196/30
40.123.184.200/30
40.123.184.204/31
40.123.184.208/29
40.123.184.230/31
40.123.184.232/29
40.123.185.8/29
40.123.185.16/28
40.123.185.32/27
40.123.185.64/30
40.123.185.84/30
40.123.185.94/31
40.123.185.100/30
40.123.185.104/30
40.123.185.110/31
40.123.185.112/28
40.123.185.128/27
40.123.185.162/31
40.123.185.168/30
40.123.185.176/29
40.123.185.190/31
40.123.185.192/27
40.123.185.224/28
40.123.185.240/29
40.123.185.250/31
40.123.185.254/31
40.123.186.0/29
40.123.186.8/31
40.123.186.28/31
40.123.186.42/31
40.123.186.44/30
40.123.186.48/31
40.123.186.52/31
40.123.186.56/29
40.123.186.64/26
40.123.186.128/25
40.123.187.0/25
40.123.187.128/27
40.123.187.160/30
40.123.187.170/31
40.123.187.172/30
40.123.187.176/29
40.123.187.188/30
40.123.187.192/29
40.123.187.200/31
40.123.187.204/30
40.123.187.208/28
40.123.187.226/31
40.123.187.228/30
40.123.187.232/29
40.123.187.244/30
40.123.187.248/29
40.124.0.0/16
40.125.32.0/19
40.125.64.0/18
40.126.0.0/24
40.126.1.0/24
40.126.2.0/24
40.126.3.0/24
40.126.4.0/24
40.126.5.0/24
40.126.6.0/24
40.126.7.0/24
40.126.8.0/24
40.126.9.0/24
40.126.11.0/25
40.126.11.128/25
40.126.23.0/24
40.126.24.0/24
40.126.25.0/24
40.126.26.0/24
40.126.27.0/24
40.126.28.0/24
40.126.29.0/24
40.126.30.0/24
40.126.31.0/24
40.126.32.0/24
40.126.33.0/24
40.126.34.0/24
40.126.62.128/25
40.126.202.0/24
40.127.96.0/20
40.127.128.0/17
48.192.0.0/17
48.192.128.0/17
48.194.0.0/17
48.194.128.0/17
48.195.0.0/17
48.195.128.0/17
48.199.0.0/16
48.200.0.0/17
48.202.0.0/17
48.202.128.0/17
48.204.0.0/17
48.204.128.0/17
48.205.0.0/24
48.205.1.0/24
48.205.2.0/24
48.205.3.0/24
48.205.4.0/24
48.205.5.0/24
48.205.6.0/24
48.205.7.0/24
48.205.8.0/24
48.205.9.0/24
48.205.10.0/24
48.205.11.0/24
48.205.12.0/24
48.205.13.0/24
48.205.14.0/24
48.205.15.0/24
48.205.16.0/24
48.205.17.0/24
48.205.18.0/24
48.205.19.0/24
48.205.20.0/24
48.205.21.0/24
48.205.22.0/24
48.205.23.0/24
48.205.24.0/24
48.205.25.0/24
48.205.26.0/24
48.205.27.0/24
48.205.28.0/24
48.205.29.0/24
48.205.30.0/24
48.205.32.0/24
48.205.33.0/24
48.205.34.0/24
48.205.35.0/24
48.205.36.0/24
48.205.37.0/24
48.205.38.0/24
48.205.39.0/24
48.205.40.0/24
48.205.41.0/24
48.205.42.0/24
48.205.43.0/24
48.205.44.0/24
48.205.45.0/24
48.205.46.0/24
48.205.47.0/24
48.205.48.0/24
48.205.49.0/24
48.205.50.0/24
48.205.51.0/24
48.205.52.0/24
48.205.53.0/24
48.205.54.0/24
48.205.55.0/24
48.205.56.0/24
48.205.57.0/24
48.205.58.0/24
48.205.59.0/24
48.205.60.0/24
48.205.61.0/24
48.205.62.0/24
48.205.64.0/24
48.205.65.0/24
48.205.66.0/24
48.205.67.0/24
48.205.68.0/24
48.205.69.0/24
48.205.70.0/24
48.205.71.0/24
48.205.72.0/24
48.205.73.0/24
48.205.74.0/24
48.205.75.0/24
48.205.76.0/24
48.205.77.0/24
48.205.78.0/24
48.205.79.0/24
48.205.80.0/24
48.205.81.0/24
48.205.82.0/24
48.205.83.0/24
48.205.84.0/24
48.205.85.0/24
48.205.86.0/24
48.205.87.0/24
48.205.88.0/24
48.205.89.0/24
48.205.91.0/24
48.205.92.0/24
48.205.93.0/24
48.205.94.0/24
48.205.95.0/24
48.205.96.0/24
48.205.97.0/24
48.205.98.0/24
48.205.99.0/24
48.205.100.0/24
48.205.101.0/24
48.205.102.0/24
48.205.103.0/24
48.205.104.0/24
48.205.105.0/24
48.205.107.0/24
48.205.108.0/24
48.205.109.0/24
48.205.110.0/24
48.205.111.0/24
48.205.112.0/24
48.205.113.0/24
48.205.114.0/24
48.205.115.0/24
48.205.116.0/24
48.205.117.0/24
48.205.118.0/24
48.205.119.0/24
48.205.121.0/24
48.205.122.0/24
48.205.123.0/24
48.205.124.0/24
48.205.125.0/24
48.205.126.0/24
48.205.127.0/24
48.205.129.0/24
48.205.130.0/24
48.205.131.0/24
48.205.132.0/24
48.205.133.0/24
48.205.134.0/24
48.205.135.0/24
48.205.137.0/24
48.205.138.0/24
48.205.139.0/24
48.205.140.0/24
48.205.141.0/24
48.205.142.0/24
48.205.143.0/24
48.205.145.0/24
48.205.146.0/24
48.205.147.0/24
48.205.148.0/24
48.205.149.0/24
48.205.151.0/24
48.205.152.0/24
48.205.153.0/24
48.205.155.0/24
48.205.156.0/24
48.205.157.0/24
48.205.159.0/24
48.205.161.0/24
48.205.163.0/24
48.205.165.0/24
48.205.167.0/24
48.205.168.0/24
48.205.169.0/24
48.205.171.0/24
48.205.173.0/24
48.205.175.0/24
48.205.177.0/24
48.205.199.0/24
48.205.209.0/24
48.205.213.0/24
48.205.215.0/24
48.205.216.0/24
48.205.218.0/24
48.205.220.0/24
48.205.226.0/24
48.205.230.0/24
48.205.232.0/24
48.205.246.0/24
48.205.250.0/24
48.205.252.0/24
48.206.0.0/16
48.207.0.0/17
48.208.3.0/24
48.208.4.0/22
48.208.8.0/23
48.208.10.0/24
48.208.11.0/24
48.208.12.0/22
48.208.16.0/23
48.208.18.0/24
48.208.19.0/24
48.208.20.0/22
48.208.24.0/23
48.208.26.0/24
48.208.28.0/24
48.208.45.0/24
48.208.47.0/24
48.208.49.0/24
48.208.53.0/24
48.208.54.0/24
48.208.55.0/24
48.208.56.0/22
48.208.60.0/23
48.208.62.0/24
48.208.67.0/24
48.208.68.0/22
48.208.72.0/24
48.208.73.0/24
48.208.74.0/23
48.208.76.0/24
48.208.77.0/24
48.208.78.0/23
48.208.80.0/24
48.208.82.0/24
48.208.83.0/24
48.208.84.0/24
48.208.85.0/24
48.208.86.0/24
48.208.88.0/24
48.208.89.0/24
48.208.90.0/24
48.208.128.0/21
48.208.136.0/22
48.208.140.0/24
48.208.141.0/24
48.208.142.0/23
48.208.144.0/22
48.208.148.0/23
48.208.150.0/24
48.208.151.0/24
48.208.152.0/21
48.208.160.0/24
48.208.169.0/24
48.208.170.0/23
48.208.172.0/22
48.208.176.0/24
48.208.177.0/24
48.208.178.0/23
48.208.180.0/23
48.208.182.0/24
48.208.216.0/24
48.208.223.0/24
48.209.0.0/17
48.209.128.0/18
48.209.192.0/18
48.211.0.0/17
48.211.128.0/17
48.212.2.0/24
48.212.3.0/24
48.212.4.0/24
48.212.5.0/24
48.212.6.0/24
48.212.7.0/24
48.212.18.0/24
48.212.23.0/24
48.212.24.0/24
48.212.25.0/24
48.212.36.0/24
48.212.58.0/24
48.212.59.0/24
48.212.128.0/24
48.212.129.0/24
48.212.130.0/24
48.212.131.0/24
48.212.132.0/24
48.212.133.0/24
48.212.134.0/24
48.212.135.0/24
48.212.146.0/24
48.212.151.0/24
48.212.163.0/24
48.212.186.0/24
48.212.187.0/24
48.213.2.0/24
48.213.3.0/24
48.213.4.0/24
48.213.5.0/24
48.213.6.0/24
48.213.7.0/24
48.213.18.0/24
48.213.23.0/24
48.213.24.0/24
48.213.25.0/24
48.213.35.0/24
48.213.56.0/24
48.213.59.0/24
48.213.128.0/25
48.213.128.128/26
48.214.0.0/17
48.214.128.0/17
48.216.128.0/17
48.217.0.0/16
48.219.240.0/20
48.221.0.0/17
48.221.128.0/17
48.222.0.0/17
48.222.128.0/17
48.223.128.0/17
50.85.0.0/16
51.5.0.0/23
51.5.2.0/23
51.5.11.0/24
51.5.12.0/24
51.5.20.0/24
51.5.23.0/24
51.5.24.0/24
51.5.26.0/24
51.5.38.0/23
51.5.40.0/23
51.5.45.0/24
51.5.46.0/24
51.5.47.0/24
51.5.48.0/24
51.5.71.0/24
51.5.255.208/28
51.5.255.224/28
51.5.255.240/28
51.8.0.0/17
51.8.128.0/18
51.8.192.0/18
51.57.0.0/17
51.104.64.0/18
51.104.128.0/18
51.105.96.0/19
51.105.128.0/17
51.124.0.0/16
51.136.0.0/16
51.137.0.0/17
51.137.192.0/18
51.138.0.0/17
51.138.176.0/20
51.138.224.0/20
51.141.160.0/19
51.143.0.0/17
51.144.0.0/16
51.145.128.0/17
52.96.11.0/24
52.101.0.0/22
52.101.4.0/22
52.101.8.0/24
52.101.9.0/24
52.101.10.0/24
52.101.11.0/24
52.101.12.0/22
52.101.16.0/22
52.101.20.0/22
52.101.24.0/22
52.101.28.0/22
52.101.32.0/22
52.101.36.0/22
52.101.40.0/24
52.101.41.0/24
52.101.42.0/24
52.101.43.0/24
52.101.44.0/23
52.101.46.0/23
52.101.48.0/23
52.101.50.0/24
52.101.51.0/24
52.101.52.0/22
52.101.56.0/22
52.101.60.0/24
52.101.61.0/24
52.101.62.0/23
52.101.64.0/24
52.101.65.0/24
52.101.66.0/23
52.101.68.0/24
52.101.69.0/24
52.101.70.0/23
52.101.72.0/23
52.101.84.0/24
52.101.85.0/24
52.101.86.0/23
52.101.189.0/24
52.101.190.0/24
52.101.191.0/24
52.101.192.0/24
52.101.193.0/24
52.101.194.0/24
52.101.201.0/24
52.101.202.0/24
52.102.128.0/24
52.102.130.0/24
52.102.132.0/24
52.102.133.0/24
52.102.134.0/24
52.102.135.0/24
52.102.136.0/24
52.102.137.0/24
52.102.138.0/24
52.102.139.0/24
52.102.140.0/24
52.102.141.0/24
52.102.144.0/24
52.102.145.0/24
52.102.146.0/24
52.102.149.0/24
52.102.158.0/24
52.102.159.0/24
52.102.160.0/24
52.102.161.0/24
52.103.0.0/24
52.103.1.0/24
52.103.2.0/24
52.103.4.0/24
52.103.6.0/24
52.103.7.0/24
52.103.8.0/24
52.103.9.0/24
52.103.10.0/24
52.103.11.0/24
52.103.12.0/24
52.103.13.0/24
52.103.14.0/24
52.103.15.0/24
52.103.18.0/24
52.103.19.0/24
52.103.20.0/24
52.103.23.0/24
52.103.32.0/24
52.103.33.0/24
52.103.128.0/24
52.103.132.0/24
52.103.133.0/24
52.103.134.0/24
52.103.135.0/24
52.103.136.0/24
52.103.137.0/24
52.103.138.0/24
52.103.139.0/24
52.103.140.0/24
52.103.141.0/24
52.103.144.0/24
52.103.145.0/24
52.103.148.0/24
52.103.160.0/24
52.103.161.0/24
52.106.0.0/24
52.106.2.0/24
52.106.3.0/24
52.106.4.0/24
52.106.5.0/24
52.106.7.0/24
52.106.8.0/24
52.106.9.0/24
52.106.10.0/23
52.106.12.0/24
52.106.13.0/24
52.106.14.0/24
52.106.17.0/24
52.106.64.0/24
52.106.65.0/24
52.106.66.0/24
52.106.120.64/27
52.106.120.96/27
52.106.121.32/27
52.106.121.64/27
52.106.122.64/27
52.106.122.96/27
52.106.122.128/27
52.106.138.0/24
52.106.139.0/24
52.106.184.96/27
52.106.184.128/27
52.108.0.0/21
52.108.16.0/21
52.108.24.0/21
52.108.42.0/23
52.108.56.0/21
52.108.72.0/24
52.108.78.0/24
52.108.79.0/24
52.108.80.0/24
52.108.84.0/24
52.108.93.0/24
52.108.102.0/23
52.108.104.0/24
52.108.105.0/24
52.108.106.0/23
52.108.108.0/23
52.108.110.0/24
52.108.139.0/24
52.108.165.0/24
52.108.166.0/23
52.108.174.0/23
52.108.176.0/24
52.108.181.0/24
52.108.182.0/24
52.108.185.0/24
52.108.186.0/24
52.108.193.0/24
52.108.196.0/24
52.108.197.0/24
52.108.202.0/24
52.108.203.0/24
52.108.208.0/21
52.108.216.0/22
52.108.232.0/23
52.108.240.0/21
52.108.248.0/21
52.109.0.0/22
52.109.4.0/22
52.109.8.0/22
52.109.12.0/22
52.109.16.0/22
52.109.20.0/22
52.109.24.0/22
52.109.76.0/22
52.109.88.0/22
52.109.92.0/22
52.109.96.0/22
52.109.136.0/22
52.109.176.0/24
52.111.206.0/24
52.111.211.0/24
52.111.226.0/24
52.111.227.0/24
52.111.229.0/24
52.111.230.0/24
52.111.235.0/24
52.111.236.0/24
52.111.239.0/24
52.111.243.0/24
52.111.245.0/24
52.111.246.0/24
52.111.251.0/24
52.112.0.0/24
52.112.3.0/24
52.112.5.0/24
52.112.9.0/24
52.112.11.0/24
52.112.13.0/24
52.112.14.0/23
52.112.17.0/24
52.112.18.0/23
52.112.22.0/24
52.112.23.0/24
52.112.24.0/21
52.112.37.0/24
52.112.38.0/24
52.112.39.0/24
52.112.41.0/24
52.112.43.0/24
52.112.44.0/24
52.112.45.0/24
52.112.46.0/24
52.112.47.0/24
52.112.51.0/24
52.112.53.0/24
52.112.55.0/24
52.112.56.0/24
52.112.57.0/24
52.112.58.0/24
52.112.59.0/24
52.112.60.0/24
52.112.61.0/24
52.112.62.0/24
52.112.63.0/24
52.112.65.0/24
52.112.66.0/24
52.112.68.0/24
52.112.69.0/24
52.112.70.0/24
52.112.72.0/24
52.112.75.0/24
52.112.76.0/22
52.112.83.0/24
52.112.84.0/23
52.112.86.0/23
52.112.88.0/24
52.112.89.0/24
52.112.90.0/24
52.112.91.0/24
52.112.92.0/24
52.112.93.0/24
52.112.94.0/24
52.112.95.0/24
52.112.96.0/24
52.112.97.0/24
52.112.98.0/23
52.112.101.0/24
52.112.102.0/24
52.112.104.0/24
52.112.105.0/24
52.112.106.0/23
52.112.108.0/24
52.112.109.0/24
52.112.110.0/24
52.112.112.0/24
52.112.113.0/24
52.112.114.0/24
52.112.115.0/24
52.112.116.0/24
52.112.117.0/24
52.112.123.0/24
52.112.124.0/24
52.112.127.0/24
52.112.128.0/24
52.112.130.0/24
52.112.131.0/24
52.112.133.0/24
52.112.135.0/24
52.112.136.0/24
52.112.137.0/24
52.112.138.0/24
52.112.144.0/20
52.112.160.0/24
52.112.161.0/24
52.112.163.0/24
52.112.191.0/24
52.112.192.0/24
52.112.193.0/24
52.112.194.0/24
52.112.196.0/24
52.112.197.0/24
52.112.209.0/24
52.112.216.0/21
52.112.228.0/24
52.112.229.0/24
52.112.232.0/24
52.112.233.0/24
52.112.236.0/24
52.112.237.0/24
52.112.238.0/24
52.112.243.0/24
52.112.254.0/24
52.112.255.0/24
52.113.0.0/24
52.113.5.0/24
52.113.7.0/24
52.113.8.0/24
52.113.9.0/24
52.113.12.0/24
52.113.16.0/20
52.113.32.0/24
52.113.34.0/24
52.113.35.0/24
52.113.37.0/24
52.113.38.0/23
52.113.40.0/21
52.113.48.0/20
52.113.64.0/24
52.113.66.0/24
52.113.67.0/24
52.113.68.0/24
52.113.69.0/24
52.113.80.0/24
52.113.81.0/24
52.113.83.0/24
52.113.84.0/24
52.113.85.0/24
52.113.86.0/24
52.113.108.0/23
52.113.111.0/24
52.113.112.0/20
52.113.129.0/24
52.113.130.0/24
52.113.131.0/24
52.113.135.0/24
52.113.136.0/21
52.113.144.0/21
52.113.160.0/19
52.113.198.0/24
52.113.199.0/24
52.113.203.0/24
52.113.205.0/24
52.113.206.0/24
52.113.207.0/24
52.113.208.0/20
52.114.1.0/24
52.114.2.0/24
52.114.53.0/24
52.114.62.0/24
52.114.63.0/24
52.114.65.0/24
52.114.67.0/24
52.114.69.0/24
52.114.71.0/24
52.114.72.0/22
52.114.76.0/22
52.114.96.0/24
52.114.97.0/24
52.114.98.0/24
52.114.99.0/24
52.114.100.0/24
52.114.122.0/24
52.114.124.0/24
52.114.126.0/24
52.114.128.0/22
52.114.132.0/22
52.114.136.0/21
52.114.144.0/22
52.114.148.0/22
52.114.152.0/21
52.114.160.0/22
52.114.164.0/22
52.114.168.0/22
52.114.172.0/22
52.114.177.0/24
52.114.179.0/24
52.114.180.0/22
52.114.184.0/23
52.114.186.0/23
52.114.189.0/24
52.114.191.0/24
52.114.206.0/23
52.114.208.0/24
52.114.210.0/23
52.114.212.0/23
52.114.220.0/22
52.114.231.0/24
52.114.233.0/24
52.114.241.0/24
52.114.242.0/24
52.114.245.0/24
52.114.247.0/24
52.114.248.0/22
52.114.252.0/22
52.115.12.0/23
52.115.15.0/24
52.115.17.0/24
52.115.19.0/24
52.115.20.0/24
52.115.21.0/24
52.115.22.0/24
52.115.23.0/24
52.115.24.0/24
52.115.25.0/24
52.115.26.0/24
52.115.27.0/24
52.115.28.0/24
52.115.29.0/24
52.115.30.0/24
52.115.31.0/24
52.115.33.0/24
52.115.35.0/24
52.115.36.0/24
52.115.37.0/24
52.115.38.0/24
52.115.39.0/24
52.115.40.0/24
52.115.41.0/24
52.115.42.0/24
52.115.43.0/24
52.115.44.0/24
52.115.45.0/24
52.115.49.0/24
52.115.50.0/24
52.115.51.0/24
52.115.52.0/24
52.115.53.0/24
52.115.54.0/24
52.115.55.0/24
52.115.56.0/24
52.115.58.0/24
52.115.59.0/24
52.115.60.0/24
52.115.61.0/24
52.115.62.0/23
52.115.65.0/24
52.115.66.0/24
52.115.67.0/24
52.115.68.0/22
52.115.72.0/24
52.115.73.0/24
52.115.74.0/24
52.115.75.0/24
52.115.76.0/22
52.115.80.0/23
52.115.82.0/24
52.115.83.0/24
52.115.84.0/22
52.115.88.0/22
52.115.92.0/24
52.115.93.0/24
52.115.94.0/24
52.115.115.0/24
52.115.116.0/24
52.115.117.0/24
52.115.119.0/24
52.115.121.0/24
52.115.123.0/24
52.115.125.0/24
52.115.127.0/24
52.115.140.0/22
52.115.144.0/20
52.115.160.0/19
52.115.192.0/19
52.115.224.0/23
52.115.226.0/23
52.115.228.0/23
52.115.230.0/24
52.115.231.0/24
52.115.232.0/24
52.115.233.0/24
52.115.234.0/24
52.115.242.0/23
52.120.0.0/19
52.120.32.0/19
52.120.64.0/19
52.120.96.0/19
52.120.128.0/21
52.120.136.0/21
52.120.152.0/22
52.120.192.0/20
52.120.208.0/20
52.120.224.0/20
52.121.0.0/21
52.121.16.0/21
52.121.24.0/21
52.121.32.0/22
52.121.36.0/22
52.121.48.0/20
52.121.64.0/20
52.121.166.0/24
52.121.184.0/21
52.121.208.0/21
52.121.224.0/24
52.122.0.0/24
52.122.1.0/24
52.122.2.0/23
52.122.4.0/23
52.122.6.0/24
52.122.7.0/24
52.122.8.0/22
52.122.12.0/22
52.122.16.0/22
52.122.20.0/22
52.122.24.0/22
52.122.56.0/21
52.122.64.0/21
52.122.72.0/21
52.122.80.0/20
52.122.96.0/20
52.122.112.0/21
52.122.148.0/22
52.122.152.0/21
52.122.160.0/22
52.122.164.0/22
52.122.168.0/21
52.122.176.0/22
52.122.180.0/22
52.122.184.0/21
52.122.192.0/22
52.123.0.0/24
52.123.1.0/24
52.123.2.0/24
52.123.3.0/24
52.123.4.0/24
52.123.5.0/24
52.123.6.0/24
52.123.7.0/24
52.123.10.0/24
52.123.11.0/24
52.123.12.0/24
52.123.13.0/24
52.123.16.0/24
52.123.17.0/24
52.123.18.0/24
52.123.19.0/24
52.123.30.0/24
52.123.41.0/24
52.123.56.0/24
52.123.57.0/24
52.123.63.0/24
52.123.64.0/24
52.123.102.0/23
52.123.104.0/24
52.123.105.0/24
52.123.106.0/23
52.123.108.0/23
52.123.110.0/24
52.123.111.0/24
52.123.112.0/23
52.123.114.0/24
52.123.115.0/24
52.123.116.0/22
52.123.120.0/22
52.123.124.0/24
52.123.125.0/24
52.123.126.0/24
52.123.133.0/24
52.123.134.0/23
52.123.136.0/22
52.123.140.0/24
52.123.183.0/24
52.123.184.0/24
52.123.185.0/24
52.123.186.0/24
52.123.187.0/24
52.123.188.0/24
52.123.189.0/24
52.123.190.0/23
52.123.195.0/24
52.123.213.0/24
52.123.216.0/24
52.123.217.0/24
52.123.218.0/24
52.123.221.0/24
52.123.222.0/24
52.125.128.0/22
52.125.132.0/22
52.125.136.0/24
52.125.137.0/24
52.125.138.0/23
52.125.140.0/23
52.136.0.0/22
52.136.4.0/22
52.136.22.0/24
52.136.23.0/24
52.136.27.0/24
52.136.29.0/24
52.136.30.0/24
52.136.64.0/18
52.136.192.0/18
52.137.0.0/18
52.137.64.0/18
52.137.128.0/17
52.138.0.0/18
52.138.80.0/21
52.138.96.0/19
52.138.128.0/17
52.139.0.0/18
52.139.64.0/18
52.141.64.0/18
52.141.128.0/18
52.141.192.0/19
52.141.240.0/20
52.142.0.0/18
52.142.64.0/18
52.142.192.0/18
52.143.0.0/18
52.143.64.0/18
52.143.192.0/24
52.143.193.0/24
52.143.194.0/24
52.143.195.0/24
52.143.197.0/24
52.143.207.0/24
52.143.208.0/24
52.143.209.0/24
52.143.211.0/24
52.143.214.0/24
52.143.224.0/19
52.146.0.0/17
52.146.128.0/17
52.147.160.0/19
52.147.192.0/18
52.148.0.0/18
52.148.128.0/18
52.148.192.0/18
52.149.0.0/18
52.149.64.0/18
52.149.128.0/17
52.150.0.0/17
52.150.128.0/17
52.151.0.0/18
52.151.128.0/17
52.152.0.0/17
52.152.128.0/17
52.153.0.0/18
52.153.64.0/18
52.153.128.0/18
52.153.192.0/18
52.154.0.0/18
52.154.64.0/18
52.154.128.0/17
52.155.0.0/19
52.155.32.0/19
52.155.64.0/19
52.155.128.0/17
52.156.0.0/19
52.156.64.0/18
52.156.128.0/19
52.156.192.0/18
52.157.0.0/18
52.157.64.0/18
52.157.128.0/17
52.158.0.0/17
52.158.160.0/20
52.158.192.0/19
52.158.224.0/19
52.159.0.0/18
52.159.64.0/18
52.159.128.0/17
52.160.0.0/16
52.161.0.0/16
52.162.0.0/16
52.164.0.0/16
52.165.0.0/19
52.165.32.0/20
52.165.48.0/28
52.165.49.0/24
52.165.56.0/21
52.165.64.0/19
52.165.96.0/21
52.165.104.0/25
52.165.128.0/17
52.166.0.0/16
52.167.0.0/16
52.168.0.0/16
52.169.0.0/16
52.170.0.0/16
52.171.0.0/16
52.173.0.0/16
52.174.0.0/16
52.175.192.0/18
52.176.0.0/17
52.176.128.0/19
52.176.160.0/21
52.176.176.0/20
52.176.192.0/19
52.176.224.0/24
52.177.0.0/16
52.178.0.0/17
52.178.128.0/17
52.179.0.0/17
52.179.128.0/17
52.180.0.0/17
52.180.128.0/19
52.180.184.0/27
52.180.184.32/28
52.180.185.0/24
52.182.128.0/17
52.183.0.0/17
52.183.192.0/18
52.184.128.0/19
52.184.160.0/21
52.184.168.0/28
52.184.168.80/28
52.184.168.96/27
52.184.168.128/28
52.184.169.0/24
52.184.170.0/24
52.184.176.0/20
52.184.192.0/18
52.185.0.0/19
52.185.32.0/20
52.185.48.0/21
52.185.56.0/26
52.185.56.64/27
52.185.56.96/28
52.185.56.128/27
52.185.56.160/28
52.185.64.0/19
52.185.96.0/20
52.185.112.0/26
52.185.112.96/27
52.185.120.0/21
52.185.192.0/18
52.186.0.0/16
52.188.0.0/16
52.189.0.0/17
52.189.128.0/18
52.190.0.0/17
52.190.128.0/17
52.191.0.0/17
52.191.128.0/18
52.191.192.0/18
52.224.0.0/16
52.225.0.0/17
52.225.128.0/21
52.225.136.0/27
52.225.136.32/28
52.225.136.64/28
52.225.137.0/24
52.225.192.0/18
52.226.0.0/16
52.228.0.0/17
52.228.128.0/17
52.229.0.0/18
52.229.64.0/18
52.230.128.0/17
52.232.0.0/17
52.232.128.0/21
52.232.146.0/24
52.232.147.0/24
52.232.148.0/24
52.232.149.0/24
52.232.151.0/24
52.232.152.0/24
52.232.156.0/24
52.232.157.0/24
52.232.159.0/24
52.232.160.0/19
52.232.192.0/18
52.233.0.0/18
52.233.64.0/18
52.233.128.0/17
52.234.0.0/17
52.234.128.0/17
52.235.0.0/18
52.235.64.0/18
52.236.0.0/17
52.236.128.0/17
52.237.0.0/18
52.237.128.0/18
52.238.0.0/18
52.238.192.0/18
52.239.0.0/17
52.239.136.0/22
52.239.140.0/22
52.239.148.32/27
52.239.148.64/26
52.239.148.128/25
52.239.149.0/24
52.239.150.0/23
52.239.152.0/22
52.239.156.0/24
52.239.157.0/25
52.239.157.128/26
52.239.157.192/27
52.239.158.0/23
52.239.160.0/22
52.239.164.0/25
52.239.164.128/26
52.239.165.64/26
52.239.165.128/27
52.239.167.0/24
52.239.168.0/22
52.239.172.0/22
52.239.176.128/25
52.239.177.32/27
52.239.177.64/26
52.239.177.128/25
52.239.178.0/23
52.239.180.0/22
52.239.184.0/25
52.239.184.128/27
52.239.184.160/28
52.239.184.192/27
52.239.185.32/27
52.239.185.64/27
52.239.186.0/24
52.239.189.0/24
52.239.190.0/25
52.239.192.0/26
52.239.192.64/28
52.239.192.96/27
52.239.192.160/27
52.239.192.192/26
52.239.193.0/24
52.239.195.0/24
52.239.198.0/25
52.239.198.160/27
52.239.198.192/26
52.239.199.0/24
52.239.200.0/23
52.239.203.0/24
52.239.205.0/24
52.239.206.0/24
52.239.207.32/28
52.239.207.64/26
52.239.207.128/26
52.239.207.192/26
52.239.208.0/23
52.239.210.0/23
52.239.212.0/23
52.239.214.0/23
52.239.220.0/23
52.239.222.0/23
52.239.228.0/23
52.239.234.0/23
52.239.236.0/23
52.239.242.0/23
52.239.244.0/23
52.239.246.0/23
52.239.248.0/24
52.239.252.0/24
52.239.253.0/24
52.239.254.0/23
52.240.0.0/17
52.240.128.0/17
52.241.0.0/16
52.242.0.0/18
52.242.64.0/18
52.242.128.0/17
52.245.8.0/22
52.245.12.0/22
52.245.24.0/22
52.245.28.0/22
52.245.32.0/22
52.245.40.0/22
52.245.44.0/24
52.245.45.0/25
52.245.45.128/28
52.245.45.160/27
52.245.45.192/26
52.245.46.0/27
52.245.46.48/28
52.245.46.64/28
52.245.46.112/28
52.245.46.128/28
52.245.46.160/27
52.245.46.192/26
52.245.48.0/22
52.245.52.0/22
52.245.60.0/22
52.245.68.0/24
52.245.69.32/27
52.245.69.64/27
52.245.69.96/28
52.245.69.144/28
52.245.69.160/27
52.245.69.192/26
52.245.70.0/23
52.245.72.0/22
52.245.88.0/22
52.245.104.0/22
52.245.108.0/22
52.245.124.0/22
52.246.0.0/17
52.246.152.0/21
52.246.192.0/18
52.247.0.0/17
52.247.192.0/18
52.248.0.0/17
52.248.128.0/17
52.249.0.0/18
52.249.128.0/17
52.250.0.0/17
52.250.128.0/18
52.250.192.0/18
52.251.0.0/17
52.252.0.0/17
52.252.128.0/17
52.253.0.0/18
52.253.64.0/20
52.253.128.0/20
52.253.148.0/23
52.253.154.0/23
52.253.160.0/24
52.253.179.0/24
52.253.180.0/24
52.253.182.0/23
52.253.184.0/24
52.253.196.0/24
52.254.0.0/18
52.254.64.0/19
52.254.96.0/20
52.254.112.0/21
52.254.128.0/17
52.255.0.0/19
52.255.64.0/18
52.255.128.0/17
57.150.0.0/23
57.150.2.0/23
57.150.4.0/23
57.150.8.0/26
57.150.8.64/27
57.150.8.96/28
57.150.8.112/28
57.150.8.128/25
57.150.9.0/24
57.150.10.0/26
57.150.10.64/28
57.150.10.80/28
57.150.10.96/27
57.150.10.128/25
57.150.11.0/26
57.150.11.64/27
57.150.11.96/28
57.150.11.112/28
57.150.11.128/25
57.150.12.0/25
57.150.12.128/28
57.150.13.128/27
57.150.13.160/28
57.150.13.176/28
57.150.13.192/26
57.150.14.0/23
57.150.16.0/25
57.150.16.128/25
57.150.18.0/26
57.150.18.64/28
57.150.18.80/28
57.150.18.96/27
57.150.18.128/26
57.150.18.192/27
57.150.18.224/28
57.150.18.240/28
57.150.19.0/26
57.150.19.64/28
57.150.19.80/28
57.150.19.96/27
57.150.19.128/27
57.150.19.160/28
57.150.20.0/28
57.150.20.16/28
57.150.20.32/27
57.150.20.64/26
57.150.20.128/25
57.150.26.0/23
57.150.28.0/23
57.150.30.0/23
57.150.32.0/23
57.150.38.0/23
57.150.42.0/23
57.150.48.0/23
57.150.52.0/23
57.150.54.0/23
57.150.56.0/23
57.150.60.0/23
57.150.62.0/23
57.150.66.0/23
57.150.68.0/23
57.150.70.0/23
57.150.72.0/23
57.150.74.0/23
57.150.78.0/23
57.150.80.0/23
57.150.82.0/23
57.150.84.0/23
57.150.86.0/23
57.150.90.0/23
57.150.96.0/23
57.150.98.0/23
57.150.102.0/23
57.150.104.0/23
57.150.106.0/23
57.150.108.0/23
57.150.110.0/23
57.150.118.0/23
57.150.124.0/23
57.150.128.0/23
57.150.132.0/23
57.150.134.0/23
57.150.140.0/22
57.150.144.0/23
57.150.146.0/23
57.150.148.0/23
57.150.150.0/23
57.150.152.0/23
57.150.154.0/23
57.150.156.0/23
57.150.158.0/23
57.150.160.0/23
57.150.162.0/23
57.150.164.0/23
57.150.166.0/23
57.150.168.0/23
57.150.178.0/23
57.150.182.0/23
57.150.188.0/23
57.150.190.0/23
57.150.192.0/23
57.150.204.0/23
57.150.220.0/23
57.150.222.0/23
57.150.224.0/23
57.150.228.0/23
57.150.232.0/23
57.150.234.0/23
57.150.244.0/23
57.150.250.0/23
57.150.252.0/23
57.151.0.0/17
57.151.128.0/19
57.152.0.0/17
57.153.0.0/16
57.154.0.0/17
57.154.128.0/18
57.154.192.0/18
57.157.0.0/25
57.157.0.128/26
57.157.0.192/27
57.157.1.24/30
57.157.1.76/30
57.157.1.80/28
57.157.1.96/29
57.157.1.106/31
57.157.1.108/30
57.157.1.112/28
57.157.1.128/31
57.157.1.138/31
57.157.1.140/30
57.157.1.144/29
57.157.1.152/30
57.157.1.164/30
57.157.1.168/29
57.157.1.176/28
57.157.1.192/26
57.157.2.0/26
57.157.2.64/29
57.157.2.72/30
57.157.2.78/31
57.157.2.80/28
57.157.2.96/28
57.157.2.112/29
57.157.2.120/30
57.157.2.126/31
57.157.2.128/25
57.157.3.0/25
57.157.3.128/27
57.157.3.160/28
57.157.3.176/29
57.157.3.184/30
57.157.3.188/31
57.157.3.202/31
57.157.3.204/30
57.157.3.208/28
57.157.3.224/27
57.157.4.0/24
57.157.5.0/26
57.157.5.64/27
57.157.5.112/29
57.157.5.126/31
57.157.5.128/26
57.157.5.192/29
57.157.5.202/31
57.157.5.204/30
57.157.5.208/28
57.157.5.224/27
57.157.6.0/24
57.157.7.0/27
57.157.7.50/31
57.157.7.52/30
57.157.7.56/29
57.157.7.64/26
57.157.7.128/25
57.157.8.0/22
57.157.12.0/22
57.157.28.0/24
57.157.29.0/25
57.157.29.128/26
57.157.29.192/27
57.157.29.224/28
57.157.29.240/30
57.157.32.0/23
57.157.34.0/25
57.157.34.128/26
57.157.34.192/27
57.157.34.224/30
57.157.44.0/25
57.157.44.128/27
57.157.44.160/28
57.157.44.180/30
57.157.44.184/30
57.157.44.188/31
57.157.44.192/26
57.157.45.0/28
57.157.45.18/31
57.157.48.0/27
57.157.48.32/29
57.157.48.40/30
57.157.48.46/31
57.157.48.48/28
57.157.48.64/26
57.157.48.128/27
57.157.48.160/30
57.157.48.168/31
57.157.48.174/31
57.157.48.176/28
57.157.48.192/29
57.157.48.200/30
57.157.48.204/31
57.157.48.210/31
57.157.48.212/30
57.157.48.216/29
57.157.48.224/27
57.157.49.0/26
57.157.49.64/28
57.157.49.80/30
57.157.49.86/31
57.157.49.88/29
57.157.49.96/27
57.157.49.128/27
57.157.49.160/28
57.157.49.176/30
57.157.49.186/31
57.157.49.188/30
57.157.49.192/27
57.157.49.224/28
57.157.49.240/30
57.157.56.0/25
57.157.56.128/26
57.157.56.192/28
57.157.56.208/29
57.157.56.216/30
57.157.56.220/31
57.157.64.0/24
57.157.65.0/29
57.157.65.8/30
57.157.65.12/31
57.157.72.0/25
57.157.72.128/26
57.157.72.192/29
57.157.76.0/25
57.157.76.128/27
57.157.76.160/28
57.157.76.176/29
57.157.76.184/31
57.157.80.0/24
57.157.81.0/26
57.157.81.64/27
57.157.81.96/29
57.157.81.104/30
57.157.81.108/31
57.157.128.0/24
57.157.129.0/25
57.157.129.128/28
57.162.0.0/17
57.162.128.0/17
57.163.10.0/23
57.163.16.0/23
57.163.18.0/23
57.163.20.0/23
57.163.22.0/23
57.165.0.0/17
57.165.128.0/17
57.166.0.0/17
57.166.128.0/17
57.167.0.0/17
64.4.8.0/24
64.4.54.0/24
64.236.0.0/17
64.236.128.0/17
65.52.0.0/19
65.52.32.0/21
65.52.48.0/20
65.52.64.0/20
65.52.104.0/24
65.52.106.0/24
65.52.108.0/23
65.52.110.0/24
65.52.111.0/24
65.52.112.0/20
65.52.128.0/19
65.52.192.0/19
65.52.224.0/21
65.52.232.0/21
65.52.240.0/21
65.54.19.128/27
65.55.32.128/28
65.55.32.193/32
65.55.32.194/31
65.55.32.196/32
65.55.32.209/32
65.55.32.210/31
65.55.44.8/29
65.55.44.16/28
65.55.44.32/27
65.55.44.64/27
65.55.44.96/28
65.55.44.112/28
65.55.44.128/27
65.55.51.0/24
65.55.60.176/29
65.55.60.188/30
65.55.105.0/26
65.55.105.96/27
65.55.105.160/27
65.55.105.192/27
65.55.105.224/27
65.55.106.0/26
65.55.106.64/27
65.55.106.128/26
65.55.106.192/28
65.55.106.208/28
65.55.106.224/28
65.55.106.240/28
65.55.107.0/28
65.55.107.48/28
65.55.107.64/27
65.55.107.96/27
65.55.108.0/24
65.55.109.0/24
65.55.110.0/24
65.55.120.0/24
65.55.144.0/23
65.55.146.0/24
65.55.207.0/24
65.55.209.0/25
65.55.209.128/26
65.55.209.192/26
65.55.210.0/24
65.55.211.0/27
65.55.211.32/27
65.55.212.0/27
65.55.212.128/25
65.55.213.0/27
65.55.213.64/26
65.55.213.128/26
65.55.217.0/24
65.55.218.0/24
65.55.219.0/27
65.55.219.32/27
65.55.219.64/26
65.55.219.128/25
65.55.250.0/24
65.55.252.0/24
68.154.0.0/17
68.219.0.0/17
68.219.128.0/19
68.219.160.0/19
68.219.192.0/18
68.220.0.0/19
68.220.32.0/19
68.220.88.0/21
68.220.128.0/17
70.37.0.0/21
70.37.8.0/22
70.37.16.0/20
70.37.32.0/20
70.37.48.0/20
70.37.64.0/18
70.37.160.0/21
70.152.4.0/24
70.152.5.0/24
70.152.7.0/24
70.152.8.0/24
70.152.9.0/24
70.152.18.0/24
70.152.19.0/24
70.152.24.0/24
70.152.35.0/24
70.152.36.0/24
70.152.38.0/24
70.152.39.0/24
70.152.40.0/24
70.152.55.0/24
70.152.56.0/23
70.152.64.0/23
70.152.66.0/24
70.152.67.0/24
70.152.68.0/23
70.152.91.0/24
70.152.92.0/22
70.152.96.0/21
70.152.104.0/23
70.152.106.0/23
70.152.108.0/22
70.152.112.0/21
70.152.120.0/24
70.152.121.0/24
70.152.122.0/23
70.152.124.0/22
70.152.128.0/21
70.152.136.0/21
70.152.144.0/22
70.152.148.0/23
70.152.150.0/24
70.152.151.0/24
70.152.152.0/21
70.152.160.0/20
70.152.176.0/22
70.152.180.0/24
70.152.181.0/24
70.152.182.0/23
70.152.184.0/21
70.152.192.0/20
70.152.208.0/23
70.152.210.0/24
70.152.220.0/24
70.152.233.0/24
70.152.243.0/24
70.152.244.0/24
70.152.245.0/24
70.152.246.0/24
70.152.251.0/24
70.152.252.0/23
72.145.0.0/17
72.145.128.0/18
72.147.128.0/17
72.152.0.0/17
72.152.128.0/17
72.153.0.0/17
72.153.128.0/17
72.154.0.0/17
72.154.128.0/17
74.178.0.0/17
74.178.128.0/17
74.179.0.0/17
74.179.128.0/17
74.234.0.0/17
74.234.128.0/17
74.235.0.0/16
74.249.0.0/17
74.249.128.0/17
94.245.88.0/21
94.245.104.0/21
94.245.117.96/27
94.245.118.0/25
94.245.120.128/27
94.245.122.0/24
94.245.123.144/28
94.245.123.176/28
98.64.0.0/16
98.71.0.0/17
98.71.128.0/17
104.40.0.0/17
104.40.128.0/17
104.41.64.0/18
104.41.128.0/19
104.41.192.0/18
104.42.0.0/16
104.43.128.0/17
104.44.88.0/27
104.44.88.32/27
104.44.88.64/27
104.44.88.96/27
104.44.88.128/27
104.44.88.160/27
104.44.89.0/27
104.44.89.64/27
104.44.89.96/27
104.44.89.128/27
104.44.89.160/27
104.44.89.192/27
104.44.90.192/27
104.44.91.0/27
104.44.91.32/27
104.44.91.64/27
104.44.91.96/27
104.44.91.128/27
104.44.91.160/27
104.44.92.64/27
104.44.92.96/27
104.44.92.192/27
104.44.92.224/27
104.44.93.0/27
104.44.93.32/27
104.44.93.64/27
104.44.93.160/27
104.44.93.192/27
104.44.94.0/28
104.44.94.16/28
104.44.94.32/28
104.44.94.48/28
104.44.94.64/28
104.44.94.80/28
104.44.94.160/27
104.44.95.0/28
104.44.95.16/28
104.44.95.32/28
104.44.95.80/28
104.44.95.96/28
104.44.95.128/27
104.44.95.160/27
104.44.95.240/28
104.44.128.0/18
104.45.0.0/18
104.45.64.0/20
104.45.80.0/20
104.45.96.0/19
104.45.128.0/18
104.45.192.0/20
104.45.208.0/20
104.45.224.0/19
104.46.0.0/21
104.46.8.0/21
104.46.32.0/19
104.46.64.0/19
104.46.96.0/19
104.46.192.0/20
104.47.128.0/18
104.47.200.0/21
104.47.208.0/23
104.47.216.64/26
104.47.218.0/23
104.47.220.0/22
104.47.224.0/20
104.208.0.0/19
104.208.32.0/20
104.208.128.0/17
104.209.0.0/18
104.209.128.0/17
104.210.0.0/20
104.210.32.0/19
104.210.128.0/19
104.210.176.0/20
104.210.192.0/19
104.211.0.0/18
104.214.0.0/17
104.214.192.0/18
104.215.64.0/18
108.141.0.0/16
108.142.0.0/15
128.24.0.0/17
128.24.128.0/17
128.85.0.0/17
128.85.128.0/17
128.203.0.0/17
128.203.128.0/17
128.251.0.0/17
128.251.128.0/17
130.107.0.0/16
130.131.0.0/17
130.131.128.0/17
130.213.0.0/17
130.213.128.0/17
131.253.12.16/28
131.253.12.40/29
131.253.12.48/29
131.253.12.160/28
131.253.12.192/28
131.253.12.208/28
131.253.12.224/30
131.253.12.228/30
131.253.12.248/29
131.253.13.0/28
131.253.13.16/29
131.253.13.24/29
131.253.13.32/28
131.253.13.48/28
131.253.13.72/29
131.253.13.80/29
131.253.13.88/30
131.253.13.96/30
131.253.13.128/27
131.253.14.4/30
131.253.14.8/31
131.253.14.16/28
131.253.14.32/27
131.253.14.96/27
131.253.14.128/27
131.253.14.160/27
131.253.14.192/29
131.253.14.208/28
131.253.14.224/28
131.253.14.248/29
131.253.15.8/29
131.253.15.16/28
131.253.15.32/27
131.253.15.192/28
131.253.15.208/28
131.253.15.224/27
131.253.24.0/28
131.253.24.160/27
131.253.24.192/26
131.253.25.0/24
131.253.27.0/24
131.253.34.224/27
131.253.35.128/26
131.253.36.128/26
131.253.36.224/27
131.253.38.0/27
131.253.38.32/27
131.253.38.128/26
131.253.38.224/27
131.253.40.0/28
131.253.40.16/28
131.253.40.32/28
131.253.40.64/28
131.253.40.80/28
131.253.40.96/27
131.253.40.128/27
131.253.40.160/28
131.253.40.192/26
131.253.41.0/24
132.164.0.0/17
132.164.128.0/17
132.196.0.0/17
132.196.128.0/17
132.220.0.0/16
134.33.0.0/17
134.33.128.0/17
134.149.0.0/17
134.149.128.0/17
134.170.220.0/23
134.170.222.0/24
135.18.128.0/17
135.119.0.0/17
135.119.128.0/17
135.130.4.0/23
135.130.6.0/23
135.130.10.0/23
135.130.12.0/23
135.130.16.0/23
135.130.18.0/23
135.130.20.0/24
135.130.21.0/24
135.130.22.0/23
135.130.24.0/24
135.130.25.128/25
135.130.26.0/23
135.130.28.0/22
135.130.32.0/23
135.130.34.0/25
135.130.34.128/26
135.130.34.192/26
135.130.36.0/23
135.130.38.0/23
135.130.48.0/23
135.130.50.0/23
135.130.52.0/23
135.130.54.0/23
135.130.60.0/23
135.130.62.0/23
135.130.64.0/23
135.130.66.0/23
135.130.68.0/23
135.130.70.0/23
135.130.74.0/23
135.130.78.0/23
135.130.80.0/23
135.130.86.0/24
135.130.92.0/23
135.130.102.0/23
135.130.104.0/23
135.130.108.0/23
135.130.112.0/23
135.130.114.0/23
135.130.116.0/23
135.130.118.0/23
135.130.120.0/23
135.130.122.0/23
135.130.134.0/23
135.130.136.0/23
135.130.142.0/23
135.130.146.0/23
135.130.157.0/25
135.130.157.128/26
135.130.158.0/23
135.130.160.0/23
135.130.162.0/23
135.130.164.0/23
135.130.166.0/23
135.130.168.0/23
135.130.170.0/23
135.130.172.0/23
135.130.176.0/23
135.130.180.0/22
135.130.184.0/23
135.130.186.0/23
135.130.196.0/23
135.130.204.0/23
135.130.206.0/23
135.130.212.0/22
135.130.217.0/24
135.130.218.0/24
135.130.222.0/23
135.130.230.128/25
135.130.231.0/24
135.130.232.0/24
135.130.233.0/25
135.130.233.128/25
135.130.234.0/24
135.130.235.0/24
135.130.238.0/25
135.130.238.128/25
135.130.239.0/24
135.130.244.0/24
135.130.245.0/25
135.130.245.128/25
135.130.246.0/24
135.130.250.0/23
135.130.253.0/24
135.222.0.0/17
135.222.128.0/18
135.222.192.0/18
135.224.0.0/17
135.224.128.0/17
135.232.0.0/17
135.232.128.0/17
135.233.0.0/17
135.233.128.0/17
135.234.0.0/17
135.234.128.0/17
135.236.0.0/17
135.236.128.0/17
135.237.0.0/17
135.237.128.0/17
137.116.0.0/18
137.116.64.0/19
137.116.96.0/22
137.116.112.0/20
137.116.176.0/21
137.116.184.0/21
137.116.192.0/19
137.116.224.0/19
137.117.0.0/19
137.117.32.0/19
137.117.64.0/18
137.117.128.0/17
137.135.0.0/18
137.135.64.0/18
137.135.128.0/17
138.91.48.0/20
138.91.64.0/19
138.91.96.0/19
138.91.128.0/17
145.132.0.0/17
145.132.128.0/17
145.190.0.0/23
145.190.2.0/24
145.190.3.0/24
145.190.4.0/23
145.190.6.0/24
145.190.7.0/24
145.190.8.0/21
145.190.16.0/20
145.190.32.0/22
145.190.36.0/24
145.190.37.0/24
145.190.38.0/23
145.190.40.0/23
145.190.42.0/24
145.190.43.0/24
145.190.44.0/22
145.190.48.0/22
145.190.59.0/24
145.190.62.0/24
145.190.66.0/23
145.190.68.0/24
145.190.130.0/24
145.190.132.0/24
145.190.133.0/24
145.190.134.0/24
145.190.135.0/24
145.190.137.0/24
145.190.141.0/24
145.190.142.0/24
145.190.143.0/24
145.190.144.0/24
145.190.145.0/24
145.190.155.0/24
145.190.159.0/24
145.190.161.0/24
145.190.162.0/24
145.190.163.0/24
145.190.169.0/24
145.190.170.0/24
145.190.171.0/24
145.191.0.0/17
151.206.71.0/24
151.206.72.0/24
151.206.73.0/24
151.206.74.0/24
151.206.79.0/25
151.206.79.128/25
151.206.80.0/24
151.206.81.0/24
151.206.82.0/24
151.206.83.0/24
151.206.84.0/24
151.206.85.0/24
151.206.86.0/24
151.206.90.0/23
151.206.92.0/23
151.206.98.0/23
151.206.100.0/23
151.206.102.0/23
151.206.104.0/23
151.206.106.0/24
151.206.107.0/25
151.206.107.128/25
151.206.108.0/23
151.206.110.0/24
151.206.129.0/24
151.206.130.0/24
151.206.131.0/24
151.206.132.0/24
151.206.133.0/24
151.206.134.0/24
151.206.135.0/24
151.206.139.0/24
151.206.150.0/24
151.206.156.0/24
151.206.160.0/24
151.206.161.0/24
151.206.176.0/24
151.206.182.0/24
151.206.186.0/24
151.206.187.0/24
157.55.2.128/26
157.55.7.128/26
157.55.8.64/26
157.55.8.144/28
157.55.10.160/29
157.55.10.176/28
157.55.10.192/26
157.55.11.128/25
157.55.12.64/26
157.55.12.128/26
157.55.13.64/26
157.55.13.128/26
157.55.37.0/24
157.55.38.0/24
157.55.39.0/24
157.55.48.0/24
157.55.50.0/25
157.55.55.0/27
157.55.55.32/28
157.55.55.100/30
157.55.55.104/29
157.55.55.136/29
157.55.55.144/29
157.55.55.152/29
157.55.55.160/28
157.55.55.176/29
157.55.55.200/29
157.55.55.216/29
157.55.55.228/30
157.55.55.232/29
157.55.55.240/28
157.55.60.224/27
157.55.64.0/20
157.55.80.0/20
157.55.103.32/27
157.55.103.128/25
157.55.106.0/26
157.55.106.128/25
157.55.107.0/24
157.55.108.0/23
157.55.110.0/23
157.55.136.0/21
157.55.153.224/28
157.55.154.128/25
157.55.160.0/20
157.55.176.0/20
157.55.192.0/21
157.55.200.0/22
157.55.204.1/32
157.55.204.2/31
157.55.204.33/32
157.55.204.34/31
157.55.204.128/25
157.55.208.0/21
157.55.248.0/21
157.56.2.0/25
157.56.2.128/25
157.56.3.0/25
157.56.3.128/25
157.56.8.0/21
157.56.24.160/27
157.56.24.192/27
157.56.28.0/22
157.56.80.0/25
157.56.160.0/21
157.56.176.0/21
157.56.216.0/26
168.61.0.0/19
168.61.32.0/20
168.61.48.0/21
168.61.56.0/21
168.61.64.0/20
168.61.80.0/20
168.61.96.0/19
168.61.128.0/25
168.61.128.128/28
168.61.128.160/27
168.61.128.192/26
168.61.129.0/25
168.61.129.128/26
168.61.129.208/28
168.61.129.224/27
168.61.130.64/26
168.61.130.128/25
168.61.131.0/26
168.61.131.128/25
168.61.132.0/26
168.61.144.0/20
168.61.160.0/19
168.61.208.0/20
168.62.0.0/19
168.62.32.0/19
168.62.64.0/19
168.62.96.0/19
168.62.128.0/19
168.62.160.0/19
168.62.192.0/19
168.62.224.0/19
168.63.0.0/19
168.63.32.0/19
168.63.64.0/20
168.63.80.0/21
168.63.88.0/23
168.63.92.0/22
168.63.96.0/19
172.168.0.0/15
172.170.0.0/16
172.171.0.0/19
172.171.32.0/19
172.171.64.0/19
172.171.96.0/19
172.171.128.0/17
172.172.0.0/17
172.172.128.0/17
172.173.8.0/21
172.173.16.0/20
172.173.64.0/18
172.173.128.0/17
172.174.0.0/16
172.175.0.0/16
172.176.0.0/15
172.178.0.0/17
172.178.128.0/17
172.179.0.0/16
172.180.0.0/15
172.182.0.0/16
172.183.0.0/16
172.184.0.0/15
172.190.0.0/15
172.193.0.0/17
172.193.128.0/17
172.194.128.0/17
172.199.0.0/16
172.200.0.0/16
172.201.0.0/16
172.202.0.0/17
172.202.128.0/17
172.203.0.0/17
172.203.128.0/17
172.205.0.0/17
172.205.128.0/17
172.206.0.0/17
172.206.128.0/18
172.206.192.0/18
172.208.0.0/17
172.208.128.0/17
172.210.0.0/17
172.210.128.0/17
172.211.0.0/16
172.212.0.0/17
172.212.128.0/17
172.214.0.0/17
172.214.128.0/17
172.215.128.0/18
172.215.192.0/18
191.233.64.0/18
191.233.144.0/20
191.234.32.0/19
191.235.128.0/18
191.235.192.0/22
191.235.208.0/20
191.235.255.0/24
191.236.0.0/18
191.236.64.0/18
191.236.128.0/18
191.236.192.0/18
191.237.0.0/17
191.237.128.0/18
191.237.192.0/23
191.237.194.0/24
191.237.196.0/24
191.237.208.0/20
191.237.232.0/22
191.238.0.0/18
191.238.70.0/23
191.238.96.0/19
191.238.144.0/20
191.238.160.0/19
191.238.224.0/19
191.239.0.0/18
191.239.200.0/22
191.239.208.0/20
191.239.224.0/20
193.149.64.0/21
193.149.72.0/21
193.149.80.0/21
193.149.88.0/21
199.30.16.0/24
199.30.18.0/23
199.30.20.0/24
199.30.22.0/24
199.30.24.0/23
199.30.27.0/25
199.30.27.144/28
199.30.27.160/27
199.30.28.64/26
199.30.28.128/25
199.30.29.0/24
199.30.31.0/25
199.30.31.192/26
204.79.180.0/24
204.152.18.0/31
204.152.18.8/29
204.152.18.32/27
204.152.18.64/26
204.152.19.0/24
207.46.13.0/24
207.46.193.192/28
207.46.200.96/27
207.46.200.176/28
207.46.202.128/28
207.46.205.0/24
207.68.174.40/29
207.68.174.48/29
207.68.174.184/29
209.199.17.80/28
209.199.17.192/26
209.199.18.0/26
209.199.21.128/25
209.199.36.0/28
209.199.36.48/28
209.199.36.128/25
209.199.37.0/25
209.199.39.128/25
209.199.40.0/25
209.199.128.0/24
209.240.212.0/23
213.199.128.0/20
213.199.180.32/28
213.199.180.96/27
213.199.180.192/27
213.199.183.0/24
216.220.210.0/24
216.220.211.0/24
216.220.212.0/24
```

### File: .\docs\HISTORIAL_IMPLEMENTACION.md
```md
# Historial de Implementación — Cómo se construyó este repositorio
**TFG ASIR 2025/2026 — Sandra Fradejas Avedillo**
> [!NOTE]
> Este documento narra el proceso real de desarrollo: decisiones tomadas, problemas encontrados y cómo se resolvieron.
> Es la historia técnica del repositorio. **No es una guía de instalación.**
>
> **→ Guía de instalación desde cero:** [`docs/INSTALACION_COMPLETA.md`](INSTALACION_COMPLETA.md)
> **→ Referencia de comandos históricos:** [`docs/PLAN_HISTORICO_DETALLADO.md`](PLAN_HISTORICO_DETALLADO.md)
---
## Fase 0 — Investigación y Decisiones de Diseño (2026-04-29)
### ¿Qué ERP elegir?
Se evaluaron tres ERPs de código abierto antes de comenzar:
| Criterio | **Odoo 17** | Dolibarr | ERPNext |
|----------|-------------|----------|---------|
| Facilidad de uso | ✅ Alta | Media | Media |
| API REST/XML-RPC | ✅ Madura | Limitada | Alta |
| Consumo de recursos | Moderado | ✅ Ligero | Pesado |
| Cobertura funcional | ✅ Completa | Básica | Muy completa |
| **Veredicto** | ✅ **Elegido** | Descartado | Descartado |
**Decisión:** Odoo 17 CE por su API XML-RPC madura y documentación oficial.
### ¿Qué sistema operativo?
Elegido **Debian 13 (Trixie)** sobre Ubuntu/Mint porque:
- Ciclos de soporte más largos
- Es el sistema de referencia en la documentación oficial de Odoo
- Sin snaps ni paquetes propietarios
- `docker.io` disponible en repositorios oficiales
### Arquitectura de red
Se decidió usar pfSense como firewall con tres zonas separadas:
- **WAN** — salida a Internet
- **LAN (VLAN 10, 192.168.10.0/24)** — equipos cliente
- **DMZ (VLAN 30, 192.168.30.0/24)** — servidor ERP
Dentro del servidor Debian, todos los servicios en contenedores Docker con red bridge interna. Solo Nginx expone puertos al host.
### Decisión inicial sobre redes Docker
Se evaluó **macvlan** (IPs físicas por contenedor) pero se descartó inicialmente por complejidad. Se comenzó con **bridge** y se añadió macvlan más adelante (Fase B).
---
## v1.0 — Creación de la Infraestructura Base (2026-04-29)
### Archivos creados
**`docker/docker-compose.yml`** — Stack inicial con 3 servicios:
- `odoo_erp` (PostgreSQL 16) — BD sin puertos expuestos
- `odoo-web` (Odoo 17 CE) — sin puertos al host
- `nginx-proxy` (Nginx Alpine) — único punto de entrada, puertos 80/443
Red Docker `odoo_net` tipo bridge. Solo Nginx expone puertos.
**`docker/odoo.conf`** — Configuración de Odoo:
- `proxy_mode = True` — imprescindible al estar detrás de Nginx
- `workers = 2` — para VM de 2 cores
- `gevent_port = 8072` — para LiveChat/WebSocket
- `limit_time_real = 1200s` — para informes PDF pesados
**`config_nginx/odoo_proxy.conf`** — Proxy inverso:
- Bloque HTTP: redirección 301 a HTTPS
- Bloque HTTPS: TLSv1.2/1.3, cabeceras de seguridad (HSTS, X-Frame-Options, nosniff), timeouts 720s
- Bloque `/longpolling/` → puerto 8072 para WebSocket
**Scripts Bash iniciales:**
- `scripts/deploy.sh` — levanta el stack y espera healthcheck
- `scripts/backup.sh` — `pg_dump -F c` con retención 7 días
- `scripts/restore.sh` — borra y recrea la BD antes de restaurar
- `scripts/update.sh` — `docker compose pull` + `image prune`
- `scripts/monitor.sh` — chequea los 3 contenedores, auto-reinicia si caen
**`sql/audit_triggers.sql`** — Auditoría PostgreSQL:
- Tabla `asir_audit_log` con campo JSONB `row_data`
- Función PL/pgSQL `func_audit_users()`
- Trigger `trg_audit_new_odoo_user` en `res_users`
**`.github/workflows/ci.yml`** — CI con GitHub Actions:
- Validación YAML del docker-compose
- ShellCheck en todos los scripts `.sh`
- Markdownlint en documentación
**Documentación inicial:** `implementation_plan.md`, `task.md`, `reglas_pfsense.md`
---
## v1.1 — Automatización y Robustez (2026-04-30)
### Problema: Despliegue manual demasiado complejo
El proceso manual de instalación tenía demasiados pasos manuales. Se crean herramientas de automatización:
**`install.sh`** — Instalador todo-en-uno:
- Instala dependencias (`git`, `curl`, `openssl`, `cockpit`, `docker.io`)
- Clona el repositorio en `/opt/erp-odoo`
- Genera certificados SSL autofirmados
- Llama a `configure.sh` y luego a `deploy.sh`
**`.env.example` + `scripts/configure.sh`** — Gestión segura de credenciales:
- La plantilla pública sirve de guía
- `configure.sh` pide contraseñas interactivamente (sin eco en terminal)
- Aplica `chmod 600` al `.env` generado
**`scripts/erp.sh`** — Orquestador central con menú interactivo (opciones 1-10 para gestionar el ciclo de vida completo)
**`config/logrotate.d/erp-odoo`** — Rotación semanal automática de logs
**`scripts/install_cron.sh`** — Instala las 3 tareas cron en `/etc/cron.d/erp-odoo`
### Problema: Docker healthchecks faltantes
Se añadieron healthchecks nativos en `docker-compose.yml`:
- PostgreSQL: `pg_isready`
- Odoo: `curl /web/health`
- Nginx: `nginx -t`
Y `depends_on` con condición `service_healthy` para garantizar orden de arranque.
### Problema: Rutas de volúmenes incorrectas
El `docker-compose.yml` estaba en `docker/` pero los volúmenes apuntaban con rutas absolutas. Se corrigió a rutas relativas con `../` para que funcionen desde cualquier ubicación.
### Problema: `longpolling_port` deprecado en Odoo 17
El parámetro antiguo se renombró a `gevent_port`. Corregido en `docker/odoo.conf`.
### Errores resueltos:
- **`Permission denied` en `/var/lib/odoo/.local`** → corregido al arreglar las rutas de volúmenes
- **Bucle de reinicio en Nginx** → resuelto sincronizando nombres de certificados SSL en `install.sh`
- **Error de inicialización de Odoo** → primer arranque con `docker compose run --rm`
---
## v1.2 — Auditoría SQL en Producción (2026-04-30)
### Ejecución del trigger de auditoría
```bash
docker exec -i odoo_erp psql -U odoo -d odoo_erp < sql/audit_triggers.sql
```
### Problema: Nombre incorrecto del contenedor
El nombre real en `docker-compose.yml` era `odoo_erp` pero en algunos scripts y documentación se usaba `odoo-db`. Corregido en `backup.sh`, `restore.sh`, `monitor.sh` y documentación.
**Commit:** `b0022e4`
### Validación end-to-end confirmada
Crear usuario desde la UI de Odoo → verificar en la tabla de auditoría:
```
audit_id=1, CREACION_USUARIO, res_users, id=8, 2026-04-30 12:13:57 UTC
```
El trigger captura el snapshot JSONB completo del usuario creado. ✅
---
## v1.3 — Pipeline CI/CD Completo (2026-04-30)
### Configuración del Self-Hosted Runner
```bash
# En el servidor Debian
/opt/erp-odoo/scripts/setup_runner.sh
```
Runner instalado en `/opt/actions-runner`, versión `2.334.0` (SHA256 verificado).  
Nombre del runner: `debian`. Labels: `self-hosted, Linux, X64`.  
Instalado como servicio systemd: `actions.runner.sandrafrv-...debian.service`
**`deploy.yml`** creado — pipeline CD que se dispara tras CI exitoso:
1. `git reset --hard origin/main` (garantiza última versión)
2. `docker pull` de las 3 imágenes
3. `bash scripts/deploy.sh`
### Errores resueltos durante la puesta en marcha del CI/CD
**Error: `permission denied` en `.env`**
- **Causa:** `.env` tenía permisos `600` (solo root). El runner corre como usuario `server`.
- **Solución:** `sudo chown root:server /opt/erp-odoo/docker/.env && sudo chmod 640 /opt/erp-odoo/docker/.env`
**Error: Docker Compose dice "errores de sintaxis" (sin haberlos)**
- **Causa:** Cascada del error de permisos. Docker no podía leer el `.env` y lo interpretaba como error de configuración.
- **Solución:** Corregir los permisos del `.env` (ver arriba).
**Error: `dubious ownership` en git**
- **Causa:** `/opt/erp-odoo` fue creado por `root` pero el runner corre como `server`. Git bloquea acceso.
- **Solución:** Step `git config --global --add safe.directory /opt/erp-odoo` añadido al inicio del workflow.
**Error: Comprobación de puertos 80/443 falla en re-deploy**
- **Causa:** `ss -tlnp` sin root no muestra el nombre del proceso. El script fallaba aunque los puertos fueran del propio `nginx-proxy`.
- **Solución:** Verificar si `nginx-proxy` está corriendo con `docker ps`. Si lo está, es re-deploy válido.
**Validación final:** 3 contenedores `healthy`, pipeline CD ejecutado y completado en commit `0cdee22`. ✅
---
## v1.4 — Resolución de Fallo en Pipeline por .env Ausente (2026-05-06)
### Problema: Pipeline CD fallaba 5+ veces consecutivas
**Síntomas:**
```
ERROR: relation "ir_module_module" does not exist
KeyError: 'ir.http'
GET /web/health HTTP/1.1" 500
```
**Causa raíz:** El archivo `docker/.env` no existía en el servidor tras una limpieza. Sin las variables de entorno, Odoo no podía conectarse a PostgreSQL y la BD quedaba sin inicializar.
**Solución aplicada:**
1. `docker compose down` — parada completa del stack
2. `sudo rm -rf postgres-data/pgdata` y `sudo rm -rf odoo-data/filestore` — borrar datos corruptos
3. Recrear el `.env` con las credenciales correctas
4. `docker compose up -d` — arranque limpio
5. Odoo inicializa la BD desde cero → primer healthcheck 200 OK ✅
---
## Fase A — Verificación de Aislamiento VLAN (2026-05-08)
### Validación de reglas pfSense
Desde el cliente VLAN 10:
- `nc -zv 192.168.30.10 5432` → **Timeout** ✅ (PostgreSQL bloqueado)
- `nc -zv 192.168.30.10 8069` → **Timeout** ✅ (Odoo directo bloqueado)
- `curl -k https://192.168.30.10` → **200/302** ✅ (Odoo accesible por Nginx)
- Desde DMZ, `ping 192.168.10.x` → **Sin respuesta** ✅ (aislado)
---
## Fase B — MACVLAN: IPs Físicas para Contenedores (2026-05-08)
### Por qué se implementó
Para que pfSense vea los contenedores como hosts físicos independientes con IPs en la VLAN30, no como un único servidor. Esto permite reglas de firewall por contenedor.
### Problema: Formato YAML incompatible
El `docker-compose.yml` usaba formato lista en `networks` (`- odoo_net`), lo que impedía añadir la red MACVLAN con IP fija. Se reescribió con Python para garantizar indentación YAML correcta.
### Implementación
```bash
docker network create \
  --driver macvlan \
  --subnet=192.168.30.0/24 \
  --gateway=192.168.30.1 \
  --opt parent=ens18 \
  macvlan_vlan30
```
`docker-compose.yml` actualizado:
- `nginx-proxy` → IP fija `192.168.30.20`
- `odoo-web` → IP fija `192.168.30.21`
- `odoo_erp` (PostgreSQL) → sin IP MACVLAN (sólo red interna, por seguridad)
### Limitación documentada
El host Debian **no puede hacer ping a las IPs MACVLAN de sus propios contenedores**. Es una limitación conocida del driver macvlan en Linux (el tráfico host→contenedor MACVLAN no pasa por la interfaz física). Verificar desde otro equipo o desde un contenedor temporal.
```bash
# Verificación desde contenedor temporal
docker run --rm --network macvlan_vlan30 alpine \
  wget -qO- --no-check-certificate https://192.168.30.20 | grep "<title>"
# → <title>Odoo</title> ✅
```
**Commit:** `7ee1cd2`
---
## Fase C — Integración LDAP (2026-05-06 → 2026-05-08)
### Objetivo
Centralizar la autenticación de Odoo contra un directorio LDAP (OpenLDAP), eliminando contraseñas locales por usuario.
### Implementación
**Servicio añadido a `docker-compose.yml`:**
```yaml
ldap:
  image: osixia/openldap:1.5.0
  container_name: odoo-ldap
  environment:
    LDAP_ORGANISATION: "TFG ASIR"
    LDAP_DOMAIN: "tfg.com"
    LDAP_ADMIN_PASSWORD: ${LDAP_ADMIN_PASSWORD}
  volumes:
    - ../ldap_data:/var/lib/ldap
    - ../ldap_config:/etc/ldap/slapd.d
  networks:
    odoo_net:
```
**Variable añadida a `docker/.env`:**
```
LDAP_ADMIN_PASSWORD=<contraseña_segura>
```
### Scripts creados para gestionar LDAP
**`scripts/ldap_crear_usuarios.sh`** — Script interactivo que:
- Verifica el contenedor `odoo-ldap`
- Crea la OU `ou=usuarios,dc=tfg,dc=com` si no existe
- Permite crear usuarios en bucle con verificación post-creación
**`scripts/odoo_setup_wizard.sh`** — Asistente post-instalación:
- Renombra la compañía en BD (`UPDATE res_company`)
- Instala módulos (incluyendo `auth_ldap` obligatorio)
- Configura la conexión LDAP en la tabla `res_company_ldap`
- Opcionalmente deshabilita contraseñas locales para usuarios no-admin
### Problemas resueltos durante la integración
**Problema: Odoo no podía conectar con LDAP por nombre de host**
- El contenedor LDAP se llama `odoo-ldap` en la red Docker interna
- En la configuración de Odoo se usa la IP detectada con `docker inspect`
**Cambio en `ldap_crear_usuarios.sh` (2026-05-08):**
- Eliminadas variables no usadas `LDAP_HOST`, `LDAP_PORT`, `LDAP_DOMAIN` (advertencias ShellCheck SC2034)
- Año actualizado en cabecera: 2025 → 2026
---
## Estado Actual del Repositorio (2026-05-13)
### Infraestructura desplegada
| Componente | Estado | Notas |
|------------|--------|-------|
| pfSense | ✅ Activo | 4 interfaces (WAN/VLAN10/DMZ/VLAN40), reglas verificadas, LDAP auth |
| Debian 13 | ✅ Activo | Con Docker y Cockpit, IP estática `192.168.30.10` |
| Docker stack | ✅ 4 contenedores healthy | PostgreSQL, Odoo, LDAP, Nginx |
| MACVLAN | ✅ Activa | Nginx en .20, Odoo en .21, LDAP en .22 |
| LDAP | ✅ Integrado | Auth centralizada para Odoo + PCs VLAN 10 (SSSD+PAM) |
| DNS interno | ✅ Configurado | `erp.odoo.tfg.com` → `192.168.30.10` |
| CI/CD | ✅ Operativo | Runner `debian-dmz` activo |
| Auditoría SQL | ✅ Ejecutada | Trigger en `res_users` |
| Backups | ✅ Programados | Diario a las 02:00 |
| UFW | ✅ Activo | Solo 22, 80, 443, 9090 |
| Control de acceso | ✅ 3 capas activas | Nginx rutas + Odoo tipos + LDAP grupos |
| VLAN 40 (Admin) | ✅ Configurada | Panel pfSense + SSH + Cockpit solo desde VLAN 40 |
### Pendiente para la defensa
| Tarea | Prioridad |
|-------|-----------|
| Debian headless (eliminar GUI) | Alta |
| SSH por clave pública | Alta |
| Capturas de pantalla para la memoria | Alta |
| Redactar memoria del TFG | Alta |
| Preparar demostración para la defensa | Alta |
---
## Anexo: Planes de Fases y Pipeline (Histórico)
> *Nota: Este anexo resume los hitos documentados originalmente en `plan_fases_pendientes.md` y `plan_iac_github.md` durante el desarrollo del proyecto.*
### Resumen de Fases
- **Fase A (VLAN):** Verificación y endurecimiento de la segmentación entre VLAN 10 (LAN) y VLAN 30 (DMZ). Acceso solo a HTTPS (443) y bloqueos explícitos a PostgreSQL y Odoo directo.
- **Fase B (MACVLAN):** Asignación de IPs físicas de la VLAN30 a los contenedores (Nginx en `.20`, Odoo en `.21`).
- **Fase C (LDAP):** Despliegue de `odoo-ldap`, creación de usuarios de prueba y configuración del login centralizado en Odoo vía XML-RPC.
- **Fase D (Headless & Hardening):** Conversión de Debian a `multi-user.target` (sin GUI) y endurecimiento de SSH (claves públicas, restricción de acceso solo a VLAN de administración).
### Infraestructura como Código (IaC) y GitHub Actions
Se diseñó un pipeline CI/CD completo en GitHub donde el repositorio actúa como **fuente de verdad**:
- **CI Validator (`ci.yml`):** Ejecuta `shellcheck` en los scripts, valida la sintaxis de `docker-compose.yml` y lint de Markdown.
- **CD Deploy (`deploy.yml`):** Utiliza un **self-hosted runner** instalado en el servidor Debian para aplicar automáticamente los cambios en producción (MACVLAN, SSH, Docker, Roles).
---
## Estructura Final del Repositorio
```
TFG-ASIRB/
├── .github/workflows/
│   ├── ci.yml          # CI: ShellCheck + YAML + Markdown
│   └── deploy.yml      # CD: despliegue automático al servidor
├── config/logrotate.d/
│   └── erp-odoo        # Rotación semanal de logs
├── config_nginx/
│   └── odoo_proxy.conf # Proxy inverso Nginx + SSL + cabeceras seguridad
├── docker/
│   ├── .env            # Credenciales (excluido de Git)
│   ├── docker-compose.yml  # 4 servicios: DB, Odoo, LDAP, Nginx
│   └── odoo.conf       # Configuración interna de Odoo
├── docs/
│   ├── GUIA_DESPLIEGUE.md         # ← Cómo desplegar desde cero
│   ├── HISTORIAL_IMPLEMENTACION.md # ← Este archivo
│   ├── CHANGELOG.md               # Registro de cambios por versión
│   ├── implementation_plan.md     # Plan técnico detallado (con comandos)
│   ├── reglas_pfsense.md          # Reglas de firewall documentadas
│   ├── task.md                    # Lista de tareas por fase
│   └── mas_info/
│       ├── informe_erp.md         # Investigación técnica completa
│       └── investigacion.md
├── scripts/
│   ├── backup.sh           # Backup comprimido de PostgreSQL
│   ├── configure.sh        # Configuración interactiva del .env
│   ├── deploy.sh           # Despliegue del stack con healthcheck
│   ├── erp.sh              # Orquestador central (menú interactivo)
│   ├── install_cron.sh     # Instala tareas cron y logrotate
│   ├── ldap_crear_usuarios.sh   # Gestión de usuarios LDAP
│   ├── monitor.sh          # Monitor de salud + auto-reinicio
│   ├── odoo_crear_usuarios.sh   # Crea usuarios Odoo por XML-RPC
│   ├── odoo_setup_wizard.sh     # Post-instalación Odoo + LDAP
│   ├── restore.sh          # Restauración de backup
│   ├── setup_runner.sh     # Registra GitHub Actions runner
│   └── update.sh           # Actualización de imágenes Docker
├── sql/
│   └── audit_triggers.sql  # Auditoría PL/pgSQL en PostgreSQL
├── .env.example            # Plantilla pública de variables
├── .gitignore              # Excluye .env, certs, data/, ISOs/
├── CLAUDE.md               # Instrucciones para el asistente AI
├── install.sh              # Instalador todo-en-uno
└── README.md               # Documentación principal del proyecto
```
```

### File: .\docs\INSTALACION_COMPLETA.md
```md
# Guía Maestra de Instalación desde Cero
**TFG ASIR 2025/2026 — Implantación Segura y Automatizada de Odoo ERP**
*Sandra Fradejas Avedillo — IES Cañaveral*
> [!IMPORTANT]
> Este es el **punto de entrada único**. Sigue las fases en orden.
> Cada sección resume lo esencial y enlaza a la sub-guía detallada.
>
> **→ Índice completo de documentación: [`docs/README.md`](README.md)**
---
## Prerequisitos
- VirtualBox ≥ 6.1 instalado en el equipo de laboratorio
- ISOs disponibles en `ISOs/`: Debian 13 netinst + pfSense 2.7.x
- Conexión a Internet en el equipo anfitrión
- Repositorio clonado localmente
---
## Arquitectura General
```
Internet (WAN)
     │ NAT 80/443
     ▼
[ pfSense — 4 interfaces ]
     │           │           │
  VLAN 10     VLAN 30     VLAN 40
  192.168.10  192.168.30  192.168.40
  Clientes    DMZ Server  Admin
     │           │           │
  PCs           Debian 13    PCs Admin
  Login LDAP    192.168.30.10  SSH/Cockpit/pfSense
                │
    ┌───────────┴───────────────────┐
    │ nginx-proxy  → MACVLAN .20   │
    │ odoo-web     → MACVLAN .21   │
    │ openldap     → MACVLAN .22   │
    │ odoo_erp     → solo interno  │
    └───────────────────────────────┘
```
---
## Tabla de Direccionamiento
| Componente | VLAN | IP | Acceso permitido |
|:-----------|:-----|:---|:----------------|
| pfSense gateway LAN | 10 | 192.168.10.1 | Solo VLAN 40 (panel) |
| pfSense gateway DMZ | 30 | 192.168.30.1 | — |
| pfSense gateway Admin | 40 | 192.168.40.1 | Solo VLAN 40 |
| Debian 13 host | DMZ | 192.168.30.10 | SSH/Cockpit solo VLAN 40 |
| **nginx-proxy** | DMZ (MACVLAN) | 192.168.30.20 | VLAN 10 + 40 + WAN (:443) |
| **odoo-web** | DMZ (MACVLAN) | 192.168.30.21 | Solo vía Nginx |
| **openldap** | DMZ (MACVLAN) | 192.168.30.22 | VLAN 10 (:389), VLAN 40 (:389/:636) |
| **odoo_erp** (PostgreSQL) | Docker interno | 172.19.0.x | Solo contenedor Odoo |
---
## Las 3 Fases de Instalación
### 🔷 FASE 1 — Red y Firewall
**Tiempo estimado: 45–60 min**
**→ Guía completa:** [`guias/INSTALACION_RED.md`](guias/INSTALACION_RED.md)
| Paso | Descripción |
|:-----|:------------|
| 1–2 | VM pfSense: 4 adaptadores (WAN/LAN10/DMZ30/Admin40) |
| 3 | Asignación de interfaces en consola de texto |
| 4 | Acceso a la interfaz web desde LAN |
| 5 | Interfaz OPT2 (VLAN_ADMIN `192.168.40.1/24`) |
| 6 | DHCP: LAN (.100–.200) y OPT2 (.10–.50) |
| 7 | DNS Resolver: Host Override `erp.odoo.tfg.com → 192.168.30.10` |
| 8 | NAT: WAN:80/443 → servidor + DNS interceptado por VLAN |
| 9 | Reglas firewall: bloqueos anti-pivoting + permisos mínimos |
| 10 | LDAP auth en panel pfSense (solo grupo `admin`) |
| 11 | Desactivar Anti-Lockout tras confirmar acceso VLAN 40 |
**Atajo:** `bash scripts/deploy/generate_pfsense_config.sh` genera el `config.xml` completo.
Importar en **Diagnostics → Backup/Restore**. También disponible como artefacto CI en GitHub Actions.
**Verificación rápida:**
```bash
nslookup erp.odoo.tfg.com   # → 192.168.30.10 desde VLAN 10
nc -zv 192.168.30.10 5432   # → Timeout (bloqueado) desde VLAN 10
```
---
### 🖧 FASE 2 — Servidor Debian + Docker + Odoo
**Tiempo estimado: 30–60 min (+ 5 min primer arranque Odoo)**
**→ Guía completa:** [`guias/INSTALACION_SERVIDOR.md`](guias/INSTALACION_SERVIDOR.md)
| Paso | Descripción |
|:-----|:------------|
| Parte 1 | VM Debian 13: IP estática `192.168.30.10`, Docker, Cockpit, clonar repo, `.env` |
| Parte 2 | Red MACVLAN, SSL, `docker compose up -d`, 4 contenedores `healthy`, cron |
| Parte 3 | Post-instalación Odoo: empresa, módulos, usuarios con roles, auditoría SQL |
**Atajo:** `sudo ./install.sh` ejecuta la Parte 1 y 2 automáticamente.
**Verificación rápida:**
```bash
docker compose -f docker/docker-compose.yml ps
curl -k -I https://erp.odoo.tfg.com   # → HTTP/2 200
```
---
### 🔐 FASE 3 — LDAP + CI/CD + Hardening
**Tiempo estimado: 30–45 min**
**→ Guía completa:** [`guias/INSTALACION_LDAP_CICD_HARDENING.md`](guias/INSTALACION_LDAP_CICD_HARDENING.md)
| Parte | Descripción |
|:------|:------------|
| LDAP | ACLs, crear usuarios del directorio, configurar SSSD+PAM en PCs VLAN 10 |
| CI/CD | Self-hosted runner, pipeline CI (ShellCheck/YAML/Markdown) + CD (deploy automático) |
| Hardening | UFW, SSH por clave pública, eliminar GNOME, headless |
> [!CAUTION]
> El hardening (SSH + headless) debe hacerse **siempre al final**, cuando todo lo demás funciona.
**Verificación rápida:**
```bash
systemctl get-default                  # → multi-user.target
sudo ufw status                        # → active
ldapwhoami -H ldap://192.168.30.22 \
  -D "uid=jdoe,ou=usuarios,dc=tfg,dc=com" -W   # → OK
```
---
## Orden de Arranque (tras Reinicio)
```
1. Arrancar pfSense VM     → esperar ~1 min (interfaces activas)
2. Arrancar Debian VM      → Docker arranca automáticamente
3. Esperar ~3 min          → Odoo inicializa (primer arranque)
4. Verificar desde VLAN 10 → https://erp.odoo.tfg.com
5. Verificar desde VLAN 40 → https://192.168.30.10:9090 (Cockpit)
```
---
## Checklist Final
```
FASE 1 — Red
  ✅ pfSense: 4 interfaces activas
  ✅ DHCP VLAN 10 y VLAN 40
  ✅ DNS: erp.odoo.tfg.com → 192.168.30.10
  ✅ NAT: WAN 80/443 → servidor
  ✅ Reglas: anti-pivoting + permisos mínimos
  ✅ Panel pfSense: solo VLAN 40, auth LDAP
  ✅ Anti-Lockout desactivado
FASE 2 — Servidor
  ✅ Debian: IP estática 192.168.30.10
  ✅ Docker + Cockpit activos
  ✅ MACVLAN: .20 (Nginx) · .21 (Odoo) · .22 (LDAP)
  ✅ 4 contenedores healthy
  ✅ Odoo: empresa + módulos + usuarios con roles
  ✅ Auditoría SQL (trigger en res_users)
  ✅ Cron: backup/monitor/update
FASE 3 — Seguridad
  ✅ LDAP: ACLs + usuarios + login Odoo + login PCs VLAN 10
  ✅ CI/CD: runner activo + pipeline funcional
  ✅ UFW: deny-all + 22/80/443/9090
  ✅ SSH: solo clave pública, sin root
  ✅ Debian headless: multi-user.target
```
---
## Documentación Relacionada
| Documento | Para qué sirve |
|:----------|:--------------|
| [`README.md`](README.md) | Índice completo de toda la documentación |
| [`CONTROL_ACCESO.md`](CONTROL_ACCESO.md) | Modelo de seguridad en 3 capas |
| [`reglas_pfsense.md`](reglas_pfsense.md) | Referencia completa de reglas pfSense |
| [`diagrama_red.md`](diagrama_red.md) | Diagramas de arquitectura |
| [`HISTORIAL_IMPLEMENTACION.md`](HISTORIAL_IMPLEMENTACION.md) | Historia del desarrollo |
| [`CHANGELOG.md`](CHANGELOG.md) | Registro de cambios |
---
*TFG ASIR 2025/2026 — IES Cañaveral*
```

### File: .\docs\memoria_tfg_borrador.md
```md
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
- **Debian 13 (Trixie):** Elegido como sistema operativo host por su altísima estabilidad, ciclo de soporte largo y su nula inclusión de paquetes propietarios intrusivos, siendo el estándar de producción.
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
```

### File: .\docs\memoria_tfg_nuevo.md
```md
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
        ├── .10 → Debian 13 Host  (Docker engine, SSH :22, Cockpit :9090)
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
- **Debian 13 (Trixie):** Elegido como sistema operativo host por su altísima estabilidad, ciclo de soporte largo y su nula inclusión de paquetes propietarios intrusivos, siendo el estándar de producción.
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
```

### File: .\docs\README.md
```md
# Documentación Técnica — TFG ASIR 2025/2026
**Proyecto:** Implantación Segura y Automatizada de Odoo ERP  
**Autora:** Sandra Fradejas Avedillo  
**Centro:** IES Cañaveral · Ciclo ASIR
---
## 🗂️ Índice de Documentos
### Guía Principal *(empieza aquí)*
| Archivo | Descripción |
|:--------|:------------|
| [`INSTALACION_COMPLETA.md`](INSTALACION_COMPLETA.md) | **Punto de entrada único.** Describe las 8 fases de instalación desde cero con resumen de cada módulo, orden de arranque y checklist final |
### Guías de Instalación por Módulo
Ubicadas en [`guias/`](guias/):
| Archivo | Contenido |
|:--------|:----------|
| [`guias/INSTALACION_RED.md`](guias/INSTALACION_RED.md) | pfSense: VM, interfaces, DHCP, DNS, NAT, reglas de firewall por VLAN, aislamiento VLAN 40, autenticación LDAP en panel |
| [`guias/INSTALACION_SERVIDOR.md`](guias/INSTALACION_SERVIDOR.md) | Debian 13: IP estática, Docker, Cockpit, MACVLAN, SSL, stack Docker, post-instalación Odoo, módulos, auditoría SQL |
| [`guias/INSTALACION_LDAP_CICD_HARDENING.md`](guias/INSTALACION_LDAP_CICD_HARDENING.md) | OpenLDAP: ACLs, usuarios, SSSD+PAM en clientes · GitHub Actions: runner, pipeline · Hardening: UFW, SSH por clave, headless |
### Referencia Técnica
| Archivo | Descripción |
|:--------|:------------|
| [`CONTROL_ACCESO.md`](CONTROL_ACCESO.md) | Modelo de seguridad en 3 capas: Nginx (rutas por VLAN) + Odoo (tipo de usuario) + LDAP (grupos por rol) |
| [`reglas_pfsense.md`](reglas_pfsense.md) | Referencia completa de todas las reglas de firewall pfSense, NAT y DNS |
| [`diagrama_red.md`](diagrama_red.md) | Diagramas Mermaid de la arquitectura: topología, zonas de seguridad, flujo de autenticación, red Docker |
### Historial y Seguimiento
| Archivo | Descripción |
|:--------|:------------|
| [`HISTORIAL_IMPLEMENTACION.md`](HISTORIAL_IMPLEMENTACION.md) | Cómo se construyó el proyecto: decisiones técnicas, problemas encontrados y cómo se resolvieron |
| [`CHANGELOG.md`](CHANGELOG.md) | Registro de cambios por versión (formato Keep a Changelog) |
### Memoria del TFG
| Archivo | Descripción |
|:--------|:------------|
| [`memoria_tfg_nuevo.md`](memoria_tfg_nuevo.md) | Memoria oficial del TFG en redacción |
| [`memoria_tfg_borrador.md`](memoria_tfg_borrador.md) | Borrador anterior de referencia |
---
## 📁 Estructura de Este Directorio
```
docs/
├── README.md                       ← Este archivo (índice)
├── INSTALACION_COMPLETA.md         ← Guía maestra (entrada principal)
├── CHANGELOG.md                    ← Historial de versiones
├── CONTROL_ACCESO.md               ← Modelo 3 capas de seguridad
├── HISTORIAL_IMPLEMENTACION.md     ← Historia del desarrollo
├── diagrama_red.md                 ← Diagramas de arquitectura
├── reglas_pfsense.md               ← Referencia de reglas pfSense
├── memoria_tfg_nuevo.md            ← Memoria del TFG
├── memoria_tfg_borrador.md         ← Borrador de la memoria
│
├── guias/                          ← Sub-guías de instalación
│   ├── INSTALACION_RED.md          (pfSense + VLAN 40)
│   ├── INSTALACION_SERVIDOR.md     (Debian + Docker + Odoo)
│   └── INSTALACION_LDAP_CICD_HARDENING.md (LDAP + CI/CD + Hardening)
│
├── archive/                        ← Documentos históricos de planificación
└── mas_info/                       ← Investigación técnica y comparativa ERP
```
---
## 🔄 Flujo de Trabajo (GitOps)
```
Modificación local → git commit + push → CI valida → CD despliega en servidor
```
> [!IMPORTANT]
> **Nunca editar scripts ni configs directamente en el servidor.**
> Cualquier cambio manual queda sobreescrito en el siguiente `git push`.
### Reglas del flujo
| Regla | Detalle |
|:------|:--------|
| Rama principal | Solo `main` dispara el CD automático |
| CI obligatorio | El CD solo se ejecuta si CI (ShellCheck + YAML + Markdown) pasa |
| Credenciales | `docker/.env` vive en el servidor — **nunca en Git** |
| Documentación | Los cambios en `docs/` también pasan por Markdownlint |
---
## 🛠️ Tareas de Administración Rápida
```bash
# Menú interactivo (recomendado para el día a día)
sudo /opt/erp-odoo/scripts/deploy/erp.sh
# Estado de los contenedores
docker compose -f /opt/erp-odoo/docker/docker-compose.yml ps
# Backup manual
bash /opt/erp-odoo/scripts/mantenimiento/backup.sh
# Restaurar backup
bash /opt/erp-odoo/scripts/mantenimiento/restore.sh /opt/erp-odoo/backups/<archivo>.dump
# Añadir usuario LDAP
bash /opt/erp-odoo/scripts/ldap/ldap_crear_usuarios.sh
# Configurar PC cliente VLAN 10 para login LDAP
sudo bash /opt/erp-odoo/scripts/ldap/configurar_cliente_ldap.sh
```
Referencia completa de scripts: [`../scripts/README.md`](../scripts/README.md)
---
## 📋 Plantillas para GitHub Issues
Copiar el bloque de descripción al crear un Issue en GitHub.
### [Infra] Verificación de Aislamiento VLAN
**Labels:** `infraestructura`, `seguridad`, `pfSense`
**Objetivo:** Verificar que la segmentación entre VLAN 10 (clientes) y VLAN 30 (DMZ) funciona correctamente.
- [ ] `nc -zv 192.168.30.10 5432` desde VLAN 10 → **timeout** ✅
- [ ] `nc -zv 192.168.30.10 8069` desde VLAN 10 → **timeout** ✅
- [ ] `nc -zv 192.168.30.10 22` desde VLAN 10 → **timeout** ✅
- [ ] `curl -k -I https://erp.odoo.tfg.com` desde VLAN 10 → **200** ✅
- [ ] `ping 192.168.10.x` desde DMZ → **sin respuesta** ✅
- [ ] Panel pfSense desde VLAN 10 → **no accesible** ✅
- [ ] Captura → `screenshots/fase_A_vlan/`
---
### [Docker] Red MACVLAN
**Labels:** `docker`, `red`
**Objetivo:** Asignar IPs físicas de la DMZ a los contenedores para que pfSense aplique reglas por host.
- [ ] `nginx-proxy` → IP `192.168.30.20` en MACVLAN
- [ ] `odoo-web` → IP `192.168.30.21` en MACVLAN
- [ ] `openldap` → IP `192.168.30.22` en MACVLAN
- [ ] `odoo_erp` → sin IP MACVLAN (solo red interna)
- [ ] `docker run --rm --network macvlan_vlan30 alpine wget -qO- https://192.168.30.20` → `<title>Odoo</title>`
- [ ] Captura de `docker network inspect macvlan_vlan30` → `screenshots/fase_B_macvlan/`
---
### [Identidad] Autenticación Centralizada LDAP
**Labels:** `ldap`, `autenticación`, `seguridad`
**Objetivo:** Una cuenta LDAP permite login en PC Linux y en Odoo.
- [ ] Contenedor OpenLDAP activo con IP `192.168.30.22`
- [ ] ACLs aplicadas: readonly=lectura, tecnico=contraseñas, admin=escritura
- [ ] Usuarios creados con `ldap_crear_usuarios.sh`
- [ ] Módulo `auth_ldap` instalado en Odoo
- [ ] Login en Odoo con credencial LDAP → OK
- [ ] `getent passwd <uid>` en PC VLAN 10 → resuelve el usuario
- [ ] Login en PC VLAN 10 con credencial LDAP → sesión abierta
- [ ] `cn=readonly` intenta modificar → error 50 (Insufficient access)
- [ ] Captura → `screenshots/fase_C_ldap/`
---
### [SecOps] Hardening SSH + Headless
**Labels:** `hardening`, `seguridad`, `debian`
**Objetivo:** Reducir superficie de ataque eliminando GUI y asegurando acceso solo por clave SSH.
- [ ] UFW activo: 22/80/443/9090 abiertos, deny-all el resto
- [ ] Clave SSH copiada al servidor (`ssh-copy-id`)
- [ ] Login SSH con clave verificado desde VLAN 40
- [ ] `PasswordAuthentication no` + `PermitRootLogin no` en sshd_config
- [ ] `systemctl set-default multi-user.target`
- [ ] Paquetes GNOME + X11 eliminados
- [ ] Reinicio → arranque en modo texto ✅
- [ ] Docker + 4 contenedores activos tras reinicio ✅
- [ ] Odoo accesible `https://erp.odoo.tfg.com` ✅
- [ ] Captura → `screenshots/fase_D_headless/`
---
### [DevOps] Pipeline CI/CD con GitHub Actions
**Labels:** `ci-cd`, `devops`
**Objetivo:** `git push` → CI valida → CD despliega automáticamente en el servidor.
- [ ] Runner instalado como servicio systemd
- [ ] Runner visible en GitHub → Idle (verde)
- [ ] Permisos `.env`: `640`, propietario `root:servidor`
- [ ] CI: ShellCheck + YAML lint + Markdownlint pasan ✅
- [ ] CD: `git reset --hard origin/main` + `docker compose pull` + `deploy.sh`
- [ ] Test end-to-end: commit vacío → push → CI ✅ → CD ✅
- [ ] Captura → `screenshots/fase_E_cicd/`
---
### [SecOps] Aislamiento VLAN 40 y Panel pfSense
**Labels:** `pfSense`, `seguridad`, `vlan40`
**Objetivo:** Panel pfSense solo accesible desde VLAN 40, autenticado con LDAP.
- [ ] OPT2 (VLAN 40): IP `192.168.40.1/24`, DHCP `40.10–50`
- [ ] Regla OPT2: `VLAN40 → This Firewall :443 → PASS`
- [ ] Acceso panel desde VLAN 40: `https://192.168.40.1` → OK
- [ ] Servidor LDAP configurado en User Manager → Authentication Servers
- [ ] Grupo `admin` en pfSense con `WebCfg - All pages`
- [ ] Authentication Server cambiado a `OpenLDAP DMZ`
- [ ] Anti-Lockout desactivado (System → Advanced → Admin Access)
- [ ] Login con `dba` → **denegado** ✅
- [ ] Login con `admin` → **concedido** ✅
- [ ] Panel desde VLAN 10 → **no accesible** ✅
---
## ⚠️ Archivos que NUNCA van a Git
```bash
# Verificar antes de cada commit:
git status
# Los siguientes NUNCA deben aparecer en la lista:
# docker/.env       → Credenciales reales
# certs/*.key       → Claves privadas SSL
# certs/*.crt       → Certificados
# data/             → Datos persistentes
# ISOs/             → Imágenes de instalación
# backups/          → Backups de PostgreSQL
```
---
## 📷 Nomenclatura de Capturas
```
screenshots/
├── fase_A_vlan/       → Reglas pfSense, nc timeout, curl 200
├── fase_B_macvlan/    → docker network inspect, IPs .20/.21/.22
├── fase_C_ldap/       → Login LDAP en Odoo, login LDAP en PC
├── fase_D_headless/   → SSH activo, Cockpit, sin GUI
└── fase_E_cicd/       → Pipeline GitHub Actions ejecutándose
```
---
*TFG ASIR 2025/2026 — Sandra Fradejas Avedillo — IES Cañaveral*
```

### File: .\docs\reglas_pfsense.md
```md
# Configuración de Reglas en pfSense (Firewall y NAT)
Este documento detalla todas las reglas configuradas en pfSense para la arquitectura de red del proyecto TFG.
La infraestructura cuenta con **cuatro interfaces**: **WAN** (red pública), **LAN/VLAN 10** (clientes 192.168.10.0/24), **OPT1/DMZ/VLAN 30** (zona desmilitarizada 192.168.30.0/24) y **OPT2/VLAN 40** (administración 192.168.40.0/24).
> **Nota:** En pfSense, el orden de las reglas importa. Se evalúan de arriba a abajo y se aplica la primera que coincide.
---
## Arquitectura de seguridad
```
Internet (WAN)
      │
      │  Solo puertos 80/443 abiertos al público
      │  SSH, Cockpit y panel pfSense → solo desde VLAN 40
      ▼
  [ pfSense ]
      │
      ├─── VLAN 10 / LAN (192.168.10.0/24) ──► Clientes / Trabajadores
      │         │  Accede a Odoo vía Nginx (80/443)
      │         │  Puede navegar por Internet
      │         │  NO puede acceder a VLAN 40, SSH, Cockpit ni panel pfSense
      │
      ├─── VLAN 30 / DMZ (192.168.30.0/24) ──► Servidor Debian + contenedores
      │         │  Puede salir a Internet (HTTP/HTTPS/DNS)
      │         │  NO puede alcanzar VLAN 10 ni VLAN 40 ← anti-pivoting
      │         │  NO puede acceder al panel de pfSense
      │
      └─── VLAN 40 / Admin (192.168.40.0/24) ──► Equipo de administración
                │  Acceso total: SSH, Cockpit, pfSense, LDAP, Odoo admin
                │  NO puede acceder a VLAN 10 ← segmentación estricta
```
---
## Interfaz WAN
*Firewall → Rules → WAN*
> Toda la administración se realiza desde la VLAN 40 (interna). Desde WAN solo se permite el acceso público a Odoo.
| Pos | Estado | Protocolo | Origen | Destino | Puerto | Descripción |
|:---:|:---:|:---|:---|:---|:---:|:---|
| 1 |  Block | * | Redes RFC 1918 | * | * | Block private networks *(automática)* |
| 2 |  Block | * | Redes Bogon | * | * | Block bogon networks *(automática)* |
| 3 |  Pass | IPv4 TCP | * | WAN address | 80 | HTTP público → redirige a HTTPS |
| 4 |  Pass | IPv4 TCP | * | WAN address | 443 | HTTPS público → Odoo |
| 5 |  Block | IPv4 * | * | * | * | **Bloquear todo lo demás** ← ¡ÚLTIMO! |
###  Puntos clave — WAN
- Las reglas **Block private networks** y **Block bogon networks** se activan en *Interfaces → WAN* y las genera pfSense automáticamente. Protegen contra spoofing.
- **SSH, Cockpit y panel pfSense no se abren desde WAN**. Toda la administración es interna desde VLAN 40.
- La regla **Bloquear todo lo demás** debe estar siempre en última posición.
---
## Interfaz LAN / VLAN 10 — Clientes
*Firewall → Rules → LAN*
Controla el tráfico desde la red de clientes (192.168.10.0/24). Los clientes solo pueden usar Odoo y navegar por Internet. No pueden administrar nada.
> ** El orden es crítico.** Los bloqueos hacia zonas de administración van **antes** que los permisos.
| # | Acción | Protocolo | Origen | Destino | Puerto | Descripción |
|:---:|:---:|:---:|:---|:---|:---:|:---|
| 1 |  Block | * | LAN | `192.168.40.0/24` | * | **Bloquear acceso a VLAN Admin** ← ¡PRIMERO! |
| 2 |  Block | * | LAN | `192.168.30.10` | 22 | Bloquear SSH al servidor |
| 3 |  Block | * | LAN | `192.168.30.10` | 9090 | Bloquear Cockpit |
| 4 |  Block | * | LAN | `192.168.30.22` | 636 | Bloquear LDAPS admin |
| 5 |  Block | * | LAN | `192.168.30.0/24` | 5432 | Bloquear PostgreSQL |
| 6 | ~~Pass~~ | IPv4 * | LAN subnets | * | * | ~~Default allow LAN to any~~ *(desactivada)* |
| 7 |  Pass | IPv4 TCP | LAN subnets | `192.168.30.10` | 80 | Odoo HTTP vía Nginx |
| 8 |  Pass | IPv4 TCP | LAN subnets | `192.168.30.10` | 443 | Odoo HTTPS vía Nginx |
| 9 |  Pass | IPv4 TCP | LAN subnets | `192.168.30.22` | 389 | LDAP autenticación *(cn=readonly)* |
| 10 |  Pass | IPv4 * | LAN subnets | * | * | Navegación general Internet |
| 11 |  Block | IPv4 * | * | * | * | **Deny all** ← ¡ÚLTIMO! |
###  Puntos clave — LAN
- La **"Default allow LAN to any"** (regla 6) debe estar **desactivada** (en gris). Se sustituye por reglas específicas.
- La regla Anti-Lockout automática de pfSense debe desactivarse desde *System → Advanced → Admin Access → Disable anti-lockout rule* **solo después** de confirmar acceso desde VLAN 40.
- Los puertos 8069 y 8072 (Odoo nativo y WebSocket) **no se abren directamente** — los clientes acceden solo a través de Nginx en los puertos 80/443.
---
## Interfaz OPT1 / DMZ / VLAN 30
*Firewall → Rules → OPT1*
Controla el tráfico desde el servidor Debian y los contenedores (192.168.30.0/24). La DMZ tiene acceso mínimo a Internet para actualizaciones y DNS.
> **El orden es crítico.** Los bloqueos de anti-pivoting deben ir **ANTES** que cualquier regla de permiso.
| Pos | Acción | Protocolo | Origen | Destino | Puerto | Descripción |
|:---:|:---:|:---:|:---|:---|:---:|:---|
| 1 |  Block | IPv4 * | DMZ | `192.168.10.0/24` | * | **DMZ NO puede atacar VLAN 10** ← ¡PRIMERO! |
| 2 |  Block | IPv4 * | DMZ | `192.168.10.1` | * | **DMZ NO puede acceder a pfSense LAN** |
| 3 |  Block | IPv4 * | DMZ | `192.168.40.0/24` | * | **DMZ NO puede acceder a VLAN Admin** |
| 4 |  Pass | IPv4 TCP | DMZ | * | 80 | Actualizaciones HTTP |
| 5 |  Pass | IPv4 TCP | DMZ | * | 443 | Actualizaciones HTTPS |
| 6 |  Pass | IPv4 UDP | DMZ | * | 53 | DNS resolución de nombres |
| 7 |  Block | IPv4 * | * | * | * | **Bloquear todo lo demás** ← ¡ÚLTIMO! |
###  Puntos clave — DMZ
- Los puertos SMTP (25, 465, 587) **no están abiertos** ya que el proyecto no utiliza envío de emails. Si en el futuro se necesitan, añadir antes del Deny all.
- PostgreSQL (5432) tampoco se abre: la base de datos es interna al servidor Debian.
- Las reglas 1, 2 y 3 de bloqueo deben estar siempre arriba del todo para evitar pivoting.
### Lógica de evaluación
```
Tráfico desde servidor DMZ (192.168.30.x)
         │
[Pos. 1] ¿Va hacia VLAN 10 (192.168.10.0/24)?  ──►  BLOQUEADO (anti-pivoting)
[Pos. 2] ¿Va hacia pfSense LAN (10.1)?          ──►  BLOQUEADO (protege pfSense)
[Pos. 3] ¿Va hacia VLAN 40 (192.168.40.0/24)?  ──►  BLOQUEADO (anti-pivoting admin)
         │ No
[Pos. 4] ¿Es TCP puerto 80?                     ──►  PERMITIDO (actualizaciones)
[Pos. 5] ¿Es TCP puerto 443?                    ──►  PERMITIDO (actualizaciones)
[Pos. 6] ¿Es UDP puerto 53?                     ──►  PERMITIDO (DNS)
         │ No coincide
[Pos. 7] Cualquier otro tráfico                 ──►  BLOQUEADO (deny-all)
```
### Nota técnica — Egress Filtering
Durante el TFG se evaluó restringir la salida de la DMZ a rangos CIDR específicos (GitHub/Azure) mediante pfBlockerNG con ASN. Se descartó por requerir un token externo de IPinfo.io, introduciendo dependencia de terceros. Se mantiene una regla de salida permisiva por **TCP 443** hacia `Any`, bloqueando el resto de protocolos y puertos. Esta decisión está documentada para su defensa en la memoria del TFG.
---
## Interfaz OPT2 / VLAN 40 — Administración
*Firewall → Interfaces → Assignments → OPT2*
La VLAN 40 (`192.168.40.0/24`) es la **red exclusiva de administración**. Desde aquí se gestiona todo: pfSense, SSH, Cockpit, LDAP y Odoo admin.
> [!IMPORTANT]
> Esta VLAN no existe en el diagrama original del TFG pero sí en el diseño IaC actualizado (mayo 2026). Requiere un adaptador de red adicional en la VM pfSense y en las máquinas de administración.
### Configuración de la interfaz OPT2
*Interfaces → OPT2*
| Campo | Valor |
|---|---|
| IPv4 Configuration | Static IPv4 |
| IPv4 Address | `192.168.40.1` / `24` |
| Description | `VLAN_ADMIN` |
### DHCP OPT2
*Services → DHCP Server → OPT2*
| Campo | Valor |
|---|---|
| Enable | Si |
| Range | `192.168.40.10 – 192.168.40.50` |
| DNS Server 1 | `192.168.40.1` |
### Reglas Firewall → OPT2
| # | Acción | Protocolo | Origen | Destino | Puerto | Descripción |
|:---:|:---:|:---:|:---|:---|:---:|:---|
| 1 |  Pass | TCP | VLAN 40 | `This Firewall` | 443 | **Panel pfSense** ← acceso exclusivo |
| 2 |  Pass | TCP | VLAN 40 | `192.168.30.10` | 22 | SSH al servidor Debian |
| 3 |  Pass | TCP | VLAN 40 | `192.168.30.10` | 9090 | Cockpit — gestión visual |
| 4 |  Pass | TCP | VLAN 40 | `192.168.30.20` | 443 | Nginx/Odoo admin completo |
| 5 |  Pass | TCP | VLAN 40 | `192.168.30.22` | 389 | LDAP admin (lectura + escritura) |
| 6 |  Pass | TCP | VLAN 40 | `192.168.30.22` | 636 | LDAPS admin (cifrado) |
| 7 |  Pass | TCP | VLAN 40 | * | 80, 443 | Actualizaciones Internet |
| 8 |  Pass | UDP | VLAN 40 | * | 53 | DNS resolución |
| 9 |  Block | * | VLAN 40 | `192.168.10.0/24` | * | Anti-pivoting a VLAN 10 |
| 10 |  Block | * | VLAN 40 | * | * | **Deny all** ← ¡ÚLTIMO! |
---
## NAT — Port Forwarding
*Firewall → NAT → Port Forward*
### Entradas WAN → DMZ (acceso público a Odoo)
| Interfaz | Proto | Source | Destino | Puerto entrada | Redirige a | Puerto destino | Descripción |
|:---:|:---:|:---:|:---|:---:|:---|:---:|:---|
| WAN | TCP | * | WAN address | 80 | `192.168.30.10` | 80 | HTTP → Nginx Odoo |
| WAN | TCP | * | WAN address | 443 | `192.168.30.10` | 443 | HTTPS → Nginx Odoo |
### Redirección DNS (forzar DNS interno por VLAN)
| Interfaz | Proto | Source | Destino | Puerto | Redirige a | Descripción |
|:---:|:---:|:---|:---:|:---:|:---|:---|
| LAN | TCP/UDP | `192.168.10.0/24` | * | 53 | `192.168.10.1` | Forzar DNS VLAN 10 → pfSense |
| OPT2 | TCP/UDP | `192.168.40.0/24` | * | 53 | `192.168.40.1` | Forzar DNS VLAN 40 → pfSense |
> **Por qué es necesario:** Los clientes Linux modernos con `systemd-resolved` pueden ignorar el DNS del DHCP y enviar consultas a 8.8.8.8. Esta regla intercepta cualquier consulta DNS desde cada VLAN y la redirige a pfSense, garantizando que `erp.odoo.tfg.com` resuelva siempre a `192.168.30.10`.
### NAT Outbound
*Firewall → NAT → Outbound → Modo: Automatic*
Con el modo automático pfSense aplica NAT a todas las subnets internas. Si usas modo Manual, añade una entrada por cada subnet:
| Source | Traducción | Descripción |
|:---|:---|:---|
| `192.168.10.0/24` | WAN address | Clientes salen a Internet |
| `192.168.30.0/24` | WAN address | DMZ/Odoo sale a Internet |
| `192.168.40.0/24` | WAN address | Admin sale a Internet |
---
## DHCP — Configuración por interfaz
### DHCP LAN / VLAN 10
*Services → DHCP Server → LAN*
| Campo | Valor |
|---|---|
| Enable | Si |
| Range | `192.168.10.100 – 192.168.10.200` |
| Gateway | `192.168.10.1` |
| DNS Server 1 | `192.168.10.1` |
### DHCP OPT2 / VLAN 40
*Services → DHCP Server → OPT2*
| Campo | Valor |
|---|---|
| Enable | si |
| Range | `192.168.40.10 – 192.168.40.50` |
| DNS Server 1 | `192.168.40.1` |
> La DMZ (VLAN 30) **no usa DHCP**. Las IPs son estáticas configuradas directamente en el servidor Debian y en los ficheros Docker MACVLAN.
---
## DNS Resolver
*Services → DNS Resolver → General Settings*
| Campo | Valor |
|---|---|
| Enable | Si |
| Network Interfaces | LAN, OPT1, OPT2, Localhost |
### Host Override — Odoo
*Services → DNS Resolver → Host Overrides → + Add*
| Campo | Valor |
|---|---|
| Host | `erp.odoo` |
| Domain | `tfg.com` |
| IP Address | `192.168.30.10` |
| Description | `Servidor Odoo ERP - DMZ` |
### Flujo completo de resolución DNS
```
Cliente VLAN 10 (systemd-resolved envía consulta a 8.8.8.8:53)
        │
        ▼  pfSense intercepta (NAT Port Forward LAN TCP/UDP :53)
        │
        ▼  Redirige a 192.168.10.1:53
        │
[ pfSense DNS Resolver ]
        │  Host Override → erp.odoo.tfg.com = 192.168.30.10
        ▼
Cliente recibe 192.168.30.10 → abre HTTPS → Nginx → Odoo 
```
---
## Tabla IPs MACVLAN — DMZ
| Contenedor | Red interna (`odoo_net`) | IP MACVLAN (`macvlan_vlan30`) | Acceso |
|:---|:---|:---|:---|
| `odoo_erp` (PostgreSQL) | 172.19.0.x |  Sin IP externa | Solo contenedores internos |
| `odoo-web` (Odoo 17) | 172.19.0.3 | `192.168.30.21` | VLAN 10 + VLAN 40 vía Nginx |
| `openldap` (LDAP) | 172.19.0.5 | `192.168.30.22` | VLAN 10 (:389 readonly), VLAN 40 (:389/:636 admin) |
| `nginx-proxy` (Nginx) | 172.19.0.4 | `192.168.30.20` | Todos (80/443) |
---
## Securización del Panel pfSense
El panel de pfSense solo debe ser accesible desde la VLAN 40. Se aplica en dos capas.
### Capa 1 — Red (Firewall)
1. Crear en *Firewall → Rules → OPT2* la regla que permite acceso al panel desde VLAN 40 (ya incluida en la tabla de OPT2, regla 1).
2. Ir a *System → Advanced → Admin Access* y marcar **Disable webConfigurator anti-lockout rule**.
>  **Solo deshabilitar la Anti-Lockout después de confirmar acceso desde una IP de la VLAN 40** (`https://192.168.40.1`). De lo contrario quedarás fuera del firewall.
### Capa 2 — Autenticación LDAP
*System → User Manager → Authentication Servers → + Add*
| Campo | Valor |
|---|---|
| Descriptive name | `OpenLDAP DMZ` |
| Type | LDAP |
| Hostname | `192.168.30.22` |
| Port | `389` |
| Transport | TCP - Standard |
| Base DN | `dc=tfg,dc=com` |
| Authentication containers | `ou=usuarios,dc=tfg,dc=com` |
| Bind credentials | `cn=admin,dc=tfg,dc=com` |
| User naming attribute | `uid` |
| Group naming attribute | `cn` |
| Group member attribute | `member` |
Crear en *System → User Manager → Groups* un grupo llamado **`admin`** con privilegio **WebCfg - All pages**. No crear el grupo `dba` con privilegios en pfSense.
Activar en *System → User Manager → Settings → Authentication Server*: `OpenLDAP DMZ`.
**Resultado:** El usuario `dba` puede ver el login pero pfSense le deniega el acceso al no pertenecer al grupo con privilegios. Solo el usuario `admin` puede entrar.
---
## Nginx — Verificación server_name
El `server_name` de Nginx debe coincidir con el Host Override DNS.
```bash
# Verificar valor actual
grep server_name /opt/erp-odoo/config_nginx/*.conf
# Corregir si es necesario
sudo sed -i 's/erp.techsolutions.local/erp.odoo.tfg.com/g' /opt/erp-odoo/config_nginx/*.conf
# Recargar sin cortar servicio
docker exec nginx-proxy nginx -s reload
docker exec nginx-proxy nginx -t
```
---
## Verificación final del sistema
```bash
# Desde cliente VLAN 10
nslookup erp.odoo.tfg.com            # Debe devolver 192.168.30.10
curl -k -I https://erp.odoo.tfg.com  # Debe devolver HTTP/2 200
# Desde admin VLAN 40
ssh usuario@192.168.30.10            # Debe conectar
# Navegador → https://192.168.40.1      → Panel pfSense accesible
# Navegador → https://192.168.30.10:9090 → Cockpit accesible
```
---
## Checklist de configuración completa
```
 Interfaces asignadas
   ├─ WAN  → IP externa (DHCP o estática)
   ├─ LAN  → 192.168.10.1/24  (VLAN 10 clientes)
   ├─ OPT1 → 192.168.30.1/24  (VLAN 30 DMZ)
   └─ OPT2 → 192.168.40.1/24  (VLAN 40 admin)
 DHCP
   ├─ LAN  → 192.168.10.100–200, DNS 192.168.10.1
   └─ OPT2 → 192.168.40.10–50,  DNS 192.168.40.1
   (OPT1/DMZ → IPs estáticas en Debian, sin DHCP)
 Firewall Rules
   ├─ WAN  → solo 80/443 público + deny all
   ├─ LAN  → bloqueos admin primero + Odoo/Internet + deny all
   ├─ OPT1 → bloqueos anti-pivoting primero + salida mínima + deny all
   └─ OPT2 → panel pfSense + SSH/Cockpit/LDAP/Odoo + deny all
 NAT Port Forward
   ├─ WAN :80  → 192.168.30.10:80   (Nginx)
   ├─ WAN :443 → 192.168.30.10:443  (Nginx)
   ├─ LAN  DNS :53 → 192.168.10.1   (forzar DNS VLAN 10)
   └─ OPT2 DNS :53 → 192.168.40.1   (forzar DNS VLAN 40)
 NAT Outbound → Automatic
 DNS Resolver
   ├─ Habilitado en LAN, OPT1, OPT2, Localhost
   └─ Host Override: erp.odoo.tfg.com → 192.168.30.10
 System → Advanced → Admin Access
   └─ Disable anti-lockout rule (tras confirmar acceso desde VLAN 40)
```
```

### File: .\docs\archive\GESTION_REPOSITORIO.md
```md
# Gestión del Repositorio — TFG ASIR 2025/2026
**→ Guía de instalación completa:** [`docs/INSTALACION_COMPLETA.md`](INSTALACION_COMPLETA.md)
---
## 📁 Estructura del Repositorio
```
TFG-ASIRB/
├── .github/workflows/
│   ├── ci.yml              # CI: ShellCheck + YAML lint + Markdownlint
│   └── deploy.yml          # CD: despliegue automático al servidor
├── config/logrotate.d/
│   └── erp-odoo            # Rotación semanal de logs de cron
├── config_nginx/
│   └── odoo_proxy.conf     # Proxy inverso Nginx + SSL + cabeceras seguridad
├── docker/
│   ├── .env                # Credenciales reales (excluido de Git)
│   ├── docker-compose.yml  # 4 servicios: PostgreSQL, Odoo, LDAP, Nginx
│   └── odoo.conf           # Configuración interna de Odoo 17
├── docs/
│   ├── INSTALACION_COMPLETA.md      # ← Punto de entrada principal
│   ├── CONTROL_ACCESO.md            # Modelo de seguridad en 3 capas
│   ├── HISTORIAL_IMPLEMENTACION.md  # Decisiones y problemas del proyecto
│   ├── CHANGELOG.md                 # Registro de cambios por versión
│   ├── GESTION_REPOSITORIO.md       # Este archivo
│   ├── reglas_pfsense.md            # Referencia completa de reglas pfSense
│   ├── GUIA_AISLAMIENTO_ADMIN.md    # Guía VLAN 40 paso a paso
│   ├── diagrama_red.md              # Diagrama de arquitectura de red
│   ├── github_issues.md             # Plantillas de Issues para GitHub
│   ├── guias/                       # Sub-guías de instalación por módulo
│   │   ├── 01_PFSENSE_INSTALACION.md
│   │   ├── 02_DEBIAN_PREPARACION.md
│   │   ├── 03_DOCKER_STACK.md
│   │   ├── 04_ODOO_CONFIGURACION.md
│   │   ├── 05_LDAP_INSTALACION.md
│   │   ├── 07_CICD_GITHUB.md
│   │   └── 08_HARDENING_FINAL.md
│   ├── archive/                     # Documentos históricos de planificación
│   └── mas_info/                    # Investigación técnica e informes ERP
├── ldap/
│   └── estructura.ldif              # Estructura base del directorio LDAP
├── scripts/
│   ├── README.md                    # Índice de scripts con descripción
│   ├── deploy/
│   │   ├── configure.sh             # Configuración interactiva del .env
│   │   ├── deploy.sh                # Levanta el stack con healthcheck
│   │   ├── erp.sh                   # Orquestador central (menú interactivo)
│   │   └── install_cron.sh          # Instala tareas cron y logrotate
│   ├── odoo/
│   │   ├── odoo_setup_wizard.sh     # Post-instalación: empresa + módulos + LDAP
│   │   └── odoo_crear_usuarios.sh   # Crea usuarios Odoo por XML-RPC
│   ├── ldap/
│   │   ├── configurar_cliente_ldap.sh  # Configura SSSD+PAM en PCs cliente
│   │   ├── ldap_crear_usuarios.sh      # Crea usuarios en el directorio LDAP
│   │   └── ldap_politica_acceso.sh     # Aplica ACLs al servidor LDAP
│   └── mantenimiento/
│       ├── backup.sh                # Backup comprimido de PostgreSQL
│       ├── restore.sh               # Restauración desde backup
│       ├── monitor.sh               # Monitor de salud + auto-reinicio
│       └── update.sh                # Actualización de imágenes Docker
├── sql/
│   └── audit_triggers.sql           # Auditoría PL/pgSQL en PostgreSQL
├── .env.example                     # Plantilla pública de variables
├── .gitignore                       # Excluye .env, certs/, data/, ISOs/
├── install.sh                       # Instalador todo-en-uno
└── README.md                        # Documentación principal del proyecto
```
---
## 🔄 Flujo de Trabajo (GitOps)
El repositorio es la **fuente de verdad** del sistema. El flujo de trabajo es:
```
1. Editar localmente  →  2. Commit + Push  →  3. CI valida  →  4. CD despliega
     (PC)                  (git push main)      (GitHub)         (Servidor)
```
> [!IMPORTANT]
> **Nunca edites scripts o archivos de configuración directamente en el servidor de producción.**
> Cualquier cambio manual será sobreescrito por el siguiente `git push`.
### Reglas del flujo GitOps
| Regla | Descripción |
|:------|:------------|
| Rama principal | Solo `main` dispara el CD automático |
| CI obligatorio | El CD solo se ejecuta si el CI pasa sin errores |
| Credenciales | El `.env` con contraseñas reales vive en el servidor, **nunca en Git** |
| Documentación | Los cambios de docs también pasan por CI (Markdownlint) |
---
## 🛠️ Tareas de Administración Diaria
```bash
# Menú interactivo completo (recomendado)
sudo /opt/erp-odoo/scripts/deploy/erp.sh
# Operaciones directas
bash scripts/mantenimiento/backup.sh       # Backup manual
bash scripts/mantenimiento/restore.sh      # Restaurar backup
bash scripts/mantenimiento/monitor.sh      # Chequeo de salud
bash scripts/mantenimiento/update.sh       # Actualizar imágenes Docker
bash scripts/ldap/ldap_crear_usuarios.sh   # Añadir usuario LDAP
# Ver logs en tiempo real
docker compose -f docker/docker-compose.yml logs -f
# Estado de los contenedores
docker compose -f docker/docker-compose.yml ps
```
Para la referencia completa de cada script, ver [`scripts/README.md`](../scripts/README.md).
---
## 📝 Mantenimiento de la Documentación
| Documento | Cuándo actualizarlo |
|:----------|:--------------------|
| `CHANGELOG.md` | En cada versión o cambio funcional relevante |
| `README.md` | Solo si cambia la arquitectura (nuevo contenedor, nueva VLAN, etc.) |
| `INSTALACION_COMPLETA.md` | Si cambian los pasos de instalación |
| `guias/` | Al añadir o modificar un módulo de la infraestructura |
| `reglas_pfsense.md` | Al modificar reglas de firewall |
| `HISTORIAL_IMPLEMENTACION.md` | Al resolver problemas significativos o tomar decisiones técnicas |
### Capturas de pantalla
Guardar en `screenshots/` con la nomenclatura:
```
screenshots/
├── fase_A_vlan/        → Verificación VLAN y reglas pfSense
├── fase_B_macvlan/     → Red MACVLAN y IPs de contenedores
├── fase_C_ldap/        → Login LDAP en Odoo y en PCs
├── fase_D_headless/    → SSH activo, Cockpit, sin GUI
└── fase_E_cicd/        → Pipeline CI/CD ejecutándose
```
---
## ⚠️ Archivos que NUNCA deben ir a Git
```bash
# Verificar que .gitignore los excluye correctamente:
git status
# Los siguientes NUNCA deben aparecer en git status:
# docker/.env         → Credenciales reales
# certs/*.key         → Claves privadas SSL
# certs/*.crt         → Certificados SSL
# data/               → Datos persistentes de contenedores
# ISOs/               → Imágenes de instalación (son muy pesadas)
# backups/            → Backups de PostgreSQL
```
---
*Para el flujo de CI/CD detallado, ver [`docs/guias/07_CICD_GITHUB.md`](guias/07_CICD_GITHUB.md)*
```

### File: .\docs\archive\github_issues.md
```md
# Plantillas para GitHub Issues — TFG ASIR 2025/2026
> Este documento contiene plantillas estandarizadas para gestionar el trabajo mediante **GitHub Issues**.
> Copiar el bloque de descripción de cada plantilla al crear un nuevo Issue en GitHub.
>
> **→ Estado del proyecto:** Ver [`docs/HISTORIAL_IMPLEMENTACION.md`](HISTORIAL_IMPLEMENTACION.md)
---
## [Infra] Verificación de Aislamiento VLAN y Reglas pfSense
**Labels sugeridos:** `infraestructura`, `seguridad`, `pfSense`
### 🎯 Objetivo
Garantizar y verificar el endurecimiento perimetral mediante segmentación de red.
La VLAN 10 (clientes) no debe tener acceso directo a la DMZ (VLAN 30) salvo a los
puertos estrictamente expuestos por el proxy inverso (Nginx).
### ✅ Tareas
- [ ] Revisar reglas en pfSense → Firewall → Rules → LAN, OPT1 (DMZ), OPT2 (VLAN 40)
- [ ] Verificar anti-lockout desactivado y acceso al panel solo desde VLAN 40
- [ ] `nc -zv 192.168.30.10 5432` desde VLAN 10 → **debe fallar** (PostgreSQL bloqueado)
- [ ] `nc -zv 192.168.30.10 8069` desde VLAN 10 → **debe fallar** (Odoo directo bloqueado)
- [ ] `nc -zv 192.168.30.10 22` desde VLAN 10 → **debe fallar** (SSH bloqueado)
- [ ] `curl -k -I https://erp.odoo.tfg.com` desde VLAN 10 → **debe devolver 200**
- [ ] `ping 192.168.10.x` desde DMZ → **sin respuesta** (anti-pivoting activo)
- [ ] `curl -k https://192.168.40.1` desde VLAN 10 → **debe fallar** (panel pfSense bloqueado)
- [ ] Capturar pantalla de las reglas en pfSense → guardar en `screenshots/fase_A_vlan/`
### 🔗 Referencias
- [`docs/reglas_pfsense.md`](reglas_pfsense.md)
- [`docs/guias/01_PFSENSE_INSTALACION.md`](guias/01_PFSENSE_INSTALACION.md)
---
## [Docker] Implementación de Redes MACVLAN
**Labels sugeridos:** `docker`, `red`, `macvlan`
### 🎯 Objetivo
Asignar IPs físicas de la subred DMZ (`192.168.30.0/24`) a los contenedores expuestos
(Nginx `.20`, Odoo `.21`, LDAP `.22`) para que pfSense aplique reglas por host individual.
### ✅ Tareas
- [ ] Crear red MACVLAN vinculada a la interfaz física del servidor (`ens18` u otra)
- [ ] Verificar sintaxis de `networks` en `docker-compose.yml` (formato mapa, no lista)
- [ ] `nginx-proxy` → IP `192.168.30.20` en red MACVLAN
- [ ] `odoo-web` → IP `192.168.30.21` en red MACVLAN
- [ ] `openldap` → IP `192.168.30.22` en red MACVLAN
- [ ] `odoo_erp` (PostgreSQL) → sin IP MACVLAN (solo red interna)
- [ ] `docker compose up -d --force-recreate` para aplicar cambios
- [ ] Verificar desde contenedor temporal: `docker run --rm --network macvlan_vlan30 alpine wget -qO- https://192.168.30.20`
- [ ] Captura de `docker network inspect macvlan_vlan30` → `screenshots/fase_B_macvlan/`
### 🔗 Referencias
- [`docs/guias/03_DOCKER_STACK.md`](guias/03_DOCKER_STACK.md)
---
## [Identidad] Integración de Autenticación Centralizada (LDAP)
**Labels sugeridos:** `ldap`, `autenticación`, `seguridad`
### 🎯 Objetivo
Centralizar la gestión de credenciales mediante OpenLDAP. Una misma cuenta
permite al empleado iniciar sesión en su PC Linux y en el ERP Odoo.
### ✅ Tareas
- [ ] Contenedor OpenLDAP activo con IP MACVLAN `192.168.30.22`
- [ ] Estructura base cargada: `ou=usuarios`, `ou=grupos`, `ou=servicios`
- [ ] ACLs aplicadas (`ldap_politica_acceso.sh`): admin → escritura, readonly → lectura, tecnico → solo contraseñas
- [ ] Usuarios de empleados creados con `ldap_crear_usuarios.sh`
- [ ] Módulo `auth_ldap` instalado en Odoo
- [ ] Conexión LDAP configurada en Odoo (IP `192.168.30.22`, bind: `cn=readonly`)
- [ ] Login en Odoo con credencial LDAP → **acceso OK**
- [ ] `configurar_cliente_ldap.sh` ejecutado en un PC de VLAN 10
- [ ] `getent passwd <uid>` en el PC cliente → **muestra el usuario LDAP**
- [ ] Login en el PC con credencial LDAP → **sesión abierta, `/home/<uid>` creado**
- [ ] Captura de login LDAP en Odoo y en PC → `screenshots/fase_C_ldap/`
### 🔗 Referencias
- [`docs/guias/05_LDAP_INSTALACION.md`](guias/05_LDAP_INSTALACION.md)
- [`docs/CONTROL_ACCESO.md`](CONTROL_ACCESO.md)
---
## [SecOps] Conversión a Debian Headless y Hardening SSH
**Labels sugeridos:** `hardening`, `seguridad`, `debian`
### 🎯 Objetivo
Reducir la superficie de ataque del servidor Debian eliminando el entorno gráfico
y asegurando el acceso administrativo exclusivamente por clave SSH desde VLAN 40.
### ✅ Tareas
- [ ] UFW instalado y activo: puertos 22, 80, 443, 9090 abiertos, deny-all el resto
- [ ] Clave SSH pública copiada al servidor (`ssh-copy-id`)
- [ ] Login SSH con clave pública verificado desde PC VLAN 40
- [ ] `PasswordAuthentication no` en `/etc/ssh/sshd_config`
- [ ] `PermitRootLogin no` en `/etc/ssh/sshd_config`
- [ ] `sshd` reiniciado y funcionando
- [ ] `systemctl set-default multi-user.target`
- [ ] Paquetes gráficos eliminados (`gnome*`, `x11*`, `xorg*`)
- [ ] Servidor reiniciado → arranca en modo texto
- [ ] SSH funciona tras el reinicio
- [ ] Docker y los 4 contenedores activos tras el reinicio
- [ ] `https://erp.odoo.tfg.com` accesible tras el reinicio
- [ ] Captura SSH activo y Cockpit funcionando → `screenshots/fase_D_headless/`
### 🔗 Referencias
- [`docs/guias/08_HARDENING_FINAL.md`](guias/08_HARDENING_FINAL.md)
---
## [DevOps] CI/CD Pipeline con GitHub Actions (IaC)
**Labels sugeridos:** `ci-cd`, `github-actions`, `devops`
### 🎯 Objetivo
Tratar la infraestructura como código: cualquier cambio en el repositorio se valida
automáticamente y se despliega en el servidor sin intervención manual.
### ✅ Tareas
- [ ] Workflow `ci.yml` activo: ShellCheck en scripts + YAML lint + Markdownlint
- [ ] Self-hosted runner instalado en Debian como servicio systemd
- [ ] Runner visible en GitHub → Settings → Actions → Runners (estado: Idle)
- [ ] Permisos de `docker/.env` ajustados para el usuario del runner (640)
- [ ] Workflow `deploy.yml` activo: dispara CD tras CI exitoso en `main`
- [ ] Prueba end-to-end: `git push` → CI ✅ → CD ✅ → contenedores actualizados
- [ ] Captura del pipeline ejecutándose en GitHub → `screenshots/fase_E_cicd/`
### 🔗 Referencias
- [`docs/guias/07_CICD_GITHUB.md`](guias/07_CICD_GITHUB.md)
---
## [SecOps] Securización del Panel de pfSense (VLAN 40 + LDAP)
**Labels sugeridos:** `pfSense`, `seguridad`, `ldap`
### 🎯 Objetivo
Restringir el panel web de pfSense exclusivamente a la red de administración (VLAN 40)
e implementar autenticación LDAP para que solo el usuario `admin` pueda acceder.
### ✅ Tareas
- [ ] Interfaz OPT2 (VLAN 40) configurada con IP `192.168.40.1/24` y DHCP activo
- [ ] Regla en OPT2: `VLAN40 → This Firewall :443 → PASS`
- [ ] Acceso al panel comprobado desde una IP de VLAN 40 (`https://192.168.40.1`)
- [ ] Servidor LDAP añadido en System → User Manager → Authentication Servers
- [ ] Grupo `admin` creado en pfSense con privilegio `WebCfg - All pages`
- [ ] Authentication Server cambiado a `OpenLDAP DMZ`
- [ ] Anti-Lockout Rule desactivada en System → Advanced → Admin Access
- [ ] Login con usuario `dba` → **denegado** ✅
- [ ] Login con usuario `admin` → **acceso concedido** ✅
- [ ] Login en panel desde VLAN 10 → **no accesible** ✅
### 🔗 Referencias
- [`docs/guias/01_PFSENSE_INSTALACION.md`](guias/01_PFSENSE_INSTALACION.md) — sección 1.10–1.11
- [`docs/GUIA_AISLAMIENTO_ADMIN.md`](GUIA_AISLAMIENTO_ADMIN.md)
---
## [Control Acceso] Configuración de Roles y 3 Capas de Seguridad
**Labels sugeridos:** `odoo`, `ldap`, `seguridad`, `roles`
### 🎯 Objetivo
Implementar el modelo de seguridad en 3 capas: Nginx filtra rutas por IP/VLAN,
Odoo controla el tipo de usuario, y los grupos LDAP definen los módulos visibles.
### ✅ Tareas
- [ ] Nginx recargado con restricciones de rutas activas
- [ ] `/web/database/manager` desde VLAN 10 → **403 Forbidden**
- [ ] `/web/tests` → **403 Forbidden** (todos)
- [ ] `/web?debug=` desde VLAN 10 → **403 Forbidden**
- [ ] Usuarios Odoo creados con `odoo_crear_usuarios.sh`
- [ ] Login becario → solo CRM, sin botón Eliminar
- [ ] Login ventas → CRM + Ventas + Facturas
- [ ] Login admin (VLAN 40) → acceso total + panel BD
- [ ] Readonly LDAP no puede modificar → error `Insufficient access (50)`
- [ ] Técnico puede cambiar contraseña de empleado con `ldappasswd`
### 🔗 Referencias
- [`docs/CONTROL_ACCESO.md`](CONTROL_ACCESO.md)
---
*Proyecto: TFG ASIR 2025/2026 — Sandra Fradejas Avedillo — IES Cañaveral*
```

### File: .\docs\archive\GUIA_AISLAMIENTO_ADMIN.md
```md
# Guía Paso a Paso: Aislamiento del Servidor y Red de Administración (VLAN 40)
Esta guía explica desde cero cómo separar tu infraestructura para que **solo un administrador desde una red especial (VLAN 40)** pueda gestionar el cortafuegos y los servidores, limitando al máximo los privilegios de los usuarios normales (VLAN 10) y la salida a internet del propio servidor (DMZ).
Como solo tenemos **un ordenador Lubuntu** para hacer pruebas, el orden de los pasos es crítico para evitar quedarnos sin acceso a nuestro propio sistema ("lockout").
---
## FASE 1: Preparar la nueva red de Administradores (VLAN 40)
Aún no vamos a mover el Lubuntu. Entraremos a pfSense (`https://192.168.10.1`) desde el Lubuntu estando en la red de clientes (VLAN 10).
### 1. Configurar la interfaz OPT2 (VLAN 40)
Si en tu hipervisor (Proxmox / VirtualBox) ya conectaste una tercera interfaz de red a pfSense:
1. En pfSense, ve a **Interfaces → Assignments**.
2. Añade la nueva interfaz disponible (normalmente será `OPT2`).
3. Ve a **Interfaces → OPT2**, marca **"Enable Interface"** y ponle la descripción `VLAN_ADMIN`.
4. En **IPv4 Configuration Type**, selecciona `Static IPv4`.
5. En **IPv4 Address**, escribe `192.168.40.1` y en el desplegable de la derecha elige `/24`.
6. Clic en **Save** y luego en **Apply Changes**.
### 2. Configurar el servidor DHCP en la VLAN 40
Para que cuando pasemos nuestro Lubuntu a esta red se conecte automáticamente:
1. Ve a **Services → DHCP Server → OPT2 (VLAN_ADMIN)**.
2. Marca la casilla **Enable DHCP server on OPT2 interface**.
3. En la sección **Range**, pon desde `192.168.40.10` hasta `192.168.40.50`.
4. En **DNS Servers**, escribe `192.168.40.1`.
5. Clic en **Save**.
### 3. Dar permisos temporales de acceso a la VLAN 40
Queremos que el administrador pueda entrar al pfSense cuando nos mudemos de red:
1. Ve a **Firewall → Rules → OPT2**.
2. Añade una regla (`+ Add`):
   - **Action:** Pass
   - **Protocol:** Any (Luego la endureceremos, ahora es para pruebas).
   - **Source:** `OPT2 subnets`
   - **Destination:** Any
3. Clic en **Save** y **Apply Changes**.
---
## FASE 2: Restringir Internet en el Servidor (Mínimo Necesario)
El servidor en la DMZ (192.168.30.10) solo debe poder actualizar sistema y descargar de GitHub/Docker, nada más.
1. En pfSense, ve a **Firewall → Aliases → IP**.
2. Añade un nuevo alias (`+ Add`):
   - **Name:** `SERVICIOS_PERMITIDOS_DMZ`
   - **Type:** Host(s)
   - Añade en las casillas (usa el botón `+ Add Host`):
     - `github.com`
     - `api.github.com`
     - `objects.githubusercontent.com`
     - `raw.githubusercontent.com`
     - `registry-1.docker.io`
     - `auth.docker.io`
     - `production.cloudflare.docker.com`
     - `deb.debian.org`
3. Guarda el alias.
4. Ve a **Firewall → Rules → DMZ (OPT1)**.
5. Edita las reglas que permiten tráfico HTTP/HTTPS (puertos 80 y 443) hacia fuera.
6. Cambia el campo **Destination** de `Any` a `Single host or alias` y escribe `SERVICIOS_PERMITIDOS_DMZ`.
7. **Importante:** Al final del todo debe haber una regla de **Bloqueo a Todo (Deny All)**:
   - Action: Block, Protocol: Any, Source: Any, Destination: Any.
8. Clic en **Save** y **Apply Changes**.
---
## FASE 3: Restringir a los clientes de la VLAN 10
Los clientes (como el Lubuntu ahora mismo) NO deben poder acceder a pfSense, ni a la administración por SSH.
1. Ve a **Firewall → Rules → LAN**.
2. Asegúrate de tener **solamente** reglas que permitan:
   - Ir a Odoo: HTTP (80) y HTTPS (443) apuntando a la IP `192.168.30.10`.
   - Ir a Odoo (nativo): Puerto `8069`.
   - Ir a LDAP para login: Puerto `389` apuntando al contenedor LDAP (`192.168.30.22`).
   - Tráfico a Internet genérico (navegación).
3. Añade una regla de **Bloqueo (Block)** al principio del todo para que la LAN no pueda conectarse nunca al servidor por SSH (puerto 22) o Cockpit (puerto 9090).
---
## FASE 4: Securizar pfSense con LDAP (Usuarios del ERP)
Vamos a configurar pfSense para que lea los usuarios del servidor en la DMZ.
1. Ve a **System → User Manager → Authentication Servers**.
2. Añade el servidor (`+ Add`):
   - **Name:** `OpenLDAP DMZ`
   - **Type:** LDAP
   - **Hostname:** `192.168.30.22` (IP de tu contenedor LDAP).
   - **Port:** `389`
   - **Transport:** TCP - Standard
   - **Base DN:** `dc=tfg,dc=com`
   - **Authentication containers:** `ou=usuarios,dc=tfg,dc=com`
   - **Bind credentials:** `cn=admin,dc=tfg,dc=com` y tu contraseña del LDAP.
   - **User naming attribute:** `uid`
   - **Group naming attribute:** `cn`
   - **Group member attribute:** `member`
3. Clic en **Save**.
4. Ve a **System → User Manager → Groups**. Crea un grupo llamado exactamente **`admin`** y asígnale en "Assigned Privileges" el privilegio **"WebCfg - All pages"**.
5. Ve a **System → User Manager → Settings**. Cambia el "Authentication Server" a `OpenLDAP DMZ`. **Save**.
---
## FASE 5: Bloquear el acceso de pfSense a los Clientes (Desactivar Anti-Lockout)
**CUIDADO AQUÍ:** Una vez hagamos esto, si cerramos la pestaña no podremos volver a entrar a pfSense desde la IP de clientes (`192.168.10.1`).
1. Ve a **System → Advanced → Admin Access**.
2. Baja hasta encontrar **Disable webConfigurator anti-lockout rule**. Marca esa casilla.
3. Clic en **Save**.
4. *(A partir de ahora, el único lugar seguro para acceder a pfSense es conectándose a la VLAN 40).*
---
## FASE 6: Mudanza a la Red de Administración y Pruebas
Llegó el momento. Como solo tenemos una máquina cliente (Lubuntu), vamos a sacarla de la red de usuarios normales y meterla en la de administradores.
1. Abre tu hipervisor (VirtualBox o Proxmox).
2. Ve a la configuración de la máquina virtual de tu **Lubuntu**.
3. En el apartado de **Red**, cambia la interfaz para que ahora apunte a la **VLAN 40** (en vez de a la VLAN 10).
4. Vuelve al Lubuntu y abre una terminal. Ejecuta estos comandos para refrescar la IP:
   ```bash
   sudo dhclient -r
   sudo dhclient
   ```
5. Comprueba tu IP ejecutando `ip a`. Debería darte una del rango `192.168.40.X`.
6. Abre el navegador en Lubuntu y entra en **`https://192.168.40.1`**.
7. Te saldrá el panel de pfSense. Intenta acceder con un usuario "normal" del LDAP (ej: `dba`); **debe rechazarlo**.
8. Intenta acceder con el usuario `admin` del LDAP; **debe dejarte entrar**.
9. Comprueba desde tu terminal en Lubuntu que puedes hacer ping y conexión SSH al servidor (`ssh usuario@192.168.30.10`), demostrando que como Administrador tienes acceso total a la DMZ.
```

### File: .\docs\archive\GUIA_DESPLIEGUE.md
```md
# Guía de Despliegue — Implantación Segura y Automatizada de Odoo
**TFG ASIR 2025/2026 — Sandra Fradejas Avedillo**
> [!IMPORTANT]
> Este archivo ha sido reemplazado por la **Guía Maestra de Instalación** que incluye sub-guías detalladas por módulo.
>
> **→ Ir a la guía actualizada: [`INSTALACION_COMPLETA.md`](INSTALACION_COMPLETA.md)**
La guía maestra incluye:
- Índice centralizado con navegación a cada fase
- Sub-guías detalladas en `docs/guias/` para pfSense, Debian, Docker, Odoo, LDAP, CI/CD y Hardening
- Checklist de verificación completo
- Solución de problemas comunes por módulo
---
*El contenido histórico de este archivo se mantiene a continuación como referencia.*
---
Esta guía explica cómo reproducir la infraestructura completa **desde cero**, en el orden correcto. Sigue los pasos en secuencia.
---
## Requisitos previos
| Componente | Versión | Notas |
|------------|---------|-------|
| VirtualBox | ≥ 6.x | Hipervisor para las VMs |
| pfSense | 2.7.x | ISO descargada de netgate.com |
| Debian | 12 (Bookworm) | Con entorno gráfico GNOME |
| Docker | 24.x (`docker.io`) | Instalado por `install.sh` |
| Docker Compose | V2 | Instalado con `docker-compose` |
---
## PASO 1 — Crear las Máquinas Virtuales
### VM 1: pfSense (Firewall)
- RAM: 1 GB | CPU: 1 core | Disco: 10 GB
- Adaptador 1 → **NAT** (WAN — salida a Internet)
- Adaptador 2 → **Red Interna `"LAN"`** (VLAN 10 Clientes)
- Adaptador 3 → **Red Interna `"DMZ"`** (VLAN 30 Servidor)
### VM 2: Debian 12 (Servidor ERP)
- RAM: 4 GB | CPU: 2 cores | Disco: 40 GB
- Adaptador 1 → **Red Interna `"DMZ"`** (misma red que Adaptador 3 de pfSense)
### VM 3: Cliente (Validación)
- RAM: 2 GB
- Adaptador 1 → **Red Interna `"LAN"`**
---
## PASO 2 — Configurar pfSense
### 2.1 Asignar interfaces en el asistente de texto
Al arrancar pfSense por primera vez, asignar:
- `vtnet0` → **WAN**
- `vtnet1` → **LAN** (Gateway: `192.168.10.1`)
- `vtnet2` → **DMZ/OPT1** (Gateway: `192.168.30.1`)
### 2.2 Configuración desde la interfaz web (`https://192.168.10.1`)
**DHCP en LAN (VLAN 10):** rango `192.168.10.100 – 192.168.10.200`
**Reglas de Firewall → WAN:**
- Bloquear todo salvo puertos 80 y 443 (redirigidos por NAT)
**Reglas de Firewall → LAN:**
| Prioridad | Acción | Protocolo | Origen | Destino | Puerto | Descripción |
|-----------|--------|-----------|--------|---------|--------|-------------|
| 1 | PASS | TCP | LAN net | 192.168.30.10 | 80, 443, 9090 | Odoo + Cockpit |
| 2 | PASS | TCP | LAN net | 192.168.30.10 | 22 | SSH admin |
| 3 | BLOCK | TCP/UDP | LAN net | 192.168.30.0/24 | 5432 | Bloquear PostgreSQL |
| 4 | BLOCK | TCP/UDP | LAN net | 192.168.30.0/24 | 8069 | Bloquear Odoo directo |
| 5 | PASS | * | LAN net | * | * | Internet |
**Reglas de Firewall → DMZ (OPT1):**
| Prioridad | Acción | Protocolo | Origen | Destino | Puerto | Descripción |
|-----------|--------|-----------|--------|---------|--------|-------------|
| 1 | BLOCK | * | DMZ net | 192.168.10.0/24 | * | Anti-pivoting a LAN |
| 2 | PASS | TCP/UDP | DMZ net | * | 53 | DNS saliente |
| 3 | PASS | TCP | DMZ net | * | 80, 443 | HTTP/HTTPS saliente |
| 4 | BLOCK | * | DMZ net | * | * | Deny all |
**NAT Port Forward (Firewall → NAT → Port Forward):**
- Interface: WAN | Proto: TCP | Puerto dest: 80/443 | IP redirigida: `192.168.30.10`
### 2.3 DNS Interno (para el dominio `erp.odoo.tfg.com`)
**Services → DNS Resolver → Host Overrides → + Add:**
| Campo | Valor |
|-------|-------|
| Host | `erp.odoo` |
| Domain | `tfg.com` |
| IP Address | `192.168.30.10` |
**Services → DHCP Server → LAN → DNS Server 1:** `192.168.10.1`
**Firewall → NAT → Port Forward (interceptar DNS de clientes):**
| Campo | Valor |
|-------|-------|
| Interface | LAN |
| Protocol | TCP/UDP |
| Source | LAN subnets (`192.168.10.0/24`) |
| Destination | `*` (cualquier IP) |
| Destination port | `53` |
| Redirect target IP | `192.168.10.1` |
| Redirect target port | `53` |
---
## PASO 3 — Preparar Debian 12 (Servidor)
### 3.1 Configurar IP estática
```bash
# Editar /etc/network/interfaces
sudo nano /etc/network/interfaces
```
```
auto ens18
iface ens18 inet static
    address 192.168.30.10
    netmask 255.255.255.0
    gateway 192.168.30.1
    dns-nameservers 192.168.30.1
```
```bash
sudo systemctl restart networking
ip addr show   # Debe mostrar 192.168.30.10
```
### 3.2 Clonar el repositorio en el servidor
```bash
# Instalar git
sudo apt update && sudo apt install git -y
# Clonar el repositorio
sudo git clone https://github.com/sandrafrv/TFG-Implantacion_Segura_y_Automatizada_de_Odoo.git /opt/erp-odoo
cd /opt/erp-odoo
```
---
## PASO 4 — Instalación Automática
```bash
# Dar permisos y ejecutar el instalador todo-en-uno
chmod +x install.sh
sudo ./install.sh
```
El instalador realiza automáticamente:
1. Instala dependencias: `git`, `curl`, `openssl`, `cockpit`, `docker.io`, `docker-compose`
2. Habilita servicios `docker` y `cockpit.socket`
3. Crea la estructura de directorios (`data/`, `backups/`, `certs/`, `docker/`)
4. Genera certificados SSL autofirmados (RSA 2048, 365 días)
5. Lanza `scripts/configure.sh` → pide contraseñas interactivamente
6. Ejecuta `scripts/deploy.sh` → levanta el stack Docker y espera healthcheck de Odoo
7. Ejecuta `scripts/install_cron.sh` → programa backup diario, monitor y actualización semanal
> ⏱️ El primer arranque de Odoo puede tardar 2-5 minutos mientras inicializa la base de datos.
---
## PASO 5 — Post-instalación: Configurar Odoo y LDAP
Una vez que el stack está arriba:
### 5.1 Asistente de configuración Odoo
```bash
bash /opt/erp-odoo/scripts/odoo_setup_wizard.sh
```
El asistente guía paso a paso:
1. **Nombre de la compañía** — cambia el nombre por defecto de "My Company"
2. **Módulos** — instala los módulos seleccionados (LDAP es obligatorio)
3. **Configuración LDAP** — detecta la IP del contenedor y configura la autenticación
4. **Restricción de acceso** — elimina contraseñas locales (sólo admin conserva la suya)
### 5.2 Crear usuarios en LDAP
```bash
bash /opt/erp-odoo/scripts/ldap_crear_usuarios.sh
```
El script es interactivo. Para cada usuario solicita:
- `uid` (login, ej: `jdoe`)
- Nombre completo, apellido, email
- Contraseña
Los usuarios se crean en la OU `ou=usuarios,dc=tfg,dc=com`.
### 5.3 Crear usuarios técnicos en Odoo (API, Ventas, etc.)
```bash
bash /opt/erp-odoo/scripts/odoo_crear_usuarios.sh
```
Crea automáticamente: Usuario API, Técnico, Ventas, Dirección, Becario.  
Las contraseñas se generan aleatoriamente y se muestran **una sola vez** al terminar.
---
## PASO 6 — Aplicar Auditoría SQL (Opcional)
```bash
docker exec -i odoo_erp psql -U odoo -d odoo_erp < /opt/erp-odoo/sql/audit_triggers.sql
```
Crea:
- Tabla `asir_audit_log` — registra creaciones de usuario con snapshot JSONB
- Trigger `trg_audit_new_odoo_user` en `res_users`
- Vista `v_audit_resumen` para consultas rápidas
Verificar que funciona:
```bash
docker exec -it odoo_erp psql -U odoo -d odoo_erp -c "SELECT * FROM v_audit_resumen;"
```
---
## PASO 6 — Control de Acceso por Roles (3 Capas + LDAP)
> 📄 Documentación completa en [`docs/CONTROL_ACCESO.md`](CONTROL_ACCESO.md)
Este paso configura el modelo de seguridad en 3 capas definido en el diagrama IaC:
### 6.1 Actualizar variables de entorno LDAP
```bash
nano /opt/erp-odoo/docker/.env
# Añadir (si no están ya):
#   LDAP_ADMIN_PASSWORD=contraseña_segura_admin
#   LDAP_READONLY_PASSWORD=contraseña_segura_readonly
```
### 6.2 Levantar OpenLDAP (IP MACVLAN: 192.168.30.22)
```bash
docker compose -f /opt/erp-odoo/docker/docker-compose.yml up -d ldap
# Verificar que está activo y accesible
docker ps | grep openldap
ldapsearch -H ldap://192.168.30.22 -x -b "dc=tfg,dc=com" "(objectClass=*)" dn
```
El archivo `ldap/estructura.ldif` se carga automáticamente al primer arranque y crea:
- `ou=usuarios` — cuentas de empleados
- `ou=grupos` — grupos departamentales (VLAN 10 y VLAN 40)
### 6.3 Configurar ACLs de LDAP
```bash
bash /opt/erp-odoo/scripts/ldap_politica_acceso.sh
```
Configura el modelo de acceso:
- `cn=admin` → escritura total (solo VLAN 40)
- `cn=tecnico` (grupo) → solo puede cambiar `userPassword` de empleados
- `cn=readonly` → lectura total (usado por Odoo para autenticar)
- Resto → sin acceso
### 6.4 Crear usuarios en LDAP con sus grupos
```bash
bash /opt/erp-odoo/scripts/ldap_crear_usuarios.sh
```
El script es interactivo. Para cada usuario solicita: `uid`, nombre, email, contraseña y **grupo departamental**. Los grupos disponibles son:
- **VLAN 10**: `becarios | ventas | rrhh | almacen | tecnico | jefe_ventas | jefe_rrhh | jefe_almacen`
- **VLAN 40**: `admin | dba`
### 6.5 Aplicar restricciones de Nginx (Capa C)
```bash
# Verificar sintaxis de la nueva configuración
docker exec nginx-proxy nginx -t
# Recargar sin cortar el servicio
docker exec nginx-proxy nginx -s reload
```
Nuevas restricciones activas en `config_nginx/odoo_proxy.conf`:
- `/web/database` → solo VLAN 40
- `/odoo/action-base_setup` → solo VLAN 40
- `/web/tests` → bloqueado completamente
- `/web?debug=` → solo VLAN 40
### 6.6 Crear usuarios en Odoo con roles (Capas A + B)
```bash
bash /opt/erp-odoo/scripts/odoo_crear_usuarios.sh
```
Crea los usuarios del ERP con sus grupos asignados automáticamente:
| Usuario | Rol | Módulos visibles |
|---------|-----|-----------------|
| `becario@erp.odoo.tfg.com` | Becario | Solo CRM (lectura) |
| `ventas@erp.odoo.tfg.com` | Ventas | CRM + Ventas + Facturas |
| `rrhh@erp.odoo.tfg.com` | RRHH | RRHH + Empleados |
| `almacen@erp.odoo.tfg.com` | Almacén | Inventario + Compras |
| `tecnico@erp.odoo.tfg.com` | Técnico | Inventario + Soporte |
| `jefe.ventas@erp.odoo.tfg.com` | Jefe Ventas | Ventas completo + aprobaciones |
| `jefe.rrhh@erp.odoo.tfg.com` | Jefe RRHH | RRHH completo + aprobaciones |
| `jefe.almacen@erp.odoo.tfg.com` | Jefe Almacén | Almacén completo + aprobaciones |
| `api.user@erp.odoo.tfg.com` | API | Solo XML-RPC |
> ⚠️ Las contraseñas se generan aleatoriamente y se muestran **una sola vez** al terminar. Guárdalas inmediatamente.
### 6.7 Configurar inicio de sesión LDAP en los PCs de VLAN 10
> 📄 Documentación completa en [`docs/CONTROL_ACCESO.md`](CONTROL_ACCESO.md) — sección "Inicio de Sesión en el Sistema Operativo"
Este paso configura los **clientes Linux de VLAN 10** para que usen el mismo usuario y contraseña LDAP tanto para entrar al PC como para entrar a Odoo.
**Ejecutar en cada PC cliente Linux de VLAN 10:**
```bash
# Copiar el script al cliente (si el repositorio no está montado localmente)
scp /opt/erp-odoo/scripts/configurar_cliente_ldap.sh usuario@192.168.10.x:~/
# Ejecutar como root en el cliente
sudo bash configurar_cliente_ldap.sh
```
El script instala y configura automáticamente:
- **SSSD** — intermediario entre el sistema y el LDAP (con caché offline)
- **PAM** — intercepta el login del SO y lo valida contra LDAP
- **NSS** — el sistema puede resolver usuarios LDAP como si fueran locales
- **pam_mkhomedir** — crea `/home/<uid>` automáticamente en el primer login
Tras la instalación, los usuarios del directorio LDAP pueden iniciar sesión con sus credenciales normales. Si se especifica un grupo durante la instalación, solo ese grupo podrá entrar en ese PC concreto.
**Verificación rápida tras ejecutar el script:**
```bash
# Debe mostrar los datos del usuario desde LDAP
getent passwd <uid_del_usuario>
# Resultado esperado (ejemplo):
# jdoe:x:2001:2000:John Doe:/home/jdoe:/bin/bash
```
---
## PASO 7 — Aplicar Auditoría SQL (Opcional)
```bash
sudo apt install ufw -y
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 9090/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
sudo ufw status verbose
```
---
## PASO 8 — Configurar Red MACVLAN (IPs físicas para contenedores)
```bash
# Detectar la interfaz de red activa del servidor Debian
ip link show   # Buscar ens18 o la interfaz conectada a la DMZ
# Crear la red MACVLAN
docker network create \
  --driver macvlan \
  --subnet=192.168.30.0/24 \
  --gateway=192.168.30.1 \
  --opt parent=ens18 \
  macvlan_vlan30
# Reiniciar el stack para que los contenedores tomen IPs de la MACVLAN
docker compose -f /opt/erp-odoo/docker/docker-compose.yml down
docker compose -f /opt/erp-odoo/docker/docker-compose.yml up -d --force-recreate
```
Resultado esperado:
- `nginx-proxy` → `192.168.30.20`
- `odoo-web` → `192.168.30.21`
- `odoo_erp` (PostgreSQL) → sin IP pública (sólo red interna)
> ⚠️ El host Debian no puede hacer ping a las IPs MACVLAN de sus propios contenedores (limitación del kernel). Verificar desde otro equipo de la red o desde un contenedor temporal.
---
## PASO 9 — CI/CD con GitHub Actions (Opcional)
```bash
# En el servidor Debian, como usuario administrador (no root)
chmod +x /opt/erp-odoo/scripts/setup_runner.sh
/opt/erp-odoo/scripts/setup_runner.sh
```
El script pide:
1. URL del repositorio GitHub
2. Token de registro (obtenido en Settings → Actions → Runners → New runner)
Instala el agente como servicio systemd. Desde ese momento, cada `git push` a `main` desencadena el pipeline automático de despliegue.
---
## PASO 10 — Hardening: Debian Headless (Último paso)
> ⚠️ Hacer este paso al final. Con GUI es más fácil diagnosticar errores anteriores.
```bash
# Cambiar a modo texto
sudo systemctl set-default multi-user.target
# Eliminar entorno gráfico GNOME
sudo apt remove --purge gnome* -y
sudo apt remove --purge x11* xorg* -y
sudo apt autoremove --purge -y
# Reiniciar y verificar
sudo reboot
```
Tras el reinicio, verificar por SSH:
```bash
systemctl get-default    # multi-user.target
systemctl is-active docker   # active
docker compose -f /opt/erp-odoo/docker/docker-compose.yml ps   # todos Up
curl -k -I https://erp.odoo.tfg.com   # 200 OK
```
---
## Verificación Final — Checklist
| Comprobación | Comando / URL | Resultado esperado |
|--------------|---------------|-------------------|
| Odoo accesible | `https://erp.odoo.tfg.com` | Pantalla de login Odoo 17 |
| Cockpit accesible | `https://192.168.30.10:9090` | Panel de administración |
| DNS resuelve correctamente | `nslookup erp.odoo.tfg.com` | `192.168.30.10` |
| Contenedores activos | `docker compose -f docker/docker-compose.yml ps` | 4 contenedores `Up (healthy)` |
| PostgreSQL bloqueado | `nc -zv 192.168.30.10 5432` (desde cliente) | Timeout / Connection refused |
| Auditoría SQL activa | `SELECT * FROM v_audit_resumen;` | Sin errores |
| Cron instalado | `cat /etc/cron.d/erp-odoo` | 3 tareas programadas |
| UFW activo | `sudo ufw status` | Status: active |
---
## Orden de Arranque (tras reinicio del servidor)
1. **Encender VM pfSense** → esperar interfaces activas
2. **Encender VM Debian** → Docker arranca automáticamente con `restart: always`
3. **Verificar** → `https://erp.odoo.tfg.com` desde el cliente
4. **Monitorizar** → Cockpit en `https://192.168.30.10:9090`
---
## Scripts de Gestión Diaria
```bash
# Menú interactivo completo
sudo /opt/erp-odoo/scripts/erp.sh
# Comandos directos
bash scripts/backup.sh          # Backup manual
bash scripts/monitor.sh         # Chequeo de salud
bash scripts/ldap_crear_usuarios.sh  # Añadir usuario LDAP
docker compose -f docker/docker-compose.yml logs -f  # Logs en tiempo real
```
```

### File: .\docs\archive\lista_capturas.md
```md
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
```

### File: .\docs\archive\plan_fases_pendientes.md
```md
# Plan Técnico por Fases — Hitos Pendientes del TFG
> **Documento complementario** al `implementation_plan.md` principal.  
> Cubre los cuatro hitos pendientes en el orden de implantación correcto.
---
## Fase A — VLAN + Aislamiento de Red en pfSense
**Objetivo:** Verificar y endurecer la segmentación entre VLAN 10 (LAN Clientes) y VLAN 30 (DMZ Servidor).
### Tareas
```bash
# Desde el cliente VLAN 10, comprobar que NO hay acceso directo a PostgreSQL
nc -zv 192.168.30.10 5432   # Debe fallar (bloqueado por pfSense)
# Comprobar que SÍ hay acceso a Odoo por HTTPS
curl -k -I https://192.168.30.10   # Debe devolver 200 o 302
```
**Reglas pfSense a verificar (Firewall → Rules → LAN):**
| Prioridad | Acción | Protocolo | Origen | Destino | Puerto | Descripción |
|-----------|--------|-----------|--------|---------|--------|-------------|
| 1 | PASS | TCP | LAN net | 192.168.30.10 | 80, 443, 9090 | Odoo + Cockpit |
| 2 | PASS | TCP | LAN net | 192.168.30.10 | 22 | SSH administración |
| 3 | BLOCK | TCP/UDP | LAN net | 192.168.30.0/24 | 5432 | Bloquear PostgreSQL |
| 4 | BLOCK | TCP/UDP | LAN net | 192.168.30.0/24 | 8069 | Bloquear Odoo directo |
| 5 | PASS | * | LAN net | * | * | Salida a Internet |
**Reglas pfSense a verificar (Firewall → Rules → DMZ):**
| Prioridad | Acción | Protocolo | Origen | Destino | Puerto | Descripción |
|-----------|--------|-----------|--------|---------|--------|-------------|
| 1 | PASS | TCP/UDP | DMZ net | * | 53 | DNS saliente |
| 2 | PASS | TCP | DMZ net | * | 80, 443 | HTTP/HTTPS saliente |
| 3 | BLOCK | * | DMZ net | 192.168.10.0/24 | * | Bloquear acceso a LAN |
### Validación ✅
- [ ] `nc -zv 192.168.30.10 5432` → **falla** (bloqueado)
- [ ] `nc -zv 192.168.30.10 8069` → **falla** (bloqueado)
- [ ] `curl -k https://192.168.30.10` → **200/302** (Odoo accesible)
- [ ] Desde DMZ, `ping 192.168.10.x` → **sin respuesta** (aislado)
### Entregable
Screenshot de las reglas de pfSense y salida de los comandos `nc` y `curl` guardados en `screenshots/fase_A_vlan/`.
---
## Fase B — MACVLAN en Docker ✅ COMPLETADA — 08/05/2026
**Objetivo:** Asignar IPs reales de la VLAN30 directamente a los contenedores Docker para que pfSense los vea como hosts independientes.
### Implementación realizada
**Problema encontrado:** El `docker-compose.yml` usaba formato lista (`- odoo_net`) en la sección `networks`, lo que impedía añadir la red MACVLAN con IP fija. Se resolvió reescribiendo el fichero con Python para garantizar indentación YAML correcta.
**1. Red MACVLAN creada** (interfaz física: `ens18`)
```bash
docker network create \
  --driver macvlan \
  --subnet=192.168.30.0/24 \
  --gateway=192.168.30.1 \
  --opt parent=ens18 \
  macvlan_vlan30
```
**2. `docker-compose.yml` actualizado** — cambios clave:
- Formato `networks` cambiado de lista a mapa en los 3 servicios
- Bloque `macvlan_vlan30` con IP fija añadido a `odoo-web` y `nginx-proxy`
- Red `macvlan_vlan30` declarada como `external: true` en la sección global
- PostgreSQL (`odoo_erp`) excluido intencionalmente de MACVLAN (solo red interna)
**3. Contenedores recreados**
```bash
docker compose -f docker/docker-compose.yml down
docker compose -f docker/docker-compose.yml up -d --force-recreate
```
### Resultado final
| Contenedor | Red bridge `odoo_net` | Red MACVLAN `192.168.30.x` | Justificación |
|---|---|---|---|
| `odoo_erp` (PostgreSQL) | `172.19.0.x` | ❌ Sin IP pública | Seguridad: BD no expuesta |
| `odoo-web` (Odoo 17) | `172.19.0.3` | ✅ `192.168.30.21` | IP física en la DMZ |
| `nginx-proxy` (Nginx) | `172.19.0.4` | ✅ `192.168.30.20` | Punto de entrada HTTPS |
### Verificación realizada
```bash
# Verificación desde contenedor temporal en la misma red MACVLAN
docker run --rm --network macvlan_vlan30 alpine \
  wget -qO- --no-check-certificate https://192.168.30.20 | grep "<title>"
# → <title>Odoo</title> ✅
```
### Limitación documentada (comportamiento esperado del kernel Linux)
> ⚠️ El host Debian **no puede hacer ping/curl directamente** a las IPs MACVLAN de sus propios contenedores. Es una limitación conocida del driver `macvlan` en Linux (el tráfico host→contenedor MACVLAN no pasa por la interfaz física). La verificación debe hacerse **desde otro equipo de la red o desde un contenedor temporal** en la misma red MACVLAN.
### Commits
- [`7ee1cd2`](https://github.com/sandrafrv/TFG-Implantacion_Segura_y_Automatizada_de_Odoo/commit/7ee1cd20041014799df1f458f8681bae749d0c25) — `docs: actualizar README con implementación MACVLAN completada`
- MACVLAN promovida de "Mejoras Futuras" a **Fase 3 implementada** en el README
### Entregable para la memoria
Capturar screenshot de `docker network inspect macvlan_vlan30` mostrando `odoo-web` (`.21`) y `nginx-proxy` (`.20`) y guardarlo en `screenshots/fase_B_macvlan/`.
---
## Fase C — Integración LDAP (Autenticación Centralizada en Odoo)
**Objetivo:** Centralizar la autenticación de usuarios de Odoo contra un directorio LDAP, eliminando credenciales locales por usuario.
### Subtarea C.1 — Desplegar OpenLDAP como contenedor
```bash
# Añadir servicio LDAP al docker-compose.yml
cat << 'EOF' >> /opt/erp-odoo/docker/docker-compose.yml
  ldap:
    image: osixia/openldap:1.5.0
    container_name: odoo-ldap
    restart: always
    environment:
      LDAP_ORGANISATION: "TFG ASIR"
      LDAP_DOMAIN: "tfg.com"
      LDAP_ADMIN_PASSWORD: "${LDAP_ADMIN_PASSWORD}"
    volumes:
      - /opt/erp-odoo/data/ldap_data:/var/lib/ldap
      - /opt/erp-odoo/data/ldap_config:/etc/ldap/slapd.d
    networks:
      - odoo_net
EOF
# Añadir variable al .env
echo "LDAP_ADMIN_PASSWORD=<contraseña_segura>" >> /opt/erp-odoo/docker/.env
# Levantar el nuevo servicio
docker compose -f /opt/erp-odoo/docker/docker-compose.yml up -d ldap
# Verificar que está corriendo
docker ps | grep ldap
```
### Subtarea C.2 — Crear usuarios de prueba en LDAP
```bash
# Crear archivo LDIF con usuarios
cat << 'EOF' > /tmp/usuarios_tfg.ldif
dn: ou=usuarios,dc=tfg,dc=com
objectClass: organizationalUnit
ou: usuarios
dn: uid=jdoe,ou=usuarios,dc=tfg,dc=com
objectClass: inetOrgPerson
uid: jdoe
cn: John Doe
sn: Doe
mail: jdoe@tfg.com
userPassword: {SSHA}HASH_AQUI
EOF
# Importar usuarios
docker exec odoo-ldap ldapadd \
  -x -D "cn=admin,dc=tfg,dc=com" \
  -w "${LDAP_ADMIN_PASSWORD}" \
  -f /tmp/usuarios_tfg.ldif
# Verificar que los usuarios existen
docker exec odoo-ldap ldapsearch \
  -x -D "cn=admin,dc=tfg,dc=com" \
  -w "${LDAP_ADMIN_PASSWORD}" \
  -b "dc=tfg,dc=com" "(uid=jdoe)"
```
### Subtarea C.3 — Configurar LDAP en Odoo (interfaz web)
1. En Odoo → **Ajustes → Técnico → Autenticación LDAP → Nuevo servidor LDAP**
2. Rellenar los campos:
| Campo | Valor |
|-------|-------|
| **Servidor LDAP** | `odoo-ldap` (nombre del contenedor en la red Docker) |
| **Puerto** | `389` |
| **TLS** | No (red interna Docker) |
| **DN base** | `ou=usuarios,dc=tfg,dc=com` |
| **Filtro LDAP** | `(uid=%s)` |
| **DN de bind** | `cn=admin,dc=tfg,dc=com` |
| **Contraseña de bind** | `${LDAP_ADMIN_PASSWORD}` |
| **Crear usuario si no existe** | ✅ Sí |
3. Guardar y **Probar conexión**.
### Validación ✅
```bash
# Test de bind LDAP desde el contenedor Odoo
docker exec odoo-web ldapsearch \
  -H ldap://odoo-ldap:389 \
  -x -D "cn=admin,dc=tfg,dc=com" \
  -w "${LDAP_ADMIN_PASSWORD}" \
  -b "dc=tfg,dc=com" "(uid=jdoe)"
```
- [ ] `ldapsearch` devuelve el usuario `jdoe`
- [ ] Login en Odoo con `jdoe` + contraseña LDAP → acceso OK
- [ ] Odoo crea automáticamente el perfil interno del usuario LDAP
- [ ] Audit trigger registra el nuevo usuario en `asir_audit_log`
### Entregable
Screenshot del panel LDAP en Odoo y del login exitoso en `screenshots/fase_C_ldap/`.
---
## Fase D — Debian Headless (Eliminación del Entorno Gráfico)
**Objetivo:** Convertir el servidor Debian de modo gráfico a `multi-user.target` (sin GUI), con acceso únicamente por SSH.
> ⚠️ **Hacer esta fase la última.** Con el sistema gráfico activo es más fácil diagnosticar errores en las fases anteriores.
### Subtarea D.1 — Cambiar el target de arranque
```bash
# Ver el target actual
systemctl get-default
# Resultado actual: graphical.target
# Cambiar a modo texto (sin GUI)
sudo systemctl set-default multi-user.target
# Verificar el cambio
systemctl get-default
# Resultado esperado: multi-user.target
```
### Subtarea D.2 — Eliminar el entorno gráfico
```bash
# Identificar el paquete del entorno gráfico instalado
dpkg -l | grep -E "gnome|kde|xfce|lxde|lxqt|mate"
# Eliminar GNOME (si es el entorno instalado)
sudo apt remove --purge gnome* -y
sudo apt remove --purge x11* xorg* -y
sudo apt autoremove --purge -y
sudo apt clean
# Verificar que no quedan procesos gráficos
ps aux | grep -E "Xorg|gdm|gnome" | grep -v grep
```
### Subtarea D.3 — Endurecer SSH
```bash
sudo nano /etc/ssh/sshd_config
```
Parámetros a verificar/ajustar:
```sshd_config
# Solo IPv4 (reducir superficie de ataque)
AddressFamily inet
# Puerto estándar (o cambiar a un puerto no estándar para el TFG)
Port 22
# Deshabilitar login como root por SSH
PermitRootLogin no
# Deshabilitar autenticación por contraseña (solo clave pública)
PasswordAuthentication no
# Limitar usuarios que pueden conectar por SSH
AllowUsers sandra
# Tiempo máximo sin autenticarse
LoginGraceTime 30
# Máximo de intentos de autenticación por conexión
MaxAuthTries 3
# Deshabilitar reenvío X11 (no hay GUI)
X11Forwarding no
```
```bash
# Recargar SSH con la nueva configuración
sudo systemctl reload sshd
# Verificar que SSH sigue funcionando ANTES de cerrar la sesión actual
ssh -v sandra@192.168.30.10
```
### Subtarea D.4 — Ajustar UFW para el nuevo estado
```bash
# Revisar reglas actuales
sudo ufw status verbose
# Restringir SSH solo desde la subred de administración (VLAN 10)
sudo ufw delete allow 22/tcp
sudo ufw allow from 192.168.10.0/24 to any port 22 proto tcp
# Recargar UFW
sudo ufw reload
sudo ufw status verbose
```
### Subtarea D.5 — Verificación post-headless
```bash
# Reiniciar el servidor y verificar que arranca sin GUI
sudo reboot
# Tras el reinicio, conectar por SSH:
ssh sandra@192.168.30.10
# Verificar que no hay servidor de display
echo $DISPLAY                          # Debe estar vacío
systemctl get-default                  # multi-user.target
systemctl is-active docker             # active
docker compose -f /opt/erp-odoo/docker/docker-compose.yml ps  # todos Up
# Verificar que Odoo sigue accesible desde cliente
curl -k -I https://erp.odoo.tfg.com
```
### Validación ✅
- [ ] `systemctl get-default` → `multi-user.target`
- [ ] Servidor arranca sin pantalla de login gráfica
- [ ] SSH funciona desde VLAN 10 (`192.168.10.x`)
- [ ] SSH denegado desde otras subredes
- [ ] `docker compose ps` muestra los 3 contenedores `Up`
- [ ] `https://erp.odoo.tfg.com` sigue accesible desde el cliente
- [ ] Cockpit sigue accesible en `https://192.168.30.10:9090`
### Entregable
Screenshot de la sesión SSH activa y del dashboard de Cockpit funcionando en `screenshots/fase_D_headless/`.
---
## Resumen de Hitos y Entregables
| Fase | Hito | Validación clave | Estado |
|------|------|-----------------|--------|
| **A** | VLAN aislada y reglas pfSense verificadas | `nc` timed out en 5432/8069 desde VLAN 10 | ✅ **Completada 08/05/2026** |
| **B** | MACVLAN — `nginx-proxy` `.20`, `odoo-web` `.21` | `docker network inspect` muestra IPs asignadas | ✅ **Completada 08/05/2026** |
| **C** | LDAP integrado con login en Odoo | Login con usuario LDAP exitoso | ⏳ Pendiente |
| **D** | Debian headless + SSH endurecido | Arranque sin GUI, SSH OK | ⏳ Pendiente |
> **Orden de ejecución:** A → B ✅ → C → D
```

### File: .\docs\archive\PLAN_HISTORICO_DETALLADO.md
```md
# Plan de Implantación Detallado — Referencia Histórica
**TFG ASIR 2025/2026 — Sandra Fradejas Avedillo**
> [!NOTE]
> **Documento histórico.** Este archivo documenta el plan técnico original con los comandos y decisiones tomadas durante el desarrollo.
> Sirve como **anexo técnico** al historial de implementación.
>
> **→ Para instalar desde cero, usa la guía actual:** [`docs/INSTALACION_COMPLETA.md`](INSTALACION_COMPLETA.md)
> **→ Para entender por qué se tomaron las decisiones:** [`docs/HISTORIAL_IMPLEMENTACION.md`](HISTORIAL_IMPLEMENTACION.md)
---
Este documento es el plan técnico original con todos los pasos de despliegue, los comandos exactos, la justificación de cada decisión técnica y el orden de ejecución seguido durante el proyecto.
---
## Fase 0: Justificación Técnica e Investigación Previa
> ✅ **Completado:** Fase de investigación, comparativa de ERPs y diseño de arquitectura finalizada.
> Esta fase documenta las decisiones de diseño tomadas **antes de la implantación**, basadas en la investigación técnica previa. No requiere ejecución de comandos — es la base académica del proyecto.
### 0.1 Elección del ERP: Odoo vs Alternativas
Se evaluaron tres soluciones ERP de código abierto antes de elegir Odoo 17:
| Criterio | **Odoo 17** | Dolibarr | ERPNext |
| :--- | :--- | :--- | :--- |
| Facilidad de uso | ✅ Alta — interfaz moderna | Media — básico | Media — abrumador |
| Flexibilidad de API | ✅ XML-RPC + JSON-RPC maduro | Limitada | Alta pero compleja |
| Consumo de recursos | Moderado (VM decente) | ✅ Muy ligero | Pesado |
| Cobertura funcional | ✅ CRM, Ventas, RRHH, Inventario | Básico | Muy completo |
| Módulos de comunidad | ✅ Muy amplia | Moderada | Moderada |
| **Veredicto** | ✅ **Elegido** | Descartado | Descartado |
**Justificación**: Odoo 17 CE ofrece la mejor relación entre cobertura funcional, flexibilidad de integración y documentación oficial para un entorno académico ASIR.
### 0.2 Decisión de Sistema Operativo: Debian 12 vs Ubuntu/Mint
El informe de investigación menciona "Linux Mint 22 / base Ubuntu" como alternativa, pero el proyecto elige **Debian 12 (Bookworm)** por:
- **Estabilidad superior**: Debian tiene ciclos de soporte más largos que Ubuntu LTS
- **Estándar de producción**: La documentación de Odoo cita Debian como sistema de referencia
- **Sin snap ni paquetes propietarios**: El servidor queda limpio y predecible
- **Compatibilidad con Docker**: `docker.io` está disponible directamente en los repositorios oficiales de Debian
### 0.3 Nota Técnica: Redes Docker — Bridge vs Macvlan
La investigación menciona redes **macvlan** para exponer contenedores directamente a pfSense con IPs propias de la red física. Se evaluó su implementación:
**¿Qué es macvlan?**
Macvlan asigna a cada contenedor una dirección MAC e IP propias de la red física (VLAN 30, rango `192.168.30.x`). pfSense los vería como hosts físicos separados, no como un único servidor.
**¿Por qué se descarta en este TFG?**
- Requiere configuración adicional en el kernel del host Debian (`ip link add macvlan0 link eth0 type macvlan`)
- El contenedor host pierde comunicación con sus propios contenedores macvlan en algunos drivers
- Aumenta la complejidad de depuración sin aporte académico diferencial
- El modo **bridge** (tipo `bridge` en Docker Compose) es suficiente para la arquitectura DMZ con un único punto de entrada (Nginx en `192.168.30.10`)
**Documentado como mejora futura**: macvlan es la solución para entornos de producción real donde cada contenedor necesita su propia identidad de red ante el firewall.
### 0.4 Referencias Técnicas del Proyecto
| Área | Recurso | URL |
| :--- | :--- | :--- |
| Redes/pfSense | Configuración VLAN — Netgate | https://docs.netgate.com/pfsense/en/latest/vlan/configuration.html |
| Docker en DMZ | Macvlan Network en pfSense | https://vegard.blog.engen.priv.no/?p=364 |
| Hardening Linux | Linux Server Hardening Checklist 2026 | https://hostperl.com/blog/linux-server-hardening-checklist-essential-security-controls-production-2026 |
| Estándar CIS | CIS Linux Mint 22 Benchmark v1.0.0 | https://www.scribd.com/document/946643717/CIS-Linux-Mint-22-Benchmark-v1-0-0 |
| Odoo despliegue | Producción y Workers Multiproceso | https://www.odoo.com/documentation/19.0/administration/on_premise/deploy.html |
| Nginx para Odoo | Proxy Inverso y SSL | https://oec.sh/guides/odoo-nginx-config |
| PostgreSQL | Generic Audit Trigger (PL/pgSQL) | https://wiki.postgresql.org/wiki/Audit_trigger |
| Odoo Backup | Backup y Disaster Recovery | https://oec.sh/guides/odoo-backup-recovery |
---
## Arquitectura General del Sistema
### ¿Por qué esta arquitectura?
El diseño separa el sistema en tres capas de red diferenciadas (WAN → LAN → DMZ) gestionadas por pfSense. Esta segmentación garantiza que el servidor ERP en la DMZ nunca sea accesible directamente desde Internet sin pasar por el firewall, y que los equipos de la LAN tampoco puedan acceder al servidor sin reglas explícitas.
Dentro del servidor Debian, se usa Docker para aislar los tres procesos principales (base de datos, aplicación y proxy inverso) entre sí. Nginx es el único punto de entrada desde el exterior: el contenedor Odoo y el de PostgreSQL nunca exponen puertos al host, garantizando que no puedan ser atacados directamente.
### Diagrama de Conexiones Lógicas
```mermaid
graph TD
    WAN((Internet / WAN)) -->|DHCP Externo| PFSENSE[pfSense Firewall/Router]
    PFSENSE -->|Gateway: 192.168.30.1| DMZ[VLAN 30 - DMZ / Servidor Principal]
    PFSENSE -->|Gateway: 192.168.10.1| LAN_CLI[VLAN 10 - LAN Clientes]
    DMZ --> DOCKER_HOST["Servidor Único Debian 12<br>192.168.30.10"]
    subgraph DOCKER_HOST ["Servidor Único Debian 12 (192.168.30.10)"]
        NGINX_PROXY["Contenedor Nginx<br>(Puertos 80/443 al Host)"]
        ODOO_DOCKER["Contenedor Odoo<br>(Aislado en Red Docker)"]
        PG_DOCKER["Contenedor PostgreSQL<br>(Aislado en Red Docker)"]
        NGINX_PROXY -.->|ProxyPass :8069| ODOO_DOCKER
        ODOO_DOCKER -.->|SQL :5432| PG_DOCKER
    end
    LAN_CLI --> PC_CLIENTE["Cliente Windows/Linux<br>192.168.10.x"]
    PC_CLIENTE -.->|Petición HTTPS 443| DOCKER_HOST
```
### Tabla de Direccionamiento IP
| Zona | Subred (CIDR) | Gateway (pfSense) | IP del Sistema | Puertos expuestos | Servicio |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **WAN** | Red DHCP del router físico | Router ISP | IP dinámica WAN | `80`, `443` (NAT) | Entrada desde Internet |
| **DMZ (VLAN 30)** | `192.168.30.0/24` | `192.168.30.1` | **`192.168.30.10`** | `22`, `80`, `443`, `9090` | Servidor Debian + Docker |
| **LAN Clientes (VLAN 10)** | `192.168.10.0/24` | `192.168.10.1` | `192.168.10.x` | — | Equipo cliente de usuario |
| *(Contenedor nginx)* | Red Docker interna | Switch Docker | Dinámica | `80`, `443` → host | Proxy Inverso |
| *(Contenedor odoo)* | Red Docker interna | Switch Docker | Dinámica | `8069` (cerrado) | Aplicación Odoo 17 |
| *(Contenedor db)* | Red Docker interna | Switch Docker | Dinámica | `5432` (cerrado) | PostgreSQL 16 |
---
## Fase 1: Preparación del Entorno de Red (pfSense)
> ✅ **Completado:** Máquinas virtuales creadas, interfaces asignadas y reglas de firewall/NAT configuradas y documentadas.
### ¿Por qué pfSense?
pfSense es un firewall de código abierto basado en FreeBSD que permite segmentar la red en zonas (WAN, LAN, DMZ), gestionar DHCP por zona, crear reglas de firewall por interfaz y hacer NAT/Port Forwarding. Es la solución estándar para simular un entorno empresarial real en un TFG.
### 1.1 Creación de Máquinas Virtuales
Crear en VirtualBox las siguientes VMs en este orden:
**VM 1 — pfSense (Firewall/Enrutador):**
- RAM: 1 GB | CPU: 1 core | Disco: 10 GB
- Adaptador 1: NAT o Bridged → será la interfaz **WAN** (salida a Internet)
- Adaptador 2: Red Interna `"LAN"` → será la interfaz **LAN Clientes (VLAN 10)**
- Adaptador 3: Red Interna `"DMZ"` → será la interfaz **DMZ (VLAN 30)**
**VM 2 — Debian 12 Server (Servidor ERP):**
- RAM: 4 GB | CPU: 2 cores | Disco: 40 GB
- Adaptador 1: Red Interna `"DMZ"` (misma que el Adaptador 3 de pfSense)
- IP estática a configurar: `192.168.30.10`
**VM 3 — Cliente Windows/Linux (Validación):**
- RAM: 2 GB | Adaptador 1: Red Interna `"LAN"`
- Obtendrá IP por DHCP de pfSense en el rango `192.168.10.x`
### 1.2 Configuración Inicial de pfSense
Arrancar la VM de pfSense e ir asignando las interfaces en el asistente de texto:
- `vtnet0` (Adaptador 1) → **WAN**
- `vtnet1` (Adaptador 2) → **LAN** (Gateway: `192.168.10.1`)
- `vtnet2` (Adaptador 3) → **DMZ** (Gateway: `192.168.30.1`)
Desde el interfaz web de pfSense (`https://192.168.10.1`), configurar:
- **DHCP en LAN (VLAN 10):** rango `192.168.10.100 – 192.168.10.200`
- **IP estática en DMZ:** asignar `192.168.30.1` a la interfaz OPT1/DMZ
### 1.3 Reglas de Firewall en pfSense
Las reglas se definen en **Firewall > Rules** por interfaz. El orden importa: pfSense evalúa de arriba a abajo y aplica la primera coincidencia.
**Interfaz WAN** (tráfico que llega desde Internet):
- Bloquear todo excepto los puertos `80` y `443` que serán redirigidos por NAT a la DMZ.
**Interfaz DMZ** (tráfico que sale del servidor Debian):
- Permitir: DNS saliente → `cualquier destino` en puerto `53/UDP`
- Permitir: HTTP/HTTPS saliente → `any` en puertos `80/TCP` y `443/TCP` (para que Debian pueda descargar paquetes y Docker pueda descargar imágenes)
- Bloquear: acceso desde DMZ hacia LAN Clientes (aislamiento de zonas)
**Interfaz LAN** (tráfico del equipo cliente):
- Permitir acceso desde LAN hacia la IP `192.168.30.10` en puertos `443`, `80` y `9090` (Cockpit)
- Permitir salida normal a Internet desde la LAN
**NAT / Port Forwarding** (Firewall > NAT > Port Forward):
- Interfaz: **WAN**
- Protocolo: TCP
- Destino: WAN address
- Puerto destino: `80` y `443`
- IP de redirección: `192.168.30.10`
- Puerto de redirección: `80` y `443`
### 1.4 Resolución de Nombres DNS Interna (pfSense DNS Resolver)
> ✅ **Completado:** Host Override configurado, regla NAT DNS redirect activa y `server_name` de Nginx actualizado a `erp.odoo.tfg.com`.
Para que los clientes de la VLAN 10 accedan a Odoo mediante `https://erp.odoo.tfg.com` en lugar de por IP directa, se configuran tres elementos en pfSense:
#### Paso 1 — Host Override en el DNS Resolver
*Services → DNS Resolver → Host Overrides → + Add*
| Campo | Valor |
|:---|:---|
| **Host** | `erp.odoo` |
| **Domain** | `tfg.com` |
| **IP Address** | `192.168.30.10` |
| **Description** | `Servidor Odoo ERP - DMZ` |
Guardar → Apply Changes.
#### Paso 2 — Servidor DNS en el DHCP de la LAN
*Services → DHCP Server → LAN → Server Options → DNS Server 1: `192.168.10.1`*
Esto fuerza a que los clientes que reciban IP por DHCP usen pfSense como DNS primario.
#### Paso 3 — Regla NAT: Interceptar todo el DNS de la VLAN 10
*Firewall → NAT → Port Forward → + Add*
**Problema real:** Los clientes Linux modernos (Lubuntu, Ubuntu) usan `systemd-resolved` con `127.0.0.53` como stub local, lo que puede ignorar el DNS del DHCP y consultar directamente a servidores públicos (8.8.8.8), obteniendo la IP real de internet de `tfg.com` en lugar de `192.168.30.10`.
**Solución:** Redirigir todo el tráfico UDP/TCP al puerto 53 originado desde la VLAN 10 hacia pfSense:
| Campo | Valor |
|:---|:---|
| **Interface** | `LAN` |
| **Protocol** | `TCP/UDP` |
| **Source** | `LAN subnets` (`192.168.10.0/24`) |
| **Destination** | `*` (cualquier IP exterior) |
| **Destination port** | `53 (DNS)` |
| **Redirect target IP** | `192.168.10.1` |
| **Redirect target port** | `53` |
| **Description** | `Forzar DNS VLAN10 → pfSense` |
Guardar → Apply Changes.
Con esta regla, da igual que el cliente apunte a `8.8.8.8`, `1.1.1.1` o `127.0.0.53`: pfSense intercepta la consulta y responde con el Host Override correcto (`192.168.30.10`).
#### Paso 4 — Actualizar server_name en Nginx
La directiva `server_name` del contenedor Nginx debe coincidir con el dominio configurado en el Host Override:
```bash
# Actualizar el dominio en la configuración de Nginx
sudo sed -i 's/erp.techsolutions.local/erp.odoo.tfg.com/g' /opt/erp-odoo/config_nginx/*.conf
# Recargar Nginx sin cortar el servicio
docker exec nginx-proxy nginx -s reload
# Validar sintaxis
docker exec nginx-proxy nginx -t
# Resultado esperado: "nginx: configuration file test is successful"
```
#### Flujo completo de resolución DNS
```
Cliente VLAN 10 (systemd-resolved → intenta 8.8.8.8:53)
        │
        ▼ pfSense intercepta (NAT Port Forward LAN TCP/UDP :53)
        │
[ pfSense DNS Resolver ] → Host Override → responde: 192.168.30.10
        │
        ▼
Cliente abre HTTPS hacia 192.168.30.10:443
        │
[ Nginx :443 ] → proxy_pass → http://odoo-web:8069
        │
[ Contenedor Odoo :8069 ] ✅
```
> Documentación detallada completa en [`docs/reglas_pfsense.md`](./reglas_pfsense.md) — sección *DNS — Resolución de Nombres para Odoo*.
---
## Fase 2: Configuración del Servidor Base (Debian 12)
> ✅ **Completado [2026-04-30]:** Preparación de sistema, Cockpit y dependencias de Docker cubiertas. Acceso validado desde el cliente LAN.
> **🚀 AUTOMATIZACIÓN (NUEVO EN FASE 9):**
> Aunque a continuación se detalla el proceso manual paso a paso por rigor académico, **todas las tareas de las Fases 2, 3 y 4 se han unificado en el script `install.sh`**.
> Para un despliegue rápido y real, sube el script al servidor o descárgalo y ejecuta:
> ```bash
> chmod +x install.sh
> sudo ./install.sh
> ```
> Este orquestador instalará dependencias, Docker, Cockpit, configurará el `.env` interactivo, levantará los contenedores y programará los backups automáticamente.
### ¿Por qué Debian 12 con entorno gráfico?
Se elige Debian 12 con GNOME porque la estabilidad de Debian es superior a Ubuntu Server para entornos de producción académica, y el entorno gráfico facilita la administración visual inicial y el acceso a Cockpit desde el propio servidor. Es una decisión pragmática para el TFG, donde la facilidad de demostración es importante.
### 2.1 Preparación Inicial del Sistema
Acceder al servidor Debian (por consola de VirtualBox o SSH desde el cliente):
```bash
# Verificar que la IP estática está bien asignada
ip addr show
# Debe mostrar 192.168.30.10 en la interfaz de red
# Comprobar conectividad a Internet a través del gateway pfSense
ping -c 4 8.8.8.8
# Actualizar el sistema completo antes de instalar nada
# Justificación: evita conflictos de dependencias con paquetes desactualizados
sudo apt update && sudo apt upgrade -y
# Instalar herramientas de administración esenciales
sudo apt install curl nano git bash-completion htop -y
```
### 2.2 Instalación de Cockpit (Panel Web de Gestión)
Cockpit permite administrar el servidor visualmente desde cualquier navegador sin necesidad de instalar software adicional en el cliente. Incluye terminal, monitor de recursos, gestión de servicios y, con plugins, gestión de contenedores Docker.
```bash
# Instalar Cockpit desde los repositorios oficiales de Debian
sudo apt install cockpit -y
# Activar el socket de Cockpit y habilitarlo en el arranque
# Usar el socket (no el servicio) es la práctica recomendada:
# Cockpit solo consume recursos cuando hay una sesión activa
sudo systemctl enable --now cockpit.socket
# Verificar que está escuchando correctamente
sudo systemctl status cockpit.socket
```
**Verificación:** Desde el equipo cliente (VLAN 10), abrir un navegador y acceder a `https://192.168.30.10:9090`. El navegador mostrará un aviso de certificado autofirmado (normal), aceptarlo y entrar con las credenciales del sistema operativo Debian.
```bash
# Instalar el plugin de métricas persistentes (historial de gráficas en Cockpit)
sudo apt install cockpit-pcp -y
sudo systemctl restart cockpit.socket
```
### 2.3 Instalación de Docker Engine y Docker Compose
Docker es el motor de contenedores que aísla cada servicio del ERP. Docker Compose orquesta los tres contenedores (db, odoo, nginx) como un stack unificado.
```bash
# Instalar Docker Engine y el CLI de Docker Compose
# Se usa docker.io (paquete oficial del repositorio Debian) para simplicidad en TFG
sudo apt install docker.io docker-compose -y
# Habilitar Docker para que arranque automáticamente con el sistema
sudo systemctl enable --now docker
# Añadir el usuario administrador al grupo docker
# Justificación: evita tener que usar "sudo" en cada comando docker,
# lo cual es necesario para que los scripts funcionen sin privilegios root
sudo usermod -aG docker $USER
# Aplicar el cambio de grupo sin cerrar sesión
newgrp docker
# Verificar la instalación
docker --version
docker compose version
docker ps   # Debe devolver una lista vacía (sin contenedores corriendo aún)
```
---
## Fase 3: Despliegue de la Infraestructura Docker (Odoo + PostgreSQL + Nginx)
> ✅ **Completado [2026-04-30]:** Estructura de volúmenes corregida, red de contenedores operativa, certificados SSL sincronizados y base de datos inicializada. Stack completamente funcional.
### ¿Por qué estos tres contenedores?
- **PostgreSQL** (`db`): Motor de base de datos relacional. Odoo lo requiere obligatoriamente. Se aísla en la red Docker para que solo Odoo pueda acceder a él.
- **Odoo** (`odoo-web`): La aplicación ERP. No expone puertos al host, solo se comunica internamente.
- **Nginx** (`nginx-proxy`): Proxy inverso. Es el único punto de entrada desde el exterior. Gestiona SSL/TLS y redirige el tráfico al puerto interno `8069` de Odoo.
### 3.1 Preparar Estructura de Directorios en el Servidor
```bash
# Crear la estructura de carpetas del proyecto ERP
# Justificación de cada carpeta:
#   data/postgres   → Datos persistentes de PostgreSQL (sobrevive al borrado del contenedor)
#   data/odoo_addons → Módulos extra de Odoo (ampliaciones del ERP)
#   data/odoo_web   → Archivos subidos por usuarios, sesiones y caché de Odoo
#   data/odoo_etc   → Reservada para configuraciones adicionales
#   scripts/        → Scripts DevOps del proyecto (deploy, backup, monitor, etc.)
#   config_nginx/   → Configuración del servidor Nginx (proxy inverso)
#   certs/          → Certificados SSL autofirmados
mkdir -p /opt/erp-odoo/data/{postgres,odoo_addons,odoo_etc,odoo_web}
mkdir -p /opt/erp-odoo/{scripts,config_nginx,certs}
```
### 3.2 Copiar los Archivos del Repositorio al Servidor
Clonar el repositorio del proyecto directamente en el servidor:
```bash
# Clonar el repositorio en la carpeta del proyecto
cd /opt/erp-odoo
git clone https://github.com/sandrafrv/TFG-Implantacion_Segura_y_Automatizada_de_Odoo.git
# Verificar que los archivos están disponibles
ls -la docker/ scripts/ config_nginx/ sql/
```
O, si el repositorio ya está descargado en el PC de desarrollo, copiar los archivos por SCP:
```bash
# Desde el PC de desarrollo (Windows/Linux):
scp -r docker/ scripts/ config_nginx/ sql/ sandra@192.168.30.10:/opt/erp-odoo/
```
### 3.3 Generar los Certificados SSL Autofirmados
Los certificados SSL son necesarios para que Nginx pueda cifrar el tráfico HTTPS. En un TFG se usan autofirmados (no son válidos para producción real, pero son funcionales en entornos internos).
```bash
# Generar clave privada y certificado autofirmado con validez de 1 año
# -x509: genera directamente el certificado (sin CSR intermedio)
# -nodes: sin contraseña en la clave privada (necesario para que Nginx lo cargue automáticamente)
# -days 365: validez de 1 año
# -newkey rsa:2048: clave RSA de 2048 bits (estándar actual)
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /opt/erp-odoo/certs/odoo-selfsigned.key \
    -out /opt/erp-odoo/certs/odoo-selfsigned.crt \
    -subj "/C=ES/ST=España/L=Local/O=TechSolutions/CN=erp.techsolutions.local"
# Verificar que se han generado correctamente
ls -la /opt/erp-odoo/certs/
```
### 3.4 Revisar y Ajustar el Archivo `.env`
El archivo `docker/.env` contiene las credenciales de la base de datos. **No debe subirse nunca a Git** (está en `.gitignore`). Ajustar los valores:
```bash
nano /opt/erp-odoo/docker/.env
```
Contenido recomendado:
```env
POSTGRES_DB=odoo_erp
POSTGRES_USER=odoo
POSTGRES_PASSWORD=<contraseña_segura_aqui>
```
### 3.5 Levantar el Stack con Docker Compose
El `docker-compose.yml` define los tres servicios (`db`, `odoo`, `nginx`) con sus volúmenes, variables de entorno y redes internas. Se ejecuta desde la raíz `/opt/erp-odoo`:
```bash
cd /opt/erp-odoo
# Arrancar todos los contenedores en segundo plano (detached)
docker compose -f docker/docker-compose.yml up -d
# Ver los logs en tiempo real para verificar que no hay errores
# (PostgreSQL debe arrancar primero, luego Odoo, luego Nginx)
docker compose -f docker/docker-compose.yml logs -f
# Verificar que los tres contenedores están en estado "Up"
docker compose -f docker/docker-compose.yml ps
```
**Verificación de salud desde el propio servidor:**
```bash
# Comprobar que Nginx responde en HTTPS (ignora error de certificado autofirmado con -k)
curl -I -k https://127.0.0.1
# Debe devolver: HTTP/2 302 o HTTP/1.1 200 OK (redirección al login de Odoo)
```
---
## Fase 4: Automatización y Scripts DevOps
> ✅ **Completado:** Scripts desarrollados, refactorizados, probados mediante CI estático y enlazados en cron. Validaciones finales manuales pendientes.
> **🚀 NOTA DE AUTOMATIZACIÓN:**
> Al igual que en las fases anteriores, si has ejecutado `install.sh`, **los permisos y las tareas cron ya están configurados automáticamente**. Los siguientes pasos solo explican el funcionamiento interno de estos scripts.
### ¿Por qué estos scripts?
El TFG exige demostrar buenas prácticas DevOps: despliegue automatizado, backups programados, monitorización activa y capacidad de recuperación ante fallos. Los scripts del directorio `/scripts` cubren cada uno de estos requisitos.
### 4.1 Dar Permisos de Ejecución a los Scripts
```bash
# Conceder permisos de ejecución a todos los scripts Bash
chmod +x /opt/erp-odoo/scripts/*.sh
# Verificar los permisos
ls -la /opt/erp-odoo/scripts/
```
### 4.2 Descripción y Justificación de Cada Script
| Script | Función | Cuándo usarlo |
|--------|---------|--------------|
| `deploy.sh` | Levanta el stack Docker con verificación de salud activa (espera hasta que Odoo responde en `/web/health`) | Primer despliegue o arranque manual |
| `update.sh` | Descarga nuevas versiones de las imágenes Docker y elimina imágenes huérfanas | Actualización del sistema ERP |
| `backup.sh` | Vuelca PostgreSQL con `pg_dump -F c` (formato comprimido con marca de tiempo) | Ejecución manual o por cron |
| `restore.sh` | Restauración limpia: elimina la BD actual, la recrea y restaura desde un backup | Recuperación ante fallos |
| `monitor.sh` | Verifica que los tres contenedores están activos; si alguno falla, lo reinicia y lo registra en `/var/log/erp_monitor.log` | Ejecución periódica por cron |
| `install_cron.sh` | Instala automáticamente todas las tareas cron del sistema de una sola vez | Configuración inicial del servidor |
### 4.3 Instalar las Tareas Cron Automáticamente
El script `install_cron.sh` programa las tres tareas automáticas sin necesidad de editar manualmente el crontab:
```bash
# Ejecutar el instalador de tareas cron
sudo /opt/erp-odoo/scripts/install_cron.sh
# Verificar que las tareas quedaron registradas
crontab -l
```
Las tareas que instala:
- **Monitor de salud** → cada 5 minutos (reinicia contenedores caídos automáticamente)
- **Backup diario** → todos los días a las 02:00 AM
- **Actualización semanal** → domingos a las 03:00 AM
### 4.4 Probar un Ciclo Completo de Backup y Restauración
```bash
# 1. Hacer un backup manual para comprobar que funciona
sudo /opt/erp-odoo/scripts/backup.sh
# Verificar que se creó el archivo .dump en la carpeta de backups
ls -lh /opt/erp-odoo/backups/
# 2. Probar la restauración (con el servicio odoo parado temporalmente)
docker compose -f /opt/erp-odoo/docker/docker-compose.yml stop odoo
sudo /opt/erp-odoo/scripts/restore.sh /opt/erp-odoo/backups/<archivo_mas_reciente>.dump
docker compose -f /opt/erp-odoo/docker/docker-compose.yml start odoo
```
---
## Fase 5: Auditoría Avanzada de Base de Datos (PL/pgSQL)
### ¿Por qué un trigger de auditoría?
El sistema de auditoría registra automáticamente en una tabla de log cada vez que se crea un nuevo usuario en Odoo. Esto demuestra conocimiento de PL/pgSQL y cumple con los requisitos de trazabilidad del TFG.
### 5.1 Conectarse a PostgreSQL dentro del Contenedor
```bash
# Acceder al intérprete de PostgreSQL dentro del contenedor odoo-db
docker exec -it odoo-db psql -U odoo -d odoo_erp
```
### 5.2 Ejecutar el Script de Auditoría
Una vez dentro de `psql`, ejecutar el contenido del archivo `sql/audit_triggers.sql`:
```bash
# Desde la terminal del servidor (fuera del contenedor)
docker exec -i odoo-db psql -U odoo -d odoo_erp < /opt/erp-odoo/sql/audit_triggers.sql
```
El script crea:
1. **Tabla `asir_audit_log`** → almacena cada evento auditado (tipo de acción, tabla afectada, ID del registro, timestamp)
2. **Función `func_audit_users()`** → lógica PL/pgSQL que inserta una fila en el log cuando se detecta un INSERT en `res_users`
3. **Trigger `trg_audit_new_odoo_user`** → enlaza la función a la tabla `res_users` de Odoo
### 5.3 Validar que la Auditoría Funciona
```bash
# Conectarse de nuevo a psql
docker exec -it odoo-db psql -U odoo -d odoo_erp
# Comprobar el contenido del log (después de crear un usuario desde la interfaz web de Odoo)
SELECT * FROM asir_audit_log ORDER BY action_time DESC LIMIT 10;
```
---
## Fase 6: Seguridad de Capa Host (UFW)
### ¿Por qué UFW además de pfSense?
pfSense protege el perímetro de red. UFW (Uncomplicated Firewall) protege el propio servidor Debian a nivel de host: si un atacante burla pfSense, UFW bloquea los puertos que no deberían estar accesibles. Es defensa en profundidad, una práctica de seguridad estándar.
```bash
# Instalar UFW si no está disponible
sudo apt install ufw -y
# Definir la política por defecto: bloquear todo el tráfico entrante
sudo ufw default deny incoming
sudo ufw default allow outgoing
# Permitir SSH para administración remota
sudo ufw allow 22/tcp
# Permitir Cockpit para el panel de gestión web
sudo ufw allow 9090/tcp
# Permitir tráfico HTTP y HTTPS al proxy Nginx
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
# Activar el firewall (pedirá confirmación)
sudo ufw enable
# Verificar el estado final
sudo ufw status verbose
```
---
## Fase 7: Validación Global del Sistema
### 7.1 Prueba de Acceso desde el Cliente (VLAN 10)
> ✅ **Completado [2026-04-30]:** DNS interno, NAT redirect y acceso HTTPS validados desde cliente Lubuntu (VLAN 10).
Desde el equipo cliente en la red LAN (`192.168.10.x`):
**DNS interno pfSense (método principal — CONFIGURADO ✅):**
La resolución DNS está completamente configurada en pfSense (ver [Fase 1.4](#14-resolución-de-nombres-dns-interna-pfsense-dns-resolver) y `docs/reglas_pfsense.md` para el detalle completo). El cliente obtiene automáticamente `192.168.30.10` al resolver `erp.odoo.tfg.com`.
Verificación desde el cliente:
```bash
# Verificar que DNS resuelve a la IP interna (no a internet)
nslookup erp.odoo.tfg.com
# Debe devolver → Address: 192.168.30.10
# Verificar acceso HTTPS
curl -k -I https://erp.odoo.tfg.com
# Debe devolver → HTTP/2 200 o HTTP/1.1 302
```
**Alternativa — Archivo hosts en el cliente (si no hay DNS):**
```
# En Windows: C:\Windows\System32\drivers\etc\hosts
# En Linux:   /etc/hosts
192.168.30.10   erp.odoo.tfg.com
```
**Verificación final:**
1. Abrir navegador en el cliente → `https://erp.odoo.tfg.com`
2. Aceptar el aviso del certificado autofirmado
3. Debe aparecer la pantalla de login de Odoo 17
4. Iniciar sesión con las credenciales creadas durante la instalación de Odoo
### 7.2 Verificar los Triggers de Auditoría desde la Web
1. En Odoo → **Ajustes > Usuarios** → Crear un nuevo usuario
2. Volver al servidor y ejecutar:
```bash
docker exec -it odoo_erp psql -U odoo -d odoo_erp -c "SELECT * FROM asir_audit_log ORDER BY action_time DESC;"
```
Debe aparecer una fila con `action_type = 'CREACION_USUARIO'`.
---
## Fase 8: Pipeline CI/CD con GitHub Actions (Self-Hosted Runner)
### ¿Por qué un runner self-hosted?
Los runners gratuitos de GitHub (ubuntu-latest) no tienen acceso a la red privada de la DMZ. Registrar el propio servidor Debian como runner permite que GitHub Actions ejecute el despliegue automáticamente dentro de la red local cada vez que se hace un `git push` a `main`.
### 8.1 Obtener el Token de Registro en GitHub
1. Ir al repositorio en GitHub
2. **Settings → Actions → Runners → New self-hosted runner**
3. Seleccionar: `Linux` / `x64`
4. Copiar la URL del repositorio y el token que aparece (caduca en 1 hora)
### 8.2 Ejecutar el Script de Configuración del Runner
En el servidor Debian (`192.168.30.10`), como el usuario administrador (no root):
```bash
# Dar permisos y ejecutar el script de instalación del runner
chmod +x /opt/erp-odoo/scripts/setup_runner.sh
./opt/erp-odoo/scripts/setup_runner.sh
```
El script pedirá interactivamente:
1. La URL del repositorio (`https://github.com/sandrafrv/TFG-Implantacion_Segura_y_Automatizada_de_Odoo.git`)
2. El token de registro de GitHub (no se muestra en pantalla)
Después, automáticamente:
- Descarga el agente del runner de GitHub (detecta arquitectura x64/arm64)
- Registra el runner con el nombre `debian-dmz` y la etiqueta `self-hosted,debian-dmz,linux`
- Lo instala como servicio `systemd` para que arranque con el servidor
### 8.3 Verificar que el Runner está Activo
```bash
# Comprobar el estado del servicio del runner
cd ~/actions-runner
sudo ./svc.sh status
```
En GitHub: **Settings → Actions → Runners** → el runner `debian-dmz` debe aparecer como **Idle** (esperando jobs).
### 8.4 Activar el Pipeline Automático
```bash
# En el PC de desarrollo, hacer cualquier commit y push a main
git add .
git commit -m "feat: activar pipeline CD"
git push origin main
```
En la pestaña **Actions** del repositorio de GitHub:
- Aparecerá el workflow `CD Deploy` ejecutándose en el runner `debian-dmz`
- El runner ejecutará `scripts/deploy.sh` en el servidor
- Al finalizar, los contenedores estarán actualizados y funcionando
> 🔄 **En Progreso [2026-05-05]:** Agente runner descargado en `/opt/actions-runner`. Pendiente configuración del servicio systemd y ejecución final del pipeline CD.
## Fase 9: Mejoras de Automatización Avanzada (Scripting y Docker)
### ¿Por qué estas mejoras?
Para acercar el despliegue a una experiencia de "enchufar servidor y olvidarse", se han añadido mejoras sobre la infraestructura base que simplifican el despliegue inicial, mejoran la configuración dinámica, robustecen los scripts existentes y aseguran el correcto seguimiento de los contenedores Docker mediante sus healthchecks nativos.
### 9.1 Novedades Implementadas
1. **Instalador `install.sh`**: Despliegue en 1 clic que clona el repo, instala dependencias, crea certificados y activa el cron.
2. **Plantilla de entorno `.env.example` y configurador `configure.sh`**: Script interactivo para configurar de forma segura las credenciales sin edición manual de archivos.
3. **Docker Healthchecks**: Se incorporó validación nativa (`pg_isready`, `curl`, `nginx -t`) en el `docker-compose.yml`.
4. **Logrotate**: Rotación semanal automática de los logs de sistema para evitar llenar la partición root.
5. **Orquestador `erp.sh`**: Comando único con subcomandos rápidos para el ciclo de vida (deploy, backup, logs, etc.).
6. **Pre-checks**: Comprobaciones de conectividad Docker, espacio libre y puertos libres antes de los despliegues.
> ✅ **Completado [2026-04-30]:** Todas las mejoras de scripting, plantillas de entorno y comprobaciones de healthcheck han sido implementadas exitosamente y añadidas al pipeline de CI (ShellCheck).
---
## Fase 10: Documentación Final y Defensa
### ¿Por qué esta fase?
La última etapa del TFG consiste en asegurar que toda la implantación técnica se refleja correctamente en la memoria escrita y preparar el material necesario para la demostración práctica ante el tribunal.
### 10.1 Cierre de Documentación Técnica
- **Plan de Implantación**: ✅ Actualizado y revisado. Refleja la arquitectura final con sus automatizaciones.
- **Changelog**: ✅ Actualizado con las últimas sesiones de trabajo (`v1.5`).
- **Readme**: Consolidar el `README.md` como una guía rápida de despliegue ("Quickstart"). (Pendiente)
### 10.2 Preparación de la Memoria
Trasladar todo el trabajo técnico a la estructura formal requerida por el TFG:
- Introducción y Objetivos (basados en automatización y seguridad).
- Arquitectura (diagramas de red de pfSense y contenedores Docker).
- Implementación (detalles de bash scripts, nginx proxy, PostgreSQL audit).
- Pruebas de funcionamiento y Conclusiones.
### 10.3 Defensa y Demostración Práctica
Preparar un entorno real (o virtual) saneado y un guion para la demostración en vivo:
1. **Acceso inicial**: pfSense y reglas DMZ.
2. **Despliegue rápido**: Ejecutar `install.sh` y mostrar su automatización.
3. **Resiliencia**: Simular una caída (`docker stop odoo`) y mostrar cómo `monitor.sh` lo recupera automáticamente.
4. **Auditoría**: Demostrar el trigger PL/pgSQL mediante la creación de un usuario en Odoo y lectura del log.
---
## Resumen de Ejecución y Orden de Arranque
Una vez desplegado todo el sistema, el orden correcto de arranque ante un reinicio es:
1. **Encender la VM de pfSense** → esperar a que las interfaces de red estén activas (~1 min)
2. **Encender la VM de Debian** → Docker arranca automáticamente (restart: always)
3. **Esperar ~3 min** → Odoo inicializa si es el primer arranque
4. **Verificar desde el cliente** → `https://erp.odoo.tfg.com` → pantalla de login Odoo
5. **Acceder a Cockpit** → `https://192.168.30.10:9090` → panel de administración
> 📌 **Dominio de acceso:** `https://erp.odoo.tfg.com` resuelto por pfSense DNS Resolver → `192.168.30.10`
---
## Estado Final del Proyecto
| Componente | Estado | Notas |
|:-----------|:-------|:------|
| pfSense | ✅ | 4 interfaces, reglas VLAN 10/30/40, LDAP auth |
| Debian 12 | ✅ | IP estática, Docker, Cockpit |
| Docker stack | ✅ | 4 contenedores healthy |
| Red MACVLAN | ✅ | Nginx .20, Odoo .21, LDAP .22 |
| LDAP | ✅ | Auth centralizada Odoo + PCs VLAN 10 |
| CI/CD | ✅ | Runner activo, pipeline CI + CD |
| Auditoría SQL | ✅ | Trigger en `res_users` |
| Backups | ✅ | Cron diario 02:00 |
| UFW | ✅ | Solo 22/80/443/9090 |
**→ Guía de instalación actualizada:** [`docs/INSTALACION_COMPLETA.md`](INSTALACION_COMPLETA.md)
```

### File: .\docs\archive\plan_iac_github.md
```md
# Plan de Implantación — Infraestructura como Código (IaC)
## TFG: Implantación Segura y Automatizada de Odoo
**Repositorio:** [sandrafrv/TFG-Implantacion_Segura_y_Automatizada_de_Odoo](https://github.com/sandrafrv/TFG-Implantacion_Segura_y_Automatizada_de_Odoo)  
**Autores:** Sandra Fradejas Avedillo · Mario García García · Javier Córdoba Del Valle  
**Centro:** IES Cañaveral — ASIR 2025/2026
---
## Resumen ejecutivo
GitHub actúa como **fuente de verdad** y plataforma central de despliegue. Todo el estado deseado del sistema — scripts de configuración, red MACVLAN, hardening SSH, roles de Odoo y el stack Docker — está versionado en el repositorio. El servidor Debian aplica exactamente lo que hay en `main` cada vez que el pipeline CI/CD se dispara.
Enfoque **Infrastructure as Code (IaC)**: si el servidor se pierde o hay que replicar el entorno, basta con registrar un nuevo runner y hacer un `push` a `main` para restaurar todo automáticamente.
> **Nota de contexto:** Este documento cubre las nuevas funcionalidades añadidas al TFG:
> servidor headless, acceso SSH restringido por máquina, redes MACVLAN, perfil DBA para
> PostgreSQL, roles y departamentos en Odoo, y GitHub como plataforma central de despliegue.
---
## Orden de implementación
> ⚠️ **Este es el orden obligatorio de implantación.**
| Orden | Fase | Estado |
|-------|------|--------|
| 1 | **VLAN + MACVLAN** — Red segmentada y contenedores con IP física | ✅ Completada 08/05/2026 |
| 2 | **LDAP** — Autenticación centralizada en Odoo | ⏳ Pendiente |
| 3 | **Debian Headless** — Eliminar GUI + SSH endurecido | ⏳ Pendiente |
| 4 | **IaC / GitHub Actions** — Pipeline CI/CD completo | ⏳ Pendiente |
---
## 1. Arquitectura general
### 1.1 Principio de funcionamiento
```
Desarrollador / Admin
       │
       │  git push → rama feature/...
       ▼
┌─────────────────────────────────────────────┐
│              GitHub                         │
│                                             │
│  CI Validator (ci.yml)                      │
│  ├── ShellCheck scripts/*.sh                │
│  ├── Validar docker-compose.yml             │
│  └── Lint Markdown                          │
│            │ (solo si pasa)                 │
│  CD Deploy (deploy.yml)                     │
│  runs-on: self-hosted                       │
│  ├── git reset --hard origin/main           │
│  ├── Fase 1: Preparación host               │
│  ├── Fase 2: Red MACVLAN                    │
│  ├── Fase 3: Hardening SSH + DBA            │
│  ├── Fase 4: Docker stack up                │
│  └── Fase 5: Roles Odoo                     │
└─────────────────────────────────────────────┘
       │  self-hosted runner (en el servidor)
       ▼
┌─────────────────────────────────────────────┐
│    Servidor Debian (192.168.30.10)          │
│  ├── Contenedor Odoo    (192.168.30.21)     │
│  └── Contenedor PostgreSQL (192.168.30.22)  │
└─────────────────────────────────────────────┘
```
### 1.2 Regla fundamental
> **Nunca se ejecuta nada manualmente en el servidor en producción.**
> Cualquier cambio se hace en el repositorio, pasa por CI, y se despliega automáticamente.
> La única excepción es la instalación inicial del runner (`setup_runner.sh`).
### 1.3 Topología de red
| Elemento | IP | Rol |
|----------|----|-----|
| pfSense (gateway) | `192.168.30.1` | Firewall / enrutador |
| Servidor Debian (host) | `192.168.30.10` | Runner + Docker host |
| Contenedor Odoo | `192.168.30.21` | Aplicación ERP (MACVLAN) ✅ |
| Contenedor Nginx | `192.168.30.20` | Proxy inverso HTTPS (MACVLAN) ✅ |
| Contenedor PostgreSQL | `172.19.0.x` | Base de datos (solo red bridge) |
| Máquina Admin | `192.168.30.11` | Administración SSH |
| Máquina DBA | `192.168.30.12` | Acceso PostgreSQL vía túnel SSH |
| Clientes Odoo | `192.168.10.x` | Acceso web HTTPS |
---
## 2. Estado actual de la red (08/05/2026)
### Red bridge interna (`docker_odoo_net`)
| Contenedor | IP bridge | Rol |
|------------|-----------|-----|
| `nginx-proxy` | `172.19.0.2` | Proxy inverso |
| `odoo_erp` | `172.19.0.3` | PostgreSQL |
| `odoo-web` | `172.19.0.4` | Odoo 17 |
### Red MACVLAN (`macvlan_vlan30`) — `ens36` — ✅ Activa
| Contenedor | IP MACVLAN | Justificación |
|------------|------------|---------------|
| `nginx-proxy` | `192.168.30.20` | Entrada HTTPS con IP física |
| `odoo-web` | `192.168.30.21` | ERP con IP física |
| `odoo_erp` | ❌ Excluido | Seguridad: BD no expuesta |
Verificación rápida del estado actual:
```bash
docker network inspect macvlan_vlan30 \
  --format '{{range .Containers}}{{.Name}}: {{.IPv4Address}}{{"\n"}}{{end}}'
```
---
## 3. Estructura del repositorio
```
TFG-Implantacion_Segura_y_Automatizada_de_Odoo/
│
├── .github/workflows/
│   ├── ci.yml              ← Validación automática (ShellCheck, YAML, Markdown)
│   └── deploy.yml          ← Despliegue automático (self-hosted runner)
│
├── scripts/
│   ├── setup_runner.sh     ← [EXISTENTE] Instala el runner de GitHub Actions
│   ├── deploy.sh           ← [EXISTENTE] Levanta el stack Docker
│   ├── backup.sh           ← [EXISTENTE] Backup de PostgreSQL
│   ├── restore.sh          ← [EXISTENTE] Restauración de backup
│   ├── monitor.sh          ← [EXISTENTE] Monitorización del stack
│   ├── update.sh           ← [EXISTENTE] Actualización de imágenes Docker
│   ├── configure.sh        ← [EXISTENTE] Configuración post-despliegue
│   ├── install_cron.sh     ← [EXISTENTE] Configura tareas programadas
│   │
│   ├── headless_check.sh   ← [PENDIENTE] Configura Debian sin GUI
│   ├── ssh_hardening.sh    ← [PENDIENTE] Restringe SSH + UFW
│   ├── dba_user_setup.sh   ← [PENDIENTE] Usuario sistema DBA (túneles)
│   ├── macvlan_setup.sh    ← [PENDIENTE] Crea red Docker MACVLAN
│   └── odoo_init_roles.sh  ← [PENDIENTE] Departamentos y roles en Odoo
│
├── docker/
│   └── docker-compose.yml  ← Stack con IPs MACVLAN (actualizado ✅)
│
└── .env.example            ← Variables de entorno (sin secretos reales)
```
---
## 4. Fase pendiente: LDAP
### Objetivo
Centralizar autenticación de usuarios de Odoo contra un directorio LDAP.
### 4.1 Añadir OpenLDAP al stack Docker
Añadir al `docker-compose.yml`:
```yaml
  ldap:
    image: osixia/openldap:1.5.0
    container_name: odoo-ldap
    restart: always
    environment:
      LDAP_ORGANISATION: "TFG ASIR"
      LDAP_DOMAIN: "tfg.com"
      LDAP_ADMIN_PASSWORD: "${LDAP_ADMIN_PASSWORD}"
    volumes:
      - ../data/ldap_data:/var/lib/ldap
      - ../data/ldap_config:/etc/ldap/slapd.d
    networks:
      odoo_net:
```
Añadir al `.env`:
```bash
LDAP_ADMIN_PASSWORD=<contraseña_segura>
```
```bash
# Levantar el nuevo servicio
docker compose -f /opt/erp-odoo/docker/docker-compose.yml up -d ldap
docker ps | grep ldap
```
### 4.2 Crear usuarios de prueba (LDIF)
```bash
cat << 'EOF' > /tmp/usuarios_tfg.ldif
dn: ou=usuarios,dc=tfg,dc=com
objectClass: organizationalUnit
ou: usuarios
dn: uid=jdoe,ou=usuarios,dc=tfg,dc=com
objectClass: inetOrgPerson
uid: jdoe
cn: John Doe
sn: Doe
mail: jdoe@tfg.com
userPassword: Odoo2024!
EOF
# Importar
docker exec odoo-ldap ldapadd \
  -x -D "cn=admin,dc=tfg,dc=com" \
  -w "${LDAP_ADMIN_PASSWORD}" \
  -f /tmp/usuarios_tfg.ldif
# Verificar
docker exec odoo-ldap ldapsearch \
  -x -D "cn=admin,dc=tfg,dc=com" \
  -w "${LDAP_ADMIN_PASSWORD}" \
  -b "dc=tfg,dc=com" "(uid=jdoe)"
```
### 4.3 Configurar LDAP en Odoo (interfaz web)
**Ajustes → Técnico → Autenticación LDAP → Nuevo servidor LDAP:**
| Campo | Valor |
|-------|-------|
| Servidor LDAP | `odoo-ldap` |
| Puerto | `389` |
| TLS | No |
| DN base | `ou=usuarios,dc=tfg,dc=com` |
| Filtro LDAP | `(uid=%s)` |
| DN de bind | `cn=admin,dc=tfg,dc=com` |
| Contraseña de bind | `${LDAP_ADMIN_PASSWORD}` |
| Crear usuario si no existe | ✅ Sí |
### 4.4 Validación LDAP
```bash
# Test conexión desde contenedor Odoo
docker exec odoo-web ldapsearch \
  -H ldap://odoo-ldap:389 \
  -x -D "cn=admin,dc=tfg,dc=com" \
  -w "${LDAP_ADMIN_PASSWORD}" \
  -b "dc=tfg,dc=com" "(uid=jdoe)"
```
- [ ] `ldapsearch` devuelve `uid=jdoe`
- [ ] Login en Odoo con `jdoe` + contraseña LDAP → OK
- [ ] Odoo crea automáticamente el perfil del usuario LDAP
- [ ] Audit trigger registra el usuario en `asir_audit_log`
---
## 5. Fase pendiente: Debian Headless
> ⚠️ **Hacer esta fase la última.** Con GUI es más fácil diagnosticar errores previos.
### 5.1 Cambiar target de arranque
```bash
sudo systemctl set-default multi-user.target
systemctl get-default   # → multi-user.target
```
### 5.2 Eliminar entorno gráfico
```bash
dpkg -l | grep -E "gnome|kde|xfce|lxde"
sudo apt remove --purge gnome* x11* xorg* -y
sudo apt autoremove --purge -y && sudo apt clean
```
### 5.3 Script `headless_check.sh`
```bash
#!/usr/bin/env bash
set -euo pipefail
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; NC='\033[0m'
log_info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }
[ "$(id -u)" -ne 0 ] && { log_error "Ejecutar como root."; exit 1; }
GRAPHICAL="xorg xserver-xorg gnome kde-plasma-desktop xfce4 lxde"
DISPLAY_MGR="gdm gdm3 lightdm sddm xdm"
FOUND=""
for pkg in $GRAPHICAL $DISPLAY_MGR; do
    dpkg -l "$pkg" 2>/dev/null | grep -q "^ii" && FOUND="$FOUND $pkg"
done
if [ -n "$FOUND" ]; then
    log_warn "Paquetes gráficos:$FOUND"
    # shellcheck disable=SC2086
    apt-get purge -y $FOUND && apt-get autoremove -y
    log_ok "Paquetes eliminados."
else
    log_ok "Sin entorno gráfico instalado."
fi
for dm in $DISPLAY_MGR; do
    systemctl is-enabled "$dm" 2>/dev/null | grep -q "enabled" && systemctl disable "$dm" --now || true
done
systemctl set-default multi-user.target
[ "$(systemctl get-default)" = "multi-user.target" ] && log_ok "Modo headless activo." \
    || { log_error "Target incorrecto."; exit 1; }
```
### 5.4 Script `ssh_hardening.sh`
```bash
#!/usr/bin/env bash
set -euo pipefail
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; NC='\033[0m'
log_info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }
[ "$(id -u)" -ne 0 ] && { log_error "Ejecutar como root."; exit 1; }
[ -z "${ADMIN_IP:-}" ] && read -r -p "IP Admin: " ADMIN_IP
[ -z "${ADMIN_IP:-}" ] && { log_error "ADMIN_IP requerida."; exit 1; }
DBA_IP="${DBA_IP:-}"
command -v ufw > /dev/null 2>&1 || apt-get install -y ufw
cp /etc/ssh/sshd_config "/etc/ssh/sshd_config.bak.$(date +%Y%m%d_%H%M%S)"
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/'               /etc/ssh/sshd_config
sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/'    /etc/ssh/sshd_config
grep -q "^PasswordAuthentication" /etc/ssh/sshd_config || echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
grep -q "^PermitRootLogin"        /etc/ssh/sshd_config || echo "PermitRootLogin no"        >> /etc/ssh/sshd_config
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow from "$ADMIN_IP" to any port 22 proto tcp comment "SSH Admin"
[ -n "$DBA_IP" ] && ufw allow from "$DBA_IP" to any port 22 proto tcp comment "SSH DBA"
ufw allow 443/tcp comment "HTTPS Odoo"
ufw allow 9090/tcp comment "Cockpit"
ufw --force enable
systemctl restart sshd
log_ok "Hardening SSH + UFW aplicado."
log_warn "Verifica acceso desde Admin antes de cerrar sesión."
```
### 5.5 Script `dba_user_setup.sh`
```bash
#!/usr/bin/env bash
set -euo pipefail
DBA_USER="odoo-dba"
DBA_HOME="/home/${DBA_USER}"
DBA_SSH_DIR="${DBA_HOME}/.ssh"
DBA_PUBKEY="${DBA_PUBKEY:-}"
[ "$(id -u)" -ne 0 ] && { echo "Ejecutar como root."; exit 1; }
id "$DBA_USER" > /dev/null 2>&1 || \
    useradd --create-home --shell /usr/sbin/nologin \
        --comment "DBA Odoo - solo SSH tunnel" "$DBA_USER"
mkdir -p "$DBA_SSH_DIR"
chmod 700 "$DBA_SSH_DIR"
chown "${DBA_USER}:${DBA_USER}" "$DBA_SSH_DIR"
if [ -n "$DBA_PUBKEY" ]; then
    echo "$DBA_PUBKEY" > "${DBA_SSH_DIR}/authorized_keys"
    chmod 600 "${DBA_SSH_DIR}/authorized_keys"
    chown "${DBA_USER}:${DBA_USER}" "${DBA_SSH_DIR}/authorized_keys"
fi
SSHD_CONFIG="/etc/ssh/sshd_config"
grep -q "Match User ${DBA_USER}" "$SSHD_CONFIG" || cat >> "$SSHD_CONFIG" << SSHBLOCK
# dba_user_setup — TFG
Match User ${DBA_USER}
    AllowTcpForwarding yes
    X11Forwarding no
    PermitTTY no
    ForceCommand /bin/false
    PasswordAuthentication no
    PubkeyAuthentication yes
SSHBLOCK
systemctl restart sshd
echo "[OK] Usuario DBA '${DBA_USER}' configurado."
echo "     Túnel: ssh -N -L 5433:172.19.0.3:5432 odoo-dba@192.168.30.10"
echo "     psql:  psql -h 127.0.0.1 -p 5433 -U odoo -d odoo_erp"
```
### 5.6 Validación headless
```bash
systemctl get-default                         # multi-user.target
echo $DISPLAY                                 # vacío
systemctl is-active docker                    # active
docker compose -f /opt/erp-odoo/docker/docker-compose.yml ps  # 3 Up
curl -k -I https://erp.odoo.tfg.com          # 200/302
ufw status verbose                            # activo
ssh server@192.168.30.10                      # acceso OK desde Admin
```
---
## 6. Pipeline CI/CD — `deploy.yml` completo
```yaml
name: CD Deploy (Self-Hosted)
on:
  workflow_run:
    workflows: ["CI Validator"]
    types: [completed]
    branches: [main]
jobs:
  deploy:
    name: Desplegar Stack en Servidor Debian
    if: ${{ github.event.workflow_run.conclusion == 'success' }}
    runs-on: self-hosted
    steps:
      - name: Verificar entorno del servidor
        run: |
          echo "Servidor: $(hostname) | Docker: $(docker --version) | $(date)"
      - name: Marcar directorio como seguro para Git
        run: git config --global --add safe.directory /opt/erp-odoo
      - name: "[0] Sincronizar repositorio"
        working-directory: /opt/erp-odoo
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          git remote set-url origin https://x-access-token:${GH_TOKEN}@github.com/${{ github.repository }}.git
          git fetch origin
          git reset --hard origin/main
      - name: "[1/5] Configurar modo headless"
        working-directory: /opt/erp-odoo
        run: sudo bash scripts/headless_check.sh
      - name: "[2/5] Configurar red MACVLAN"
        working-directory: /opt/erp-odoo
        env:
          PARENT_IFACE: ${{ vars.PARENT_IFACE }}
          SUBNET:       ${{ vars.SUBNET }}
          GATEWAY:      ${{ vars.GATEWAY }}
          ODOO_IP:      ${{ vars.ODOO_IP }}
          POSTGRES_IP:  ${{ vars.POSTGRES_IP }}
          HOST_MACVLAN_IP: ${{ vars.HOST_MACVLAN_IP }}
        run: sudo -E bash scripts/macvlan_setup.sh
      - name: "[3/5] SSH hardening + usuario DBA"
        working-directory: /opt/erp-odoo
        env:
          ADMIN_IP:   ${{ secrets.ADMIN_IP }}
          DBA_IP:     ${{ secrets.DBA_IP }}
          DBA_PUBKEY: ${{ secrets.DBA_PUBKEY }}
        run: |
          sudo -E bash scripts/ssh_hardening.sh
          sudo -E bash scripts/dba_user_setup.sh
      - name: "[4/5] Desplegar stack Docker"
        working-directory: /opt/erp-odoo
        run: bash scripts/deploy.sh
      - name: "[5/5] Inicializar roles en Odoo"
        working-directory: /opt/erp-odoo
        run: |
          sleep 20
          bash scripts/odoo_init_roles.sh
      - name: Verificación final
        working-directory: /opt/erp-odoo
        run: |
          docker compose -f docker/docker-compose.yml ps
          echo "[OK] Despliegue completado."
```
---
## 7. Secrets y Variables en GitHub
### Secrets (`Settings → Secrets → Actions`)
| Secret | Descripción |
|--------|-------------|
| `ADMIN_IP` | IP máquina de administración |
| `DBA_IP` | IP máquina del DBA |
| `DBA_PUBKEY` | Clave pública SSH del DBA |
| `POSTGRES_PASSWORD` | Contraseña PostgreSQL |
| `ODOO_ADMIN_PASSWORD` | Contraseña admin Odoo |
| `LDAP_ADMIN_PASSWORD` | Contraseña admin LDAP |
### Variables (`Settings → Variables → Actions`)
| Variable | Valor ejemplo |
|----------|--------------|
| `PARENT_IFACE` | `ens36` |
| `SUBNET` | `192.168.30.0/24` |
| `GATEWAY` | `192.168.30.1` |
| `ODOO_IP` | `192.168.30.21` |
| `POSTGRES_IP` | `192.168.30.22` |
| `HOST_MACVLAN_IP` | `192.168.30.23` |
| `ODOO_DB` | `odoo_erp` |
| `ODOO_URL` | `http://localhost:8069` |
---
## 8. Perfiles de acceso al sistema
| Perfil | IP | SSH | PostgreSQL | Odoo web |
|--------|----|-----|------------|----------|
| Admin técnico | `192.168.30.11` | ✅ Shell + sudo | ✅ `docker exec` | ✅ Puerto 8069 |
| DBA | `192.168.30.12` | ✅ Solo túnel TCP | ✅ Túnel SSH `.5433` | ❌ |
| Usuarios Odoo | `192.168.10.x` | ❌ | ❌ | ✅ HTTPS 443 |
| GitHub Actions | localhost | N/A | ❌ | ❌ |
| Cualquier otro | — | ❌ UFW DENY | ❌ | ❌ |
### Acceso DBA a PostgreSQL
```bash
# 1. Abrir túnel SSH desde la máquina DBA
ssh -N -L 5433:172.19.0.3:5432 -i ~/.ssh/dba_key odoo-dba@192.168.30.10
# 2. Conectar con psql (en otra terminal)
psql -h 127.0.0.1 -p 5433 -U odoo -d odoo_erp
```
---
## 9. Reglas pfSense
| Regla | Origen | Destino | Puerto | Acción |
|-------|--------|---------|--------|--------|
| SSH Admin | `192.168.30.11/32` | `192.168.30.10` | `22/TCP` | ALLOW |
| SSH DBA | `192.168.30.12/32` | `192.168.30.10` | `22/TCP` | ALLOW |
| HTTPS clientes → Odoo | `192.168.10.0/24` | `192.168.30.20` | `443/TCP` | ALLOW |
| Admin → Odoo debug | `192.168.30.11/32` | `192.168.30.21` | `8069/TCP` | ALLOW |
| Bloquear PostgreSQL | Cualquiera | `192.168.30.22` | `5432/TCP` | BLOCK |
| SSH resto | Cualquiera | `192.168.30.10` | `22/TCP` | BLOCK |
| Todo lo demás | Cualquiera | Cualquiera | — | DENY |
---
## 10. Checklist de puesta en marcha
### Primera vez — manual (solo una vez)
- [ ] Instalar Debian Server sin entorno gráfico
- [ ] Ejecutar `scripts/setup_runner.sh` para registrar el runner en GitHub
- [ ] Añadir Secrets y Variables en GitHub Actions
- [ ] Copiar `.env.example` → `.env` y rellenar valores reales
- [ ] Configurar reglas pfSense (sección 9)
### Despliegue automático (cada push a `main`)
- [ ] CI Validator pasa (ShellCheck, YAML, Markdown)
- [ ] CD Deploy ejecuta las 5 fases en el servidor
- [ ] Verificar pestaña Actions → todos los pasos en verde
---
## 11. Verificaciones por componente
### MACVLAN (✅ ya hecho)
```bash
docker network inspect macvlan_vlan30 \
  --format '{{range .Containers}}{{.Name}}: {{.IPv4Address}}{{"\n"}}{{end}}'
# nginx-proxy: 192.168.30.20/24
# odoo-web:    192.168.30.21/24
```
### LDAP (⏳ pendiente)
```bash
docker exec odoo-ldap ldapsearch \
  -x -D "cn=admin,dc=tfg,dc=com" -w "${LDAP_ADMIN_PASSWORD}" \
  -b "dc=tfg,dc=com" "(uid=jdoe)"
```
### Headless (⏳ pendiente)
```bash
systemctl get-default          # multi-user.target
ufw status verbose             # activo
systemctl is-active docker     # active
```
### Usuario DBA (⏳ pendiente)
```bash
getent passwd odoo-dba
grep -A6 "Match User odoo-dba" /etc/ssh/sshd_config
```
### Pipeline GitHub Actions (⏳ pendiente)
1. Ir a pestaña **Actions** del repositorio en GitHub
2. CI Validator → verde ✅
3. CD Deploy → pasos [1/5]–[5/5] en verde ✅
---
## 12. Notas de seguridad
- Los **Secrets de GitHub** nunca se almacenan en el repositorio
- Las contraseñas de ejemplo en `odoo_init_roles.sh` deben cambiarse antes de producción
- El backup de `sshd_config` queda en `/etc/ssh/sshd_config.bak.*`
- Las IPs Admin y DBA deben ser estáticas (reserva DHCP en pfSense o IP fija)
- El puerto `5432` de PostgreSQL **nunca se expone** en la red física — solo vía túnel SSH
- La red `macvlan_vlan30` en Docker está declarada como `external: true` y es creada por `macvlan_setup.sh`
```

### File: .\docs\archive\propuestas_mejoras_extra.md
```md
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
```

### File: .\docs\archive\task.md
```md
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
- [x] Validar crontab: verificar tareas instaladas en `/etc/cron.d/erp-odoo` por el script de despliegue.
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
- [x] **[2026-04-30]** Runner descargado manualmente: `actions-runner-linux-x64-2.334.0.tar.gz` en `/opt/actions-runner`. SHA256 verificado: OK.
- [x] **[2026-04-30]** Runner extraído y configurado: `./config.sh --url ... --token ...` — nombre `debian`, grupo `Default`, labels `self-hosted, Linux, X64`.
- [x] **[2026-04-30]** Runner instalado como servicio systemd: `sudo ./svc.sh install && sudo ./svc.sh start`.
  - Servicio: `actions.runner.sandrafrv-TFG-Implantacion_Segura_y_Automatizada_de_Odoo.debian.service`
  - Estado: `active (running)` desde las 17:15:23 CEST.
- [x] **[2026-04-30]** Runner verificado como **Idle** en GitHub → Settings → Actions → Runners.
- [x] **[2026-04-30]** Pipeline CD disparado y completado con éxito — commit `0cdee22`.
  - Errores resueltos durante la puesta en marcha:
    - `permission denied` en `.env` → `chown root:server + chmod 640`.
    - `docker-compose.yml tiene errores de sintaxis` → era cascada del error de permisos.
    - `puertos 80/443 en uso` → `ss -tlnp` sin root no muestra PID; corregido comprobando si `nginx-proxy` está corriendo.
    - `posesión dudosa` en git → `git config --global --add safe.directory /opt/erp-odoo` añadido al workflow.
    - `git pull` falla por permisos → `sudo chown -R server:server /opt/erp-odoo`.
- [x] **[2026-04-30]** Validación final del pipeline: los 3 contenedores `healthy`, Odoo operativo en `https://erp.techsolutions.local`.
---
## Fase 9: Mejoras de Automatización Avanzada (Scripting y Docker)
- [x] **[2026-04-30]** Crear script `install.sh` (instalador todo-en-uno).
- [x] **[2026-04-30]** Crear plantilla `.env.example` y configurador.
- [x] **[2026-04-30]** Añadir `healthcheck` nativos en Docker.
- [x] **[2026-04-30]** Mejorar `monitor.sh` y añadir Logrotate.
- [x] **[2026-04-30]** Crear orquestador `erp.sh` y pre-checks.
- [x] **[2026-04-30]** Actualizar CI de GitHub Actions.
---
## Fase 10: Documentación Final y Defensa
- [x] Revisar y completar `docs/implementation_plan.md` con todas las decisiones técnicas tomadas.
- [x] Actualizar `CHANGELOG.md` con los cambios de cada sesión de trabajo.
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
| 8 | CI/CD GitHub Actions | ✅ Completada |
| 9 | Mejoras Automatización | ✅ Completada |
| 10 | Documentación y defensa | ⏳ Pendiente |
```

### File: .\docs\guias\INSTALACION_LDAP_CICD_HARDENING.md
```md
# Guía Avanzada — LDAP + CI/CD + Hardening
**← Volver a:** [`docs/INSTALACION_COMPLETA.md`](../INSTALACION_COMPLETA.md)
**← Fase anterior:** [`guias/INSTALACION_SERVIDOR.md`](INSTALACION_SERVIDOR.md)
---
## PARTE 1 — OpenLDAP: Directorio Centralizado de Usuarios
### 1.1 Arquitectura del Directorio
```
dc=tfg,dc=com
├── ou=usuarios         ← Cuentas personales de empleados
│   ├── uid=jdoe
│   └── uid=mbrown
├── ou=grupos           ← Grupos departamentales
│   ├── cn=becarios     (VLAN 10)
│   ├── cn=ventas       (VLAN 10)
│   ├── cn=rrhh         (VLAN 10)
│   ├── cn=almacen      (VLAN 10)
│   ├── cn=tecnico      (VLAN 10 — puede cambiar contraseñas)
│   ├── cn=jefe_ventas  (VLAN 10 — aprobaciones)
│   ├── cn=jefe_rrhh    (VLAN 10 — aprobaciones)
│   ├── cn=jefe_almacen (VLAN 10 — aprobaciones)
│   ├── cn=admin        (VLAN 40 — acceso total)
│   └── cn=dba          (VLAN 40 — solo base de datos)
└── ou=servicios        ← Cuentas técnicas
    ├── cn=readonly     (Odoo + PAM autentican con esta)
    └── cn=api
```
> OpenLDAP ya está levantado en el stack Docker (IP MACVLAN `192.168.30.22`).
> Esta parte configura su estructura y ACLs internas.
### 1.2 Verificar el Contenedor OpenLDAP
```bash
docker ps | grep openldap   # → Up (healthy)
# Prueba básica de conectividad
ldapsearch -H ldap://192.168.30.22 -x -b "dc=tfg,dc=com" "(objectClass=*)" dn
# Si ldapsearch no está instalado: sudo apt install ldap-utils -y
```
### 1.3 Aplicar ACLs de Seguridad
```bash
bash /opt/erp-odoo/scripts/ldap/ldap_politica_acceso.sh
```
| Cuenta | Permisos | Uso |
|:-------|:---------|:----|
| `cn=admin,dc=tfg,dc=com` | Escritura total | Administración del directorio |
| `cn=tecnico` (grupo) | `write` solo en `userPassword` de `ou=usuarios` | Técnicos cambian contraseñas |
| `cn=readonly,dc=tfg,dc=com` | Lectura de todo el árbol | Odoo y PAM autentican |
| Anónimo | Solo `auth` en `userPassword` | Bind básico |
| Todos los demás | `deny all` | Seguridad por defecto |
### 1.4 Crear Usuarios en el Directorio LDAP
```bash
bash /opt/erp-odoo/scripts/ldap/ldap_crear_usuarios.sh
```
El script pide interactivamente: uid, nombre, email, contraseña y grupo departamental.
Ejemplo de entrada LDIF generada:
```ldif
dn: uid=jdoe,ou=usuarios,dc=tfg,dc=com
objectClass: inetOrgPerson
objectClass: posixAccount
uid: jdoe
cn: John Doe
sn: Doe
mail: jdoe@techsolutions.local
uidNumber: 2001
gidNumber: 2000
homeDirectory: /home/jdoe
loginShell: /bin/bash
```
### 1.5 Verificar LDAP
```bash
# Ver todos los usuarios
ldapsearch -H ldap://192.168.30.22 \
  -D "cn=readonly,dc=tfg,dc=com" -w "<LDAP_READONLY_PASSWORD>" \
  -b "ou=usuarios,dc=tfg,dc=com" "(objectClass=inetOrgPerson)" uid cn
# Probar autenticación de un usuario
ldapwhoami -H ldap://192.168.30.22 \
  -D "uid=jdoe,ou=usuarios,dc=tfg,dc=com" -W
# Resultado esperado: dn: uid=jdoe,ou=usuarios,dc=tfg,dc=com ✅
# Verificar que readonly NO puede modificar (debe dar error 50)
ldapmodify -H ldap://192.168.30.22 \
  -D "cn=readonly,dc=tfg,dc=com" -w "password" <<EOF
dn: uid=jdoe,ou=usuarios,dc=tfg,dc=com
changetype: modify
replace: cn
cn: Test
EOF
# → ldap_modify: Insufficient access (50) ✅
```
### 1.6 Configurar Login LDAP en PCs Cliente VLAN 10
Permite que los empleados usen **la misma contraseña LDAP** para login en su PC y en Odoo.
```bash
# Ejecutar EN CADA PC CLIENTE (no en el servidor)
sudo bash /opt/erp-odoo/scripts/ldap/configurar_cliente_ldap.sh
```
El script pide interactivamente:
```
URI del servidor LDAP → ldap://192.168.30.22
Base DN              → dc=tfg,dc=com
Contraseña readonly  → <LDAP_READONLY_PASSWORD>
Grupo de acceso      → ventas  (opcional — restringe qué grupo puede entrar en este PC)
```
Instala y configura:
| Componente | Función |
|:-----------|:--------|
| **SSSD** | Intermediario SO ↔ LDAP, con caché offline |
| **PAM** (`pam_sss.so`) | Intercepta el login del SO y valida contra LDAP |
| **NSS** | El SO resuelve usuarios LDAP como si fueran locales |
| **pam_mkhomedir** | Crea `/home/<uid>` automáticamente en el primer login |
**Verificar en el PC cliente:**
```bash
getent passwd jdoe       # → jdoe:x:2001:2000:John Doe:/home/jdoe:/bin/bash ✅
su - jdoe                # → Pide contraseña LDAP, abre shell ✅
journalctl -u sssd -f    # Logs de SSSD en tiempo real (para depurar)
```
### 1.7 Operaciones de Mantenimiento LDAP
```bash
# Cambiar contraseña (técnico tiene permiso)
ldappasswd -H ldap://192.168.30.22 \
  -D "uid=tecnico,ou=usuarios,dc=tfg,dc=com" -W \
  -S "uid=jdoe,ou=usuarios,dc=tfg,dc=com"
# Cambiar contraseña como admin
ldappasswd -H ldap://192.168.30.22 \
  -D "cn=admin,dc=tfg,dc=com" -W \
  -S "uid=jdoe,ou=usuarios,dc=tfg,dc=com"
# Eliminar un usuario
ldapdelete -H ldap://192.168.30.22 \
  -D "cn=admin,dc=tfg,dc=com" -W \
  "uid=jdoe,ou=usuarios,dc=tfg,dc=com"
# Estado SSSD (en PC cliente)
sssctl domain-status tfg.com
sss_cache -E && systemctl restart sssd   # Forzar reconexión
```
### 1.8 Límites de Compatibilidad
> [!TIP]
> **Windows no es compatible como cliente nativo de OpenLDAP** para login del SO.
> Los PCs Windows de VLAN 10 hacen login local en Windows pero **sí se autentican con LDAP en Odoo** vía navegador.
>
> Para soportar Windows en el dominio, la mejora futura sería reemplazar OpenLDAP por **Samba 4 AD DC**.
---
## PARTE 2 — CI/CD con GitHub Actions (Despliegue Automático)
### 2.1 Cómo Funciona
```
git push → GitHub CI (ShellCheck + YAML + Markdown) → pasa ✅ → CD (deploy.sh en Debian)
```
### 2.2 Obtener Token de Registro
En GitHub: **Settings → Actions → Runners → New self-hosted runner**
→ Linux / x64 → copiar el **token** (válido 1 hora)
### 2.3 Instalar el Runner
```bash
chmod +x /opt/erp-odoo/scripts/deploy/setup_runner.sh
/opt/erp-odoo/scripts/deploy/setup_runner.sh
```
El script pide:
1. URL del repositorio
2. Token de registro
Instala el agente en `/opt/actions-runner` como servicio systemd.
### 2.4 Permisos del `.env` para el Runner
```bash
sudo chown root:servidor /opt/erp-odoo/docker/.env
sudo chmod 640 /opt/erp-odoo/docker/.env
```
### 2.5 Verificar
```bash
sudo systemctl is-active actions.runner.*   # → active ✅
# En GitHub → Settings → Actions → Runners → estado: Idle ✅
```
### 2.6 Probar el Pipeline
```bash
git commit --allow-empty -m "test: verificar CI/CD"
git push origin main
# GitHub → Actions → CI ✅ → CD ✅
```
### 2.7 Problemas Comunes CI/CD
| Error | Solución |
|:------|:---------|
| Runner no aparece en GitHub | `sudo systemctl restart actions.runner.*` |
| `dubious ownership` | `git config --global --add safe.directory /opt/erp-odoo` |
| `.env` no legible | `sudo chown root:servidor docker/.env && sudo chmod 640 docker/.env` |
| Puertos en uso en re-deploy | `deploy.sh` detecta si `nginx-proxy` ya corre y hace update en lugar de nuevo deploy |
---
## PARTE 3 — Hardening Final
> [!CAUTION]
> **Realizar SIEMPRE AL FINAL.** Con GNOME es mucho más fácil diagnosticar problemas.
> Una vez sin GUI, el único acceso es SSH o Cockpit.
### 3.1 Configurar UFW
```bash
sudo apt install ufw -y
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP Nginx
sudo ufw allow 443/tcp   # HTTPS Nginx
sudo ufw allow 9090/tcp  # Cockpit
sudo ufw enable
sudo ufw status verbose
```
### 3.2 Endurecer SSH
**Primero: copiar clave pública desde PC de administración (VLAN 40):**
```bash
ssh-keygen -t ed25519 -C "admin-tfg" -f ~/.ssh/tfg_admin
ssh-copy-id -i ~/.ssh/tfg_admin.pub servidor@192.168.30.10
ssh -i ~/.ssh/tfg_admin servidor@192.168.30.10   # Verificar login
```
**Luego: deshabilitar contraseñas (solo tras verificar que la clave funciona):**
```bash
sudo nano /etc/ssh/sshd_config
```
```ini
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
ChallengeResponseAuthentication no
LoginGraceTime 30
AllowUsers servidor
X11Forwarding no
MaxAuthTries 3
```
```bash
sudo systemctl restart sshd
# Verificar desde OTRA ventana de terminal antes de cerrar la actual:
ssh -i ~/.ssh/tfg_admin servidor@192.168.30.10   # ✅
```
> [!CAUTION]
> **NO cierres la sesión SSH actual** hasta confirmar que puedes entrar con la clave.
> Si configuras `PasswordAuthentication no` sin tener la clave copiada, **perderás el acceso**.
### 3.3 Convertir a Modo Headless (Sin GUI)
```bash
# Cambiar target de arranque
sudo systemctl set-default multi-user.target
systemctl get-default   # → multi-user.target
# Eliminar GNOME y X11
sudo apt remove --purge gnome* -y
sudo apt remove --purge x11* xorg* -y
sudo apt autoremove --purge -y
sudo apt clean
```
### 3.4 Reiniciar y Verificar
```bash
sudo reboot
# Reconectar por SSH:
ssh -i ~/.ssh/tfg_admin servidor@192.168.30.10
systemctl get-default          # → multi-user.target ✅
sudo ufw status                # → Status: active ✅
systemctl is-active docker     # → active ✅
systemctl is-active cockpit.socket  # → active ✅
# Los 4 contenedores deben estar Up automáticamente (restart: always)
docker compose -f /opt/erp-odoo/docker/docker-compose.yml ps
# Odoo accesible
curl -k -I https://erp.odoo.tfg.com   # → HTTP/2 200 ✅
```
### 3.5 Checklist Final Completo del Sistema
```
✅ Red (pfSense)
   ├── 4 interfaces activas
   ├── Reglas por VLAN (bloqueos primero)
   ├── Anti-Lockout desactivado
   └── LDAP auth panel pfSense
✅ Servidor Debian (VLAN 30)
   ├── IP estática 192.168.30.10
   ├── Docker + Cockpit activos
   ├── UFW: solo 22/80/443/9090
   ├── SSH: solo clave pública, sin root
   └── Modo: multi-user.target (headless)
✅ Docker Stack (4 contenedores healthy)
   ├── odoo_erp    → PostgreSQL 16 (solo red interna)
   ├── odoo-web    → Odoo 17 CE (MACVLAN .21)
   ├── openldap    → OpenLDAP 1.5.0 (MACVLAN .22)
   └── nginx-proxy → Nginx Alpine (MACVLAN .20)
✅ Odoo
   ├── Empresa: TechSolutions S.L.
   ├── Módulos: CRM, Ventas, RRHH, Inventario, auth_ldap
   ├── Usuarios: 10 creados con roles
   └── Auditoría SQL: trigger en res_users
✅ LDAP
   ├── ACLs aplicadas (mínimo privilegio)
   ├── Usuarios de empleados creados
   ├── Login Odoo con credencial LDAP ✅
   └── Login PCs VLAN 10 con credencial LDAP ✅
✅ CI/CD
   ├── Runner activo (Idle en GitHub)
   └── Pipeline: git push → CI → CD → contenedores actualizados
✅ Mantenimiento
   ├── Backup diario 02:00
   ├── Monitor cada 15 min
   └── Update imágenes domingos 03:00
```
---
**← Volver al índice:** [`docs/INSTALACION_COMPLETA.md`](../INSTALACION_COMPLETA.md)
*TFG ASIR 2025/2026 — IES Cañaveral*
```

### File: .\docs\guias\INSTALACION_RED.md
```md
# Guía de Red — pfSense: Firewall, DHCP, DNS y VLAN 40
**← Volver a:** [`docs/INSTALACION_COMPLETA.md`](../INSTALACION_COMPLETA.md)
> [!IMPORTANT]
> pfSense debe configurarse **antes** que cualquier otro componente.
> Es el firewall, router, DHCP y servidor DNS de toda la infraestructura.
> [!TIP]
> **¿Quieres automatizar?** El script `scripts/deploy/generate_pfsense_config.sh` genera un
> `config.xml` completo con todas las interfaces, DHCP, DNS, NAT y reglas de firewall documentadas
> a continuación. Impórtalo en **Diagnostics → Backup/Restore** y salta a la [sección 10](#10-autenticación-ldap-en-el-panel-pfsense).
> También disponible como artefacto descargable en el pipeline CI de GitHub Actions.
---
## 1. Crear la VM pfSense en VirtualBox
### Parámetros de la VM
| Campo | Valor |
|:------|:------|
| Nombre | `pfSense-TFG` |
| Tipo | BSD → FreeBSD (64-bit) |
| RAM | 1024 MB |
| CPU | 1 core |
| Disco | 10 GB (VDI, dinámico) |
### Adaptadores de red (¡orden importante!)
| Adaptador | Modo VirtualBox | Interfaz pfSense | Subred |
|:----------|:----------------|:-----------------|:-------|
| Adaptador 1 | **NAT** | `vtnet0` → **WAN** | Internet |
| Adaptador 2 | **Red Interna** → `LAN_10` | `vtnet1` → **LAN** | VLAN 10 clientes (192.168.10.0/24) |
| Adaptador 3 | **Red Interna** → `DMZ_30` | `vtnet2` → **OPT1** | VLAN 30 DMZ (192.168.30.0/24) |
| Adaptador 4 | **Red Interna** → `ADMIN_40` | `vtnet3` → **OPT2** | VLAN 40 admin (192.168.40.0/24) |
> [!NOTE]
> Las otras VMs deben usar los **mismos nombres** de red interna (`LAN_10`, `DMZ_30`, `ADMIN_40`) para que estén en la misma red virtual.
---
## 2. Instalar pfSense
1. Arrancar la VM con la ISO adjunta como unidad óptica
2. Seleccionar **Install pfSense** → aceptar licencia
3. Seleccionar **Auto (UFS)** → **Continue** → esperar instalación (~2 min)
4. **Reboot** → retirar la ISO antes del reinicio
---
## 3. Asignación de Interfaces (Primera Consola)
Al arrancar aparece el asistente de texto. Opción **1 (Assign Interfaces)**:
```
Should VLANs be set up now? → n
Enter the WAN interface name:      vtnet0
Enter the LAN interface name:      vtnet1
Enter the Optional 1 interface:    vtnet2
Enter the Optional 2 interface:    vtnet3
Do you want to proceed? → y
```
Opción **2 (Set Interface IP Addresses)**:
- **LAN** → IP `192.168.10.1`, máscara `/24`, habilitar DHCP: SÍ, rango `192.168.10.100–200`
- **OPT1 (DMZ)** → IP `192.168.30.1`, máscara `/24`, DHCP: NO
La WAN recibe IP por DHCP de VirtualBox automáticamente.
---
## 4. Acceso a la Interfaz Web
Desde una VM conectada a `LAN_10`:
```
URL:      https://192.168.10.1
Usuario:  admin
Password: pfsense  (cambiar en el primer login)
```
Asistente inicial: hostname `pfsense`, dominio `tfg.com`, timezone `Europe/Madrid`, cambiar contraseña.
---
## 5. Configurar Interfaz OPT2 (VLAN 40 — Administración)
*Interfaces → Assignments → añadir `vtnet3` → Guardar*
Ir a *Interfaces → OPT2*:
| Campo | Valor |
|:------|:------|
| Enable | ✅ |
| Description | `VLAN_ADMIN` |
| IPv4 Configuration Type | Static IPv4 |
| IPv4 Address | `192.168.40.1 / 24` |
**Save** → **Apply Changes**
---
## 6. DHCP por Interfaz
### DHCP LAN (VLAN 10) — *Services → DHCP Server → LAN*
| Campo | Valor |
|:------|:------|
| Enable | ✅ |
| Range | `192.168.10.100 – 192.168.10.200` |
| Gateway | `192.168.10.1` |
| DNS Server 1 | `192.168.10.1` |
### DHCP OPT2 (VLAN 40) — *Services → DHCP Server → OPT2*
| Campo | Valor |
|:------|:------|
| Enable | ✅ |
| Range | `192.168.40.10 – 192.168.40.50` |
| DNS Server 1 | `192.168.40.1` |
> La DMZ (VLAN 30) **no usa DHCP**. El servidor Debian tiene IP estática.
---
## 7. DNS Resolver — Host Override para Odoo
*Services → DNS Resolver → General Settings*: habilitar en LAN, OPT1, OPT2, Localhost.
*Services → DNS Resolver → Host Overrides → + Add*:
| Campo | Valor |
|:------|:------|
| Host | `erp.odoo` |
| Domain | `tfg.com` |
| IP Address | `192.168.30.10` |
| Description | `Servidor Odoo ERP — DMZ` |
**Save** → **Apply Changes**
---
## 8. NAT — Port Forwarding
*Firewall → NAT → Port Forward*
### WAN → Nginx (acceso público a Odoo)
| Interfaz | Proto | Puerto entrada | Redirige a | Puerto destino |
|:---:|:---:|:---:|:---|:---:|
| WAN | TCP | 80 | `192.168.30.10` | 80 |
| WAN | TCP | 443 | `192.168.30.10` | 443 |
### Forzar DNS interno (interceptar consultas externas)
| Interfaz | Proto | Source | Destino | Puerto | Redirige a |
|:---:|:---:|:---|:---:|:---:|:---|
| LAN | TCP/UDP | `192.168.10.0/24` | Any | 53 | `192.168.10.1` |
| OPT2 | TCP/UDP | `192.168.40.0/24` | Any | 53 | `192.168.40.1` |
> **Por qué es necesario:** Clientes Linux con `systemd-resolved` pueden ignorar el DNS del DHCP y consultar a 8.8.8.8. Esta regla intercepta cualquier consulta DNS y la redirige a pfSense, garantizando que `erp.odoo.tfg.com` resuelva siempre a `192.168.30.10`.
### NAT Outbound — *Firewall → NAT → Outbound → Modo: Automatic*
Con modo automático, pfSense aplica NAT a todas las subnets internas automáticamente.
---
## 9. Reglas de Firewall
> [!IMPORTANT]
> El orden de las reglas es **crítico**. pfSense evalúa de arriba a abajo y aplica la **primera que coincide**.
> Los bloqueos siempre van **antes** que los permisos.
### WAN
| # | Acción | Proto | Origen | Destino | Puerto | Descripción |
|:-:|:------:|:-----:|:-------|:--------|:------:|:------------|
| 1 | ❌ Block | * | Redes RFC 1918 | * | * | Block private networks *(auto)* |
| 2 | ❌ Block | * | Redes Bogon | * | * | Block bogon networks *(auto)* |
| 3 | ✅ Pass | TCP | * | WAN address | 80 | HTTP público |
| 4 | ✅ Pass | TCP | * | WAN address | 443 | HTTPS público |
| 5 | ❌ Block | * | * | * | * | **Deny all** ← ¡último! |
> Las reglas 1 y 2 se activan en *Interfaces → WAN* marcando "Block private networks" y "Block bogon networks".
### LAN (VLAN 10 — Clientes)
> [!WARNING]
> La **"Default allow LAN to any"** debe estar **desactivada** (en gris/tachada).
| # | Acción | Proto | Origen | Destino | Puerto | Descripción |
|:-:|:------:|:-----:|:-------|:--------|:------:|:------------|
| 1 | ❌ Block | * | LAN | `192.168.40.0/24` | * | **Bloquear VLAN Admin** ← ¡primero! |
| 2 | ❌ Block | * | LAN | `192.168.30.10` | 22 | Bloquear SSH al servidor |
| 3 | ❌ Block | * | LAN | `192.168.30.10` | 9090 | Bloquear Cockpit |
| 4 | ❌ Block | * | LAN | `192.168.30.22` | 636 | Bloquear LDAPS admin |
| 5 | ❌ Block | * | LAN | `192.168.30.0/24` | 5432 | Bloquear PostgreSQL |
| 6 | ~~Pass~~ | * | LAN subnets | * | * | ~~Default allow~~ *(desactivar)* |
| 7 | ✅ Pass | TCP | LAN subnets | `192.168.30.10` | 80 | Odoo HTTP vía Nginx |
| 8 | ✅ Pass | TCP | LAN subnets | `192.168.30.10` | 443 | Odoo HTTPS vía Nginx |
| 9 | ✅ Pass | TCP | LAN subnets | `192.168.30.22` | 389 | LDAP auth readonly |
| 10 | ✅ Pass | * | LAN subnets | * | * | Navegación Internet |
| 11 | ❌ Block | * | * | * | * | **Deny all** ← ¡último! |
### OPT1 (DMZ / VLAN 30)
| # | Acción | Proto | Origen | Destino | Puerto | Descripción |
|:-:|:------:|:-----:|:-------|:--------|:------:|:------------|
| 1 | ❌ Block | * | DMZ | `192.168.10.0/24` | * | **Anti-pivoting a VLAN 10** ← ¡primero! |
| 2 | ❌ Block | * | DMZ | `192.168.10.1` | * | DMZ no accede a pfSense LAN |
| 3 | ❌ Block | * | DMZ | `192.168.40.0/24` | * | **Anti-pivoting a VLAN Admin** |
| 4 | ✅ Pass | TCP | DMZ | * | 80 | Actualizaciones HTTP |
| 5 | ✅ Pass | TCP | DMZ | * | 443 | Actualizaciones HTTPS |
| 6 | ✅ Pass | UDP | DMZ | * | 53 | DNS resolución |
| 7 | ❌ Block | * | * | * | * | **Deny all** ← ¡último! |
### OPT2 (VLAN 40 — Admin)
| # | Acción | Proto | Origen | Destino | Puerto | Descripción |
|:-:|:------:|:-----:|:-------|:--------|:------:|:------------|
| 1 | ✅ Pass | TCP | VLAN 40 | `This Firewall` | 443 | **Panel pfSense** ← exclusivo |
| 2 | ✅ Pass | TCP | VLAN 40 | `192.168.30.10` | 22 | SSH al servidor Debian |
| 3 | ✅ Pass | TCP | VLAN 40 | `192.168.30.10` | 9090 | Cockpit |
| 4 | ✅ Pass | TCP | VLAN 40 | `192.168.30.20` | 443 | Nginx/Odoo admin completo |
| 5 | ✅ Pass | TCP | VLAN 40 | `192.168.30.22` | 389 | LDAP admin |
| 6 | ✅ Pass | TCP | VLAN 40 | `192.168.30.22` | 636 | LDAPS admin (cifrado) |
| 7 | ✅ Pass | TCP/UDP | VLAN 40 | * | 80, 443, 53 | Internet + DNS |
| 8 | ❌ Block | * | VLAN 40 | `192.168.10.0/24` | * | Anti-pivoting a VLAN 10 |
| 9 | ❌ Block | * | VLAN 40 | * | * | **Deny all** ← ¡último! |
---
## 10. Autenticación LDAP en el Panel pfSense
> Realizar este paso **después** de que el contenedor OpenLDAP esté activo (Fase LDAP).
*System → User Manager → Authentication Servers → + Add*:
| Campo | Valor |
|:------|:------|
| Descriptive name | `OpenLDAP DMZ` |
| Type | LDAP |
| Hostname or IP address | `192.168.30.22` |
| Port value | `389` |
| Transport | TCP - Standard |
| Base DN | `dc=tfg,dc=com` |
| Authentication containers | `ou=usuarios,dc=tfg,dc=com` |
| Bind credentials — User DN | `cn=admin,dc=tfg,dc=com` |
| Bind credentials — Password | `<LDAP_ADMIN_PASSWORD>` |
| User naming attribute | `uid` |
| Group naming attribute | `cn` |
| Group member attribute | `member` |
*System → User Manager → Groups → + Add*:
- Nombre: `admin` → Privilegios: **WebCfg - All pages**
*System → User Manager → Settings → Authentication Server*: `OpenLDAP DMZ` → **Save**
---
## 11. Aislamiento del Panel pfSense — Orden Seguro (Anti-Lockout)
> [!CAUTION]
> Seguir este orden exacto. Si desactivas la Anti-Lockout sin tener acceso VLAN 40,
> **perderás el acceso al firewall** y tendrás que restaurar desde la consola de VirtualBox.
### Paso a paso (desde el PC de administración)
**Desde el PC actual (aún en VLAN 10):**
1. *Interfaces → Assignments* → añadir `vtnet3` como OPT2
2. *Interfaces → OPT2* → habilitar, descripción `VLAN_ADMIN`, IP `192.168.40.1/24` → Save
3. *Services → DHCP Server → OPT2* → habilitar, rango `192.168.40.10–50` → Save
4. *Firewall → Rules → OPT2* → añadir regla temporal: Pass, Any, OPT2 subnets → Any → Save
**Mover el PC de administración a la red ADMIN_40 en VirtualBox:**
5. En VirtualBox: configuración de red del PC admin → cambiar a `ADMIN_40`
6. En el PC admin, refrescar IP:
   ```bash
   sudo dhclient -r && sudo dhclient
   ip a   # Debe mostrar 192.168.40.x
   ```
7. Abrir `https://192.168.40.1` → verificar acceso al panel pfSense
8. Aplicar las reglas definitivas de OPT2 (sección 9)
**Desactivar Anti-Lockout (solo tras confirmar acceso desde VLAN 40):**
9. *System → Advanced → Admin Access* → marcar **Disable webConfigurator anti-lockout rule** → Save
**Verificar aislamiento:**
```bash
# Desde el PC admin en VLAN 40 (debe funcionar)
curl -k https://192.168.40.1       # → Panel pfSense ✅
ssh usuario@192.168.30.10          # → SSH al servidor ✅
# Desde un PC en VLAN 10 (debe fallar)
curl -k https://192.168.10.1       # → Sin respuesta ✅
```
---
## 12. Checklist de Verificación pfSense
```
✅ Interfaces asignadas
   ├─ WAN  → IP externa (DHCP/NAT de VirtualBox)
   ├─ LAN  → 192.168.10.1/24  (VLAN 10 clientes)
   ├─ OPT1 → 192.168.30.1/24  (VLAN 30 DMZ)
   └─ OPT2 → 192.168.40.1/24  (VLAN 40 admin)
✅ DHCP
   ├─ LAN  → 192.168.10.100–200, DNS 192.168.10.1
   └─ OPT2 → 192.168.40.10–50,  DNS 192.168.40.1
✅ Firewall Rules (bloqueos ANTES que permisos)
   ├─ WAN  → solo 80/443 + deny all
   ├─ LAN  → bloqueos admin primero + Odoo/Internet + deny all
   ├─ OPT1 → anti-pivoting primero + salida mínima + deny all
   └─ OPT2 → panel pfSense + SSH/Cockpit/LDAP + deny all
✅ NAT Port Forward
   ├─ WAN:80  → 192.168.30.10:80
   ├─ WAN:443 → 192.168.30.10:443
   ├─ LAN DNS:53  → 192.168.10.1
   └─ OPT2 DNS:53 → 192.168.40.1
✅ DNS Resolver — Host Override: erp.odoo.tfg.com → 192.168.30.10
✅ LDAP auth en pfSense (grupo admin con WebCfg - All pages)
✅ Anti-Lockout desactivado (tras confirmar acceso desde VLAN 40)
```
---
**→ Siguiente:** [`INSTALACION_SERVIDOR.md`](INSTALACION_SERVIDOR.md) — Debian + Docker + Odoo
**Referencia completa de reglas:** [`../reglas_pfsense.md`](../reglas_pfsense.md)
```

### File: .\docs\guias\INSTALACION_SERVIDOR.md
```md
# Guía del Servidor — Debian + Docker + Odoo
**← Volver a:** [`docs/INSTALACION_COMPLETA.md`](../INSTALACION_COMPLETA.md)
**← Fase anterior:** [`guias/INSTALACION_RED.md`](INSTALACION_RED.md)
---
## PARTE 1 — Debian 13: Preparación del Servidor
### 1.1 Crear la VM Debian en VirtualBox
| Campo | Valor |
|:------|:------|
| Nombre | `Debian-Servidor-TFG` |
| Tipo | Linux → Debian (64-bit) |
| RAM | **4096 MB** mínimo |
| CPU | **2 cores** mínimo |
| Disco | **40 GB** (VDI, dinámico) |
| Adaptador de red | **Red Interna** → `DMZ_30` |
### 1.2 Instalar Debian 13
1. Arrancar con ISO de Debian 13 → **Graphical Install**
2. Idioma: Español | País: España | Teclado: Español
3. Hostname: `debian-erp` | Domain: `tfg.com`
4. Crear usuario `root` y usuario normal (ej. `servidor`)
5. Particionado: **Utilizar disco completo** (guiado)
6. Software: ✅ `GNOME` + ✅ `SSH server` + ✅ `standard system utilities`
> GNOME se instalará ahora para facilitar el diagnóstico. Se eliminará en la fase de Hardening.
> Debian 13 (Trixie) usa systemd-networkd por defecto — la configuración de IP estática
> puede hacerse también con `nmcli` o `nmtui` si la ISO incluye Network Manager.
### 1.3 Configurar IP Estática
```bash
sudo nano /etc/network/interfaces
```
```
auto ens18
iface ens18 inet static
    address 192.168.30.10
    netmask 255.255.255.0
    gateway 192.168.30.1
    dns-nameservers 192.168.30.1
```
> El nombre de la interfaz puede variar. Compruébalo con `ip link show` (`ens18`, `eth0`, `enp0s3`...).
```bash
sudo systemctl restart networking
ip addr show   # Debe mostrar: inet 192.168.30.10/24
ping -c 3 192.168.30.1   # Gateway pfSense responde
```
### 1.4 Actualizar e Instalar Dependencias Base
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl wget openssl ca-certificates gnupg lsb-release net-tools ldap-utils
```
### 1.5 Instalar Docker
> [!NOTE]
> En Debian 13 (Trixie) el paquete `docker.io` puede no estar en los repos oficiales todavía.
> Se recomienda instalar desde el repositorio oficial de Docker:
```bash
# Instalar dependencias necesarias
sudo apt install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
# Agregar clave GPG oficial de Docker
sudo curl -fsSL https://download.docker.com/linux/debian/gpg \
  -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
# Añadir el repositorio oficial de Docker (Trixie)
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/debian \
  trixie stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
# Instalar Docker Engine + Compose
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo systemctl enable docker && sudo systemctl start docker
sudo usermod -aG docker $USER
newgrp docker   # Aplicar sin cerrar sesión
docker --version && docker compose version
docker run --rm hello-world   # Prueba rápida
```
### 1.6 Instalar Cockpit
```bash
sudo apt install -y cockpit
sudo systemctl enable cockpit.socket && sudo systemctl start cockpit.socket
```
Acceder desde VLAN 40: `https://192.168.30.10:9090`
### 1.7 Clonar el Repositorio
```bash
sudo git clone \
    https://github.com/sandrafrv/TFG-Implantacion_Segura_y_Automatizada_de_Odoo.git \
    /opt/erp-odoo
sudo chown -R $USER:$USER /opt/erp-odoo
cd /opt/erp-odoo
```
### 1.8 Crear el Archivo `.env` con Credenciales
```bash
cp .env.example docker/.env
nano docker/.env   # Editar con contraseñas reales
chmod 600 docker/.env
```
El `.env` debe quedar así (con contraseñas **reales**, no los ejemplos):
```bash
POSTGRES_USER=odoo
POSTGRES_PASSWORD=<contraseña_segura_postgres>
POSTGRES_DB=odoo_erp
ODOO_MASTER_PASSWORD=<contraseña_maestra_odoo>
LDAP_ADMIN_PASSWORD=<contraseña_admin_ldap>
LDAP_READONLY_PASSWORD=<contraseña_readonly_ldap>
LDAP_DOMAIN=tfg.com
LDAP_BASE_DN=dc=tfg,dc=com
LDAP_ORG=TechSolutions SL
```
> [!CAUTION]
> **Nunca hagas `git add docker/.env`**. Está en `.gitignore`, pero verifica siempre con `git status` antes de hacer commit.
### 1.9 Alternativa: Instalador Todo-en-Uno
Los pasos 1.4 a 1.8 se pueden automatizar con:
```bash
cd /opt/erp-odoo
chmod +x install.sh
sudo ./install.sh
```
El instalador hace: dependencias → Cockpit → Docker → estructura de dirs → SSL → `.env` interactivo → deploy → cron.
---
## PARTE 2 — Stack Docker: PostgreSQL + Odoo + LDAP + Nginx
### 2.1 Arquitectura de Contenedores
```
Red interna Docker: odoo_net (bridge)
  odoo_erp (PostgreSQL) ← odoo-web (Odoo) ← nginx-proxy (Nginx)
  openldap  ─────────────────────────────────────────────────────
Redes MACVLAN (IPs físicas en DMZ):
  nginx-proxy → 192.168.30.20
  odoo-web    → 192.168.30.21
  openldap    → 192.168.30.22
  odoo_erp    → sin IP MACVLAN (solo red interna, por seguridad)
```
### 2.2 Crear la Red MACVLAN
```bash
# Detectar la interfaz de red activa
ip link show   # Buscar ens18 o la interfaz conectada a la DMZ
# Crear la red MACVLAN (una sola vez, persiste en Docker)
docker network create \
  --driver macvlan \
  --subnet=192.168.30.0/24 \
  --gateway=192.168.30.1 \
  --opt parent=ens18 \
  macvlan_vlan30
docker network ls | grep macvlan   # Verificar
```
> [!WARNING]
> **Limitación del kernel Linux con macvlan:** el host Debian **no puede hacer ping** a las IPs MACVLAN de sus propios contenedores. Para verificar, usa un contenedor temporal:
> ```bash
> docker run --rm --network macvlan_vlan30 alpine \
>   wget -qO- --no-check-certificate https://192.168.30.20 | head -5
> ```
### 2.3 Generar Certificados SSL
Si no usaste `install.sh`:
```bash
sudo mkdir -p /opt/erp-odoo/certs
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /opt/erp-odoo/certs/erp.key \
    -out    /opt/erp-odoo/certs/erp.crt \
    -subj "/C=ES/ST=Madrid/L=Madrid/O=TechSolutions/CN=erp.odoo.tfg.com"
ls /opt/erp-odoo/certs/   # → erp.crt  erp.key
```
### 2.4 Levantar el Stack Docker
```bash
cd /opt/erp-odoo
docker compose -f docker/docker-compose.yml up -d
# Seguir el arranque en tiempo real (Ctrl+C para salir)
docker compose -f docker/docker-compose.yml logs -f
```
> ⏱️ El **primer arranque de Odoo puede tardar 2–5 minutos** mientras inicializa la base de datos PostgreSQL. Es normal.
### 2.5 Verificar Estado de Contenedores
```bash
docker compose -f docker/docker-compose.yml ps
```
Resultado esperado (todos `Up (healthy)`):
```
NAME          IMAGE                  STATUS
odoo_erp      postgres:16            Up (healthy)
odoo-web      odoo:17                Up (healthy)
openldap      osixia/openldap:1.5.0  Up (healthy)
nginx-proxy   nginx:alpine           Up (healthy)
```
### 2.6 Solución de Problemas Comunes
| Error | Causa | Solución |
|:------|:------|:---------|
| `password authentication failed` | `.env` con contraseñas incorrectas o datos de BD anterior | `docker compose down` → borrar `data/postgres-data/` → recrear `.env` → `docker compose up -d` |
| Nginx en bucle de reinicios | Certificados con nombre incorrecto | Verificar `grep ssl_certificate config_nginx/*.conf` y regenerar con ese nombre |
| `dubious ownership` en git | `/opt/erp-odoo` creado por root, runner usa otro usuario | `git config --global --add safe.directory /opt/erp-odoo` |
| Puerto 80/443 en uso | Contenedor nginx en estado corrupto | `docker compose down --remove-orphans && docker compose up -d --force-recreate` |
### 2.7 Instalar Cron de Mantenimiento
```bash
bash /opt/erp-odoo/scripts/deploy/install_cron.sh
cat /etc/cron.d/erp-odoo   # Verificar 3 tareas instaladas
```
| Tarea | Horario | Script |
|:------|:--------|:-------|
| Backup PostgreSQL | Diario 02:00 | `mantenimiento/backup.sh` |
| Monitor de salud | Cada 15 min | `mantenimiento/monitor.sh` |
| Actualizar imágenes | Domingo 03:00 | `mantenimiento/update.sh` |
---
## PARTE 3 — Post-instalación de Odoo
### 3.1 Asistente de Configuración
```bash
bash /opt/erp-odoo/scripts/odoo/odoo_setup_wizard.sh
```
El asistente realiza 4 pasos:
1. **Renombrar empresa** → "My Company" → "TechSolutions S.L." (UPDATE en BD)
2. **Instalar módulos** → CRM, Ventas, RRHH, Inventario, `auth_ldap` (obligatorio)
3. **Configurar LDAP** → detecta IP del contenedor OpenLDAP, configura `cn=readonly`
4. **Restricción** (opcional) → elimina contraseñas locales (solo admin conserva la suya)
> ⏱️ La instalación de módulos puede tardar 2–5 minutos.
### 3.2 Crear Usuarios Odoo con Roles
```bash
bash /opt/erp-odoo/scripts/odoo/odoo_crear_usuarios.sh
```
| Usuario | Rol | Módulos visibles | Tipo Odoo |
|:--------|:----|:----------------|:----------|
| `becario@erp.odoo.tfg.com` | Becario | Solo CRM (lectura) | Interno |
| `ventas@erp.odoo.tfg.com` | Ventas | CRM + Ventas + Facturas | Interno |
| `rrhh@erp.odoo.tfg.com` | RRHH | RRHH + Empleados | Interno |
| `almacen@erp.odoo.tfg.com` | Almacén | Inventario + Compras | Interno |
| `tecnico@erp.odoo.tfg.com` | Técnico | Inventario + Soporte | Interno |
| `jefe.ventas@erp.odoo.tfg.com` | Jefe Ventas | Ventas completo + aprobaciones | Interno |
| `jefe.rrhh@erp.odoo.tfg.com` | Jefe RRHH | RRHH completo + aprobaciones | Interno |
| `jefe.almacen@erp.odoo.tfg.com` | Jefe Almacén | Almacén completo + aprobaciones | Interno |
| `api.user@erp.odoo.tfg.com` | API | Solo XML-RPC | Interno |
| `dba@erp.odoo.tfg.com` | DBA | Sin UI (solo BD) | Interno |
> [!WARNING]
> Las contraseñas se generan aleatoriamente y se muestran **una sola vez**. Guárdalas inmediatamente.
### 3.3 Auditoría SQL en PostgreSQL *(Opcional)*
```bash
# Aplicar triggers de auditoría
docker exec -i odoo_erp psql -U odoo -d odoo_erp \
    < /opt/erp-odoo/sql/audit_triggers.sql
# Verificar que funciona
docker exec -it odoo_erp psql -U odoo -d odoo_erp \
    -c "SELECT * FROM v_audit_resumen;"
```
El script crea:
- **Tabla** `asir_audit_log` — snapshot JSONB de cada usuario creado
- **Trigger** `trg_audit_new_odoo_user` en `res_users`
- **Vista** `v_audit_resumen` para consultas rápidas
### 3.4 Verificación Completa del Servidor
```bash
# Contenedores activos
docker compose -f docker/docker-compose.yml ps
# Odoo responde
curl -k -I https://erp.odoo.tfg.com   # → HTTP/2 200
# PostgreSQL bloqueado desde fuera (verificar desde cliente VLAN 10)
nc -zv 192.168.30.10 5432             # → Timeout ✅
# Empresa renombrada
docker exec -it odoo_erp psql -U odoo -d odoo_erp \
    -c "SELECT name FROM res_company WHERE id=1;"
# → TechSolutions S.L. ✅
# Módulo auth_ldap instalado
docker exec -it odoo_erp psql -U odoo -d odoo_erp \
    -c "SELECT name, state FROM ir_module_module WHERE name='auth_ldap';"
# → auth_ldap | installed ✅
```
---
**→ Siguiente:** [`guias/INSTALACION_LDAP_CICD_HARDENING.md`](INSTALACION_LDAP_CICD_HARDENING.md) — LDAP + CI/CD + Hardening
```

### File: .\docs\mas_info\informe_erp.md
```md
# **Informe final de prácticas** **Proyecto 2 – Implementación y** **centralización de sistemas de gestión** **ERP/CRM**
## Damaris Antonela Antón Oltean
# **Introducción**
En este proyecto he montado un ERP para VRCardio / Spika Tech con Odoo Community 16, empezando
desde un entorno de pruebas en local hasta dejarlo desplegado en la nube. Primero probé Odoo con
Docker y lo comparé con Dolibarr y ERPNext para decidir qué sistema encajaba mejor.​
Una vez elegido Odoo, configuré la infraestructura sobre una instancia de AWS con Odoo y PostgreSQL
en contenedores Docker, Nginx como proxy inverso con HTTPS y un sistema de copias de seguridad
automáticas. Sobre ese Odoo de producción he ido activando y ajustando los módulos de Ventas, CRM,
Proyectos, RRHH e Inventario, definiendo el pipeline comercial (Lead → Contacto → Demo → Cierre),
modelando las licencias como productos de servicio y creando las primeras integraciones con scripts en
Python usando la API XML‑RPC.
# **Semana 1 - Levantamiento de Requisitos y** **Odoo Base**
## **Introducción**
**Objetivo de la semana:** Configurar un entorno de pruebas con Odoo Community Edition 16 y evaluar
los módulos principales para cubrir los procesos de ventas, facturación, inventario y gestión de proyectos
de VRCardio.
## **Requisitos básicos de VRCardio para el ERP**
En el menú **Aplicaciones** he instalado los módulos que necesito para cubrir los requisitos de la práctica.
Estos son los que he activado y para qué los voy a usar:
**Ventas** : para crear presupuestos y pedidos de venta de las licencias de VRCardio y servicios
relacionados.
**Facturación** : para generar y validar las facturas a partir de los pedidos de venta.
**CRM** : para llevar el seguimiento de leads y oportunidades (hospitales interesados, demos, etc.).
**Inventario** : para definir los productos y servicios, en este caso las licencias de VRCardio (como
productos de tipo servicio).
**Proyecto** : para crear proyectos de implantación y desarrollo, con sus tareas y responsables.
**Empleados** : para gestionar la información básica de los empleados y preparar la parte de RRHH.
**Contactos** : para dar de alta hospitales y personas de contacto.
**Calendario** : para planificar reuniones, demos y eventos.
**Sitio web** : como base para una posible web/portal más adelante.
**Conversaciones (chat)** : para comunicación interna básica entre usuarios dentro de Odoo.
1
## **Despliegue de Odoo 16 Community en sandbox**
Para el entorno de pruebas he montado Odoo Community 16 con Docker, junto a una base de datos
#### **1. Preparar la carpeta del proyecto y subcarpetas**
#### **2. Crear fichero docker-compose.yml dentro de la carpeta** **semana1 odoo sandbox**
2
```
 services:
  db:
  image: postgres:15
  restart: always
  environment:
  - POSTGRES_DB=postgres
  - POSTGRES_USER=odoo
  - POSTGRES_PASSWORD=odoo123
  volumes:
  - ./odoo-db-data:/var/lib/postgresql/data # Guarda la BBDD en esta carpeta
  odoo:
  image: odoo:16
  restart: always
  depends_on:
  - db
  ports:
  - "8069:8069"
  environment:
  - DB_HOST=db
  - DB_USER=odoo
  - DB_PASSWORD=odoo123
  volumes:
  - ./addons:/mnt/extra-addons # Conecta la carpeta addons
  - ./config:/etc/odoo # Conecta la carpeta config
```
_Nota: las credenciales son simples ya que se trata de un entorno de pruebas (sandbox). En_
_producción se usarían variables de entorno seguras._
#### **3. Crear fichero odoo.conf**
En la carpeta /config
```
 nano odoo.conf
```
3
```
 [options]
  addons_path = /mnt/extra-addons
  data_dir = /var/lib/odoo
  db_host = db
  db_user = odoo
  db_password = odoo123
  db_port = 5432
```
_Nota: Este fichero permite externalizar la configuración del servidor Odoo y facilita futuras_
_modificaciones sin reconstruir la imagen Docker._
#### **4. Iniciar el despliegue**
#### **5. Crear base de datos**
Desde el navegador (http://localhost:8069), he creado la base de datos vrcardio_test con el usuario
administrador.
## **Pruebas Odoo**
#### **Ejemplo 1: Cliente (hospital) en Contactos**
Ruta: Contactos → Nuevo
**Nombre** : Hospital Demo VRCardio
Compañía
**Dirección** : C/ Salud 123, 28001 Madrid, España
**NIF** : B12345678
**Teléfono** : 910 000 111
**Móvil** : 600 000 222
**Correo electrónico** : contacto@hospitaldemo.com
**Sitio web** : https://www.hospitaldemo.com
**Etiquetas** : Hospital, Cliente VRCardio
4
#### **Ejemplo 2: Producto Licencia VRCardio Anual**
Ruta: Inventario → Productos → Nuevo
**Nombre del producto** : Licencia VRCardio Anual
Puede ser vendido
**Tipo de producto** : Servicio
**Precio de venta** : 5000
**Impuestos del cliente** : IVA 21 %
**Categoría de producto** : Licencias VR
**Referencia interna** : LIC-VRC-ANUAL
**Notas internas** : Licencia anual de VRCardio para un hospital
#### **Ejemplo 3: Presupuesto de venta**
Ruta: Ventas → Pedidos → Presupuesto de venta → Nuevo
**Cliente** : Hospital Demo VRCardio
**Línea de pedido** :
Producto: Licencia VRCardio Anual
Descripción: Licencia anual VRCardio
Cantidad: 1
Precio unitario: 5000 (se rellena solo)
#### **Ejemplo 4: Proyecto de implantación**
Ruta: Proyecto → Nuevo
**Nombre del proyecto** : Implantación VRCardio - Hospital Demo
A continuación, dentro del proyecto, se crea la tarea:
**Nombre de la tarea** : Instalación y configuración inicial
**Personas asignadas** : Administrator
**Cliente** : Hospital Demo VRCardio
**Fecha límite** : 28/02/2026
#### **Ejemplo 5: Empleado de prueba**
Ruta: Empleados → Nuevo
**Nombre** : Técnico VR
**Puesto** : Técnico de implantación
**Correo de trabajo** : tecnico@vrcardio.com
5
## **Conclusiones**
Durante la primera semana se ha conseguido:
1. Identificar los módulos esenciales de Odoo para VRCardio.
2. Montar un entorno de pruebas funcional con Docker y PostgreSQL.
3. Realizar pruebas iniciales de creación de clientes, productos, presupuestos, proyectos y empleados.
4. Próximo paso: comparar los flujos de Odoo con otros ERP.
# **Semana 2 - Despliegue de Alternativas**
## **Introducción**
**Objetivo de la semana:** Desplegar dos alternativas Open Source a Odoo (Dolibarr y ERPNext) en
modo sandbox usando Docker Compose, y preparar una prueba de concepto replicando un flujo clave de
Spika Tech.
## **Selección de alternativas Open Source**
Para comparar Odoo con otras soluciones ERP libres, he seleccionado:
**Dolibarr ERP & CRM** : ERP ligero, modular y orientado a pymes, con módulos de ventas,
facturación, proyectos y otros similares a los de Odoo.
**ERPNext** : ERP más completo, con módulos de contabilidad, proyectos, CRM, soporte y otros
procesos empresariales avanzados.
Ambas herramientas cuentan con imágenes oficiales o repositorios preparados para Docker, lo que
facilita su despliegue rápido en un entorno de pruebas.
## **Despliegue de Dolibarr en sandbox**
Para comparar con Odoo he montado un entorno de pruebas de Dolibarr usando Docker y MariaDB.
Todo está dentro de la carpeta `semana2_dolibarr_sandbox` del proyecto.
#### **1. Preparar la carpeta del proyecto y subcarpetas**
6
_Nota: separo el volumen de base de datos (dolibarr-db) y el de documentos (dolibarr-docs) para_
_poder conservar los datos aunque borre los contenedores y reutilizar el sandbox en otras semanas._
#### **2. Crear fichero docker-compose.yml dentro de la carpeta** **semana2 dolibarr sandbox**
```
 nano docker-compose.yml
```
#### **3. Iniciar el despliegue**
7
Desde el navegador (http://localhost:8081), se puede entrar con el login admin y contraseña admin
(valores por defecto de la imagen oficial).
## **Despliegue de ERPNext en sandbox**
Para ERPNext he elegido un despliegue sencillo usando una imagen Docker “all‑in‑one” (incluye
MariaDB, Redis, Frappe y Nginx en un solo contenedor), suficiente para pruebas y comparativas con
Odoo y Dolibarr. Todo está dentro de la carpeta `semana2_erpnext_sandbox` del proyecto.
#### **1. Preparar la carpeta del proyecto y subcarpetas**
#### **2. Crear fichero docker-compose.yml dentro de la carpeta** **semana2 erpnext sandbox**
```
 nano docker-compose.yml
```
8
#### **3. Iniciar el despliegue**
#### **4. Problemas encontrados**
Durante el despliegue de ERPNext aparecieron varios problemas relacionados con permisos y
configuración inicial del sitio:
**Errores de permisos con el usuario Administrator** : después del asistente inicial, al intentar
_“Method Not Allowed / You are not permitted to access this resource”_ . Esto impedía continuar la
configuración desde la interfaz web.
**Idioma del sistema incorrecto** : al configurar el idioma en el asistente, la interfaz cambiaba a
chino en lugar de aplicar el español. Para forzar el idioma global del sitio a español ejecuté en el
contenedor:
```
 > docker exec -it erpnext15 bash
  > bench --site www.gdjoian.com set-config language es
```
**Creación de un usuario administrador alternativo vía consola** : para recuperar el acceso de
administración, creé un nuevo usuario con permisos de System Manager usando la consola de
Frappe.
9
```
 from frappe.utils.password import update_password
  import frappe
  # crea un usuario nuevo si no existe
  if not frappe.db.exists("User", "admin@vrcardio.local"):
  user = frappe.get_doc({
  "doctype": "User",
  "email": "admin@vrcardio.local",
  "first_name": "Admin VRCardio",
  "enabled": 1,
  "language": "es",
  "time_zone": "Europe/Madrid"
  })
  user.insert(ignore_permissions=True)
  else:
  user = frappe.get_doc("User", "admin@vrcardio.local")
  # asignar rol de administrador (System Manager)
  user.add_roles("System Manager")
  user.save(ignore_permissions=True)
  # establecer contraseña
  update_password("admin@vrcardio.local", "clave$1")
  frappe.db.commit()
  exit()
```
Desde el navegador (http://localhost:8080), el acceso final se hace con el correo admin@vrcardio.local y
contraseña clave$1.
## **Pruebas Dolibarr**
#### **Activación de módulos en Dolibarr**
Antes de realizar las pruebas he habilitado en Dolibarr los módulos necesarios para replicar el flujo
definido en Odoo:
**Terceros** : permite gestionar empresas y contactos (clientes y clientes potenciales), equivalente a los
contactos/clientes de Odoo.
**Presupuestos** : añade el módulo de propuestas comerciales, que usaré para crear el presupuesto de
la licencia VRCardio anual.
**Productos** : habilita la gestión de productos, imprescindible para definir el catálogo de licencias.
10
**Servicios** : complementa al módulo de productos para poder crear la “Licencia VRCardio Anual”
como servicio en lugar de producto físico.
**Proyectos u Oportunidades** : permite crear proyectos y tareas asociadas al cliente, que utilizaré
para documentar la implantación en el hospital.
Con estos módulos activos, se facilitará la comparación de los flujos de trabajo.
#### **Configuración de la empresa**
Ruta: Inicio → Configuración → Empresa/Organización → Empresa
**Razón social** : Spika Tech
**Divisa principal** : EUR
**País** : España
**Dirección** : C/ Ejemplo 1, 28001 Madrid, España
**Capital** : 3000
**Tipo de entidad comercial** : Sociedad limitada (o equivalente)
**Objeto de la empresa** : Desarrollo de soluciones VR para salud
En la sección fiscal:
**Mes de inicio de ejercicio** : Enero
**Gestión de IVA** : “Sujeto a IVA”
_Nota: con esta configuración, Dolibarr permite asignar tipos de IVA (por ejemplo, 21 %) a los_
_servicios como “Licencia VRCardio Anual” y usar correctamente los impuestos en presupuestos y_
_facturas._
#### **Ejemplo 1: Cliente (hospital) como Tercero**
Ruta: Terceros → Nuevo tercero → Cliente
**Nombre** : Hospital Demo VRCardio
Tipo: Cliente
**Dirección** : C/ Salud 123, 28001 Madrid, España
**Teléfono** : 910 000 111
**Móvil** : 600 000 222
**Sitio web** : https://www.hospitaldemo.com
**Correo electrónico** : contacto@hospitaldemo.com
**NIF/CIF** : B12345678
**Tipo de tercero** : Gran empresa
#### **Ejemplo 2: Producto Licencia VRCardio Anual**
Ruta: Productos/Servicios → Nuevo servicio
**Ref. producto** : LIC-VRC-ANUAL
11
**Etiqueta** : Licencia VRCardio Anual
**Descripción** : Licencia anual de VRCardio para un hospital
**Precio de venta** : 5000
**Tasa IVA** : 21 %
#### **Ejemplo 3: Proyecto de implantación**
Ruta: Proyectos → Nueva oportunidad o proyecto
**Ref.** : PROJ-VRC-001
**Etiqueta** : Implantación VRCardio - Hospital Demo
**Uso** : SIga las tareas o el tiempo dedicado
**Tercero** : Hospital Demo VRCardio
**Estado** : Activo
**Presupuesto** : 5000
**Fecha** : 06/02/2026 a 28/02/2026
**Descripción** : Proyecto de implantación de VRCardio en Hospital Demo
**Visibilidad** : Contactos asignados
**Asignarme como contacto con el tipo** : Jefe de proyecto
#### **Ejemplo 4: Presupuesto de venta (Propuesta comercial)**
Ruta: Comercial → Presupuestos → Nuevo presupuesto
**Cliente** : Hospital Demo VRCardio
**Fecha presupuesto** : 06/02/2026
**Duración de validez** : 30
**Condiciones de pago** : 30 días
**Forma de pago** : Transferencia bancaria
**Proyecto** : PROJ-VRC-001
**Nota (pública)** : Presupuesto de licencia anual VRCardio para Hospital Demo VRCardio
**Añadir nueva línea** :
Productos/servicios predefinidos: LIC-VRC-ANUAL
Taxes: 21 %
P.U.: 5000
Cant.: 1
#### **Ejemplo 5: Empleado de prueba**
Ruta: Configuración → Usuarios y grupos → Nuevo usuario
**Apellido** : Técnico
**Login** : tecnico.vr
**Administrador de sistema** : No
12
**Supervisor** : SuperAdmin
**Contraseña** : AXuaCybHJWDP (por defecto)
**Correo** : tecnico@vrcardio.com
**Puesto de trabajo** : Técnico VR
## **Pruebas ERPNext**
#### **Ejemplo 1: Cliente (hospital)**
Ruta: Ventas → Cliente → Crea tu primer cliente
**Nombre del cliente** : Hospital Demo VRCardio
**Tipo de Cliente** : Compañía
**ID de Correo Electrónico** : contacto@hospitaldemo.com
**Número de teléfono móvil** : 600 000 222
**Dirección línea 1** : C/ Salud 123
**Ciudad** : Madrid
**Estado** : Madrid
**Código postal** : 28001
**País** : Spain
#### **Ejemplo 2: Producto Licencia VRCardio Anual**
Ruta: Almacén → Producto → Crea tu primer producto
**Código del Producto** : LIC-VRC-ANUAL
**Nombre del artículo** : Licencia VRCardio Anual
**Grupo de Productos** : Servicios
**Unidad de Medida** : Unidad
**Precio de venta estándar** : 5000
**Descripcion** : Licencia anual de VRCardio para un hospital
#### **Ejemplo 3: Presupuesto / Sales Order**
Ruta: Ventas → Cotización → Crea tu primer cotización
**Cliente** : Hospital Demo VRCardio
**Fecha** : 06/02/2026
**Válida hasta** : 28/02/2026
**Tipo de orden** : Ventas
En la tabla **Productos** :
**Código del Producto** : LIC-VRC-ANUAL: Licencia anual VRCardio
13
**Cantidad** : 1
**Precio** : 5000 (se rellena automáticamente a partir del producto)
#### **Ejemplo 4: Proyecto de implantación**
Ruta: Proyecto → Proyecto → Crear: Proyecto
**Nombre del Proyecto** : Implantación VRCardio - Hospital Demo
**Fecha prevista de inicio** : 06/02/2026
**Fecha prevista de finalización** : 28/02/2026
**Cliente** : Hospital Demo VRCardio
Dentro del proyecto, crear una tarea:
Ruta: Proyectos → Tarea → +
**Asunto** : Instalación y configuración inicial
**Proyecto** : PROJ-0001
#### **Ejemplo 5: Empleado de prueba**
Ruta: Usuarios → Usuario → Agregar usuario
**Primer Nombre** : Técnico VR
**Género** : Masculino
**Fecha de ingreso** : 06/02/2026
**Fecha de nacimiento** : 16/08/2002
**Compañía** : Spika Tech
## **Conclusiones (Dolibarr y ERPNext)**
Durante la segunda semana se ha conseguido:
1. Replicar en Dolibarr el flujo básico de VRCardio: creación de cliente, servicio (licencia), presupuesto,
proyecto asociado y usuario técnico con permisos limitados.
2. Replicar el mismo flujo en ERPNext: cliente, ítem de servicio, cotización, proyecto con tareas y
empleado/usuario “Técnico VR”.
3. Detectar diferencias de usabilidad y permisos entre ambos ERP (creación de productos, gestión de
proyectos y configuración de roles/RRHH).
4. Próximo paso: documentar comparativamente los flujos de venta e implantación en ambos sistemas y
evaluar cuál encaja mejor con las necesidades de VRCardio.
14
# **Semana 3 - Comparativa Técnica y Funcional**
## **Introducción**
**Objetivo de la semana:** Comparar de forma estructurada Odoo, Dolibarr y ERPNext a partir de los
flujos que ya he probado en las semanas 1 y 2, y decidir qué ERP encaja mejor con las necesidades de
VRCardio y Spika Tech. Para ello se ha elaborado una matriz de decisión con varios criterios (usabilidad,
mantenimiento, API y consumo de recursos en el VPS) y un informe de recomendación técnica,
evaluando facilidad de uso, coste de mantenimiento, flexibilidad de la API y consumo de recursos en el
VPS.
## **Matriz de decisión: Odoo vs Dolibarr vs ERPNext**
A partir de los despliegues y pruebas de las semanas anteriores se ha preparado una matriz de decisión
con los criterios que pide el proyecto. La puntuación es de 1 a 5 (5 = mejor valoración), acompañada de
una breve justificación basada en la experiencia práctica en los flujos de cliente‑licencia‑proyecto.
|Criterio|Odoo|Dolibarr|ERPNext|
|---|---|---|---|
|Facilidad de uso|4 – Interfaz moderna e<br>intuitiva.|3 – Sencillo y directo,<br>algo básico.|3 – Muy completo, algo<br>abrumador.|
|Coste de<br>mantenimiento|3 – Algo de trabajo en<br>módulos y updates.|4 – Fácil de mantener y<br>actualizar.|3 – Más complejo por su<br>arquitectura.|
|Flexibilidad de la API|5 – Muy buena para<br>integraciones.|3 – API limitada, casos<br>simples.|4 – API REST completa,<br>más configuración.|
|Consumo de recursos<br>en el VPS|3 – Requiere servidor<br>decente, pero manejable.|4 – Muy ligero, ideal<br>para VPS pequeños.|2 – Pesado y exigente en<br>recursos.|
|Encaje con VRCardio<br>(flujos)|5 – Cubre bien clientes,<br>proyectos y licencias.|4 – Encaja en flujos<br>básicos.|4 – Potente, quizá más de<br>lo necesario.|
|Uso en móvil|4 – Buena app y versión<br>responsive.|3 – Móvil funcional<br>pero básico.|4 – Experiencia móvil<br>correcta.|
_Nota: las puntuaciones se basan en los escenarios configurados en las semanas 1 y 2 (cliente_
_hospital, licencia VRCardio anual, presupuesto/cotización y proyecto de implantación)._
15
## **Análisis comparativo**
#### **Odoo**
**Ventajas:**
Integración entre módulos (Ventas, CRM, Inventario, Proyectos, RRHH).
API madura y flexible para futuras integraciones con el software VRCardio.
Buena experiencia móvil (app y versión web responsive).
**Desventajas:**
Requiere un VPS con recursos decentes.
Actualizaciones de módulos y mantenimiento algo más complejos.
#### **Dolibarr**
**Ventajas:**
Ligero y fácil de mantener en un VPS.
Permite el flujo básico de clientes, proyectos y licencias VRCardio.
**Desventajas:**
Interfaz menos homogénea y menos pulida.
Funcionalidad más limitada para flujos complejos.
#### **ERPNext**
**Ventajas:**
Muy completo y potente a nivel de proyectos y ventas.
API REST lista para integraciones externas.
**Desventajas:**
Complejidad inicial alta y curva de aprendizaje mayor.
Problemas de permisos e idioma en la configuración inicial.
## **Recomendación técnica**
Teniendo en cuenta los criterios definidos en la matriz de decisión (facilidad de uso, coste de
mantenimiento, flexibilidad de la API y consumo de recursos en el VPS), el sistema que mejor se ajusta al
proyecto es **Odoo Community 16** .
#### **Por qué Odoo es el elegido**
Ofrece una integración muy buena entre módulos clave (Ventas, CRM, Inventario, Proyectos y
RRHH).
16
Dispone de una API madura y flexible, ideal para integrarla con el software VRCardio en el futuro.
Cubre de forma sólida los flujos necesarios: gestión de clientes (hospitales), licencias de software y
proyectos de implantación.
Mantiene un equilibrio razonable entre facilidad de uso y consumo de recursos en el VPS.
Para una empresa como VRCardio, que necesita gestionar licencias de software, proyectos en hospitales y
relaciones comerciales, **Odoo ofrece una base sólida y escalable**, centralizando los procesos y
facilitando la colaboración entre equipos.
## **Conclusiones**
Durante la tercera semana se ha conseguido:
1. Elaborar una matriz de decisión comparando Odoo, Dolibarr y ERPNext según los criterios
solicitados (facilidad de uso, coste de mantenimiento, flexibilidad de la API y consumo de recursos en
el VPS).
2. Analizar las ventajas e inconvenientes de cada ERP a partir de los flujos ya configurados en semanas
anteriores, para justificar la elección del sistema final.
3. Seleccionar Odoo Community 16 como sistema ganador para las siguientes fases del proyecto
(instalación en producción, parametrización y migración de datos).
4. Próximo paso: realizar una instalación limpia de Odoo en el VPS de producción, configurando
PostgreSQL de forma segura y añadiendo HTTPS con Let’s Encrypt y restricciones de acceso.
# **Semana 4 - Infraestructura de Producción**
## **Introducción**
**Objetivo de la semana:** Realizar una instalación limpia de **Odoo Community 16** como sistema ERP
ganador en un entorno de producción, con PostgreSQL configurado de forma más robusta y con medidas
de seguridad básicas (HTTPS y restricciones de acceso), preparándolo para su ejecución definitiva en el
VPS. En vez de ir directamente al VPS, esta semana he montado primero un entorno de “producción
local” en mi portátil usando Docker, como paso intermedio antes del despliegue final.
17
## **Instalación limpia de Odoo Community 16**
#### **Arquitectura de la infraestructura de producción**
La idea es tener cada parte en su sitio: un contenedor para Odoo, otro para PostgreSQL y carpetas en el
host donde se guarda toda la información importante.
**Componentes:**
**Odoo (aplicación):**
**PostgreSQL (base de datos):**
Usuario y contraseña específicos para Odoo ( `odoo_prod` / `odoo_prod_pass` ).
**Carpetas del proyecto (volúmenes):**
para entrar por HTTPS con un nombre de dominio.
_Navegador → Nginx (en el VPS) → Odoo (contenedor, puerto 8069) → PostgreSQL (contenedor,_
_puerto 5432)_
Para no romper nada en producción real, primero he montado este entorno de producción local en el
portátil, separado del sandbox de la semana 1.
#### **1. Preparar la carpeta del proyecto y subcarpetas** **2. Crear fichero docker-compose.yml dentro de la carpeta** **semana4 odoo prod_local**
```
 nano docker-compose.yml
```
18
_Nota: levanta dos contenedores: odoo-prod-db (PostgreSQL 15) y odoo-prod-app (Odoo_
_Community 16), conectados entre sí y con volúmenes persistentes para sus datos._
#### **3. Crear fichero odoo.conf**
En la carpeta /odoo-conf
```
 nano odoo.conf
```
19
_Nota: adminpasswd es la contraseña maestra que pide Odoo cuando creas una base de datos_
_nueva. Los parámetros db* son los datos para que Odoo se conecte al contenedor de PostgreSQL, y_
_data_dir es la carpeta donde Odoo guarda sus archivos internos._
#### **4. Iniciar el despliegue**
En el asistente de Odoo:
**Master Password:** Clave$123
**Database Name:** vrcardio _prod_ local
**Email** : damaris.anton@educa.madrid.org
**Password:** Clave$1
_Nota: no se han cargado datos ficticios, ya que en la próxima fase se trabajará con datos reales_
_proporcionados por la empresa._
#### **5. Problemas encontrados**
Durante el despliegue del entorno de producción local de Odoo aparecieron varios problemas
relacionados con permisos en las carpetas de datos y con el acceso desde el host:
**Internal Server Error al entrar en Odoo:**
Al acceder a http://localhost:8069 Odoo mostraba un “Internal Server Error”. Revisando los logs del
contenedor aparecía un mensaje del tipo:
```
 AssertionError: /var/lib/odoo/sessions: directory is not writable
```
Esto significaba que la carpeta donde Odoo guarda las sesiones (/var/lib/odoo/sessions, que corresponde
al volumen odoo-data) no tenía permisos de escritura para el usuario interno de Odoo (UID 101). Para
20
solucionarlo detuve el contenedor y cambié el propietario de la carpeta:
Después de este cambio Odoo pudo crear las sesiones correctamente y el error 500 desapareció.
**Aviso [error opening dir] en odoo-data y postgres-data al usar tree:**
Al listar la estructura de la carpeta del proyecto con tree aparecían líneas como:
Esto no afectaba al funcionamiento de Odoo ni de PostgreSQL, pero indicaba que mi usuario ubuntu no
tenía permisos para ver el contenido de esas carpetas porque pertenecían a otro UID (por ejemplo, el 101
que usa Odoo dentro del contenedor).
### **`cd ~/proyecto-erp/semana4_odoo_prod_local`** **`sudo chown -R ubuntu:ubuntu odoo-data postgres-data`**
## **Configuración robusta de PostgreSQL**
#### **Usuario y accesos**
En el docker-compose.yml he definido un usuario específico para Odoo:
**Usuario:** odoo_prod
**Contraseña:** odoo _prod_ pass
Esto se pasa al contenedor de PostgreSQL y también lo uso en odoo.conf y en las variables de entorno de
Odoo, para que todo cuadre.
#### **Aislamiento**
El puerto 5432 de PostgreSQL no está publicado hacia fuera, solo se usa dentro de la red de Docker entre
los contenedores. Así evito que alguien se conecte directamente a la base de datos desde fuera; la única
forma de entrar es a través de Odoo.
21
#### **Persistencia de datos**
Los datos de la base se guardan en la carpeta postgres-data. He comprobado que si hago la base
vrcardio _prod_ local sigue existiendo y puedo entrar con normalidad, así que la parte de persistencia
funciona. En el VPS usaré esta misma configuración y allí ya se podrán ajustar parámetros de
rendimiento según la RAM que tenga el servidor.
## **Configuración de HTTPS y restricción de accesos**
Aunque esta semana solo he montado el entorno en mi portátil, he dejado pensado cómo voy a proteger
el ERP cuando lo pase al VPS, usando Nginx, Let’s Encrypt y un firewall.
#### **Nginx como proxy inverso**
En el VPS se añadirá Nginx delante de Odoo con la siguiente lógica:
**Escuchar en los puertos 80 y 443.**
**Redirigir todo el tráfico HTTP (80) a HTTPS (443).**
**Reenviar las peticiones HTTPS al contenedor de Odoo (puerto 8069 interno).**
Ejemplo de bloque de configuración planteado:
22
_Nota: con esto, el usuario siempre entra por HTTPS y Odoo ve las cabeceras correctas de proxy._
#### **Certificados HTTPS con Let’s Encrypt**
En el VPS se utilizarán certificados gratuitos de Let’s Encrypt:
**Apuntar el dominio del ERP al VPS desde el DNS.**
**Instalar certbot y ejecutarlo contra Nginx para sacar los certificados SSL/TLS.**
**Dejar configurada la renovación automática para que los certificados se renueven solos**
**y no caduquen.**
#### **Firewall y restricción de puertos**
También voy a limitar qué puertos están abiertos en el VPS, por ejemplo con ufw:
**Permitir solo:**
22/tcp → SSH para administrar el servidor.
80/tcp → para que Let’s Encrypt pueda validar el dominio.
443/tcp → acceso HTTPS de los usuarios al ERP.
23
**Bloquear el acceso directo a:**
8069/tcp → puerto interno de Odoo.
5432/tcp → puerto de PostgreSQL.
De esta forma, la aplicación y la base de datos quedan siempre detrás de Nginx y de la red interna de
Docker, y desde fuera solo se ve el servicio HTTPS del ERP.
## **Conclusiones**
Durante la cuarta semana se ha conseguido:
1. Montar un entorno de producción local para Odoo Community 16 y PostgreSQL con Docker,
separado del sandbox de pruebas.
volúmenes para que los datos sean persistentes.
cargar datos reales en las siguientes semanas.
4. Próximo paso: definir roles y permisos (Administrador, Becario, Ventas, Dirección) y dar de alta el
personal en Odoo, iniciando la fase de gestión de usuarios y accesos.
# **Semana 5 – Plan de despliegue de Odoo en** **AWS y acceso por URL**
## **Introducción**
**Objetivo de la semana:** Dejar preparado el plan de despliegue en la nube de Odoo Community 16 para
Spika Tech usando AWS, de forma que el ERP quede accesible mediante una URL con dominio propio
(con Nginx como proxy inverso). El despliegue real se hará el lunes, cuando tenga acceso a la cuenta
institucional de AWS; esta semana he definido la arquitectura y los pasos exactos (comandos y
configuraciones) que seguiré, partiendo de la infraestructura local que monté en la semana 4 con Docker
y PostgreSQL.​
24
## **Diseño de la infraestructura en AWS**
#### **Plataforma y recursos**
Para el despliegue he elegido Amazon Web Services (AWS) con una instancia EC2 pequeña (1 GB de RAM
y 20 GB de disco SSD), suficiente para un entorno piloto de Odoo. AWS permite instalar Ubuntu Server,
Docker, docker‑compose y Nginx, y ofrece free tier para una instancia pequeña durante el primer año, lo
que reduce el coste inicial para la empresa.​
**Configuración prevista de la instancia EC2:**
`Tipo` → t3.micro / t3a.micro (1 GiB RAM).​
`Disco` → 20 GB SSD.
22 (SSH)
80 (HTTP)
443 (HTTPS)
#### **Arquitectura objetivo**
**La arquitectura que quiero tener en AWS es:**
Instancia EC2 con Ubuntu Server 22.04.
Contenedor Docker odoo-prod-db con PostgreSQL 15.
Contenedor Docker odoo-prod-app con Odoo 16 Community.
Carpetas en el host para separar datos y configuración:
~/proyecto-erp/odooaws/odoo-config
~/proyecto-erp/odooaws/odoo-addons
~/proyecto-erp/odooaws/odoo-data
~/proyecto-erp/odooaws/postgres-data​
Nginx instalado en la instancia como proxy inverso, escuchando en 80/443 y reenviando peticiones al
Odoo que escucha en 8069.​
Un dominio/subdominio tipo erp.spikatech.com apuntando a la IP de la instancia para el acceso por
URL.
## **Preparación de la instancia EC2 y Docker**
#### **Conexión por SSH**
Una vez creada la instancia EC2 con Ubuntu, la conexión se hará con la clave .pem:
25
```
 chmod 600 erp-spikatech-key.pem
  ssh -i erp-spikatech-key.pem ubuntu@IP_PUBLICA
#### **Instalación de Docker y docker‑compose**
```
Dentro de la instancia:
Después saldré y volveré a entrar para que se apliquen los permisos:
## **Despliegue de Odoo en AWS**
#### **1. Creación de la estructura de carpetas**
Voy a replicar la estructura de producción que usé en la semana 4, pero en AWS:
_Nota: con esto separo configuración y datos para que sean persistentes aunque borre los_
_contenedores.​_
#### **2. Crear fichero docker-compose.yml dentro de la carpeta odooaws**
26
_Nota: levanta dos contenedores Docker (PostgreSQL y Odoo) y monta las carpetas del host como_
_volúmenes, igual que en mi entorno de producción local.​_
#### **3. Crear fichero odoo.conf**
En la carpeta /odoo-config
```
 nano odoo.conf
```
27
_admin_passwd: contraseña maestra para crear bases de datos. db_*: datos de conexión al_
_contenedor de PostgreSQL. data_dir: ruta interna de datos de Odoo. proxy_mode = True: deja_
_Odoo listo para trabajar detrás de Nginx.​_
#### **4.Levantar los contenedores**
En la carpeta del proyecto:
_Nota: Con esto Odoo y PostgreSQL quedarán levantados en segundo plano en la instancia EC2._
#### **5.Creación de la base de datos**
Mientras todavía no tenga dominio, podré entrar (temporalmente) por IP:
**http://IP_PUBLICA:8069**
En el asistente de Odoo, crearé la base de datos de producción, por ejemplo:
**Master password:** Clave$123.
**Nombre de la base de datos:** vrcardioprodaws.
**Usuario administrador:** email de admin y contraseña.
## **Publicación por URL con Nginx y dominio**
#### **Instalación y configuración básica de Nginx**
Para que el ERP sea accesible por una URL, usaré Nginx como proxy inverso delante de Odoo:​
**Instalación:**
28
**Eliminar la configuración por defecto:**
```
sudo rm /etc/nginx/sites-enabled/default
 sudo rm /etc/nginx/sites-available/default
```
**Crear el archivo /etc/nginx/sites-available/odoo.conf:**
```
sudo nano /etc/nginx/sites-available/odoo.conf
 ```text
 upstream odoo {
 server 127.0.0.1:8069;
 }
 server {
 listen 80;
 server_name erp.spikatech.com;
 proxy_read_timeout 720s;
 proxy_connect_timeout 720s;
 proxy_send_timeout 720s;
 proxy_set_header Host $host;
 proxy_set_header X-Real-IP $remote_addr;
 proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
 proxy_set_header X-Forwarded-Proto $scheme;
 location / {
 proxy_redirect off;
 proxy_pass http://odoo;
 }
 location ~* /web/static/ {
 proxy_cache_valid 200 90m;
 proxy_buffering on;
 expires 864000;
 proxy_pass http://odoo;
 }
 }
```
**Habilitar el sitio y recargar Nginx:**
29
Con esto, cuando el dominio erp.spikatech.com apunte a la IP de la instancia, las peticiones a
http://erp.spikatech.com irán al Odoo del puerto 8069 sin que el usuario lo vea.​
## **HTTPS con Let’s Encrypt (planificado)**
Una vez que el DNS esté configurado, el siguiente paso será activar HTTPS con Let’s Encrypt:
#### **Instalar certbot**
```
 sudo apt install -y certbot python3-certbot-nginx
#### **Solicitar el certificado para el dominio:**
 sudo certbot --nginx -d erp.spikatech.com
```
El asistente ajustará la configuración de Nginx para usar HTTPS y, si se selecciona esa opción, redirigir
todo el tráfico HTTP a HTTPS. El resultado final será que el ERP esté disponible en:
**https://erp.spikatech.com**
con la conexión cifrada y sin necesidad de exponer el puerto 8069 directamente a Internet.
## **Conclusiones**
Durante la quinta semana se ha conseguido:
1. Dejar preparado el diseño de la infraestructura en AWS (tipo de instancia, puertos, disco, sistema
operativo).
2. Crear la estructura de carpetas, el docker-compose.yml y el odoo.conf que se usarán para levantar
Odoo y PostgreSQL en la instancia, siguiendo el modelo que ya funcionó en el entorno local de
producción de la semana 4.​
3. Definir la configuración prevista de Nginx como proxy inverso y el uso de Let’s Encrypt para que el
ERP quede publicado mediante una URL propia (erp.spikatech.com) y con HTTPS.
4. Próximo paso: aplicar estos comandos y configuraciones en la cuenta de AWS de la empresa para
dejar el ERP funcionando en la nube y accesible por URL.
30
# **Semana 6 – Despliegue real de Odoo en AWS,** **HTTPS con Let’s Encrypt y diseño de gestión de** **licencias y proyectos**
## **Introducción**
**Objetivo de la semana:** Poner en marcha de forma real Odoo Community 16 en la instancia de AWS
proporcionada por la empresa, publicándolo en Internet con HTTPS válido y dejando configurada la base
para gestionar las licencias de software de VRCardio y los proyectos de implantación y desarrollo dentro
de Odoo.
## **Acceso a la instancia de AWS**
#### **Conexión por SSH con la clave PEM**
Una vez que la empresa me facilitó el fichero erp_keys.pem y el DNS público de la instancia (ec2-56-228
82-108.eu-north-1.compute.amazonaws.com), lo primero que hice fue ajustar permisos a la clave y
conectarme por SSH desde mi equipo:
Tras aceptar la huella del host la primera vez, me conecté como ec2-user en un sistema Amazon Linux
2023, desde donde ya he realizado toda la instalación de Docker y el despliegue de Odoo.
## **Instalación de Docker y Docker Compose**
Dentro de la instancia, actualicé paquetes e instalé Docker:
Después salí y volví a entrar por SSH para que se aplicaran los permisos del grupo docker y comprobé
que Docker estaba operativo con docker ps.
31
Como en Amazon Linux 2023 el paquete docker-compose-plugin no está disponible, instalé Docker
Compose descargando el binario y registrándolo como plugin de Docker:
## **Despliegue de Odoo y PostgreSQL con Docker**
#### **1. Creación de la estructura de carpetas**
Para mantener ordenados los datos y la configuración, he replicado en la instancia la estructura que ya
usé en local:
_Nota: con esto separo la configuración (odoo-config), posibles addons extra (odoo-addons) y los_
_datos persistentes tanto de Odoo (odoo-data) como de PostgreSQL (postgres-data)._
#### **2. Crear fichero docker-compose.yml dentro de la carpeta odooaws**
```
 nano docker-compose.yml
```
32
_Nota: este fichero levanta dos contenedores: uno con PostgreSQL 15 y otro con Odoo 16_
_Community, utilizando las carpetas del host como volúmenes para que los datos no se pierdan al_
_recrear contenedores._
#### **3. Crear fichero odoo.conf**
En la carpeta /odoo-config
33
_Nota: adminpasswd será la contraseña maestra para la creación de bases de datos, y los_
_parámetros db* apuntan al contenedor de PostgreSQL definido en docker-compose.yml. El_
_datadir coincide con el volumen montado en odoo-data y proxymode = True deja preparado Odoo_
_para trabajar en el futuro detrás de un proxy inverso._
#### **4. Levantar los contenedores**
En la carpeta del proyecto:
#### **5. Resolución del error 500**
Al probar desde la propia instancia inicialmente obtenía un error 500. Revisando los logs del contenedor
de Odoo:
encontré un **Permission denied: '/var/lib/odoo/sessions'**, lo que indicaba que el usuario interno
de Odoo no tenía permisos para escribir en el volumen odoo-data. Para solucionarlo, probé a cambiar el
propietario del directorio y, abrí permisos temporalmente para que Odoo pudiera crear la carpeta de
sesiones:
Después de este ajuste, el acceso a **http://localhost:8069/web/database** devolvió el HTML de la
pantalla de selección/creación de base de datos.
34
#### **6. Creación de la base de datos**
En el asistente de Odoo:
**Master Password:** Qen01,6xc(7Xl8!L
**Database Name:** vrcardio
**Email** : admin.its@spikatech.com
**Password:** c19U{o8PT|Z()~3R
## **Publicación del ERP con Nginx y subdominio** **erp.spikatech.com**
#### **Instalación y configuración básica de Nginx** **1. Instalación de Nginx para dejarlo activo**
#### **2. Crear fichero odoo.conf**
En /etc/nginx/conf.d/odoo.conf he creado una configuración para que Nginx escuche en 80/443, redirija
HTTP a HTTPS y actúe como proxy inverso hacia Odoo en 127.0.0.1:8069.​
```
 sudo nano /etc/nginx/conf.d/odoo.conf
```
35
#### **3. Comprobar la configuración y recargar Nginx:**
#### **Creación del subdominio y pruebas de puertos**
La empresa ha creado el subdominio erp.spikatech.com en su dominio, con un registro DNS tipo A
apuntando a la IP pública 56.228.82.108 de la instancia.​Desde mi equipo lo he comprobado con:
```
 nslookup erp.spikatech.com
```
_Nota: se obtiene Address: 56.228.82.108.​_
Para verificar qué puertos se ven desde Internet he usado nmap:
```
 nmap -p 22,80,443,8069,5432 erp.spikatech.com
```
36
El resultado muestra:
_Nota: esto confirma que solo están expuestos 22, 80 y 443, mientras que los puertos internos de_
_Odoo (8069) y PostgreSQL (5432) permanecen filtrados y no se puede acceder directamente a_
_ellos desde Internet.​_
Desde el navegador ya es posible acceder a Odoo con la URL: **https://erp.spikatech.com**
## **Configuración de HTTPS con Let’s Encrypt (Certbot)**
Para cumplir el requisito de **Configuración de HTTPS Let’s Encrypt y restricción de accesos** de
la semana 4 he sustituido el certificado autofirmado por un certificado gratuito de Let’s Encrypt usando
Certbot.​
#### **Instalación de Certbot y emisión del certificado**
En la instancia he instalado Certbot y el plugin de Nginx, y luego he ejecutado Certbot indicando el
subdominio:
Durante el asistente he introducido el correo **admin.its@spikatech.com**, aceptado los términos de
servicio y seleccionado la opción de redirigir todo el tráfico HTTP a HTTPS.
Certbot ha modificado automáticamente la configuración de Nginx para usar los certificados de Let’s
Encrypt ubicados en /etc/letsencrypt/live/erp.spikatech.com/ y ha configurado la renovación
automática.
Finalmente, he probado la renovación en modo simulación:
Desde el navegador, al acceder de nuevo a **https://erp.spikatech.com**, el candado aparece como
seguro y el certificado se identifica como emitido por Let’s Encrypt para erp.spikatech.com, sin avisos de
37
seguridad.
## **Gestión de licencias de software (Inventario / Suscripciones)**
Además de la parte de sistemas, esta semana he dejado preparada la configuración funcional para
gestionar las licencias de software de VRCardio usando el módulo de Inventario (y opcionalmente
Suscripciones) de Odoo.
#### **Licencias como productos de servicio**
La idea es modelar cada tipo de licencia como un producto de tipo servicio vendible, asociado a una
categoría específica de “Licencias VR”, como por ejemplo el usado en la semana 1:​
Ruta: Inventario → Productos → Productos → Nuevo
**Tipo de producto:** Servicio
**Categoría:** Licencias VR (creada para agrupar las licencias)
**Impuestos:** IVA correspondiente
**Campos adicionales:** descripción técnica de la licencia, duración, etc
#### **Control de fechas de caducidad y asignación a clientes**
El objetivo es poder controlar la fecha de caducidad de cada licencia y a qué cliente/hospital está
asignada.​
A nivel de diseño:
Cada licencia contratada se reflejará en Odoo como una línea de pedido de venta y posteriormente
como una factura asociada al producto de licencia correspondiente.​
La fecha de caducidad se controlará mediante campos de fecha en la ficha de la licencia o mediante el
módulo de Suscripciones (si se activa), que permite gestionar renovaciones automáticas y periodos de
validez.​
Mediante la relación entre pedido/factura y cliente, se podrá ver qué licencias tiene cada hospital y
cuándo expiran para planificar renovaciones.
En esta semana he dejado documentado este modelo de datos y el flujo de trabajo, a la espera de
importar las licencias reales mediante CSV cuando reciba las plantillas de la empresa.​
## **Gestión de proyectos y seguimiento de tareas (Kanban, horas)**
#### **Configuración del módulo de Proyectos**
El flujo que he diseñado es:
38
Crear un proyecto por cada implantación o cliente.​
Definir columnas Kanban que representen los estados de las tareas (Pendiente, En curso, En revisión,
Completada).​
Dentro de cada proyecto, crear tareas para las actividades principales: instalación, configuración,
formación, soporte, desarrollo de nuevas funcionalidades, etc.​
Esto permite que el equipo tenga una visión clara del estado de los trabajos en curso y que dirección vea
la carga de trabajo por cliente.​
#### **Imputación de horas en tareas**
Odoo permite registrar el tiempo dedicado por cada usuario a las tareas del proyecto. A nivel de diseño, la
idea es:​
Cada técnico inicia y registra el tiempo en las tareas que tenga asignadas, indicando fecha, duración y
descripción breve de lo realizado.
Desde el proyecto se puede ver el total de horas por tarea, por empleado y por proyecto, lo que ayuda
a controlar el esfuerzo invertido en cada implantación o desarrollo vinculado a las licencias vendidas.​
## **Conclusiones**
Durante la sexta semana se ha conseguido:
1. Dejar desplegado en la instancia de AWS un entorno de producción con Odoo y PostgreSQL en
Docker, correctamente configurado y protegido detrás de Nginx para que no se expongan
directamente los puertos internos.
2. Configurar el acceso al ERP mediante el subdominio erp.spikatech.com, usando Nginx como proxy
inverso y activando HTTPS con certificados válidos de Let’s Encrypt, de forma que ahora el acceso es
seguro y sin avisos de certificado en el navegador.
3. Definir cómo se gestionarán las licencias de software y los proyectos en Odoo, utilizando el módulo de
Inventario/Suscripciones para las licencias y el módulo de Proyectos con vista Kanban e imputación
de horas por tarea.
4. Próximo paso: trabajar la parte de CRM y ventas sobre este Odoo de producción, configurando el
pipeline de oportunidades y la generación de presupuestos y facturas con los datos de VRCardio.
39
# **Semana 7 - Configuración del CRM y** **personalización de presupuestos/facturas con** **logo y datos fiscales**
## **Introducción**
**Objetivo de la semana:** Adaptar el módulo de CRM/Ventas de Odoo al proceso comercial de Spika
Tech, definiendo un pipeline con las etapas Lead → Contacto → Demo → Cierre, y personalizar las
plantillas PDF de presupuestos y facturas para que incluyan el logotipo corporativo y los datos fiscales y
legales de la empresa, según el documento del proyecto.​
## **Configuración del pipeline de CRM (Lead → Contacto → Demo** **→ Cierre)**
#### **Acceso al CRM y revisión del flujo por defecto**
Partiendo del Odoo de producción desplegado en AWS, he accedido al módulo CRM desde la barra
superior de aplicaciones. La vista principal muestra el tablero de oportunidades en formato Kanban, con
las columnas estándar “Nuevo”, “Calificado”, “Propuesta” y “Ganado”, además del botón “NUEVO” para
crear oportunidades. Este flujo es genérico y no refleja todavía las fases concretas que necesita Spika
Tech para gestionar su ciclo de ventas.
#### **Redefinición de etapas del pipeline**
Para adaptar el sistema al proceso comercial definido en el proyecto, he entrado en CRM → Ventas → Mi
flujo y he editado las etapas existentes. A partir de las columnas por defecto (“Nuevo”, “Calificado”,
“Propuesta”, “Ganado”), he renombrado y reordenado las etapas hasta dejar las siguientes fases:
**Lead:** registro de oportunidades iniciales, por ejemplo hospitales o clínicas que muestran interés por
VRCardio o solicitan información.​
**Contacto:** oportunidades en las que ya se ha realizado un primer contacto comercial (llamada,
correo, reunión) y se ha validado que hay interés real.​
**Demo:** fase en la que se ha propuesto o realizado una demostración de la solución, ya sea presencial
  - remota.​
**Cierre:** etapa final del embudo, donde se negocian condiciones, precios y fechas de implantación con
el objetivo de cerrar el acuerdo.​
Tras guardar los cambios, el tablero de CRM pasa a mostrar las columnas Lead, Contacto, Demo y Cierre
en lugar de los nombres genéricos iniciales. Esto deja preparado el entorno para trabajar con datos reales
cuando la empresa los facilite.
40
## **Configuración de la compañía: logo y datos fiscales**
#### **Edición de la ficha de compañía en Odoo**
En paralelo al CRM, he trabajado en la configuración de la compañía dentro de Odoo, ya que estos datos
son la base de los documentos de ventas (presupuestos y facturas). Desde el módulo Ajustes he accedido
a Gestionar compañías y he editado el registro principal “My Company” para que refleje los datos reales
de Spika Tech.​
En esta ficha he dejado configurado:
**Nombre de la empresa:** SPIKA TECH, S.L
**Dirección:** c/ Alcalá de Guadaira, nº 6, 6ºA Derecha, 28018 MADRID, España
**NIF:** B87386900
**Moneda:** EUR
**Correo electrónico:** admin.its@spikatech.com
**Sitio web:** http://spikatech.com
Además, he cargado el logotipo corporativo de Spika Tech en la parte superior de la ficha de compañía.
Gracias a esto, el logo ya aparece tanto en la pantalla de login de Odoo como en la interfaz una vez dentro
del ERP, y se reutiliza también en los presupuestos y facturas en PDF.
## **Personalización del diseño de presupuestos y facturas (PDF)**
#### **Configuración del diseño de documentos en Odoo**
Una vez que la compañía ya tenía el logo y los datos fiscales bien puestos, he usado el asistente de Diseño
de documento de Odoo para ajustar cómo salen los PDFs de presupuestos y facturas. Para ello he ido a
Ajustes → Configurar diseño de documento y he:
Elegido un tema (por ejemplo Light)
Revisado que use el logotipo de Spika Tech
Comprobado en **Detalles de la compañía** que aparecen los mismos datos que en la ficha de
empresa:
Razón social: SPIKA TECH, S.L.
Dirección completa en Madrid
País: España
Con esto me aseguro de que en la cabecera del PDF salga el emisor con nombre, NIF y domicilio.
41
#### **Inserción del texto legal en el pie de página**
Para que el PDF se parezca al modelo del proyecto, he rellenado el Pie de página del asistente con:
**Primera línea:** correo y web de la empresa
contact@spikatech.com - www.spikatech.com
**Segunda línea:** el texto legal completo del documento del proyecto, con domicilio social, NIF y
datos del Registro Mercantil de Madrid.
Así, todos los presupuestos y facturas que genera Odoo llevan abajo la misma coletilla legal que el PDF de
referencia.
#### **Resultado final**
Después de estos cambios, los documentos quedan así:
Logotipo de Spika Tech en la parte superior.
Razón social, NIF y dirección visibles en la cabecera.
Texto legal completo en el pie de página.
No es exactamente igual que el PDF original (el asistente de Odoo tiene sus límites), pero el diseño es
muy parecido y, sobre todo, cumple con lo que pide el proyecto usando solo configuración, sin tocar
código.
## **Conclusiones**
Durante la séptima semana se ha conseguido:
1. Adaptar el módulo de CRM de Odoo al flujo comercial de VRCardio/Spika Tech, sustituyendo las
etapas genéricas por el pipeline Lead → Contacto → Demo → Cierre.
2. Configurar la ficha de la compañía con los datos fiscales reales de Spika Tech y el logotipo
corporativo, que ya aparece en el login y dentro del ERP.
3. Personalizar las plantillas PDF de presupuestos y facturas para que incluyan el logo, los datos fiscales
y el texto legal completo que la empresa utiliza en sus documentos.
4. Próximo paso: investigar la API de Odoo y crear un pequeño script en Python que se conecte al ERP
desde fuera y lea algún dato sencillo (por ejemplo, un cliente u oportunidad) como base para futuras
integraciones.
42
# **Semana 8 – Pruebas de integración con** **Sistemas (API)**
## **Introducción**
**Objetivo de la semana:** Investigar la API de Odoo (XML‑RPC) y desarrollar un primer script en
Python que se conecte desde fuera al ERP de producción desplegado en AWS, se autentique contra la
base de datos vrcardio y lea algunos datos reales del sistema (contactos). Partiendo del Odoo 16
Community que ya dejé instalado en la instancia de AWS, publicado con Nginx y HTTPS bajo el
subdominio erp.spikatech.com, en esta semana he dado el primer paso hacia la integración externa del
ERP, preparando un usuario técnico específico y construyendo un pequeño “Hola Mundo” de integración
que demuestra que se pueden consultar datos desde scripts o aplicaciones externas.
## **Creación de un usuario técnico para la API**
Antes de escribir el script, he creado un usuario específico para las integraciones, con el fin de no utilizar
la cuenta de administrador general y poder controlar mejor los accesos.
Los pasos que he seguido han sido:
1. Acceder a Odoo en la URL **https://erp.spikatech.com**, seleccionando la base de datos vrcardio e
iniciando sesión con el usuario administrador.​
2. Ir al módulo Ajustes → Usuarios y empresas → Usuarios → Nuevo para crear un usuario llamado
“Usuario API”.
**Correo electrónico** : api.user@spikatech.com
**Contraseña** : 5NjF65G!|9TdW;R*
3. Guardar el usuario y comprobar que puede iniciar sesión en la web, cerrando sesión con el
administrador e iniciando con api.user@spikatech.com y su contraseña.
Con esto queda preparado un usuario de servicio específico para la API, que en el futuro se podrá
restringir o deshabilitar sin afectar al resto de usuarios de la organización.
## **Investigación básica de la API XML‑RPC de Odoo**
Odoo proporciona una API estándar basada en XML‑RPC que permite realizar operaciones sobre los
modelos internos del ERP (como res.partner para contactos o crm.lead para oportunidades) desde
aplicaciones externas, siempre que se disponga de la URL, el nombre de la base de datos y las
credenciales de un usuario válido.​
La API se divide en dos endpoints principales:
43
**https://erp.spikatech.com/xmlrpc/2/common:** utilizado para autenticarse mediante la
función authenticate(db, username, password, {}), que devuelve un identificador de usuario (uid) si el
login es correcto o False si falla.​
**https://erp.spikatech.com/xmlrpc/2/object:** usado para invocar métodos sobre los modelos
mediante la función execute _kw, que permite hacer operaciones como search_ read (buscar y leer
registros), create, write, etc.
Para la práctica de esta semana he decidido trabajar con el modelo res.partner, que es el que Odoo utiliza
para almacenar contactos, clientes y proveedores, ya que es un modelo sencillo y siempre tiene algunos
datos creados por defecto (empresa, administradores, etc.).
## **Desarrollo del script “Hola Mundo” en Python**
El siguiente paso ha sido desarrollar un script en Python 3 que se conecte a la instancia de Odoo en AWS,
se autentique con el usuario técnico creado y lea algunos contactos mediante la API XML‑RPC.
#### **Ubicación y entorno**
He creado el script directamente en la instancia de AWS, dentro de la carpeta del proyecto del ERP donde
ya tenía el docker-compose.yml y el resto de archivos de despliegue de Odoo:​
La instancia ya cuenta con Python 3 instalado, por lo que no ha sido necesario añadir dependencias
externas; para trabajar con XML‑RPC he usado el módulo estándar xmlrpc.client que viene con Python.
44
#### **Código del script**
```
 import xmlrpc.client
  url = "https://erp.spikatech.com"
  db = "vrcardio"
  username = "api.user@spikatech.com"
  password = "5NjF65G!|9TdW;R*"
  common = xmlrpc.client.ServerProxy(f"{url}/xmlrpc/2/common")
  uid = common.authenticate(db, username, password, {})
  print("UID devuelto por Odoo:", uid)
  if not uid:
  raise SystemExit("Error: no se ha podido autenticar (revisa usuario/contraseña/ba
  se de datos)")
  models = xmlrpc.client.ServerProxy(f"{url}/xmlrpc/2/object")
  partners = models.execute_kw(
  db,
  uid,
  password,
  "res.partner",
  "search_read",
  [[]],
  {"fields": ["name", "email"], "limit": 5},
  )
  print("Contactos leídos desde Odoo:")
  for p in partners:
  print("-", p["name"], "-", p.get("email", "sin email"))
```
_Nota: el script realiza tres pasos principales: autenticarse en Odoo, conectarse al endpoint de_
_objetos y ejecutar una consulta search_read sobre el modelo res.partner para recuperar los_
_primeros cinco contactos, mostrando por pantalla su nombre y correo electrónico.​_
#### **Pruebas de ejecución y resultados obtenidos**
Una vez guardado el archivo odoo _api_ test.py, he ejecutado el script desde la misma carpeta del proyecto:
45
El script ha mostrado por consola el uid devuelto por Odoo ("UID devuelto por Odoo: 7") seguido de un
listado de contactos con su nombre y correo electrónico:
Estos resultados demuestran que el script es capaz de conectarse a la instancia de Odoo desplegada en
AWS, autenticarse como el usuario técnico y leer datos reales del modelo res.partner a través de la API
XML‑RPC.
## **Conclusiones**
Durante la octava semana se ha conseguido:
1. Crear un usuario técnico de servicio (Usuario API) para acceder al ERP sin usar la cuenta de
administrador.
2. Entender la API XML‑RPC de Odoo y cómo autenticarse y consultar modelos desde fuera.
3. Desarrollar y ejecutar un script “Hola Mundo” en Python que se conecta a Odoo en AWS y lee
contactos reales de `res.partner` .
4. Próximo paso: reutilizar esta integración para trabajar con otros modelos del negocio y empezar a
automatizar intercambios de datos con el ERP.
# **Semana 9 – Importación de Datos**
## **Introducción**
**Objetivo de la semana:** preparar y ejecutar la importación de datos importantes en el Odoo de
producción (base de datos vrcardio): clientes, proveedores, productos/licencias y empleados,
comprobando que los registros quedan completos para usarlos en ventas, compras y RRHH.​Partiendo
del Odoo 16 Community desplegado en la instancia de AWS y publicado con Nginx y HTTPS en
**https://erp.spikatech.com**, en esta semana he diseñado las plantillas CSV y he desarrollado un script
en Python que se conecta a Odoo mediante la API XML‑RPC usando un usuario técnico de servicio
(Usuario API) para realizar la carga masiva.
46
## **Limpieza – Preparación de los CSV de proveedores y productos** **(más empleados)**
#### **Datos que se van a importar**
Antes de tocar Odoo he definido qué datos tenía que tener preparados:
**Proveedores:** empresas que suministran hardware, servicios cloud, etc.
**Productos:** elementos que se van a vender desde el ERP (licencias de software, servicios asociados,
etc).
**Empleados:** personas de VRCardio que van a usar el sistema o aparecer en ventas y proyectos.
CSV siguiendo esos campos.
#### **CSV de proveedores**
Para los proveedores he creado un fichero separado **proveedores_plantilla.csv** con la misma
estructura que el de clientes, pero con datos y etiquetas de proveedor.
CIF/NIF de cada proveedor en vat.
País correcto en country_id para que Odoo lo encuentre.
Etiquetas claras en category_id (“Proveedor;Tecnología”, “Proveedor;Cloud”) para distinguirlos de
los clientes.
#### **CSV de productos**
Para los productos he preparado **productos_plantilla.csv**, usando el diseño de la semana 6: licencias
como servicios en la categoría “Licencias VR”, con su precio e impuestos.
type="service" para indicar que es un servicio.
sale _ok=True y purchase_ ok=False porque se vende pero no se compra.
default_code como código interno tipo SKU.
list_price como precio de venta sin impuestos.
taxes_id con el nombre del impuesto (“IVA 21%”) que ya está creado en Odoo.
categ_id="Licencias VR" para agrupar todas las licencias.
47
description_sale como texto que se verá en presupuestos y facturas.
De momento la empresa todavía no me ha enviado el fichero de productos relleno, así que esta semana
solo he dejado preparada la plantilla licencias_plantilla.csv a la espera de importarla en cuanto me la
pasen.
#### **CSV de empleados**
Para empleados he preparado el fichero **empleados_plantilla.csv**, con los campos básicos del modelo
de empleados.
name con el nombre completo.
work _email y work_ phone como contacto de trabajo.
job_title para el puesto (“Responsable de Ventas”).
department_id con el nombre del departamento (“Ventas”) ya creado en Odoo.
He comprobado que los correos de trabajo no se repiten y que cada empleado tiene un departamento
asignado.
## **Importación – Carga masiva con script y usuario API**
#### **Uso de un usuario API**
Para hacer la importación no he usado el usuario administrador general, sino un usuario técnico de
servicio (“Usuario API”) que ya había creado para integraciones en la semana 8.​De esta forma separo las
tareas automáticas (scripts) del uso normal del ERP: si en algún momento hay que bloquear los accesos
desde scripts, basta con desactivar este usuario sin afectar al resto de usuarios ni al admin.
#### **Conexión del script a Odoo**
He creado el script **import** _**odoo**_ **data.py** en la instancia de AWS, dentro de la carpeta del proyecto,
reutilizando el mismo esquema de conexión XML‑RPC que en el “Hola Mundo” de la semana 8.​
48
_Nota: con esto el script se autentica en la base de datos vrcardio con el usuario API y queda listo_
_para crear registros en los modelos necesarios.​_
#### **Importación de proveedores**
Para los proveedores, el script abre **proveedores_plantilla.csv** y crea contactos en res.partner para
cada fila.
49
_Nota: tras ejecutar esta función, en el módulo Contactos aparecen los proveedores importados con_
_sus nombres, ciudades y correos._
#### **Importación de empleados**
Para los empleados, el script usa **empleados_plantilla.csv** y crea registros en hr.employee.
_Nota: después de lanzar esta parte del script, en el módulo Empleados aparecen las tarjetas de los_
_empleados con su correo, teléfono y puesto, como se ve en la vista Kanban._
#### **Ejecución del script y comprobaciones**
En la instancia de AWS he ejecutado el script desde la carpeta del proyecto:​
El script muestra un mensaje de fin de importación y, a continuación, he verificado en la interfaz web de
Odoo que:
En **Contactos** se ven los proveedores importados con su información básica.
En **Empleados** se ven los empleados importados con su correo, teléfono y puesto.
## **Conclusiones**
Durante la semana 9 se ha conseguido:
1. Diseñar y preparar las plantillas CSV de proveedores, productos y empleados, ajustadas a los modelos
estándar de Odoo.
50
2. Completar estas plantillas con datos coherentes (direcciones, países, teléfonos, correos, categorías)
realizando una limpieza básica para evitar errores en la importación.
3. Desarrollar un script en Python que se conecta a Odoo mediante XML‑RPC utilizando un usuario
técnico de servicio (Usuario API) y que importa de forma masiva los proveedores y empleados
definidos en los CSV.
4. Próximo paso: configurarar el sistema de copias de seguridad automáticas de la base de datos
vrcardio y la sincronización de estos backups con el NAS Synology de la empresa.
# **Semana 10 - Estrategia de Backups y** **Recuperación**
## **Introducción**
**Objetivo de la semana:** automatizar la generación diaria de dumps de la base de datos, almacenarlos
de forma ordenada con política de retención y dejar preparada la futura integración con el NAS Synology
para disponer de copias externas.
## **Sistema de backup**
#### **Backup manual inicial de la base de datos**
Como primer paso he realizado un backup manual de la base de datos del ERP para comprobar el uso de
pg_dump desde el contenedor Docker de PostgreSQL y validar la ruta de almacenamiento de las copias.
Para ello he ejecutado:
Con este comando se genera un fichero **vrcardio_YYYYMMDDHHMM.sql** dentro del directorio
~/proyecto-erp/backups, que contiene un volcado completo de la base de datos postgres utilizada por el
ERP. El listado me ha permitido comprobar que el archivo se crea correctamente y que el tamaño es
coherente con la información almacenada en el sistema.
#### **Creación del script de backup automatizado**
He creado un script de bash encargado de generar las copias de seguridad y de gestionar la retención de
los ficheros antiguos. Los pasos seguidos han sido:
51
El contenido final del script **backup_vrcardio.sh** es el siguiente:
#### **Programación del backup diario con cron**
Una vez validado el script, he configurado una tarea programada con cron para que el backup se ejecute
de forma automática todos los días a una hora fija. En la instancia de AWS se utiliza el servicio crond
(paquete cronie) para gestionar las tareas programadas del usuario ec2-user.
Primero he instalado y activado el servicio:
52
A continuación, he editado el crontab del usuario para añadir la tarea:
Dejando la siguiente línea:
Con esta configuración:
El script de backup se ejecuta todos los días a las 03:00.
Se llama al script usando la ruta absoluta dentro del proyecto.
Toda la salida (tanto estándar como de error) se redirige al fichero /home/ec2-user/backup.log, que
sirve como registro para revisar si los backups se han realizado correctamente.
Por último, he comprobado que la entrada se ha guardado correctamente con:
## **Integración con NAS Synology**
El objetivo final es que, además de las copias locales en la instancia de AWS, los backups de la base de
datos queden también guardados en el NAS Synology del centro. Para ello he diseñado una integración
basada en `rsync` y he empezado a probar la conexión con el usuario `odoo` que me han facilitado.
#### **Diseño de la integración**
La idea es la siguiente:
Que el NAS Synology permita acceso remoto desde mi instancia de AWS (por SSH/SFTP y rsync).
Añadir el comando de sincronización al final del script `backup_vrcardio.sh`   - crear una tarea `cro`
`n` adicional para que, después de generar el dump local, se copie automáticamente al NAS.
El comando que tengo preparado para cuando la conexión funcione es:
53
```
 rsync -avz /home/ec2-user/proyecto-erp/backups/ \
  odoo@dreamtechnologycl.fr3.quickconnect.to:/odoo/
#### **Pruebas de conexión con el NAS**
```
Con el usuario `odoo` y la URL de QuickConnect que me han dado, he intentado conectarme desde la
instancia de AWS de tres formas distintas:
En los tres casos, al introducir la contraseña de `odoo`, el NAS responde siempre con:
La integración con Synology queda ya diseñada y con los comandos preparados, pero pendiente de
copias de seguridad automáticas en la instancia de AWS funciona correctamente y genera los dumps
diarios con una política de retención de 7 días.
## **Conclusiones**
Durante la semana 10 se ha conseguido:
1. Definir y poner en marcha un sistema de copias de seguridad automatizadas de la base de datos del
ERP en la instancia de AWS, con generación diaria de dumps y política de retención de 7 días.
2. Implementar un script de backup ( `backup_vrcardio.sh` ) integrado con `cron`, que ejecuta `pg_dum`
`p` dentro del contenedor de PostgreSQL, genera los ficheros con marca de tiempo y registra la
ejecución en un fichero de log.
3. Diseñar la integración con el NAS Synology utilizando rsync y realizar pruebas de conexión desde la
instancia de AWS, quedando la copia externa pendiente.
# **Semana 11 - Manuales de Procedimiento**
**Objetivo de la semana:** redactar dos guías rápidas para el staff de VRCardio (“Cómo dar de alta una
nueva licencia” y “Cómo imputar horas a un proyecto”) y publicarlas dentro del Docusaurus del Proyecto
1, usando el repositorio existente.
54
## **Preparación del entorno de documentación**
Para poder editar la documentación he preparado primero el entorno de Docusaurus del Proyecto 1 en la
instancia de AWS:
obteniendo la carpeta del proyecto con todo el sitio de Docusaurus.
todas las dependencias necesarias (React, Docusaurus, etc.), dejándolo listo para desarrollo.
`p://localhost:3000/docs` que se cargaban correctamente las secciones ya existentes (ISO 13485 e
ISO 27001) antes de añadir las nuevas guías.
## **Contenido de las guías rápidas para el staff de VRCardio**
He creado una nueva carpeta `docs/vrcardio` y dentro de ella dos ficheros Markdown que actúan como
“manuales de procedimiento” breves:
1. Guía “Cómo dar de alta una nueva licencia” ( `docs/vrcardio/licencias_alta.md` )
Explica a personal de administración/soporte cómo crear una licencia VRCardio en Odoo.
Estructura:
Objetivo: registrar una licencia nueva y asociarla al cliente correcto.
Requisitos previos: usuario con permisos y cliente ya creado.
Pasos: entrar en el menú de licencias, pulsar **Crear**, rellenar cliente, tipo de licencia, fechas de
inicio y fin y, si aplica, número de serie/clave, guardar y revisar que aparece bien en el listado.
Resumen rápido: tres líneas con el menú y los campos mínimos que no se pueden olvidar.
2. Guía “Cómo imputar horas a un proyecto” ( `docs/vrcardio/imputar_horas.md` )
Orientada a técnicos que necesitan registrar el tiempo dedicado a proyectos de VRCardio.
Estructura:
Objetivo: dejar claro cómo imputar horas en tareas de proyecto para que queden en los partes
de horas.
Requisitos previos: acceso a Proyectos/Partes de horas y proyecto/tareas ya creados.
Pasos: abrir el proyecto y la tarea en Odoo, ir a la pestaña de partes de horas, añadir una línea
indicando usuario, descripción breve y número de horas (por ejemplo 1.5 para 1h 30min) y
guardar.
Resumen rápido: recordar el menú exacto y que siempre hay que guardar la tarea y comprobar
que las horas se ven en el histórico.
55
## **Publicación en el Docusaurus del Proyecto 1**
El Proyecto 1 ya estaba configurado con un sidebar autogenerado que construye el menú a partir de la
Docusaurus ha detectado automáticamente las nuevas páginas al reiniciar `npm run start` .
En `http://localhost:3000/docs` aparece una nueva sección relacionada con VRCardio en el menú
lateral, y dentro de ella las dos guías rápidas creadas esta semana.
Con esto se cumple el requisito de que la documentación de los procedimientos resida en el
Docusaurus del Proyecto 1 y quede accesible para el staff de VRCardio desde el mismo portal que el
resto de documentación del proyecto.
## **Conclusiones**
Durante la semana 11 se ha conseguido:
1. Preparar el entorno de documentación en la instancia de AWS, clonando el repositorio del Proyecto 1
y dejando Docusaurus funcionando en modo desarrollo tras ejecutar `npm install` y `npm run star`
`t` .
2. Crear dos guías rápidas específicas para VRCardio ( `licencias_alta.md` e `imputar_horas.md` )
cómo dar de alta licencias y cómo imputar horas en proyectos.
3. Integrar estas nuevas guías en el Docusaurus del Proyecto 1 sin tocar la configuración del sidebar,
aprovechando el sistema autogenerado para que aparezcan automáticamente en el menú de
documentación y queden accesibles junto al resto de contenidos.
# **Semana 12 – Arquitectura final y credenciales**
## **Introducción**
**Objetivo de la semana:** Documentar de forma visual y resumida la arquitectura final del ERP basado
en Odoo Community 16 (AWS + Docker + Nginx + PostgreSQL), y dejar recogido un cuadro claro con los
tipos de credenciales que se usan en el sistema.
56
## **Mapa de arquitectura**
Usuarios → Internet → erp.spikatech.com (DNS)
**Usuarios**
Acceden desde el navegador a: https://erp.spikatech.com.
**Instancia AWS**
Servidor Amazon Linux con Docker y Nginx.
Puertos abiertos: 22 (SSH), 80 (HTTP), 443 (HTTPS).
Puertos internos solo locales: 8069 (Odoo), 5432 (PostgreSQL).
**Nginx**
Recibe todo el tráfico a erp.spikatech.com.
Redirige HTTP → HTTPS.
Usa certificados Let’s Encrypt.
Reenvía las peticiones a Odoo en 127.0.0.1:8069.
**Docker**
Contenedor odoo-prod-app (Odoo 16) conectado a:
Contenedor odoo-prod-db (PostgreSQL 15) con usuario odooprod.
Volúmenes:
Configuración y addons de Odoo.
Datos de Odoo.
Datos de la base de datos.
**Backups**
Script diario que hace pg _dump de la base de datos y guarda ficheros_
_vrcardio_ YYYYMMDDHHMM.sql.
Copias previstas a NAS Synology mediante rsync (diseñado, pendiente de permisos).
## **Cuadro de credenciales**
_Nota: aquí se documenta qué credenciales existen y para qué sirven, pero las contraseñas reales se_
_gestionan mediante variables de entorno en el servidor, no expuestas en el código ni en la_
_documentación._
57
[Instancia AWS EC2]
Usuario sistema: ec2-user
Clave SSH: [CLAVE _PRIVADA_ ARCHIVO_PROTEGIDO]
Host: ec2-56-228-82-108.eu-north-1.compute.amazonaws.com
[Base de datos PostgreSQL (contenedor odoo-prod-db)]
Usuario BD Odoo: odooprod
Contraseña BD Odoo: [CONTRASEÑA_OCULTA]
Base de datos usada por Odoo: postgres (donde está la BD vrcardio)
Definido en: docker-compose.yml (POSTGRES _USER, POSTGRES_ PASSWORD)
Referenciado en: odoo.conf (db _user=odooprod, db_ password=[CONTRASEÑA_OCULTA])
Puerto: 5432 (solo red interna Docker)
[Odoo – Usuarios de aplicación]
Administrador ERP:
Email (login): admin.its@spikatech.com
Password (asistente de creación): [CONTRASEÑA_OCULTA]
Rol: configuración global, instalación de apps, gestión de usuarios
Usuario API (servicios externos):
Email (login): api.user@spikatech.com
Password: [CONTRASEÑA_OCULTA]
Uso: scripts Python vía XML-RPC (odoo _api_ test.py, import _odoo_ data.py)
Base de datos objetivo: vrcardio
Endpoints usados:
https://erp.spikatech.com/xmlrpc/2/common
https://erp.spikatech.com/xmlrpc/2/object
[Nginx / HTTPS]
Dominio ERP: erp.spikatech.com
Certificados Let’s Encrypt:
Ruta: /etc/letsencrypt/live/erp.spikatech.com/
Archivos: fullchain.pem, privkey.pem
Comando de emisión:
sudo certbot --nginx -d erp.spikatech.com
[Backups]
Script: /home/ec2-user/proyecto-erp/scripts/backup_vrcardio.sh
Carpeta de copias: /home/ec2-user/proyecto-erp/backups
Nombre de ficheros: vrcardio_YYYYMMDDHHMM.sql
Tarea cron:
58
0 3 * * * /home/ec2-user/proyecto-erp/scripts/backup_vrcardio.sh >> /home/ec2
user/backup.log 2>&1
[NAS Synology]
Usuario remoto: odoo
Host: dreamtechnologycl.fr3.quickconnect.to
Carpeta remota: /odoo/
Sincronización prevista:
rsync -avz /home/ec2-user/proyecto-erp/backups/ \
odoo@dreamtechnologycl.fr3.quickconnect.to:/odoo/
Estado: diseño terminado, pendiente de resolver "Permission denied (password)".
## **Conclusiones**
Durante la semana 12 se ha conseguido:
1. Dejar documentado de forma clara y esquemática el mapa de arquitectura final del ERP: instancia
AWS con Docker, contenedores de Odoo y PostgreSQL, Nginx como proxy inverso y sistema de copias
de seguridad diarias.
2. Elaborar un cuadro de credenciales que identifica los tipos de usuarios y accesos (sistema, base de
datos, Odoo, API, HTTPS y NAS), facilitando la gestión segura de contraseñas y el traspaso de
conocimiento a futuros administradores del sistema.
# **Conclusión**
Al terminar el proyecto, el resultado es un Odoo 16 en producción en AWS, accesible por
https://erp.spikatech.com, con los módulos necesarios configurados, los datos reales de Spika Tech
cargados en la compañía y los flujos principales listos: venta de licencias, seguimiento comercial,
proyectos de implantación con imputación de horas y gestión básica de empleados.​
En la parte técnica he pasado por el despliegue con Docker, la configuración de Nginx y HTTPS, la
automatización de backups y el uso de la API de Odoo desde scripts de Python para consultar e importar
datos. En la parte funcional he configurado Odoo para que reúna en un solo sitio clientes, licencias,
proyectos, ventas y empleados, de forma que podría utilizarse como ERP real en VRCardio / Spika Tech y
ampliarse con más usuarios, módulos e integraciones en siguientes fases.
59
```

### File: .\docs\mas_info\investigacion.md
```md
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
```

### File: .\ISOs\.gitkeep
```text

```

### File: .\ldap\estructura.ldif
```ldif
## Estructura LDAP — TechSolutions SL (TFG ASIR 2025/2026)
##
## Este fichero se carga automáticamente al iniciar el contenedor
## openldap (osixia/openldap) la primera vez, creando:
##
##   Árbol:  dc=tfg,dc=com
##   OUs:    ou=usuarios   → cuentas de personas
##           ou=grupos     → grupos departamentales
##           ou=servicios  → cuentas de servicio (readonly, api)
##
## Grupos y sus VLANs:
##   VLAN 10 (Usuarios ERP):
##     cn=becarios    → acceso solo lectura, nunca pueden eliminar
##     cn=ventas      → CRM, Ventas, Contactos
##     cn=rrhh        → RRHH, Empleados, Nóminas
##     cn=almacen     → Inventario, Compras
##     cn=tecnico     → Inventario, Soporte + puede cambiar contraseñas LDAP
##     cn=jefe_ventas → Ventas con aprobaciones
##     cn=jefe_rrhh   → RRHH con aprobaciones
##     cn=jefe_almacen→ Almacén con aprobaciones
##
##   VLAN 40 (Gestión del servidor):
##     cn=admin       → acceso total: servidor, BD, Odoo, LDAP
##     cn=dba         → solo base de datos (PostgreSQL)
##
## ─────────────────────────────────────────────────────────────
# ── Unidad Organizativa: Usuarios ────────────────────────────
dn: ou=usuarios,dc=tfg,dc=com
objectClass: organizationalUnit
objectClass: top
ou: usuarios
description: Cuentas personales de los trabajadores de TechSolutions SL
# ── Unidad Organizativa: Grupos ───────────────────────────────
dn: ou=grupos,dc=tfg,dc=com
objectClass: organizationalUnit
objectClass: top
ou: grupos
description: Grupos departamentales para control de acceso
# ── Unidad Organizativa: Servicios ───────────────────────────
dn: ou=servicios,dc=tfg,dc=com
objectClass: organizationalUnit
objectClass: top
ou: servicios
description: Cuentas de servicio sin acceso interactivo
# ══════════════════════════════════════════════════════════════
# GRUPOS — VLAN 10 (Usuarios internos del ERP)
# ══════════════════════════════════════════════════════════════
# Becarios: acceso de solo lectura, sin permisos de eliminación
dn: cn=becarios,ou=grupos,dc=tfg,dc=com
objectClass: groupOfNames
objectClass: top
cn: becarios
description: Becarios - acceso solo lectura en Odoo, no pueden eliminar registros
member: cn=placeholder,ou=grupos,dc=tfg,dc=com
# Ventas: CRM, pipeline de ventas, contactos y facturas de clientes
dn: cn=ventas,ou=grupos,dc=tfg,dc=com
objectClass: groupOfNames
objectClass: top
cn: ventas
description: Equipo de Ventas - CRM, pipeline, contactos, facturas
member: cn=placeholder,ou=grupos,dc=tfg,dc=com
# RRHH: gestión de empleados, contratos y nóminas
dn: cn=rrhh,ou=grupos,dc=tfg,dc=com
objectClass: groupOfNames
objectClass: top
cn: rrhh
description: Recursos Humanos - empleados, contratos, nominas
member: cn=placeholder,ou=grupos,dc=tfg,dc=com
# Almacén: inventario, recepciones y pedidos de compra
dn: cn=almacen,ou=grupos,dc=tfg,dc=com
objectClass: groupOfNames
objectClass: top
cn: almacen
description: Almacen - inventario, recepciones, pedidos de compra
member: cn=placeholder,ou=grupos,dc=tfg,dc=com
# Técnico: inventario + soporte técnico + permiso para cambiar contraseñas LDAP
# NOTA: Las ACLs en ldap_politica_acceso.sh le dan write sobre userPassword
dn: cn=tecnico,ou=grupos,dc=tfg,dc=com
objectClass: groupOfNames
objectClass: top
cn: tecnico
description: Tecnico - soporte, inventario, puede gestionar contrasenas LDAP de usuarios VLAN10
member: cn=placeholder,ou=grupos,dc=tfg,dc=com
# Jefe de Ventas: permisos de manager en el módulo de ventas
dn: cn=jefe_ventas,ou=grupos,dc=tfg,dc=com
objectClass: groupOfNames
objectClass: top
cn: jefe_ventas
description: Jefe de Ventas - aprobaciones y gestion completa del equipo de ventas
member: cn=placeholder,ou=grupos,dc=tfg,dc=com
# Jefe de RRHH: permisos de manager en el módulo de RRHH
dn: cn=jefe_rrhh,ou=grupos,dc=tfg,dc=com
objectClass: groupOfNames
objectClass: top
cn: jefe_rrhh
description: Jefe de RRHH - aprobaciones y gestion completa de recursos humanos
member: cn=placeholder,ou=grupos,dc=tfg,dc=com
# Jefe de Almacén: permisos de manager en el módulo de inventario
dn: cn=jefe_almacen,ou=grupos,dc=tfg,dc=com
objectClass: groupOfNames
objectClass: top
cn: jefe_almacen
description: Jefe de Almacen - aprobaciones y gestion completa de inventario y compras
member: cn=placeholder,ou=grupos,dc=tfg,dc=com
# ══════════════════════════════════════════════════════════════
# GRUPOS — VLAN 40 (Gestión del servidor)
# ══════════════════════════════════════════════════════════════
# Admin: acceso total al servidor, BD, Odoo y LDAP
# Solo accesible desde VLAN 40 (192.168.40.0/24)
dn: cn=admin,ou=grupos,dc=tfg,dc=com
objectClass: groupOfNames
objectClass: top
cn: admin
description: Administradores del sistema - acceso total desde VLAN 40
member: cn=placeholder,ou=grupos,dc=tfg,dc=com
# DBA: acceso solo a PostgreSQL y gestión de backups
# Solo accesible desde VLAN 40 (192.168.40.0/24)
dn: cn=dba,ou=grupos,dc=tfg,dc=com
objectClass: groupOfNames
objectClass: top
cn: dba
description: DBAs - gestion de base de datos PostgreSQL, sin acceso a Odoo UI
member: cn=placeholder,ou=grupos,dc=tfg,dc=com
```

### File: .\scripts\README.md
```md
# Scripts de Administración y Despliegue
**TFG ASIR 2025/2026 — TechSolutions S.L.**
> [!IMPORTANT]
> Todos los scripts están diseñados para ejecutarse **únicamente en el servidor Debian** (`192.168.30.10`).
> **No ejecutar en PCs cliente, en pfSense ni en Windows/macOS localmente.**
---
## Dar Permisos de Ejecución (Primera Vez)
```bash
# Dar permisos a todos los scripts del proyecto de una sola vez
find /opt/erp-odoo/scripts -name "*.sh" -exec chmod +x {} \;
# O individualmente:
chmod +x /opt/erp-odoo/scripts/deploy/*.sh
chmod +x /opt/erp-odoo/scripts/odoo/*.sh
chmod +x /opt/erp-odoo/scripts/ldap/*.sh
chmod +x /opt/erp-odoo/scripts/mantenimiento/*.sh
```
---
## 🚀 Despliegue y Configuración (`deploy/`)
Scripts para el ciclo de vida del stack: instalación, configuración y arranque.
| Script | Descripción | Cuándo usarlo |
|:-------|:------------|:--------------|
| `erp.sh` | **Orquestador central.** Menú interactivo para gestionar todo el proyecto sin memorizar comandos | Administración diaria |
| `deploy.sh` | Levanta el stack Docker (`docker compose up -d`) y espera confirmación de healthcheck de Odoo | Primer despliegue o arranque manual |
| `configure.sh` | Configurador interactivo del archivo `docker/.env` (pide contraseñas con eco desactivado) | Instalación inicial o cambio de credenciales |
| `install_cron.sh` | Instala las 3 tareas cron del sistema (backup, monitor, update) y aplica logrotate | Una sola vez, en la instalación inicial |
| `generate_pfsense_config.sh` | Genera `config/pfsense_config.xml` con todas las interfaces, DHCP, DNS, NAT y reglas de firewall del proyecto. El CI lo valida y lo sube como artefacto descargable | Instalación inicial de pfSense o reimplantación |
```bash
# Menú interactivo (opción recomendada para el día a día)
sudo /opt/erp-odoo/scripts/deploy/erp.sh
# Levantar el stack manualmente
bash /opt/erp-odoo/scripts/deploy/deploy.sh
# Configurar .env de forma segura
bash /opt/erp-odoo/scripts/deploy/configure.sh
# Instalar cron automático
sudo bash /opt/erp-odoo/scripts/deploy/install_cron.sh
# Generar config.xml de pfSense (también disponible como artefacto CI)
bash /opt/erp-odoo/scripts/deploy/generate_pfsense_config.sh
```
---
## 🏢 Gestión de Odoo (`odoo/`)
Scripts para la configuración interna del ERP vía API XML-RPC.
| Script | Descripción | Cuándo usarlo |
|:-------|:------------|:--------------|
| `odoo_setup_wizard.sh` | Asistente post-instalación: renombra la empresa, instala módulos y configura la conexión LDAP | Justo después del primer arranque de Odoo |
| `odoo_crear_usuarios.sh` | Crea usuarios Odoo con sus grupos de rol (becario, ventas, RRHH, etc.) vía XML-RPC | Tras la configuración de LDAP |
```bash
# Configuración inicial de Odoo (empresa + módulos + LDAP)
bash /opt/erp-odoo/scripts/odoo/odoo_setup_wizard.sh
# Crear todos los usuarios con sus roles
bash /opt/erp-odoo/scripts/odoo/odoo_crear_usuarios.sh
```
> [!WARNING]
> `odoo_crear_usuarios.sh` muestra las contraseñas generadas **una sola vez** al terminar.
> Cópialas inmediatamente en un gestor de contraseñas.
---
## 🔐 Integración LDAP (`ldap/`)
Scripts para gestionar el directorio centralizado de usuarios.
| Script | Descripción | Cuándo usarlo |
|:-------|:------------|:--------------|
| `configurar_cliente_ldap.sh` | Instala y configura SSSD + PAM + NSS en un PC cliente VLAN 10 para login con credencial LDAP | En cada PC de VLAN 10 que necesite login LDAP |
| `ldap_crear_usuarios.sh` | Crea usuarios en el directorio OpenLDAP de forma interactiva (uid, nombre, email, contraseña, grupo) | Dar de alta nuevos empleados |
| `ldap_politica_acceso.sh` | Aplica las ACLs de seguridad LDAP: admin=escritura, tecnico=solo contraseñas, readonly=lectura | Una vez tras el primer arranque de OpenLDAP |
```bash
# Aplicar ACLs (una sola vez tras instalar OpenLDAP)
bash /opt/erp-odoo/scripts/ldap/ldap_politica_acceso.sh
# Añadir un nuevo empleado al directorio
bash /opt/erp-odoo/scripts/ldap/ldap_crear_usuarios.sh
# Configurar un PC cliente VLAN 10 para login con LDAP
# (ejecutar EN EL PC CLIENTE, no en el servidor)
sudo bash /opt/erp-odoo/scripts/ldap/configurar_cliente_ldap.sh
```
---
## 🛠️ Mantenimiento y Operaciones (`mantenimiento/`)
Scripts para el mantenimiento automatizado del sistema ERP.
| Script | Descripción | Cuándo usarlo | Cron |
|:-------|:------------|:--------------|:-----|
| `backup.sh` | Volcado completo de PostgreSQL en formato comprimido (`pg_dump -F c`). Retención de 7 días. | Manual o por cron | Diario 02:00 |
| `restore.sh` | Borra la BD actual, la recrea limpia y restaura desde un archivo `.dump` | Recuperación ante desastres | Manual |
| `monitor.sh` | Comprueba que los 4 contenedores están `Up`. Si alguno falla, lo reinicia y lo registra en log | Por cron | Cada 15 min |
| `update.sh` | Descarga las últimas imágenes Docker, reinicia los contenedores y elimina imágenes huérfanas | Por cron | Domingos 03:00 |
```bash
# Backup manual
bash /opt/erp-odoo/scripts/mantenimiento/backup.sh
# Restaurar desde un backup específico
bash /opt/erp-odoo/scripts/mantenimiento/restore.sh /opt/erp-odoo/backups/erp_20260513_020001.dump
# Chequeo de salud manual
bash /opt/erp-odoo/scripts/mantenimiento/monitor.sh
# Actualización manual de imágenes Docker
bash /opt/erp-odoo/scripts/mantenimiento/update.sh
# Ver los backups disponibles
ls -lh /opt/erp-odoo/backups/
```
---
## Referencia Rápida — Comandos Docker
```bash
# Estado de los contenedores
docker compose -f /opt/erp-odoo/docker/docker-compose.yml ps
# Logs en tiempo real (todos)
docker compose -f /opt/erp-odoo/docker/docker-compose.yml logs -f
# Logs de un servicio específico
docker compose -f /opt/erp-odoo/docker/docker-compose.yml logs -f odoo-web
# Reiniciar un servicio
docker compose -f /opt/erp-odoo/docker/docker-compose.yml restart nginx-proxy
# Parar todo el stack
docker compose -f /opt/erp-odoo/docker/docker-compose.yml down
# Arrancar todo el stack
docker compose -f /opt/erp-odoo/docker/docker-compose.yml up -d
# Entrar a la consola de PostgreSQL
docker exec -it odoo_erp psql -U odoo -d odoo_erp
# Limpiar imágenes sin usar
docker system prune -f
```
---
*Guía de instalación completa: [`docs/INSTALACION_COMPLETA.md`](../docs/INSTALACION_COMPLETA.md)*
```

### File: .\scripts\repomix_lite.py
```py
import os
import re
import fnmatch
def should_ignore(path, ignore_patterns):
    for pattern in ignore_patterns:
        if fnmatch.fnmatch(path, pattern) or fnmatch.fnmatch(os.path.basename(path), pattern):
            return True
        if any(fnmatch.fnmatch(part, pattern.strip('/')) for part in path.split(os.sep)):
            return True
    return False
def clean_content(content, ext):
    if ext in ['.sh', '.py', '.yml', '.yaml', '.conf']:
        content = re.sub(r'(^|\s)#.*', '', content)
    elif ext in ['.js', '.css']:
        content = re.sub(r'/\*.*?\*/', '', content, flags=re.DOTALL)
        content = re.sub(r'//.*', '', content)
    elif ext in ['.html', '.xml']:
        content = re.sub(r'<!--.*?-->', '', content, flags=re.DOTALL)
    lines = [line for line in content.splitlines() if line.strip()]
    return "\n".join(lines)
def main():
    root_dir = "."
    output_file = "repomix-output.md"
    ignore_file = ".repomixignore"
    ignore_patterns = ['.git', 'repomix-output.md', '__pycache__', '*.iso', '*.png', '*.jpg', '*.pdf']
    if os.path.exists(ignore_file):
        with open(ignore_file, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#'):
                    ignore_patterns.append(line)
    with open(output_file, 'w', encoding='utf-8') as out:
        out.write("# Repository Analysis: TFG-ASIRB\n\n")
        out.write("## Directory Structure\n```text\n")
        for root, dirs, files in os.walk(root_dir):
            dirs[:] = [d for d in dirs if not should_ignore(os.path.join(root, d), ignore_patterns)]
            level = root.replace(root_dir, '').count(os.sep)
            indent = ' ' * 4 * level
            out.write(f"{indent}{os.path.basename(root)}/\n")
            sub_indent = ' ' * 4 * (level + 1)
            for f in files:
                if not should_ignore(os.path.join(root, f), ignore_patterns):
                    out.write(f"{sub_indent}{f}\n")
        out.write("```\n\n## File Contents\n\n")
        for root, dirs, files in os.walk(root_dir):
            dirs[:] = [d for d in dirs if not should_ignore(os.path.join(root, d), ignore_patterns)]
            for f in files:
                file_path = os.path.join(root, f)
                if should_ignore(file_path, ignore_patterns):
                    continue
                ext = os.path.splitext(f)[1].lower()
                if ext in ['.iso', '.png', '.jpg', '.pdf', '.exe', '.zip', '.tar', '.gz']:
                    continue
                try:
                    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f_in:
                        content = f_in.read()
                        cleaned = clean_content(content, ext)
                        out.write(f"### File: {file_path}\n")
                        out.write(f"```{ext.strip('.') or 'text'}\n")
                        out.write(cleaned)
                        out.write("\n```\n\n")
                except Exception as e:
                    print(f"Error reading {file_path}: {e}")
if __name__ == "__main__":
    main()
```

### File: .\scripts\deploy\configure.sh
```sh
set -euo pipefail
PROJECT_DIR="/opt/erp-odoo"
ENV_TEMPLATE="$PROJECT_DIR/.env.example"
ENV_FILE="$PROJECT_DIR/docker/.env"
[ ! -f "$ENV_TEMPLATE" ] && { echo "[ERROR] No existe $ENV_TEMPLATE"; exit 1; }
mkdir -p "$PROJECT_DIR/docker"
if [ -f "$ENV_FILE" ]; then
    read -rp "El archivo $ENV_FILE ya existe. ¿Sobreescribir? (y/N): " r
    [[ "${r,,}" != "y" ]] && { echo "Usando configuración existente."; exit 0; }
fi
cp "$ENV_TEMPLATE" "$ENV_FILE"
echo "Introduce las contraseñas del entorno:"
read -rsp "POSTGRES_PASSWORD:      " PG;      echo ""
read -rsp "ODOO_MASTER_PASSWORD:   " ODOO;    echo ""
read -rsp "LDAP_ADMIN_PASSWORD:    " LDAP_A;  echo ""
read -rsp "LDAP_READONLY_PASSWORD: " LDAP_R;  echo ""
set_var() {
    local key="$1" val="$2"
    local escaped; escaped=$(printf '%s' "$val" | sed 's/[\/&]/\\&/g')
    sed -i "s|^${key}=.*|${key}=${escaped}|" "$ENV_FILE"
}
set_var POSTGRES_PASSWORD      "$PG"
set_var ODOO_MASTER_PASSWORD   "$ODOO"
set_var LDAP_ADMIN_PASSWORD    "$LDAP_A"
set_var LDAP_READONLY_PASSWORD "$LDAP_R"
chmod 600 "$ENV_FILE"
echo "[OK] $ENV_FILE configurado (permisos 600)."
```

### File: .\scripts\deploy\deploy.sh
```sh
set -e
PROJECT_DIR="/opt/erp-odoo"
COMPOSE_FILE="$PROJECT_DIR/docker/docker-compose.yml"
MAX_INTENTOS=30  
echo "[1/4] Comprobaciones previas..."
command -v docker &>/dev/null || { echo "[ERROR] Docker no está instalado."; exit 1; }
docker info &>/dev/null         || { echo "[ERROR] Docker no está activo o sin permisos."; exit 1; }
cd "$PROJECT_DIR" || exit 1
docker compose -f "$COMPOSE_FILE" config -q \
    || { echo "[ERROR] docker-compose.yml tiene errores de sintaxis."; exit 1; }
NGINX_UP=$(docker ps --filter "name=nginx-proxy" --filter "status=running" -q)
for PORT in 80 443; do
    if ss -tlnp | grep -q ":${PORT} " && [ -z "$NGINX_UP" ]; then
        echo "[ERROR] Puerto $PORT en uso por un proceso externo al stack."
        exit 1
    fi
done
echo "[2/4] Levantando contenedores..."
docker compose -f "$COMPOSE_FILE" up -d
echo "[3/4] Comprobando base de datos..."
sleep 5 
HAS_DB=$(docker exec odoo_erp psql -U odoo -d odoo_erp -tAc \
    "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name='ir_module_module');" \
    2>/dev/null || echo "f")
if [ "$HAS_DB" = "f" ]; then
    echo "  [!] BD vacía — inicializando Odoo (1-2 min)..."
    MASTER_PASS=$(grep -E '^ODOO_MASTER_PASSWORD=' "$PROJECT_DIR/docker/.env" \
        | cut -d= -f2- | tr -d '"')
    docker exec odoo-web \
        odoo -c /etc/odoo/odoo.conf \
             -w "$MASTER_PASS" \
             -d odoo_erp \
             -i base \
             --stop-after-init \
             --http-port=8070
    echo "  [OK] BD inicializada."
else
    echo "  [OK] BD ya inicializada."
fi
echo "[4/4] Esperando a Odoo (máx. $((MAX_INTENTOS * 10))s)..."
for i in $(seq 1 $MAX_INTENTOS); do
    if curl -sf -k https://localhost/web/health -o /dev/null 2>/dev/null; then
        echo ""
        echo "[OK] Stack operativo en https://erp.odoo.tfg.com"
        docker compose -f "$COMPOSE_FILE" ps
        exit 0
    fi
    echo "  Intento $i/$MAX_INTENTOS — esperando 10s..."
    sleep 10
done
echo "[ERROR] Odoo no respondió. Logs:"
docker compose -f "$COMPOSE_FILE" logs --tail=30
exit 1
```

### File: .\scripts\deploy\erp.sh
```sh
PROJECT_DIR="/opt/erp-odoo"
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$PROJECT_DIR/docker/docker-compose.yml"
LOG_FILE="/var/log/erp-odoo/erp.log"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'
log() {
    local nivel="$1"; shift
    local mensaje="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "[$timestamp] [$nivel] $mensaje" >> "$LOG_FILE"
}
ok()   { echo -e "${GREEN}  [OK]${NC} $*"; log "OK" "$*"; }
warn() { echo -e "${YELLOW}  [!]${NC}  $*"; log "WARN" "$*"; }
error(){ echo -e "${RED}  [ERROR]${NC} $*"; log "ERROR" "$*"; }
info() { echo -e "${CYAN}  [i]${NC}  $*"; log "INFO" "$*"; }
pausa() {
    echo ""
    read -rp "  Pulsa ENTER para volver al menú..."
}
requerir_root() {
    if [ "$EUID" -ne 0 ]; then
        error "Este script debe ejecutarse como root o con sudo."
        exit 1
    fi
}
estado_contenedores() {
    echo -e "${BOLD}\n  Estado actual de los contenedores:${NC}"
    docker compose -f "$COMPOSE_FILE" ps --format \
        "table {{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || \
        docker compose -f "$COMPOSE_FILE" ps
}
cabecera() {
    clear
    echo -e "${BLUE}${BOLD}"
    echo "  ╔══════════════════════════════════════════════════════════╗"
    echo "  ║         GESTOR ERP ODOO — TFG ASIR 2025/2026            ║"
    echo "  ║         TechSolutions S.L. — Servidor DMZ               ║"
    echo "  ╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "  ${CYAN}Nginx${NC}  → https://192.168.30.20"
    echo -e "  ${CYAN}Odoo${NC}   → https://192.168.30.21"
    echo -e "  ${CYAN}Logs${NC}   → $LOG_FILE"
    echo ""
}
opcion_estado() {
    cabecera
    echo -e "${BOLD}  ── Estado del Stack ──────────────────────────────────────${NC}"
    estado_contenedores
    echo ""
    info "Uso de recursos Docker:"
    docker stats --no-stream --format \
        "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" 2>/dev/null
    pausa
}
opcion_iniciar() {
    cabecera
    echo -e "${BOLD}  ── Iniciar Stack ─────────────────────────────────────────${NC}"
    info "Levantando contenedores..."
    log "INFO" "Iniciando stack Docker Compose"
    if docker compose -f "$COMPOSE_FILE" up -d; then
        ok "Stack iniciado correctamente."
        estado_contenedores
    else
        error "Fallo al iniciar el stack. Revisa los logs con la opción 7."
    fi
    pausa
}
opcion_parar() {
    cabecera
    echo -e "${BOLD}  ── Parar Stack ───────────────────────────────────────────${NC}"
    warn "Se van a detener todos los contenedores del stack."
    read -rp "  ¿Confirmas? (s/N): " confirm
    if [[ "$confirm" =~ ^[sS]$ ]]; then
        log "INFO" "Parando stack Docker Compose"
        docker compose -f "$COMPOSE_FILE" stop
        ok "Stack detenido."
    else
        info "Operación cancelada."
    fi
    pausa
}
opcion_reiniciar() {
    cabecera
    echo -e "${BOLD}  ── Reiniciar Stack ───────────────────────────────────────${NC}"
    warn "Se van a reiniciar todos los contenedores."
    read -rp "  ¿Confirmas? (s/N): " confirm
    if [[ "$confirm" =~ ^[sS]$ ]]; then
        log "INFO" "Reiniciando stack Docker Compose"
        docker compose -f "$COMPOSE_FILE" restart
        ok "Stack reiniciado."
        estado_contenedores
    else
        info "Operación cancelada."
    fi
    pausa
}
opcion_backup() {
    cabecera
    echo -e "${BOLD}  ── Backup de Base de Datos ───────────────────────────────${NC}"
    info "Ejecutando backup.sh..."
    log "INFO" "Lanzando backup.sh"
    if bash "$PROJECT_DIR/scripts/mantenimiento/backup.sh"; then
        ok "Backup completado."
    else
        error "El backup falló. Revisa $LOG_FILE para más detalles."
    fi
    pausa
}
opcion_restaurar() {
    cabecera
    echo -e "${BOLD}  ── Restaurar Base de Datos ───────────────────────────────${NC}"
    warn "ATENCIÓN: Esta operación sobreescribe la base de datos actual."
    echo ""
    info "Backups disponibles:"
    ls -lh /opt/erp-odoo/backups/*.dump 2>/dev/null || \
        warn "No se encontraron archivos .dump en /opt/erp-odoo/backups/"
    echo ""
    read -rp "  Introduce el nombre del archivo .dump a restaurar: " dump_file
    if [ -f "/opt/erp-odoo/backups/$dump_file" ]; then
        log "INFO" "Restaurando desde $dump_file"
        bash "$PROJECT_DIR/scripts/mantenimiento/restore.sh" "/opt/erp-odoo/backups/$dump_file"
    else
        error "Archivo no encontrado: /opt/erp-odoo/backups/$dump_file"
    fi
    pausa
}
opcion_actualizar() {
    cabecera
    echo -e "${BOLD}  ── Actualizar Imágenes Docker ────────────────────────────${NC}"
    warn "Se descargarán las últimas imágenes y se recrearán los contenedores."
    read -rp "  ¿Confirmas? (s/N): " confirm
    if [[ "$confirm" =~ ^[sS]$ ]]; then
        log "INFO" "Lanzando update.sh"
        bash "$PROJECT_DIR/scripts/mantenimiento/update.sh"
    else
        info "Operación cancelada."
    fi
    pausa
}
opcion_logs() {
    cabecera
    echo -e "${BOLD}  ── Logs de Contenedores ──────────────────────────────────${NC}"
    echo ""
    echo "  ¿De qué contenedor quieres ver los logs?"
    echo "  1) nginx-proxy"
    echo "  2) odoo-web"
    echo "  3) odoo_erp (PostgreSQL)"
    echo "  4) Todos (últimas 50 líneas)"
    echo ""
    read -rp "  Opción: " log_op
    case $log_op in
        1) docker logs nginx-proxy --tail 50 -f ;;
        2) docker logs odoo-web --tail 50 -f ;;
        3) docker logs odoo_erp --tail 50 -f ;;
        4) docker compose -f "$COMPOSE_FILE" logs --tail 50 -f ;;
        *) warn "Opción no válida." ;;
    esac
    pausa
}
opcion_monitor() {
    cabecera
    echo -e "${BOLD}  ── Monitor de Salud ──────────────────────────────────────${NC}"
    log "INFO" "Lanzando monitor.sh"
    bash "$PROJECT_DIR/scripts/mantenimiento/monitor.sh"
    pausa
}
opcion_despliegue_completo() {
    cabecera
    echo -e "${BOLD}  ── Despliegue Completo (Primera vez) ────────────────────${NC}"
    warn "Esto ejecuta deploy.sh — despliegue inicial con verificación de salud."
    read -rp "  ¿Confirmas? (s/N): " confirm
    if [[ "$confirm" =~ ^[sS]$ ]]; then
        log "INFO" "Lanzando deploy.sh"
        bash "$SCRIPTS_DIR/deploy.sh"
    else
        info "Operación cancelada."
    fi
    pausa
}
menu_principal() {
    while true; do
        cabecera
        echo -e "${BOLD}  ── Gestión del Stack ─────────────────────────────────────${NC}"
        echo "  1) Estado de contenedores y recursos"
        echo "  2) Iniciar stack"
        echo "  3) Parar stack"
        echo "  4) Reiniciar stack"
        echo ""
        echo -e "${BOLD}  ── Base de Datos ─────────────────────────────────────────${NC}"
        echo "  5) Hacer backup"
        echo "  6) Restaurar backup"
        echo ""
        echo -e "${BOLD}  ── Mantenimiento ─────────────────────────────────────────${NC}"
        echo "  7) Ver logs de contenedores"
        echo "  8) Monitor de salud"
        echo "  9) Actualizar imágenes Docker"
        echo " 10) Despliegue completo (primera vez / re-deploy)"
        echo ""
        echo -e "  ${RED}0) Salir${NC}"
        echo ""
        read -rp "  Selecciona una opción [0-10]: " opcion
        case $opcion in
            1)  opcion_estado ;;
            2)  opcion_iniciar ;;
            3)  opcion_parar ;;
            4)  opcion_reiniciar ;;
            5)  opcion_backup ;;
            6)  opcion_restaurar ;;
            7)  opcion_logs ;;
            8)  opcion_monitor ;;
            9)  opcion_actualizar ;;
            10) opcion_despliegue_completo ;;
            0)  echo -e "\n  ${GREEN}Hasta luego.${NC}\n"; log "INFO" "Sesión erp.sh cerrada"; exit 0 ;;
            *)  warn "Opción no válida. Elige entre 0 y 10."; sleep 1 ;;
        esac
    done
}
requerir_root
menu_principal
```

### File: .\scripts\deploy\generate_pfsense_config.sh
```sh
set -euo pipefail
WAN_IF="vtnet0"
LAN_IF="vtnet1"
DMZ_IF="vtnet2"
ADMIN_IF="vtnet3"
LAN_IP="192.168.10.1"
LAN_SUBNET="24"
LAN_DHCP_START="192.168.10.100"
LAN_DHCP_END="192.168.10.200"
DMZ_IP="192.168.30.1"
DMZ_SUBNET="24"
SERVER_IP="192.168.30.10"
NGINX_IP="192.168.30.20"
ODOO_IP="192.168.30.21"
LDAP_IP="192.168.30.22"
ADMIN_IP="192.168.40.1"
ADMIN_SUBNET="24"
ADMIN_DHCP_START="192.168.40.10"
ADMIN_DHCP_END="192.168.40.50"
HOSTNAME="pfsense"
DOMAIN="tfg.com"
TIMEZONE="Europe/Madrid"
DNS_HOST="erp.odoo"
DNS_DOMAIN="tfg.com"
DNS_TARGET="$SERVER_IP"
ADMIN_HASH='$2b$10$XnBAqMBPIZoGweMJsHLx9OFXzO/UMMBNkSYUFODjWsXsgYyMoGxIy'
OUTPUT_DIR="$(cd "$(dirname "$0")/../.." && pwd)/config"
mkdir -p "$OUTPUT_DIR"
OUTPUT_FILE="$OUTPUT_DIR/pfsense_config.xml"
echo "=== Generador de config.xml para pfSense ==="
echo "Archivo de salida: $OUTPUT_FILE"
TS=$(date +%s)
cat > "$OUTPUT_FILE" << 'XMLEOF'
<?xml version="1.0"?>
<pfsense>
  <version>24.0</version>
  <lastchange></lastchange>
XMLEOF
{
cat << XMLEOF
  <system>
    <optimization>normal</optimization>
    <hostname>${HOSTNAME}</hostname>
    <domain>${DOMAIN}</domain>
    <timeservers>pool.ntp.org</timeservers>
    <timezone>${TIMEZONE}</timezone>
    <language>es_ES</language>
    <dnsallowoverride>on</dnsallowoverride>
    <disablechecksumoffloading>on</disablechecksumoffloading>
    <webgui>
      <protocol>https</protocol>
      <port>443</port>
      <max_procs>2</max_procs>
      <noantilockout/>
    </webgui>
    <user>
      <name>admin</name>
      <descr><![CDATA[System Administrator]]></descr>
      <scope>system</scope>
      <groupname>admins</groupname>
      <bcrypt-hash>${ADMIN_HASH}</bcrypt-hash>
      <uid>0</uid>
      <priv>page-all</priv>
    </user>
    <group>
      <name>admins</name>
      <description><![CDATA[System Administrators]]></description>
      <scope>system</scope>
      <gid>1999</gid>
      <member>0</member>
      <priv>page-all</priv>
    </group>
    <disablenatreflection>yes</disablenatreflection>
    <bogonsinterval>monthly</bogonsinterval>
  </system>
XMLEOF
cat << XMLEOF
  <interfaces>
    <wan>
      <enable/>
      <if>${WAN_IF}</if>
      <descr><![CDATA[WAN]]></descr>
      <ipaddr>dhcp</ipaddr>
      <dhcphostname/>
      <blockpriv/>
      <blockbogons/>
      <spoofmac/>
    </wan>
    <lan>
      <enable/>
      <if>${LAN_IF}</if>
      <descr><![CDATA[LAN]]></descr>
      <ipaddr>${LAN_IP}</ipaddr>
      <subnet>${LAN_SUBNET}</subnet>
      <spoofmac/>
    </lan>
    <opt1>
      <enable/>
      <if>${DMZ_IF}</if>
      <descr><![CDATA[DMZ]]></descr>
      <ipaddr>${DMZ_IP}</ipaddr>
      <subnet>${DMZ_SUBNET}</subnet>
      <spoofmac/>
    </opt1>
    <opt2>
      <enable/>
      <if>${ADMIN_IF}</if>
      <descr><![CDATA[VLAN_ADMIN]]></descr>
      <ipaddr>${ADMIN_IP}</ipaddr>
      <subnet>${ADMIN_SUBNET}</subnet>
      <spoofmac/>
    </opt2>
  </interfaces>
XMLEOF
cat << XMLEOF
  <dhcpd>
    <lan>
      <enable/>
      <range>
        <from>${LAN_DHCP_START}</from>
        <to>${LAN_DHCP_END}</to>
      </range>
      <gateway>${LAN_IP}</gateway>
      <dnsserver>${LAN_IP}</dnsserver>
    </lan>
    <opt2>
      <enable/>
      <range>
        <from>${ADMIN_DHCP_START}</from>
        <to>${ADMIN_DHCP_END}</to>
      </range>
      <dnsserver>${ADMIN_IP}</dnsserver>
    </opt2>
  </dhcpd>
XMLEOF
cat << XMLEOF
  <unbound>
    <enable>on</enable>
    <dnssec/>
    <active_interface>lan,opt1,opt2,lo0</active_interface>
    <outgoing_interface>wan</outgoing_interface>
    <hosts>
      <host>${DNS_HOST}</host>
      <domain>${DNS_DOMAIN}</domain>
      <ip>${DNS_TARGET}</ip>
      <descr><![CDATA[Servidor Odoo ERP - DMZ]]></descr>
    </hosts>
  </unbound>
XMLEOF
cat << XMLEOF
  <nat>
    <outbound>
      <mode>automatic</mode>
    </outbound>
    <rule>
      <descr><![CDATA[HTTP publico - Nginx Odoo]]></descr>
      <interface>wan</interface>
      <protocol>tcp</protocol>
      <source><any/></source>
      <destination>
        <network>wanip</network>
        <port>80</port>
      </destination>
      <target>${SERVER_IP}</target>
      <local-port>80</local-port>
      <associated-rule-id>pass</associated-rule-id>
    </rule>
    <rule>
      <descr><![CDATA[HTTPS publico - Nginx Odoo]]></descr>
      <interface>wan</interface>
      <protocol>tcp</protocol>
      <source><any/></source>
      <destination>
        <network>wanip</network>
        <port>443</port>
      </destination>
      <target>${SERVER_IP}</target>
      <local-port>443</local-port>
      <associated-rule-id>pass</associated-rule-id>
    </rule>
    <rule>
      <descr><![CDATA[Forzar DNS VLAN 10 a pfSense]]></descr>
      <interface>lan</interface>
      <protocol>tcp/udp</protocol>
      <source>
        <network>lan</network>
      </source>
      <destination>
        <any/>
        <port>53</port>
      </destination>
      <target>${LAN_IP}</target>
      <local-port>53</local-port>
      <associated-rule-id>pass</associated-rule-id>
    </rule>
    <rule>
      <descr><![CDATA[Forzar DNS VLAN 40 a pfSense]]></descr>
      <interface>opt2</interface>
      <protocol>tcp/udp</protocol>
      <source>
        <network>opt2</network>
      </source>
      <destination>
        <any/>
        <port>53</port>
      </destination>
      <target>${ADMIN_IP}</target>
      <local-port>53</local-port>
      <associated-rule-id>pass</associated-rule-id>
    </rule>
  </nat>
XMLEOF
cat << XMLEOF
  <aliases>
    <alias>
      <name>Servidor_Debian</name>
      <type>host</type>
      <address>${SERVER_IP}</address>
      <descr><![CDATA[Servidor Debian DMZ]]></descr>
    </alias>
    <alias>
      <name>Nginx_Proxy</name>
      <type>host</type>
      <address>${NGINX_IP}</address>
      <descr><![CDATA[Nginx Reverse Proxy]]></descr>
    </alias>
    <alias>
      <name>OpenLDAP</name>
      <type>host</type>
      <address>${LDAP_IP}</address>
      <descr><![CDATA[Contenedor OpenLDAP]]></descr>
    </alias>
    <alias>
      <name>VLAN_Clientes</name>
      <type>network</type>
      <address>192.168.10.0/24</address>
      <descr><![CDATA[Red VLAN 10 - Clientes]]></descr>
    </alias>
    <alias>
      <name>VLAN_Admin</name>
      <type>network</type>
      <address>192.168.40.0/24</address>
      <descr><![CDATA[Red VLAN 40 - Administracion]]></descr>
    </alias>
  </aliases>
XMLEOF
cat << XMLEOF
  <filter>
    <!-- ===================== WAN ===================== -->
    <!-- WAN Pos.3: HTTP publico -->
    <rule>
      <type>pass</type>
      <ipprotocol>inet</ipprotocol>
      <protocol>tcp</protocol>
      <interface>wan</interface>
      <source><any/></source>
      <destination>
        <network>wanip</network>
        <port>80</port>
      </destination>
      <descr><![CDATA[HTTP publico - redirige a HTTPS]]></descr>
    </rule>
    <!-- WAN Pos.4: HTTPS publico -->
    <rule>
      <type>pass</type>
      <ipprotocol>inet</ipprotocol>
      <protocol>tcp</protocol>
      <interface>wan</interface>
      <source><any/></source>
      <destination>
        <network>wanip</network>
        <port>443</port>
      </destination>
      <descr><![CDATA[HTTPS publico - Odoo]]></descr>
    </rule>
    <!-- WAN Pos.5: Deny all -->
    <rule>
      <type>block</type>
      <ipprotocol>inet</ipprotocol>
      <interface>wan</interface>
      <source><any/></source>
      <destination><any/></destination>
      <descr><![CDATA[Bloquear todo lo demas WAN]]></descr>
    </rule>
    <!-- ===================== LAN (VLAN 10) ===================== -->
    <!-- LAN Pos.1: Bloquear acceso a VLAN Admin -->
    <rule>
      <type>block</type>
      <ipprotocol>inet</ipprotocol>
      <interface>lan</interface>
      <source><network>lan</network></source>
      <destination>
        <address>192.168.40.0/24</address>
      </destination>
      <descr><![CDATA[Bloquear acceso a VLAN Admin]]></descr>
    </rule>
    <!-- LAN Pos.2: Bloquear SSH al servidor -->
    <rule>
      <type>block</type>
      <ipprotocol>inet</ipprotocol>
      <interface>lan</interface>
      <source><network>lan</network></source>
      <destination>
        <address>${SERVER_IP}</address>
        <port>22</port>
      </destination>
      <descr><![CDATA[Bloquear SSH al servidor]]></descr>
    </rule>
    <!-- LAN Pos.3: Bloquear Cockpit -->
    <rule>
      <type>block</type>
      <ipprotocol>inet</ipprotocol>
      <interface>lan</interface>
      <source><network>lan</network></source>
      <destination>
        <address>${SERVER_IP}</address>
        <port>9090</port>
      </destination>
      <descr><![CDATA[Bloquear Cockpit]]></descr>
    </rule>
    <!-- LAN Pos.4: Bloquear LDAPS admin -->
    <rule>
      <type>block</type>
      <ipprotocol>inet</ipprotocol>
      <interface>lan</interface>
      <source><network>lan</network></source>
      <destination>
        <address>${LDAP_IP}</address>
        <port>636</port>
      </destination>
      <descr><![CDATA[Bloquear LDAPS admin]]></descr>
    </rule>
    <!-- LAN Pos.5: Bloquear PostgreSQL -->
    <rule>
      <type>block</type>
      <ipprotocol>inet</ipprotocol>
      <interface>lan</interface>
      <source><network>lan</network></source>
      <destination>
        <address>192.168.30.0/24</address>
        <port>5432</port>
      </destination>
      <descr><![CDATA[Bloquear PostgreSQL]]></descr>
    </rule>
    <!-- LAN Pos.7: Odoo HTTP via Nginx -->
    <rule>
      <type>pass</type>
      <ipprotocol>inet</ipprotocol>
      <protocol>tcp</protocol>
      <interface>lan</interface>
      <source><network>lan</network></source>
      <destination>
        <address>${SERVER_IP}</address>
        <port>80</port>
      </destination>
      <descr><![CDATA[Odoo HTTP via Nginx]]></descr>
    </rule>
    <!-- LAN Pos.8: Odoo HTTPS via Nginx -->
    <rule>
      <type>pass</type>
      <ipprotocol>inet</ipprotocol>
      <protocol>tcp</protocol>
      <interface>lan</interface>
      <source><network>lan</network></source>
      <destination>
        <address>${SERVER_IP}</address>
        <port>443</port>
      </destination>
      <descr><![CDATA[Odoo HTTPS via Nginx]]></descr>
    </rule>
    <!-- LAN Pos.9: LDAP autenticacion readonly -->
    <rule>
      <type>pass</type>
      <ipprotocol>inet</ipprotocol>
      <protocol>tcp</protocol>
      <interface>lan</interface>
      <source><network>lan</network></source>
      <destination>
        <address>${LDAP_IP}</address>
        <port>389</port>
      </destination>
      <descr><![CDATA[LDAP autenticacion readonly]]></descr>
    </rule>
    <!-- LAN Pos.10: Navegacion general Internet -->
    <rule>
      <type>pass</type>
      <ipprotocol>inet</ipprotocol>
      <interface>lan</interface>
      <source><network>lan</network></source>
      <destination><any/></destination>
      <descr><![CDATA[Navegacion general Internet]]></descr>
    </rule>
    <!-- LAN Pos.11: Deny all -->
    <rule>
      <type>block</type>
      <ipprotocol>inet</ipprotocol>
      <interface>lan</interface>
      <source><any/></source>
      <destination><any/></destination>
      <descr><![CDATA[Deny all LAN]]></descr>
    </rule>
    <!-- ===================== OPT1 / DMZ (VLAN 30) ===================== -->
    <!-- DMZ Pos.1: Anti-pivoting a VLAN 10 -->
    <rule>
      <type>block</type>
      <ipprotocol>inet</ipprotocol>
      <interface>opt1</interface>
      <source><network>opt1</network></source>
      <destination>
        <address>192.168.10.0/24</address>
      </destination>
      <descr><![CDATA[DMZ NO puede atacar VLAN 10]]></descr>
    </rule>
    <!-- DMZ Pos.2: DMZ no accede a pfSense LAN -->
    <rule>
      <type>block</type>
      <ipprotocol>inet</ipprotocol>
      <interface>opt1</interface>
      <source><network>opt1</network></source>
      <destination>
        <address>${LAN_IP}</address>
      </destination>
      <descr><![CDATA[DMZ NO puede acceder a pfSense LAN]]></descr>
    </rule>
    <!-- DMZ Pos.3: Anti-pivoting a VLAN Admin -->
    <rule>
      <type>block</type>
      <ipprotocol>inet</ipprotocol>
      <interface>opt1</interface>
      <source><network>opt1</network></source>
      <destination>
        <address>192.168.40.0/24</address>
      </destination>
      <descr><![CDATA[DMZ NO puede acceder a VLAN Admin]]></descr>
    </rule>
    <!-- DMZ Pos.4: Actualizaciones HTTP -->
    <rule>
      <type>pass</type>
      <ipprotocol>inet</ipprotocol>
      <protocol>tcp</protocol>
      <interface>opt1</interface>
      <source><network>opt1</network></source>
      <destination>
        <any/>
        <port>80</port>
      </destination>
      <descr><![CDATA[Actualizaciones HTTP]]></descr>
    </rule>
    <!-- DMZ Pos.5: Actualizaciones HTTPS -->
    <rule>
      <type>pass</type>
      <ipprotocol>inet</ipprotocol>
      <protocol>tcp</protocol>
      <interface>opt1</interface>
      <source><network>opt1</network></source>
      <destination>
        <any/>
        <port>443</port>
      </destination>
      <descr><![CDATA[Actualizaciones HTTPS]]></descr>
    </rule>
    <!-- DMZ Pos.6: DNS resolucion -->
    <rule>
      <type>pass</type>
      <ipprotocol>inet</ipprotocol>
      <protocol>udp</protocol>
      <interface>opt1</interface>
      <source><network>opt1</network></source>
      <destination>
        <any/>
        <port>53</port>
      </destination>
      <descr><![CDATA[DNS resolucion de nombres]]></descr>
    </rule>
    <!-- DMZ Pos.7: Deny all -->
    <rule>
      <type>block</type>
      <ipprotocol>inet</ipprotocol>
      <interface>opt1</interface>
      <source><any/></source>
      <destination><any/></destination>
      <descr><![CDATA[Bloquear todo lo demas DMZ]]></descr>
    </rule>
    <!-- ===================== OPT2 / VLAN 40 (Admin) ===================== -->
    <!-- ADMIN Pos.1: Panel pfSense -->
    <rule>
      <type>pass</type>
      <ipprotocol>inet</ipprotocol>
      <protocol>tcp</protocol>
      <interface>opt2</interface>
      <source><network>opt2</network></source>
      <destination>
        <network>(self)</network>
        <port>443</port>
      </destination>
      <descr><![CDATA[Panel pfSense - acceso exclusivo VLAN 40]]></descr>
    </rule>
    <!-- ADMIN Pos.2: SSH al servidor Debian -->
    <rule>
      <type>pass</type>
      <ipprotocol>inet</ipprotocol>
      <protocol>tcp</protocol>
      <interface>opt2</interface>
      <source><network>opt2</network></source>
      <destination>
        <address>${SERVER_IP}</address>
        <port>22</port>
      </destination>
      <descr><![CDATA[SSH al servidor Debian]]></descr>
    </rule>
    <!-- ADMIN Pos.3: Cockpit -->
    <rule>
      <type>pass</type>
      <ipprotocol>inet</ipprotocol>
      <protocol>tcp</protocol>
      <interface>opt2</interface>
      <source><network>opt2</network></source>
      <destination>
        <address>${SERVER_IP}</address>
        <port>9090</port>
      </destination>
      <descr><![CDATA[Cockpit - gestion visual]]></descr>
    </rule>
    <!-- ADMIN Pos.4: Nginx/Odoo admin completo -->
    <rule>
      <type>pass</type>
      <ipprotocol>inet</ipprotocol>
      <protocol>tcp</protocol>
      <interface>opt2</interface>
      <source><network>opt2</network></source>
      <destination>
        <address>${NGINX_IP}</address>
        <port>443</port>
      </destination>
      <descr><![CDATA[Nginx/Odoo admin completo]]></descr>
    </rule>
    <!-- ADMIN Pos.5: LDAP admin -->
    <rule>
      <type>pass</type>
      <ipprotocol>inet</ipprotocol>
      <protocol>tcp</protocol>
      <interface>opt2</interface>
      <source><network>opt2</network></source>
      <destination>
        <address>${LDAP_IP}</address>
        <port>389</port>
      </destination>
      <descr><![CDATA[LDAP admin lectura y escritura]]></descr>
    </rule>
    <!-- ADMIN Pos.6: LDAPS admin cifrado -->
    <rule>
      <type>pass</type>
      <ipprotocol>inet</ipprotocol>
      <protocol>tcp</protocol>
      <interface>opt2</interface>
      <source><network>opt2</network></source>
      <destination>
        <address>${LDAP_IP}</address>
        <port>636</port>
      </destination>
      <descr><![CDATA[LDAPS admin cifrado]]></descr>
    </rule>
    <!-- ADMIN Pos.7: Internet + DNS -->
    <rule>
      <type>pass</type>
      <ipprotocol>inet</ipprotocol>
      <protocol>tcp</protocol>
      <interface>opt2</interface>
      <source><network>opt2</network></source>
      <destination>
        <any/>
        <port>80</port>
      </destination>
      <descr><![CDATA[Actualizaciones HTTP Admin]]></descr>
    </rule>
    <rule>
      <type>pass</type>
      <ipprotocol>inet</ipprotocol>
      <protocol>tcp</protocol>
      <interface>opt2</interface>
      <source><network>opt2</network></source>
      <destination>
        <any/>
        <port>443</port>
      </destination>
      <descr><![CDATA[Actualizaciones HTTPS Admin]]></descr>
    </rule>
    <rule>
      <type>pass</type>
      <ipprotocol>inet</ipprotocol>
      <protocol>udp</protocol>
      <interface>opt2</interface>
      <source><network>opt2</network></source>
      <destination>
        <any/>
        <port>53</port>
      </destination>
      <descr><![CDATA[DNS resolucion Admin]]></descr>
    </rule>
    <!-- ADMIN Pos.8: Anti-pivoting a VLAN 10 -->
    <rule>
      <type>block</type>
      <ipprotocol>inet</ipprotocol>
      <interface>opt2</interface>
      <source><network>opt2</network></source>
      <destination>
        <address>192.168.10.0/24</address>
      </destination>
      <descr><![CDATA[Anti-pivoting a VLAN 10]]></descr>
    </rule>
    <!-- ADMIN Pos.9: Deny all -->
    <rule>
      <type>block</type>
      <ipprotocol>inet</ipprotocol>
      <interface>opt2</interface>
      <source><any/></source>
      <destination><any/></destination>
      <descr><![CDATA[Deny all VLAN Admin]]></descr>
    </rule>
  </filter>
XMLEOF
cat << 'XMLEOF'
</pfsense>
XMLEOF
} >> "$OUTPUT_FILE"
echo ""
echo "[OK] Archivo generado: $OUTPUT_FILE"
echo ""
echo "=== Instrucciones de importacion ==="
echo "1. Copiar el archivo a un USB o compartirlo por red"
echo "2. En pfSense: Diagnostics → Backup/Restore"
echo "3. Pestaña 'Restore Backup Configuration'"
echo "4. Seleccionar el archivo y pulsar 'Restore Configuration'"
echo "5. pfSense se reiniciara con la configuracion aplicada"
echo ""
echo "=== Post-importacion ==="
echo "6. Cambiar la contrasena admin en el primer login"
echo "7. Configurar LDAP auth (requiere OpenLDAP activo):"
echo "   System → User Manager → Authentication Servers → + Add"
echo "8. Verificar acceso desde VLAN 40: https://192.168.40.1"
echo ""
echo "ADVERTENCIA: La autenticacion LDAP NO se incluye en el XML"
echo "porque requiere que el contenedor OpenLDAP este activo primero."
```

### File: .\scripts\deploy\install_cron.sh
```sh
set -e
[ "$(id -u)" -ne 0 ] && { echo "[ERROR] Ejecutar como root."; exit 1; }
PROJECT_DIR="/opt/erp-odoo"
CRON_FILE="/etc/cron.d/erp-odoo"
echo "Instalando tareas cron en $CRON_FILE..."
cat > "$CRON_FILE" << EOF
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
*/15 * * * * root $PROJECT_DIR/scripts/mantenimiento/monitor.sh >> /var/log/erp_monitor.log 2>&1
0 2 * * * root $PROJECT_DIR/scripts/mantenimiento/backup.sh >> /var/log/erp_backup.log 2>&1
0 3 * * 0 root $PROJECT_DIR/scripts/mantenimiento/update.sh >> /var/log/erp_update.log 2>&1
EOF
chmod 644 "$CRON_FILE"
chown root:root "$CRON_FILE"
if [ -f "$PROJECT_DIR/config/logrotate.d/erp-odoo" ]; then
    cp "$PROJECT_DIR/config/logrotate.d/erp-odoo" /etc/logrotate.d/erp-odoo
    chmod 644 /etc/logrotate.d/erp-odoo
    echo "[OK] Logrotate configurado."
fi
echo ""
echo "[OK] Cron instalado:"
echo "  - Cada 15 min  → monitor.sh"
echo "  - 02:00 diario → backup.sh"
echo "  - 03:00 domingo → update.sh"
echo ""
cat "$CRON_FILE"
```

### File: .\scripts\ldap\configurar_cliente_ldap.sh
```sh
set -euo pipefail
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'
info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[AVISO]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
title() { echo -e "\n${BOLD}${CYAN}$*${NC}"; echo "────────────────────────────────────────────"; }
if [[ "$EUID" -ne 0 ]]; then
    error "Este script debe ejecutarse como root."
    error "Usa: sudo bash scripts/ldap/configurar_cliente_ldap.sh"
    exit 1
fi
clear
echo -e "${BOLD}"
echo "  ╔══════════════════════════════════════════════════╗"
echo "  ║  Configuración LDAP en Cliente — TFG ASIR 2026  ║"
echo "  ║  Autenticación de sistema operativo vía SSSD     ║"
echo "  ╚══════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo "  Este script configura la máquina para que los usuarios"
echo "  del directorio LDAP (192.168.30.22) puedan iniciar"
echo "  sesión en el sistema operativo con sus credenciales."
echo ""
echo "  Tecnología: SSSD + PAM + NSS"
echo "  Servidor LDAP: ldap://192.168.30.22"
echo "  Base DN: dc=tfg,dc=com"
echo ""
title "⚙  Configuración de conexión al servidor LDAP"
LDAP_URI="ldap://192.168.30.22"
LDAP_BASE="dc=tfg,dc=com"
LDAP_BIND_DN="cn=readonly,dc=tfg,dc=com"
LDAP_BIND_PASS=""
read -r -p "  URI del servidor LDAP [${LDAP_URI}]: " input_uri
LDAP_URI="${input_uri:-$LDAP_URI}"
read -r -p "  Base DN [${LDAP_BASE}]: " input_base
LDAP_BASE="${input_base:-$LDAP_BASE}"
read -r -p "  Usuario de bind (readonly) [${LDAP_BIND_DN}]: " input_bind
LDAP_BIND_DN="${input_bind:-$LDAP_BIND_DN}"
read -r -s -p "  Contraseña del usuario readonly: " LDAP_BIND_PASS
echo ""
if [[ -z "$LDAP_BIND_PASS" ]]; then
    error "La contraseña no puede estar vacía."
    exit 1
fi
echo ""
echo "  ¿Restringir el acceso al sistema solo a un grupo LDAP?"
echo "  Ejemplo: 'ventas' → solo los del grupo cn=ventas pueden iniciar sesión"
echo "  Dejar vacío para permitir a TODOS los usuarios del directorio."
read -r -p "  Grupo de acceso (vacío = todos): " ACCESS_GROUP
title "1/6  Verificando conectividad con el servidor LDAP"
if ! nc -z -w 5 192.168.30.22 389 2>/dev/null; then
    error "No se puede conectar a 192.168.30.22:389."
    error "Comprueba:"
    error "  1. Que el contenedor openldap está activo en el servidor"
    error "  2. Que las reglas de pfSense permiten VLAN 10 → DMZ :389"
    error "  3. Que esta máquina está en la VLAN 10 correcta"
    exit 1
fi
ok "Conectividad con el servidor LDAP verificada."
if ! ldapsearch -H "$LDAP_URI" -D "$LDAP_BIND_DN" -w "$LDAP_BIND_PASS" \
    -b "$LDAP_BASE" -s base "(objectClass=*)" dn > /dev/null 2>&1; then
    error "Las credenciales de readonly no son correctas."
    error "Verifica la contraseña en docker/.env (LDAP_READONLY_PASSWORD)"
    exit 1
fi
ok "Autenticación con usuario readonly verificada."
title "2/6  Instalando paquetes SSSD y herramientas LDAP"
apt-get update -qq
apt-get install -y \
    sssd \
    sssd-ldap \
    libpam-sss \
    libnss-sss \
    libsss-sudo \
    ldap-utils \
    oddjob-mkhomedir \
    2>/dev/null
ok "Paquetes instalados correctamente."
title "3/6  Generando configuración de SSSD"
if [[ -n "$ACCESS_GROUP" ]]; then
    ACCESS_FILTER="(&(objectClass=posixAccount)(memberOf=cn=${ACCESS_GROUP},ou=grupos,${LDAP_BASE}))"
    info "Restricción de acceso: solo grupo '${ACCESS_GROUP}'"
else
    ACCESS_FILTER="(objectClass=posixAccount)"
    info "Acceso permitido a todos los usuarios del directorio LDAP."
fi
cat > /etc/sssd/sssd.conf << EOF
[sssd]
services = nss, pam, sudo
config_file_version = 2
domains = tfg.com
[logging]
default_domain_suffix = tfg.com
[domain/tfg.com]
id_provider = ldap
auth_provider = ldap
access_provider = ldap
ldap_uri = ${LDAP_URI}
ldap_search_base = ${LDAP_BASE}
ldap_user_search_base = ou=usuarios,${LDAP_BASE}
ldap_group_search_base = ou=grupos,${LDAP_BASE}
ldap_default_bind_dn = ${LDAP_BIND_DN}
ldap_default_authtok_type = password
ldap_default_authtok = ${LDAP_BIND_PASS}
ldap_schema = rfc2307
ldap_user_name = uid
ldap_user_gecos = cn
ldap_user_home_directory = homeDirectory
ldap_user_shell = loginShell
ldap_user_uid_number = uidNumber
ldap_user_gid_number = gidNumber
ldap_group_name = cn
ldap_group_member = member
ldap_access_filter = ${ACCESS_FILTER}
cache_credentials = true
entry_cache_timeout = 3600
ldap_network_timeout = 5
ldap_opt_timeout = 5
ldap_connection_expire_timeout = 300
fallback_homedir = /home/%u
default_shell = /bin/bash
ldap_tls_reqcert = never
ldap_referrals = false
enumerate = false
EOF
chmod 600 /etc/sssd/sssd.conf
ok "Archivo /etc/sssd/sssd.conf generado y protegido (permisos 600)."
title "4/6  Configurando PAM (creación automática de /home)"
pam-auth-update --enable sss --enable mkhomedir 2>/dev/null || {
    warn "pam-auth-update no disponible. Configurando PAM manualmente..."
    if ! grep -q "pam_mkhomedir" /etc/pam.d/common-session; then
        echo "session required pam_mkhomedir.so skel=/etc/skel umask=0077" \
            >> /etc/pam.d/common-session
        ok "pam_mkhomedir añadido a common-session."
    fi
}
ok "PAM configurado para crear directorios home automáticamente."
title "5/6  Configurando NSS (resolución de nombres)"
cp /etc/nsswitch.conf "/etc/nsswitch.conf.bak.$(date +%Y%m%d)"
sed -i 's/^passwd:.*/passwd:         files sss/' /etc/nsswitch.conf
sed -i 's/^group:.*/group:          files sss/' /etc/nsswitch.conf
sed -i 's/^shadow:.*/shadow:         files sss/' /etc/nsswitch.conf
PASSWD_LINE=$(grep "^passwd:" /etc/nsswitch.conf)
info "NSS passwd: $PASSWD_LINE"
ok "NSS configurado. Los usuarios LDAP se resolverán en el sistema."
title "6/6  Habilitando y arrancando SSSD"
systemctl enable sssd
systemctl restart sssd
sleep 3
if systemctl is-active --quiet sssd; then
    ok "SSSD está activo y funcionando."
else
    error "SSSD no arrancó correctamente."
    error "Revisa los logs: journalctl -u sssd --no-pager -n 50"
    exit 1
fi
title "✅  Verificación de la configuración"
echo ""
echo "  Probando resolución de nombres desde LDAP..."
echo "  (Esto puede tardar unos segundos mientras SSSD llena la caché)"
echo ""
if getent passwd 2>/dev/null | grep -q "ou=usuarios" || \
   ldapsearch -H "$LDAP_URI" -D "$LDAP_BIND_DN" -w "$LDAP_BIND_PASS" \
       -b "ou=usuarios,${LDAP_BASE}" "(objectClass=posixAccount)" uid 2>/dev/null \
       | grep -q "uid:"; then
    ok "Directorio LDAP accesible y con usuarios posixAccount."
else
    warn "No se encontraron usuarios con objectClass=posixAccount en LDAP."
    warn "Asegúrate de crear usuarios con ldap_crear_usuarios.sh antes de hacer login."
fi
echo ""
echo "════════════════════════════════════════════════════════════"
echo "  CONFIGURACIÓN COMPLETADA"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "  Servidor LDAP:  ${LDAP_URI}"
echo "  Base DN:        ${LDAP_BASE}"
echo "  Bind user:      ${LDAP_BIND_DN}"
if [[ -n "$ACCESS_GROUP" ]]; then
    echo "  Acceso:         Solo grupo '${ACCESS_GROUP}'"
else
    echo "  Acceso:         Todos los usuarios del directorio"
fi
echo ""
echo "  ¿Cómo funciona ahora?"
echo ""
echo "  1. En el login del PC escribe el uid del usuario LDAP"
echo "     (el mismo que usas para entrar a Odoo)"
echo "  2. SSSD verifica la contraseña contra el LDAP"
echo "  3. Si es correcta, se crea /home/<uid> automáticamente"
echo "     y se abre la sesión"
echo ""
echo "  Comandos de verificación:"
echo ""
echo "   
echo "    getent passwd | grep -v nologin"
echo ""
echo "   
echo "    getent passwd <uid_del_usuario>"
echo ""
echo "   
echo "    getent group"
echo ""
echo "   
echo "    su - <uid_del_usuario>"
echo ""
echo "   
echo "    journalctl -u sssd -f"
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""
ok "La máquina está configurada para autenticación LDAP. ✅"
echo ""
```

### File: .\scripts\ldap\ldap_crear_usuarios.sh
```sh
set -euo pipefail
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
info()  { echo -e "${CYAN}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[!]${NC}    $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
ENV_FILE="$PROJECT_DIR/docker/.env"
LDAP_CONT="openldap"
BASE_DN="dc=tfg,dc=com"
USERS_OU="ou=usuarios,${BASE_DN}"
GROUPS_OU="ou=grupos,${BASE_DN}"
BIND_DN="cn=admin,${BASE_DN}"
BIND_PASS=""
[[ -f "$ENV_FILE" ]] && \
    BIND_PASS=$(grep -E '^LDAP_ADMIN_PASSWORD=' "$ENV_FILE" | cut -d= -f2- | tr -d '"' || true)
GRUPOS_VALIDOS="becarios ventas rrhh almacen tecnico jefe_ventas jefe_rrhh jefe_almacen admin dba"
clear
echo -e "${BOLD}"
echo "  ╔══════════════════════════════════════════════════╗"
echo "  ║     Gestión de Usuarios LDAP — TFG ASIR 2026    ║"
echo "  ╚══════════════════════════════════════════════════╝"
echo -e "${NC}"
docker ps --format '{{.Names}}' | grep -q "^${LDAP_CONT}$" \
    || { error "Contenedor '$LDAP_CONT' no está activo."; exit 1; }
ok "Contenedor $LDAP_CONT activo."
read -rp "  DN admin [${BIND_DN}]: " inp; BIND_DN="${inp:-$BIND_DN}"
if [[ -z "$BIND_PASS" ]]; then
    read -rsp "  Contraseña admin LDAP: " BIND_PASS; echo ""
else
    info "Contraseña cargada desde .env"
fi
asegurar_ou() {
    local ou_dn="$1"
    local ou_name="${ou_dn%%,*}"; ou_name="${ou_name#ou=}"
    local exists
    exists=$(docker exec "$LDAP_CONT" ldapsearch \
        -x -D "$BIND_DN" -w "$BIND_PASS" \
        -b "$ou_dn" -s base "(objectClass=*)" dn 2>/dev/null | grep -c "^dn:" || true)
    if [[ "$exists" -eq 0 ]]; then
        warn "OU '$ou_dn' no existe. Creando..."
        docker exec -i "$LDAP_CONT" ldapadd -x -D "$BIND_DN" -w "$BIND_PASS" <<EOF
dn: ${ou_dn}
objectClass: organizationalUnit
ou: ${ou_name}
EOF
        ok "OU '$ou_dn' creada."
    fi
}
asegurar_ou "$USERS_OU"
asegurar_ou "$GROUPS_OU"
aniadir_grupo() {
    local uid="$1" grupo="$2"
    docker exec -i "$LDAP_CONT" ldapmodify \
        -x -D "$BIND_DN" -w "$BIND_PASS" <<EOF 2>/dev/null && return
dn: cn=${grupo},${GROUPS_OU}
changetype: modify
add: member
member: uid=${uid},${USERS_OU}
EOF
    warn "No se pudo añadir '$uid' al grupo '$grupo'."
}
while true; do
    echo ""
    echo -e "${BOLD}  ── Nuevo usuario ──────────────────────────────────────${NC}"
    read -rp "  uid (login): " UID_USER
    [[ -z "$UID_USER" ]] && { warn "El uid no puede estar vacío."; continue; }
    EXISTS=$(docker exec "$LDAP_CONT" ldapsearch \
        -x -D "$BIND_DN" -w "$BIND_PASS" \
        -b "$USERS_OU" "(uid=${UID_USER})" dn 2>/dev/null | grep -c "^dn:" || true)
    if [[ "$EXISTS" -gt 0 ]]; then
        warn "El usuario '$UID_USER' ya existe."; continue
    fi
    read -rp "  Nombre completo (cn): " CN_USER
    read -rp "  Apellido (sn): "         SN_USER
    read -rp "  Email: "                  MAIL_USER
    read -rsp "  Contraseña: "            USER_PASS; echo ""
    echo "  Grupos: $GRUPOS_VALIDOS"
    read -rp "  Grupo: " GRUPO_USER
    if ! grep -qw "$GRUPO_USER" <<< "$GRUPOS_VALIDOS"; then
        warn "Grupo '$GRUPO_USER' no reconocido. Usuario sin grupo."; GRUPO_USER=""
    fi
    docker exec -i "$LDAP_CONT" ldapadd -x -D "$BIND_DN" -w "$BIND_PASS" <<EOF
dn: uid=${UID_USER},${USERS_OU}
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
uid: ${UID_USER}
cn: ${CN_USER}
sn: ${SN_USER}
mail: ${MAIL_USER}
userPassword: ${USER_PASS}
uidNumber: $(shuf -i 2000-9999 -n 1)
gidNumber: 2000
homeDirectory: /home/${UID_USER}
loginShell: /bin/bash
EOF
    ok "Usuario '$UID_USER' creado."
    [[ -n "$GRUPO_USER" ]] && aniadir_grupo "$UID_USER" "$GRUPO_USER" && ok "Añadido al grupo '$GRUPO_USER'."
    read -rp "  ¿Añadir otro usuario? [s/N]: " otro
    [[ ! "${otro,,}" =~ ^s ]] && break
done
echo ""
echo -e "${BOLD}  Usuarios en LDAP:${NC}"
docker exec "$LDAP_CONT" ldapsearch \
    -x -D "$BIND_DN" -w "$BIND_PASS" \
    -b "$USERS_OU" "(objectClass=inetOrgPerson)" uid cn 2>/dev/null \
    | grep -E "^(dn|uid|cn):" | sed 's/^/  /'
ok "Operación finalizada. ✅"
```

### File: .\scripts\ldap\ldap_politica_acceso.sh
```sh
set -euo pipefail
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
info()  { echo -e "${CYAN}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[!]${NC}    $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
ENV_FILE="$PROJECT_DIR/docker/.env"
LDAP_CONT="openldap"
BASE_DN="dc=tfg,dc=com"
ADMIN_DN="cn=admin,${BASE_DN}"
ADMIN_PASS=""
[[ -f "$ENV_FILE" ]] && \
    ADMIN_PASS=$(grep -E '^LDAP_ADMIN_PASSWORD=' "$ENV_FILE" | cut -d= -f2- | tr -d '"' || true)
clear
echo -e "${BOLD}"
echo "  ╔══════════════════════════════════════════════════╗"
echo "  ║   Configuración de ACLs LDAP — TFG ASIR 2026    ║"
echo "  ╚══════════════════════════════════════════════════╝"
echo -e "${NC}"
docker ps --format '{{.Names}}' | grep -q "^${LDAP_CONT}$" \
    || { error "Contenedor '$LDAP_CONT' no está activo."; exit 1; }
ok "Contenedor $LDAP_CONT activo."
[[ -z "$ADMIN_PASS" ]] && { read -rsp "  Contraseña admin LDAP: " ADMIN_PASS; echo ""; }
aplicar_acl() {
    local desc="$1"
    local ldif="$2"
    info "Aplicando: $desc"
    echo "$ldif" | docker exec -i "$LDAP_CONT" \
        ldapmodify -Y EXTERNAL -H ldapi:/// 2>/dev/null \
    || echo "$ldif" | docker exec -i "$LDAP_CONT" \
        ldapmodify -x -D "$ADMIN_DN" -w "$ADMIN_PASS" 2>/dev/null \
    || warn "No se aplicó '$desc' (puede que ya exista)."
    ok "$desc aplicada."
}
aplicar_acl "ACL 1 — userPassword protegido" \
"dn: olcDatabase={1}mdb,cn=config
changetype: modify
add: olcAccess
olcAccess: {0}to attrs=userPassword,shadowLastChange
  by self write
  by dn=\"cn=admin,dc=tfg,dc=com\" write
  by group.exact=\"cn=tecnico,ou=grupos,dc=tfg,dc=com\" write
  by anonymous auth
  by * none"
aplicar_acl "ACL 2 — readonly puede leer todo el árbol" \
"dn: olcDatabase={1}mdb,cn=config
changetype: modify
add: olcAccess
olcAccess: {1}to dn.subtree=\"dc=tfg,dc=com\"
  by dn=\"cn=admin,dc=tfg,dc=com\" write
  by dn=\"cn=readonly,dc=tfg,dc=com\" read
  by self read
  by * none"
aplicar_acl "ACL 3 — tecnico puede cambiar userPassword de usuarios" \
"dn: olcDatabase={1}mdb,cn=config
changetype: modify
add: olcAccess
olcAccess: {2}to dn.subtree=\"ou=usuarios,dc=tfg,dc=com\" attrs=userPassword
  by dn=\"cn=admin,dc=tfg,dc=com\" write
  by group.exact=\"cn=tecnico,ou=grupos,dc=tfg,dc=com\" write
  by self write
  by anonymous auth
  by * none"
aplicar_acl "ACL 4 — deny all para el resto" \
"dn: olcDatabase={1}mdb,cn=config
changetype: modify
add: olcAccess
olcAccess: {3}to *
  by dn=\"cn=admin,dc=tfg,dc=com\" write
  by dn=\"cn=readonly,dc=tfg,dc=com\" read
  by * none"
echo ""
info "ACLs configuradas actualmente:"
docker exec "$LDAP_CONT" ldapsearch \
    -Y EXTERNAL -H ldapi:/// \
    -b "olcDatabase={1}mdb,cn=config" \
    "(objectClass=olcDatabaseConfig)" olcAccess 2>/dev/null \
    | grep "olcAccess:" | nl -ba | sed 's/^/  /'
echo ""
ok "Política de acceso LDAP configurada. ✅"
```

### File: .\scripts\mantenimiento\backup.sh
```sh
set -e
BACKUP_DIR="${1:-/opt/erp-odoo/backups}"
FECHA=$(date +"%Y%m%d_%H%M%S")
DB_CONT="odoo_erp"
DB_USER="odoo"
DB_NAME="odoo_erp"
mkdir -p "$BACKUP_DIR"
ESPACIO=$(df -BG "$BACKUP_DIR" | awk 'NR==2 {gsub("G","",$4); print $4}')
if [ "$ESPACIO" -lt 1 ]; then
    echo "[ERROR] Espacio libre crítico (${ESPACIO}GB). Backup cancelado."
    exit 1
fi
echo "Iniciando backup en $BACKUP_DIR..."
docker exec -t "$DB_CONT" pg_dump -U "$DB_USER" -d "$DB_NAME" -F c \
    -f "/tmp/backup_${FECHA}.dump"
docker cp "$DB_CONT:/tmp/backup_${FECHA}.dump" "$BACKUP_DIR/backup_${FECHA}.dump"
docker exec -t "$DB_CONT" rm "/tmp/backup_${FECHA}.dump"
echo "[OK] Backup: $BACKUP_DIR/backup_${FECHA}.dump"
find "$BACKUP_DIR" -name "backup_*.dump" -mtime +7 -delete
echo "[OK] Limpieza de backups >7 días completada."
```

### File: .\scripts\mantenimiento\monitor.sh
```sh
LOG_FILE="/var/log/erp_monitor.log"
CONTENEDORES=("odoo_erp" "openldap" "odoo-web" "nginx-proxy")
ALERTAS=0
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }
log "=== Chequeo de salud ERP ==="
for cont in "${CONTENEDORES[@]}"; do
    RUNNING=$(docker inspect -f '{{.State.Running}}' "$cont" 2>/dev/null || echo "false")
    HEALTH=$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$cont" 2>/dev/null)
    if [ "$RUNNING" = "true" ] && [ "$HEALTH" != "unhealthy" ]; then
        log "[OK]     $cont — en línea"
    else
        log "[ALERTA] $cont — caído o unhealthy. Reiniciando..."
        if docker start "$cont" 2>/dev/null; then
            log "[OK]     $cont reiniciado."
        else
            log "[CRÍTICO] No se pudo reiniciar $cont."
        fi
        ALERTAS=$((ALERTAS + 1))
    fi
done
if [ "$ALERTAS" -eq 0 ]; then
    log "=== Todo OK ==="
else
    log "=== $ALERTAS alertas ==="
    exit 1
fi
```

### File: .\scripts\mantenimiento\restore.sh
```sh
set -e
if [ -z "$1" ] || [ ! -f "$1" ]; then
    echo "USO: $0 /ruta/al/backup.dump"
    exit 1
fi
BKP_FILE="$1"
DB_CONT="odoo_erp"
DB_USER="odoo"
DB_NAME="odoo_erp"
echo "Copiando backup al contenedor..."
docker cp "$BKP_FILE" "$DB_CONT:/tmp/restore.dump"
echo "Recreando base de datos limpia..."
docker exec -t "$DB_CONT" dropdb  -U "$DB_USER" --if-exists "$DB_NAME"
docker exec -t "$DB_CONT" createdb -U "$DB_USER" "$DB_NAME"
echo "Restaurando datos..."
docker exec -t "$DB_CONT" pg_restore -U "$DB_USER" -d "$DB_NAME" -1 /tmp/restore.dump
docker exec -t "$DB_CONT" rm /tmp/restore.dump
echo "Reiniciando Odoo..."
docker restart odoo-web
echo "[OK] Restauración completada."
```

### File: .\scripts\mantenimiento\update.sh
```sh
set -e
PROJECT_DIR="/opt/erp-odoo"
COMPOSE_FILE="$PROJECT_DIR/docker/docker-compose.yml"
echo "Comprobando Docker..."
docker info &>/dev/null || { echo "[ERROR] Docker no está activo."; exit 1; }
ESPACIO=$(df -BG /opt | awk 'NR==2 {gsub("G","",$4); print $4}')
if [ "$ESPACIO" -lt 2 ]; then
    echo "[WARNING] Poco espacio (${ESPACIO}GB). ¿Continuar? (s/N)"
    read -r r; [[ "${r,,}" != "s" ]] && exit 1
fi
cd "$PROJECT_DIR"
echo "Descargando nuevas versiones de imágenes..."
docker compose -f "$COMPOSE_FILE" pull
echo "Recreando contenedores actualizados..."
docker compose -f "$COMPOSE_FILE" up -d
echo "Limpiando imágenes antiguas..."
docker image prune -f
echo "[OK] Actualización completada."
```

### File: .\scripts\odoo\odoo_crear_usuarios.sh
```sh
set -euo pipefail
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'
info()    { echo -e "${BLUE}[INFO]${NC}    $*"; }
ok()      { echo -e "${GREEN}[OK]${NC}      $*"; }
warn()    { echo -e "${YELLOW}[AVISO]${NC}   $*"; }
error()   { echo -e "${RED}[ERROR]${NC}   $*" >&2; }
title()   { echo -e "\n${BOLD}${CYAN}$*${NC}"; echo "────────────────────────────────────────────"; }
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
ENV_FILE="$PROJECT_DIR/docker/.env"
if [[ ! -f "$ENV_FILE" ]]; then
    error "No se encontró: $ENV_FILE"
    error "Copia docker/.env.example a docker/.env y rellena las credenciales."
    exit 1
fi
set -a
source <(grep -v '^\s*#' "$ENV_FILE" | grep -v '^\s*$')
set +a
ODOO_URL="http://localhost:8069"
ODOO_DB="${POSTGRES_DB:-odoo_erp}"
ADMIN_LOGIN="admin"
ADMIN_PASS="${ODOO_MASTER_PASSWORD:-cambia_esto}"
xmlrpc_call() {
    local endpoint="$1"
    local body="$2"
    curl -s --max-time 30 \
        -H "Content-Type: text/xml" \
        -d "$body" \
        "${ODOO_URL}${endpoint}"
}
odoo_autenticar() {
    local login="$1"
    local pass="$2"
    local respuesta
    respuesta=$(xmlrpc_call "/xmlrpc/2/common" "<?xml version='1.0'?>
<methodCall>
  <methodName>authenticate</methodName>
  <params>
    <param><value><string>${ODOO_DB}</string></value></param>
    <param><value><string>${login}</string></value></param>
    <param><value><string>${pass}</string></value></param>
    <param><value><struct/></value></param>
  </params>
</methodCall>")
    echo "$respuesta" | grep -oP '(?<=<int>)\d+(?=</int>)' | head -1
}
usuario_existe() {
    local uid="$1"; local pass="$2"; local login_buscar="$3"
    local respuesta
    respuesta=$(xmlrpc_call "/xmlrpc/2/object" "<?xml version='1.0'?>
<methodCall>
  <methodName>execute_kw</methodName>
  <params>
    <param><value><string>${ODOO_DB}</string></value></param>
    <param><value><int>${uid}</int></value></param>
    <param><value><string>${pass}</string></value></param>
    <param><value><string>res.users</string></value></param>
    <param><value><string>search</string></value></param>
    <param><value><array><data>
      <value><array><data>
        <value><array><data>
          <value><string>login</string></value>
          <value><string>=</string></value>
          <value><string>${login_buscar}</string></value>
        </data></array></value>
      </data></array></value>
    </data></array></value></param>
    <param><value><struct/></value></param>
  </params>
</methodCall>")
    echo "$respuesta" | grep -q '<int>' && return 0 || return 1
}
obtener_grupo_id() {
    local xml_id="$1"
    local modulo="${xml_id%%.*}"
    local nombre="${xml_id##*.}"
    local respuesta
    respuesta=$(xmlrpc_call "/xmlrpc/2/object" "<?xml version='1.0'?>
<methodCall>
  <methodName>execute_kw</methodName>
  <params>
    <param><value><string>${ODOO_DB}</string></value></param>
    <param><value><int>${ADMIN_UID}</int></value></param>
    <param><value><string>${ADMIN_PASS}</string></value></param>
    <param><value><string>ir.model.data</string></value></param>
    <param><value><string>search_read</string></value></param>
    <param><value><array><data>
      <value><array><data>
        <value><array><data>
          <value><string>module</string></value>
          <value><string>=</string></value>
          <value><string>${modulo}</string></value>
        </data></array></value>
        <value><array><data>
          <value><string>name</string></value>
          <value><string>=</string></value>
          <value><string>${nombre}</string></value>
        </data></array></value>
      </data></array></value>
    </data></array></value></param>
    <param><value><struct>
      <member><name>fields</name><value><array><data>
        <value><string>res_id</string></value>
      </data></array></value></member>
      <member><name>limit</name><value><int>1</int></value></member>
    </struct></value></param>
  </params>
</methodCall>")
    echo "$respuesta" | grep -oP '(?<=<int>)\d+(?=</int>)' | head -1
}
crear_usuario() {
    local nombre="$1"; local login="$2"
    local password_nuevo="$3"; local tipo_usuario="$4"
    local respuesta
    respuesta=$(xmlrpc_call "/xmlrpc/2/object" "<?xml version='1.0'?>
<methodCall>
  <methodName>execute_kw</methodName>
  <params>
    <param><value><string>${ODOO_DB}</string></value></param>
    <param><value><int>${ADMIN_UID}</int></value></param>
    <param><value><string>${ADMIN_PASS}</string></value></param>
    <param><value><string>res.users</string></value></param>
    <param><value><string>create</string></value></param>
    <param><value><array><data>
      <value><struct>
        <member><name>name</name><value><string>${nombre}</string></value></member>
        <member><name>login</name><value><string>${login}</string></value></member>
        <member><name>password</name><value><string>${password_nuevo}</string></value></member>
        <member><name>lang</name><value><string>es_ES</string></value></member>
        <member><name>tz</name><value><string>Europe/Madrid</string></value></member>
        <member>
          <name>sel_groups_1_10_11</name>
          <value><int>${tipo_usuario}</int></value>
        </member>
      </struct></value>
    </data></array></value></param>
    <param><value><struct/></value></param>
  </params>
</methodCall>")
    echo "$respuesta" | grep -oP '(?<=<int>)\d+(?=</int>)' | head -1
}
asignar_grupo() {
    local user_id="$1"
    local grupo_xml_id="$2"
    local grupo_id
    grupo_id=$(obtener_grupo_id "$grupo_xml_id")
    if [[ -z "$grupo_id" || ! "$grupo_id" =~ ^[0-9]+$ ]]; then
        warn "No se encontró el grupo '${grupo_xml_id}' (puede no estar instalado el módulo)."
        return 0
    fi
    xmlrpc_call "/xmlrpc/2/object" "<?xml version='1.0'?>
<methodCall>
  <methodName>execute_kw</methodName>
  <params>
    <param><value><string>${ODOO_DB}</string></value></param>
    <param><value><int>${ADMIN_UID}</int></value></param>
    <param><value><string>${ADMIN_PASS}</string></value></param>
    <param><value><string>res.users</string></value></param>
    <param><value><string>write</string></value></param>
    <param><value><array><data>
      <value><array><data>
        <value><int>${user_id}</int></value>
      </data></array></value>
      <value><struct>
        <member>
          <name>groups_id</name>
          <value><array><data>
            <value><array><data>
              <value><int>4</int></value>
              <value><int>${grupo_id}</int></value>
            </data></array></value>
          </data></array></value>
        </member>
      </struct></value>
    </data></array></value></param>
    <param><value><struct/></value></param>
  </params>
</methodCall>" > /dev/null
    ok "  Grupo asignado: ${grupo_xml_id} (ID: ${grupo_id})"
}
grupos_por_rol() {
    local rol="$1"
    case "$rol" in
        becario)
            echo "base.group_user"
            ;;
        ventas)
            echo "base.group_user"
            echo "crm.group_crm_salesperson"
            echo "sales_team.group_sale_salesman"
            echo "account.group_account_invoice"
            ;;
        rrhh)
            echo "base.group_user"
            echo "hr.group_hr_user"
            ;;
        almacen)
            echo "base.group_user"
            echo "stock.group_stock_user"
            echo "purchase.group_purchase_user"
            ;;
        tecnico)
            echo "base.group_user"
            echo "stock.group_stock_user"
            ;;
        jefe_ventas)
            echo "base.group_user"
            echo "crm.group_crm_manager"
            echo "sales_team.group_sale_manager"
            echo "account.group_account_invoice"
            ;;
        jefe_rrhh)
            echo "base.group_user"
            echo "hr.group_hr_manager"
            ;;
        jefe_almacen)
            echo "base.group_user"
            echo "stock.group_stock_manager"
            echo "purchase.group_purchase_manager"
            ;;
        api)
            echo "base.group_user"
            ;;
        *)
            echo "base.group_user"
            ;;
    esac
}
tipo_usuario_por_rol() {
    local rol="$1"
    case "$rol" in
        admin) echo "11" ;;   
        *)     echo "10" ;;   
    esac
}
echo ""
echo "══════════════════════════════════════════════════════════════"
echo "  Creación automática de usuarios en Odoo 17"
echo "  URL: ${ODOO_URL}  |  BD: ${ODOO_DB}"
echo "══════════════════════════════════════════════════════════════"
echo ""
if ! docker ps --format '{{.Names}}' | grep -q '^odoo-web$'; then
    error "El contenedor 'odoo-web' no está en ejecución."
    exit 1
fi
ok "Contenedor odoo-web activo."
if ! curl -sf --max-time 10 "${ODOO_URL}/web/health" > /dev/null 2>&1; then
    error "Odoo no responde en ${ODOO_URL}. Espera ~90s al arranque."
    exit 1
fi
ok "Odoo responde correctamente."
info "Autenticando como '${ADMIN_LOGIN}' en BD '${ODOO_DB}'..."
ADMIN_UID=$(odoo_autenticar "$ADMIN_LOGIN" "$ADMIN_PASS")
if [[ -z "$ADMIN_UID" || "$ADMIN_UID" == "0" ]]; then
    error "No se pudo autenticar. Revisa ADMIN_LOGIN y ADMIN_PASS."
    exit 1
fi
ok "Autenticado. UID administrador = ${ADMIN_UID}"
declare -a USUARIOS=(
    "Usuario API|api.user@erp.odoo.tfg.com|$(openssl rand -base64 16)|api"
    "Becario Ejemplo|becario@erp.odoo.tfg.com|$(openssl rand -base64 16)|becario"
    "Agente Ventas|ventas@erp.odoo.tfg.com|$(openssl rand -base64 16)|ventas"
    "Responsable RRHH|rrhh@erp.odoo.tfg.com|$(openssl rand -base64 16)|rrhh"
    "Operario Almacen|almacen@erp.odoo.tfg.com|$(openssl rand -base64 16)|almacen"
    "Tecnico Sistema|tecnico@erp.odoo.tfg.com|$(openssl rand -base64 16)|tecnico"
    "Jefe de Ventas|jefe.ventas@erp.odoo.tfg.com|$(openssl rand -base64 16)|jefe_ventas"
    "Jefe de RRHH|jefe.rrhh@erp.odoo.tfg.com|$(openssl rand -base64 16)|jefe_rrhh"
    "Jefe de Almacen|jefe.almacen@erp.odoo.tfg.com|$(openssl rand -base64 16)|jefe_almacen"
)
CREADOS=0; OMITIDOS=0; ERRORES=0
declare -a RESUMEN=()
echo ""
title "Procesando usuarios..."
echo ""
for entrada in "${USUARIOS[@]}"; do
    IFS='|' read -r nombre login password_nuevo rol <<< "$entrada"
    if usuario_existe "$ADMIN_UID" "$ADMIN_PASS" "$login"; then
        warn "OMITIDO   '${nombre}' (${login}) — ya existe."
        OMITIDOS=$((OMITIDOS + 1))
        continue
    fi
    tipo=$(tipo_usuario_por_rol "$rol")
    nuevo_id=$(crear_usuario "$nombre" "$login" "$password_nuevo" "$tipo")
    if [[ -n "$nuevo_id" && "$nuevo_id" =~ ^[0-9]+$ ]]; then
        ok "CREADO    '${nombre}' (${login}) → ID: ${nuevo_id} | tipo: ${tipo} | rol: ${rol}"
        info "Asignando grupos para rol '${rol}'..."
        while IFS= read -r grupo_xml_id; do
            [[ -n "$grupo_xml_id" ]] && asignar_grupo "$nuevo_id" "$grupo_xml_id"
        done < <(grupos_por_rol "$rol")
        RESUMEN+=("${nombre}|${login}|${password_nuevo}|${nuevo_id}|${rol}")
        CREADOS=$((CREADOS + 1))
    else
        error "ERROR     '${nombre}' (${login}) — no se pudo crear."
        ERRORES=$((ERRORES + 1))
    fi
    echo ""
done
echo "────────────────────────────────────────────────────────────"
echo "  Resumen: ${CREADOS} creados | ${OMITIDOS} ya existían | ${ERRORES} errores"
echo "────────────────────────────────────────────────────────────"
if [[ ${#RESUMEN[@]} -gt 0 ]]; then
    echo ""
    warn "⚠  CONTRASEÑAS GENERADAS — GUÁRDALAS AHORA (no se vuelven a mostrar):"
    echo ""
    printf "  %-22s %-35s %-22s %-8s %s\n" "NOMBRE" "LOGIN" "CONTRASEÑA" "ID" "ROL"
    printf "  %-22s %-35s %-22s %-8s %s\n" \
        "──────────────────────" "───────────────────────────────────" \
        "──────────────────────" "────────" "───────────────"
    for linea in "${RESUMEN[@]}"; do
        IFS='|' read -r n l p i r <<< "$linea"
        printf "  %-22s %-35s %-22s %-8s %s\n" "$n" "$l" "$p" "$i" "$r"
    done
    echo ""
fi
echo ""
```

### File: .\scripts\odoo\odoo_setup_wizard.sh
```sh
set -euo pipefail
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
info()  { echo -e "${CYAN}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[!]${NC}    $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
title() { echo -e "\n${BOLD}${CYAN}══ $* ══${NC}"; }
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
ENV_FILE="$PROJECT_DIR/docker/.env"
ODOO_CONT="odoo-web"
DB_CONT="odoo_erp"
DB_USER="odoo"
DB_NAME="odoo_erp"
LDAP_IP="192.168.30.22"  
[[ -f "$ENV_FILE" ]] && { set -a; source <(grep -vE '^\s*#|^\s*$' "$ENV_FILE"); set +a; }
LDAP_ADMIN_PASSWORD="${LDAP_ADMIN_PASSWORD:-}"
clear
echo -e "${BOLD}"
echo "  ╔══════════════════════════════════════════════════════╗"
echo "  ║    Asistente Post-Instalación Odoo — TFG ASIR 2026  ║"
echo "  ╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"
title "COMPROBACIONES"
for cont in "$ODOO_CONT" "$DB_CONT" "openldap"; do
    if docker ps --format '{{.Names}}' | grep -q "^${cont}$"; then
        ok "Contenedor '$cont' activo."
    else
        error "Contenedor '$cont' no está en ejecución."
        exit 1
    fi
done
title "PASO 1 — Nombre de la empresa"
read -rp "  Nombre de la empresa en Odoo: " COMPANY_NAME
[[ -z "$COMPANY_NAME" ]] && { error "El nombre no puede estar vacío."; exit 1; }
docker exec "$DB_CONT" psql -U "$DB_USER" -d "$DB_NAME" -q \
    -c "UPDATE res_company SET name='${COMPANY_NAME}' WHERE id=1;"
docker exec "$DB_CONT" psql -U "$DB_USER" -d "$DB_NAME" -q \
    -c "UPDATE res_partner SET name='${COMPANY_NAME}' WHERE id=1;"
ok "Empresa configurada: '$COMPANY_NAME'"
title "PASO 2 — Módulos a instalar"
echo "  [1] Ventas (sale_management)   [4] Proyectos (project)"
echo "  [2] CRM (crm)                  [5] Empleados (hr)"
echo "  [3] Inventario (stock)         [6] LDAP ← obligatorio"
echo "  [7] Todos los anteriores"
echo ""
read -rp "  Selección [6]: " SEL; SEL="${SEL:-6}"
declare -A MAP=([1]="sale_management" [2]="crm" [3]="stock"
                [4]="project" [5]="hr" [6]="auth_ldap")
if [[ "$SEL" == "7" ]]; then
    MODULOS="sale_management,crm,stock,project,hr,auth_ldap"
else
    MODULOS=""
    IFS=',' read -ra NUMS <<< "$SEL"
    for n in "${NUMS[@]}"; do
        n="${n// /}"
        [[ -n "${MAP[$n]:-}" ]] && MODULOS="${MODULOS:+$MODULOS,}${MAP[$n]}"
    done
fi
[[ "$MODULOS" != *"auth_ldap"* ]] && MODULOS="${MODULOS:+$MODULOS,}auth_ldap"
info "Instalando: $MODULOS (puede tardar varios minutos)..."
docker exec "$ODOO_CONT" bash -c \
    "odoo -c /etc/odoo/odoo.conf -d ${DB_NAME} -i ${MODULOS} --stop-after-init 2>&1 | tail -3" || true
ok "Módulos instalados."
title "PASO 3 — Configuración LDAP"
read -rp "  IP del servidor LDAP [$LDAP_IP]: " inp; LDAP_IP="${inp:-$LDAP_IP}"
read -rp "  Bind DN [cn=admin,dc=tfg,dc=com]: " inp
LDAP_BINDDN="${inp:-cn=admin,dc=tfg,dc=com}"
read -rp "  Contraseña LDAP [${LDAP_ADMIN_PASSWORD:-}]: " inp
LDAP_PASS="${inp:-$LDAP_ADMIN_PASSWORD}"
read -rp "  Base DN [ou=usuarios,dc=tfg,dc=com]: " inp
LDAP_BASE="${inp:-ou=usuarios,dc=tfg,dc=com}"
docker exec "$DB_CONT" psql -U "$DB_USER" -d "$DB_NAME" -q \
    -c "DELETE FROM res_company_ldap;"
docker exec "$DB_CONT" psql -U "$DB_USER" -d "$DB_NAME" -q -c \
    "INSERT INTO res_company_ldap
       (company_id, sequence, ldap_server, ldap_server_port,
        ldap_binddn, ldap_password, ldap_base, ldap_filter, create_user)
     VALUES (1, 10, '${LDAP_IP}', 389,
             '${LDAP_BINDDN}', '${LDAP_PASS}',
             '${LDAP_BASE}', '(uid=%s)', true);"
ok "LDAP configurado: ${LDAP_IP}:389 → ${LDAP_BASE}"
title "PASO 4 — Forzar LDAP (opcional)"
warn "Esto elimina la contraseña local de todos los usuarios excepto 'admin'."
read -rp "  ¿Confirmas? [s/N]: " r
if [[ "${r,,}" =~ ^s ]]; then
    docker exec "$DB_CONT" psql -U "$DB_USER" -d "$DB_NAME" -q \
        -c "UPDATE res_users SET password=NULL WHERE login!='admin';"
    ok "Acceso local deshabilitado para usuarios no-admin."
else
    warn "Paso omitido."
fi
echo ""
echo -e "${GREEN}${BOLD}  ✅ Configuración completada${NC}"
echo "  Empresa : $COMPANY_NAME"
echo "  Módulos : $MODULOS"
echo "  LDAP    : $LDAP_IP:389 → $LDAP_BASE"
echo ""
echo "  Próximos pasos:"
echo "    docker restart odoo-web"
echo "    bash scripts/ldap/ldap_crear_usuarios.sh"
echo ""
```

### File: .\sql\audit_triggers.sql
```sql
-- ====================================================================================
-- SCRIPT DE AUDITORÍA AVANZADA PARA ODOO 17 (PostgreSQL 16)
-- TFG ASIR - Control de Usuarios y Seguridad en Base de Datos
--
-- FUENTE TÉCNICA: Wiki Oficial PostgreSQL - Generic Audit Trigger (PL/pgSQL)
--   https://wiki.postgresql.org/wiki/Audit_trigger
--
-- MÓDULO ACADÉMICO: GBD (Gestión de Bases de Datos)
-- MEJORA RESPECTO A LA VERSIÓN INICIAL: Se añade campo JSONB para registrar
--   el estado completo del registro en el momento de la acción, tal como
--   documenta el estándar de auditoría de PostgreSQL y el informe de investigación.
-- ====================================================================================
-- ====================================================================================
-- 1. TABLA DE AUDITORÍA AMPLIADA CON JSONB
-- ====================================================================================
-- Cada fila representa un evento auditado en la base de datos de Odoo.
-- El campo 'row_data' (tipo JSONB) almacena el estado completo del registro
-- en el momento del evento — esto permite reconstruir qué datos existían.
-- JSONB es el formato recomendado por la Wiki de PostgreSQL para auditorías
-- porque permite búsquedas, filtros y operadores JSON nativos en PostgreSQL.
-- ====================================================================================
CREATE TABLE IF NOT EXISTS asir_audit_log (
    audit_id        SERIAL PRIMARY KEY,
    -- Tipo de operación: CREACION_USUARIO, UPDATE, DELETE
    action_type     VARCHAR(100) NOT NULL,
    -- Nombre de la tabla de Odoo afectada (ej: 'res_users', 'res_partner')
    table_name      VARCHAR(100) NOT NULL,
    -- ID del registro afectado en esa tabla (clave primaria de Odoo)
    record_id       INTEGER,
    -- Usuario técnico de PostgreSQL que realizó la acción (no el usuario de Odoo)
    db_user_actor   VARCHAR(100) DEFAULT current_user,
    -- Marca de tiempo exacta del evento (con zona horaria)
    action_time     TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    -- JSONB: estado completo del registro NUEVO (para INSERT y UPDATE)
    -- Permite ver exactamente qué valores tenía el registro en ese momento.
    -- Ejemplo: {"id": 42, "login": "javier@empresa.com", "active": true, ...}
    row_data        JSONB
);
-- Comentario descriptivo para administradores de la BD
COMMENT ON TABLE asir_audit_log IS
    'Tabla de auditoría de seguridad (TFG ASIR) — Registra creaciones y cambios en tablas críticas de Odoo. Incluye snapshot JSONB del registro para trazabilidad completa. Ref: https://wiki.postgresql.org/wiki/Audit_trigger';
-- Índice para acelerar búsquedas por fecha (útil en la defensa y en producción)
CREATE INDEX IF NOT EXISTS idx_audit_log_time ON asir_audit_log (action_time DESC);
-- Índice para búsquedas por tabla auditada
CREATE INDEX IF NOT EXISTS idx_audit_log_table ON asir_audit_log (table_name);
-- ====================================================================================
-- 2. FUNCIÓN PL/pgSQL CON SOPORTE JSONB
-- ====================================================================================
-- Esta función se ejecuta automáticamente cada vez que se crea un usuario en Odoo.
-- La mejora clave respecto a la v1: ahora captura el estado completo del registro
-- usando row_to_json(NEW)::JSONB, que convierte toda la fila nueva a formato JSON.
-- ====================================================================================
CREATE OR REPLACE FUNCTION func_audit_users()
RETURNS TRIGGER AS $$
BEGIN
    -- TG_OP contiene el tipo de operación: 'INSERT', 'UPDATE' o 'DELETE'
    -- TG_TABLE_NAME contiene automáticamente el nombre de la tabla donde ocurrió el evento
    -- NEW es el registro tal como quedará después del INSERT
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO asir_audit_log (
            action_type,
            table_name,
            record_id,
            db_user_actor,
            action_time,
            -- row_to_json(NEW) serializa toda la fila NEW a JSON,
            -- ::JSONB lo convierte al tipo JSONB nativo de PostgreSQL.
            -- Esto almacena el email, nombre, permisos, etc. del usuario creado.
            row_data
        )
        VALUES (
            'CREACION_USUARIO',
            TG_TABLE_NAME,
            NEW.id,
            current_user,
            CURRENT_TIMESTAMP,
            row_to_json(NEW)::JSONB
        );
        -- OBLIGATORIO: devolver NEW para que el INSERT original en res_users se complete.
        -- Si devolviéramos NULL, el usuario no se crearía en Odoo.
        RETURN NEW;
    END IF;
    -- Para cualquier otro evento no contemplado, devolvemos NULL (sin acción)
    RETURN NULL;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER  -- La función se ejecuta con los permisos del propietario (más seguro)
   SET search_path = public, pg_temp;  -- Evita ataques de path injection en el search_path
-- ====================================================================================
-- 3. TRIGGER: Enlaza la función a la tabla res_users de Odoo
-- ====================================================================================
-- Primero eliminamos el trigger si ya existía (permite re-ejecutar el script sin errores)
DROP TRIGGER IF EXISTS trg_audit_new_odoo_user ON res_users;
-- AFTER INSERT: el trigger se dispara DESPUÉS de que la fila se haya insertado,
-- lo que garantiza que NEW.id ya tiene el valor correcto asignado por PostgreSQL.
CREATE TRIGGER trg_audit_new_odoo_user
    AFTER INSERT ON res_users
    FOR EACH ROW
    EXECUTE FUNCTION func_audit_users();
-- Comentario del trigger para documentación
COMMENT ON TRIGGER trg_audit_new_odoo_user ON res_users IS
    'TFG ASIR: Audita la creación de nuevos usuarios en Odoo. Registra snapshot JSONB completo en asir_audit_log.';
-- ====================================================================================
-- 4. VISTA DE CONSULTA RÁPIDA (Para usar en la defensa del TFG)
-- ====================================================================================
-- Esta vista simplifica la consulta al log de auditoría, mostrando los campos
-- más relevantes en un formato legible. Útil para demostrar el sistema en vivo.
-- ====================================================================================
CREATE OR REPLACE VIEW v_audit_resumen AS
SELECT
    audit_id,
    action_type                                     AS tipo_accion,
    table_name                                      AS tabla,
    record_id                                       AS id_registro,
    db_user_actor                                   AS usuario_postgres,
    action_time                                     AS fecha_hora,
    -- Extraer el campo 'login' del JSONB (email del usuario de Odoo creado)
    -- El operador ->> devuelve el valor como texto
    row_data ->> 'login'                            AS email_usuario_odoo,
    -- Extraer el nombre completo del usuario
    row_data ->> 'name'                             AS nombre_usuario_odoo
FROM
    asir_audit_log
ORDER BY
    action_time DESC;
COMMENT ON VIEW v_audit_resumen IS
    'TFG ASIR: Vista simplificada del log de auditoría. Muestra los últimos eventos con campos extraídos del JSONB.';
-- ====================================================================================
-- USO Y COMPROBACIÓN EN LA DEFENSA DEL TFG:
-- ====================================================================================
-- Paso 1: Ejecutar este script completo en la BD de Odoo:
--   docker exec -i odoo-db psql -U odoo -d odoo_erp < /opt/erp-odoo/sql/audit_triggers.sql
--
-- Paso 2: Crear un usuario nuevo desde la interfaz web de Odoo:
--   Ajustes → Usuarios → Nuevo usuario → (rellenar datos) → Guardar
--
-- Paso 3: Verificar el registro en el log (usando la vista simplificada):
--   docker exec -it odoo-db psql -U odoo -d odoo_erp
--   SELECT * FROM v_audit_resumen;
--
-- Paso 4: Ver el JSONB completo del registro auditado:
--   SELECT audit_id, action_type, row_data FROM asir_audit_log ORDER BY action_time DESC LIMIT 1;
--
-- Resultado esperado en la consulta:
--   audit_id | action_type       | email_usuario_odoo       | fecha_hora
--   ---------|-------------------|--------------------------|--------------------
--   1        | CREACION_USUARIO  | javier@empresa.com       | 2026-04-29 21:30:00
-- ====================================================================================
```

### File: .\vagrant\Explicacion_provision_postgres.md
```md
El script vagrant/provision_postgres.sh es el fichero que Vagrant ejecuta automáticamente dentro de la VM de base de datos (la VM 3 — db-server) justo después de crearla, para dejarla lista sin que toques nada manualmente.
Qué hace línea por línea
bash
set -e
Si cualquier comando falla, el script para inmediatamente. Evita que continúe con errores silenciosos.
bash
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-changeme_db}"
Coge la contraseña del entorno (la que le pasa el Vagrantfile) o usa changeme_db como valor por defecto si no se la pasan.
bash
apt-get update -qq
apt-get install -y postgresql-16 postgresql-client-16
systemctl enable --now postgresql
Instala PostgreSQL 16 y lo arranca como servicio del sistema.
bash
sudo -u postgres psql <<EOF
CREATE USER odoo WITH PASSWORD '${POSTGRES_PASSWORD}';
CREATE DATABASE odoo_erp OWNER odoo;
GRANT ALL PRIVILEGES ON DATABASE odoo_erp TO odoo;
EOF
Crea el usuario odoo y la base de datos odoo_erp dentro de PostgreSQL.
bash
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" "$PG_CONF"
echo "host odoo_erp odoo 192.168.30.0/24 md5" >> "$PG_HBA"
systemctl restart postgresql
Estas tres líneas son las más importantes de seguridad. Hacen dos cosas:
listen_addresses = '*' → PostgreSQL escucha en todas las interfaces (por defecto solo escucha en localhost y Odoo no podría conectarse desde otra VM)
Regla pg_hba.conf → Solo permite conexiones desde la red 192.168.30.0/24 (la VLAN de Odoo), con usuario odoo, con contraseña MD5. Nadie más puede conectarse.
¿Está bien?
✅ Sí, el script está correcto. Pero hay una cosa a tener en cuenta: la línea del sed busca exactamente este texto:
text
#listen_addresses = 'localhost'
En Debian/Ubuntu con PostgreSQL 16, ese comentario existe por defecto, así que funcionará. Si por algún motivo ya estuviera descomentado, el sed no haría nada y tendrías que editarlo a mano.
Flujo completo cuando haces vagrant up
text
vagrant up db-server
       │
       ▼
VMware crea la VM (Debian, 2 GB RAM, IP 192.168.40.10)
       │
       ▼
Vagrant ejecuta provision_postgres.sh dentro de la VM
       │
       ▼
PostgreSQL 16 instalado + usuario odoo + BD odoo_erp
       │
       ▼
Acepta conexiones solo desde 192.168.30.0/24 (Odoo)
Cuando luego levantes la VM de Odoo, apuntará a 192.168.40.10:5432 y se conectará directamente a esta base de datos.
```

### File: .\vagrant\provision_postgres.sh
```sh
set -e
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-changeme_db}"
echo "=========================================="
echo " Instalando PostgreSQL 16..."
echo "=========================================="
apt-get update -qq
apt-get install -y postgresql-16 postgresql-client-16
systemctl enable --now postgresql
sudo -u postgres psql <<EOF
CREATE USER odoo WITH PASSWORD '${POSTGRES_PASSWORD}';
CREATE DATABASE odoo_erp OWNER odoo;
GRANT ALL PRIVILEGES ON DATABASE odoo_erp TO odoo;
EOF
PG_HBA="/etc/postgresql/16/main/pg_hba.conf"
PG_CONF="/etc/postgresql/16/main/postgresql.conf"
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" "$PG_CONF"
echo "host  odoo_erp  odoo  192.168.30.0/24  md5" >> "$PG_HBA"
systemctl restart postgresql
echo ""
echo "=========================================="
echo " PostgreSQL listo en 192.168.40.10:5432"
echo " Base de datos: odoo_erp"
echo " Usuario: odoo"
echo "=========================================="
```

