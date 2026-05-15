# LDAP — Material Legacy

> ⚠️ **Esta carpeta es material de referencia histórica. LDAP no forma parte del despliegue activo del proyecto.**

---

## ¿Por qué no se usa LDAP?

LDAP fue descartado del despliegue principal por las siguientes razones:

1. **Reducción de superficie de ataque:** Eliminar OpenLDAP elimina un servicio adicional expuesto en la DMZ (puertos `:389` y `:636`).
2. **Complejidad de mantenimiento:** La integración LDAP en Odoo requiere mantener dos sistemas de usuarios sincronizados.
3. **Alcance del TFG:** El objetivo principal es la seguridad perimetral y la automatización, no la gestión centralizada de identidades.
4. **Alternativa más simple:** Odoo gestiona sus propios usuarios internamente con control de roles suficiente para el caso de uso.

---

## Contenido de esta carpeta

| Archivo | Descripción |
|:--------|:------------|
| `estructura.ldif` | Estructura base del directorio LDAP: unidades organizativas (`ou=usuarios`, `ou=grupos`), usuarios de ejemplo y grupos (`admin`, `tecnico`, `readonly`). Equivalente al archivo en `extras/ldap/`. |

---

## Dónde está el material LDAP completo

Todo el material de LDAP como **mejora futura** está en:

- [`extras/ldap/`](../extras/ldap/) — `estructura.ldif` + `README.md` con pasos de implementación
- [`scripts/ldap/`](../scripts/ldap/) — Scripts de aprovisionamiento (`configurar_cliente_ldap.sh`, `ldap_crear_usuarios.sh`, `ldap_politica_acceso.sh`) marcados como desactivados
- [`docs/CONTROL_ACCESO.md`](../docs/CONTROL_ACCESO.md) — Sección sobre LDAP como mejora futura

---

> Si en el futuro se quiere retomar la implementación de LDAP, el punto de partida es `extras/ldap/README.md`.
