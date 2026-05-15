# scripts/ldap/ — Scripts LDAP (DESACTIVADOS)

> ⚠️ **ATENCIÓN: Estos scripts están desactivados y NO forman parte del despliegue principal.**
>
> LDAP fue descartado de la arquitectura actual por complejidad y para reducir la superficie de ataque. Los scripts se conservan como referencia para una posible integración futura.
>
> Ver: [`extras/ldap/README.md`](../../extras/ldap/README.md)

---

## Scripts disponibles

### `configurar_cliente_ldap.sh`
Configura el sistema Debian como cliente LDAP, conectando con el servidor OpenLDAP. Instala `libnss-ldap`, `libpam-ldap` y configura `/etc/nsswitch.conf`.

**Estado:** Desactivado. El servicio OpenLDAP ya no existe en `docker-compose.yml`.

### `ldap_crear_usuarios.sh`
Crea la estructura de unidades organizativas (OU) y usuarios en el directorio LDAP. Genera entradas LDIF y las carga con `ldapadd`.

**Estado:** Desactivado. Ver `extras/ldap/estructura.ldif` para la estructura de referencia.

### `ldap_politica_acceso.sh`
Configure las ACLs (Access Control Lists) del servidor LDAP para controlar qué usuarios pueden leer/escribir cada atributo del directorio.

**Estado:** Desactivado.

---

## Cómo retomar LDAP en el futuro

1. Consultar `extras/ldap/README.md` para el plan de integración
2. Añadir el servicio `openldap` a `docker/docker-compose.yml`
3. Ejecutar `ldap_crear_usuarios.sh` para poblar el directorio
4. Ejecutar `configurar_cliente_ldap.sh` para conectar el sistema
5. Configurar el módulo LDAP de Odoo desde la interfaz web
