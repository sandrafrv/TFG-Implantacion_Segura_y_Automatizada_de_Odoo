#!/bin/bash
# ============================================================
# SCRIPT: configurar_cliente_ldap.sh
# DESCRIPCIÓN: Configura una máquina cliente Linux (Debian/Ubuntu)
#              de la VLAN 10 para que use el servidor OpenLDAP
#              como proveedor de identidad, permitiendo que los
#              usuarios del directorio inicien sesión en el
#              sistema operativo con sus credenciales LDAP.
#
# TECNOLOGÍA: SSSD (System Security Services Daemon)
#   - Reemplaza los paquetes antiguos libnss-ldap + libpam-ldap
#   - Gestiona NSS (quién es este usuario) + PAM (verificar contraseña)
#   - Soporta caché offline: el usuario puede iniciar sesión aunque
#     el servidor LDAP esté temporalmente caído
#   - Es el estándar actual en entornos empresariales Debian/Ubuntu
#
# FLUJO DE AUTENTICACIÓN RESULTANTE:
#   1. Usuario escribe su uid y contraseña en el login del PC
#   2. PAM pregunta a SSSD si las credenciales son correctas
#   3. SSSD consulta al servidor LDAP (192.168.30.22) usando
#      el usuario readonly (cn=readonly,dc=tfg,dc=com)
#   4. LDAP verifica la contraseña → OK / FAIL
#   5. Si OK: SSSD crea la sesión. Si es el primer login,
#      pam_mkhomedir crea automáticamente /home/<uid>
#
# CONTROL DE ACCESO AL SISTEMA OPERATIVO:
#   - Solo los usuarios en ou=usuarios,dc=tfg,dc=com pueden iniciar sesión
#   - Opcionalmente se puede restringir a un grupo concreto (access_provider)
#   - El grupo cn=becarios puede acceder al PC pero con permisos Linux limitados
#   - El grupo cn=admin puede usar sudo en la máquina (configurable)
#
# USO (ejecutar en cada cliente Linux de VLAN 10):
#   sudo bash scripts/ldap/configurar_cliente_ldap.sh
#
# REQUISITOS:
#   - Máquina Debian 12 / Ubuntu 22.04 o superior
#   - Conectividad con 192.168.30.22 (OpenLDAP) por el puerto 389
#   - Conocer la contraseña de cn=readonly,dc=tfg,dc=com
# ============================================================

set -euo pipefail

# ── Colores ──────────────────────────────────────────────────
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

# ── Verificar que se ejecuta como root ───────────────────────
if [[ "$EUID" -ne 0 ]]; then
    error "Este script debe ejecutarse como root."
    error "Usa: sudo bash scripts/ldap/configurar_cliente_ldap.sh"
    exit 1
fi

# ── Cabecera ─────────────────────────────────────────────────
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

# ── Pedir datos de conexión ───────────────────────────────────
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

# Opción: restringir acceso a un grupo LDAP concreto
echo ""
echo "  ¿Restringir el acceso al sistema solo a un grupo LDAP?"
echo "  Ejemplo: 'ventas' → solo los del grupo cn=ventas pueden iniciar sesión"
echo "  Dejar vacío para permitir a TODOS los usuarios del directorio."
read -r -p "  Grupo de acceso (vacío = todos): " ACCESS_GROUP

# ── 1. Verificar conectividad con el servidor LDAP ────────────
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

# Verificar autenticación con readonly
if ! ldapsearch -H "$LDAP_URI" -D "$LDAP_BIND_DN" -w "$LDAP_BIND_PASS" \
    -b "$LDAP_BASE" -s base "(objectClass=*)" dn > /dev/null 2>&1; then
    error "Las credenciales de readonly no son correctas."
    error "Verifica la contraseña en docker/.env (LDAP_READONLY_PASSWORD)"
    exit 1
fi
ok "Autenticación con usuario readonly verificada."

# ── 2. Instalar paquetes necesarios ──────────────────────────
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

# ── 3. Crear configuración de SSSD ───────────────────────────
title "3/6  Generando configuración de SSSD"

# Construir el filtro de acceso por grupo (si se especificó)
if [[ -n "$ACCESS_GROUP" ]]; then
    ACCESS_FILTER="(&(objectClass=posixAccount)(memberOf=cn=${ACCESS_GROUP},ou=grupos,${LDAP_BASE}))"
    info "Restricción de acceso: solo grupo '${ACCESS_GROUP}'"
else
    ACCESS_FILTER="(objectClass=posixAccount)"
    info "Acceso permitido a todos los usuarios del directorio LDAP."
fi

