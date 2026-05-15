# ldap/ — Directorio Legacy

> [!WARNING]
> **Este directorio es material legacy.**
> Contiene la estructura base del directorio LDAP generada durante el diseño inicial del proyecto. OpenLDAP **no está activo** en el despliegue actual.

---

## Contenido

| Archivo | Descripción |
|:--------|:------------|
| `estructura.ldif` | Árbol LDIF con OUs y usuarios de ejemplo para TechSolutions S.L. |

> Este fichero es idéntico al de `extras/ldap/estructura.ldif`.
> La copia canónica y con documentación actualizada está en **`extras/ldap/`**.

---

## Por qué existe esta carpeta

Durante el desarrollo del proyecto se utilizó este directorio como espacio de trabajo para el diseño del directorio LDAP. Una vez descartado LDAP del despliegue principal, el material se consolidó en `extras/ldap/` y esta carpeta se conserva como referencia histórica.

---

## Referencia actualizada

Para información completa sobre LDAP como mejora futura del proyecto, consultar:

- [`extras/ldap/README.md`](../extras/ldap/README.md) — Documentación completa y guía de reactivación
- [`docs/guias/INSTALACION_LDAP_CICD_HARDENING.md`](../docs/guias/INSTALACION_LDAP_CICD_HARDENING.md) — Parte 1: LDAP
- [`scripts/ldap/`](../scripts/ldap/) — Scripts de configuración

---

*TFG ASIR 2025/2026 — IES Cañaveral*
