# scripts/ldap/ — Scripts LDAP (Desactivados)

> [!WARNING]
> **Estos scripts están desactivados.** LDAP fue descartado del despliegue principal del proyecto.
> El servicio `openldap` ya **no existe** en `docker/docker-compose.yml`.
> Ejecutar estos scripts en el entorno actual no tendrá efecto porque no hay ningún servidor LDAP corriendo.

---

## Contenido

| Script | Descripción | Estado |
|:-------|:------------|:-------|
| `ldap_politica_acceso.sh` | Aplica ACLs de seguridad en el directorio OpenLDAP (modelo de mínimo privilegio) | ⚠️ Desactivado |
| `ldap_crear_usuarios.sh` | Crea usuarios interactivamente en OpenLDAP vía `ldapadd` | ⚠️ Desactivado |
| `configurar_cliente_ldap.sh` | Instala y configura SSSD + PAM + NSS en un cliente Debian para login con credenciales LDAP | ⚠️ Desactivado |

---

## Por qué se desactivaron

OpenLDAP fue descartado del stack activo por:

- Punto único de fallo: si LDAP cae, los usuarios no pueden acceder a Odoo.
- Complejidad de mantenimiento del directorio y sincronización con Odoo.
- Aumento innecesario de la superficie de ataque para el alcance del TFG.

---

## Si quieres reactivar LDAP

1. Consultar [`extras/ldap/README.md`](../../extras/ldap/README.md) para añadir el servicio al stack Docker.
2. Levantar el contenedor `openldap` y aplicar la estructura LDIF.
3. Ejecutar `ldap_politica_acceso.sh` para aplicar ACLs.
4. Ejecutar `ldap_crear_usuarios.sh` para crear los usuarios de empleados.
5. (Opcional) Ejecutar `configurar_cliente_ldap.sh` en cada PC cliente de VLAN 10.

Ver también: [`docs/guias/INSTALACION_LDAP_CICD_HARDENING.md`](../../docs/guias/INSTALACION_LDAP_CICD_HARDENING.md) — Parte 1.

---

*TFG ASIR 2025/2026 — IES Cañaveral*