cat > /etc/sssd/sssd.conf << EOF
# ============================================================
# Configuración SSSD — TFG ASIR 2025/2026
# Generado por: scripts/ldap/configurar_cliente_ldap.sh
#
# SSSD actúa como intermediario entre PAM/NSS y el servidor LDAP.
# Ventajas sobre libnss-ldap directo:
#   - Caché local: funciona aunque el LDAP esté temporalmente caído
#   - Mejor seguridad: la contraseña no viaja en claro internamente
#   - Soporte nativo para sudo vía LDAP
# ============================================================

[sssd]
# Servicios que SSSD gestiona:
#   nss → resolución de nombres (getpwnam, getgrnam)
#   pam → autenticación (login, sudo, etc.)
services = nss, pam, sudo
config_file_version = 2

# Dominio de identidad que usamos (apunta a nuestro OpenLDAP)
domains = tfg.com

# Nivel de log (0=errores, 1=avisos, 5=debug completo)
# En producción usar 1. Para depuración usar 5 temporalmente.
[logging]
default_domain_suffix = tfg.com

# ── Dominio LDAP ─────────────────────────────────────────────
[domain/tfg.com]

# Tipo de proveedor de identidad
id_provider = ldap

# Proveedor de autenticación (también LDAP en nuestro caso)
auth_provider = ldap

# Proveedor de acceso:
#   ldap → comprueba si el usuario puede iniciar sesión
#   simple → lista blanca/negra de usuarios o grupos
access_provider = ldap

# ── Conexión al servidor LDAP ────────────────────────────────

# URI del servidor OpenLDAP (contenedor en DMZ con IP MACVLAN)
ldap_uri = ${LDAP_URI}

# Base DN: raíz del árbol donde buscar usuarios y grupos
ldap_search_base = ${LDAP_BASE}

# OU específica donde están las cuentas de usuarios
ldap_user_search_base = ou=usuarios,${LDAP_BASE}

# OU específica donde están los grupos
ldap_group_search_base = ou=grupos,${LDAP_BASE}

# ── Credenciales para consultar el directorio ────────────────
# SSSD usa el usuario "readonly" para buscar entradas en el LDAP.
# Este usuario tiene solo permiso de lectura (configurado en
# ldap_politica_acceso.sh). Nunca se expone al usuario final.

ldap_default_bind_dn = ${LDAP_BIND_DN}
ldap_default_authtok_type = password
ldap_default_authtok = ${LDAP_BIND_PASS}

# ── Esquema de usuario ───────────────────────────────────────
# Indica qué atributos LDAP corresponden a los campos POSIX Unix.
# inetOrgPerson + posixAccount (definido en ldap/estructura.ldif)

ldap_schema = rfc2307

# Atributo LDAP que contiene el login del usuario (uid POSIX)
ldap_user_name = uid

# Atributo que contiene el nombre real del usuario
ldap_user_gecos = cn

# Atributo del directorio home
ldap_user_home_directory = homeDirectory

# Shell de login del usuario
ldap_user_shell = loginShell

# Atributo del número de usuario (UID numérico Unix)
ldap_user_uid_number = uidNumber

# Atributo del número de grupo primario
ldap_user_gid_number = gidNumber

# ── Esquema de grupo ─────────────────────────────────────────
ldap_group_name = cn
ldap_group_member = member

# ── Filtro de acceso ─────────────────────────────────────────
# Solo los usuarios que cumplan este filtro pueden iniciar sesión.
# Si ACCESS_GROUP está definido, solo los miembros del grupo pueden.
ldap_access_filter = ${ACCESS_FILTER}

# ── Caché y rendimiento ──────────────────────────────────────
# Tiempo que SSSD guarda la información en caché local.
# Si el LDAP está caído, el usuario puede seguir iniciando sesión
# durante este tiempo con sus credenciales cacheadas.

# Tiempo de vida de la caché de usuarios (segundos). 24h = 86400
cache_credentials = true
entry_cache_timeout = 3600

# Tiempo de reintento si el LDAP no está disponible
ldap_network_timeout = 5
ldap_opt_timeout = 5
ldap_connection_expire_timeout = 300

# ── Directorio home ──────────────────────────────────────────
# Si el usuario no tiene homeDirectory definido en LDAP, usar este
fallback_homedir = /home/%u

# Shell por defecto si no está definido en LDAP
default_shell = /bin/bash

# ── Opciones de seguridad ────────────────────────────────────
# No requerir TLS (el LDAP está en red interna DMZ, no en Internet)
# En producción real con datos sensibles, usar ldaps:// y TLS.
ldap_tls_reqcert = never

# No usar referrals (no necesarios en nuestra arquitectura)
ldap_referrals = false

