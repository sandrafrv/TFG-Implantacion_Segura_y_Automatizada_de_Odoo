# ldap/ — Estructura LDAP (Legacy)

> ⚠️ **Esta carpeta es material legacy.** Contiene la estructura base del directorio LDAP de cuando el servicio OpenLDAP formaba parte del `docker-compose.yml`.
>
> **LDAP no está activo** en la arquitectura actual. Fue descartado del despliegue principal en Mayo 2026.

---

## Contenido

### `estructura.ldif`
Archivo LDIF con la estructura de usuarios y grupos que se usaba con OpenLDAP:
- Unidades Organizativas: `ou=People` y `ou=Groups`
- Usuarios de ejemplo: empleados de TechSolutions S.L.
- Grupos: `grp_ventas`, `grp_admin`, `grp_rrhh`

---

## Relación con otros archivos

| Archivo | Descripción |
|---|---|
| `extras/ldap/estructura.ldif` | Copia actualizada del mismo LDIF |
| `extras/ldap/README.md` | Plan para retomar LDAP en el futuro |
| `scripts/ldap/` | Scripts de configuración LDAP (desactivados) |

---

## ¿Por qué se descartó LDAP?

- Complejidad añadida al despliegue sin beneficio directo para el TFG
- Superficie de ataque mayor con un contenedor más expuesto
- La autenticación nativa de Odoo cubre los requisitos del proyecto
- Se priorizaron la segmentación de red y la separación de la BD como mejoras más significativas

Ver `extras/ldap/README.md` para el plan de integración futura.