# Enumeración desactivada por seguridad:
# Con enumerate=false, "getent passwd" no lista TODOS los usuarios LDAP.
# Los usuarios solo se resuelven cuando se les busca explícitamente.
enumerate = false
EOF

# Proteger el archivo (contiene contraseña)
chmod 600 /etc/sssd/sssd.conf
ok "Archivo /etc/sssd/sssd.conf generado y protegido (permisos 600)."

# ── 4. Configurar PAM para SSSD ──────────────────────────────
title "4/6  Configurando PAM (creación automática de /home)"

# pam_sss.so → SSSD gestiona la autenticación PAM
# pam_mkhomedir.so → crea /home/<usuario> automáticamente en el
#                    primer inicio de sesión si no existe

# En Debian/Ubuntu, pam-auth-update gestiona la configuración PAM
# El paquete libpam-sss ya añade pam_sss automáticamente
pam-auth-update --enable sss --enable mkhomedir 2>/dev/null || {
    warn "pam-auth-update no disponible. Configurando PAM manualmente..."

    # Configuración manual de /etc/pam.d/common-session
    if ! grep -q "pam_mkhomedir" /etc/pam.d/common-session; then
        echo "session required pam_mkhomedir.so skel=/etc/skel umask=0077" \
            >> /etc/pam.d/common-session
        ok "pam_mkhomedir añadido a common-session."
    fi
}

ok "PAM configurado para crear directorios home automáticamente."

# ── 5. Configurar NSS ────────────────────────────────────────
title "5/6  Configurando NSS (resolución de nombres)"

# NSS (Name Service Switch) define el orden en que el sistema
# busca información de usuarios y grupos.
# Añadimos 'sss' después de 'files' para que:
#   1. Primero busque en /etc/passwd y /etc/group (usuarios locales)
#   2. Si no lo encuentra, pregunte a SSSD → LDAP

# Hacer copia de seguridad
cp /etc/nsswitch.conf /etc/nsswitch.conf.bak.$(date +%Y%m%d)

# Actualizar las líneas de passwd, group y shadow
sed -i 's/^passwd:.*/passwd:         files sss/' /etc/nsswitch.conf
sed -i 's/^group:.*/group:          files sss/' /etc/nsswitch.conf
sed -i 's/^shadow:.*/shadow:         files sss/' /etc/nsswitch.conf

# Verificar
PASSWD_LINE=$(grep "^passwd:" /etc/nsswitch.conf)
info "NSS passwd: $PASSWD_LINE"

ok "NSS configurado. Los usuarios LDAP se resolverán en el sistema."

# ── 6. Habilitar y arrancar SSSD ─────────────────────────────
title "6/6  Habilitando y arrancando SSSD"

systemctl enable sssd
systemctl restart sssd

# Esperar a que SSSD esté listo
sleep 3

if systemctl is-active --quiet sssd; then
    ok "SSSD está activo y funcionando."
else
    error "SSSD no arrancó correctamente."
    error "Revisa los logs: journalctl -u sssd --no-pager -n 50"
    exit 1
fi

# ── Verificación automática ───────────────────────────────────
title "✅  Verificación de la configuración"

echo ""
echo "  Probando resolución de nombres desde LDAP..."
echo "  (Esto puede tardar unos segundos mientras SSSD llena la caché)"
echo ""

# Intentar resolver un usuario de ejemplo del LDAP
# (getent busca en NSS, que ahora incluye SSSD → LDAP)
if getent passwd 2>/dev/null | grep -q "ou=usuarios" || \
   ldapsearch -H "$LDAP_URI" -D "$LDAP_BIND_DN" -w "$LDAP_BIND_PASS" \
       -b "ou=usuarios,${LDAP_BASE}" "(objectClass=posixAccount)" uid 2>/dev/null \
       | grep -q "uid:"; then
    ok "Directorio LDAP accesible y con usuarios posixAccount."
else
    warn "No se encontraron usuarios con objectClass=posixAccount en LDAP."
    warn "Asegúrate de crear usuarios con ldap_crear_usuarios.sh antes de hacer login."
fi

# ── Resumen final ─────────────────────────────────────────────
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
echo "    # Ver usuarios LDAP disponibles en este sistema"
echo "    getent passwd | grep -v nologin"
echo ""
echo "    # Buscar un usuario específico"
echo "    getent passwd <uid_del_usuario>"
echo ""
echo "    # Ver grupos LDAP"
echo "    getent group"
echo ""
echo "    # Probar autenticación manual"
echo "    su - <uid_del_usuario>"
echo ""
echo "    # Ver logs de SSSD en tiempo real"
echo "    journalctl -u sssd -f"
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""
ok "La máquina está configurada para autenticación LDAP. ✅"
echo ""
