# SQL — Auditoría de Base de Datos

**TFG ASIR 2025/2026 — TechSolutions S.L.**

Esta carpeta contiene los scripts SQL que se aplican sobre la base de datos **PostgreSQL 16** ubicada en la VM externa (`vm-postgres`, `192.168.40.10`, VLAN 40).

---

## Contenido

| Archivo | Descripción |
|:--------|:------------|
| `audit_triggers.sql` | Crea la tabla de auditoría `asir_audit_log`, la función PL/pgSQL `func_audit_users()` y el trigger `trg_audit_new_odoo_user` sobre la tabla `res_users` de Odoo. |

---

## ¿Qué hace `audit_triggers.sql`?

Implementa un sistema de auditoría sobre la base de datos de Odoo que registra automáticamente:

- **Creación de nuevos usuarios** en Odoo (tabla `res_users`)
- Almacena en `asir_audit_log`: timestamp, operación (`CREACION_USUARIO`), tabla afectada, ID del registro y los datos completos de la fila en formato **JSONB**
- Incluye la vista `v_audit_resumen` que extrae `login` y `name` del campo JSONB para consultas rápidas

### Estructura de `asir_audit_log`

```sql
CREATE TABLE asir_audit_log (
    audit_id   SERIAL PRIMARY KEY,
    fecha      TIMESTAMP DEFAULT NOW(),
    operacion  VARCHAR(50),    -- ej: 'CREACION_USUARIO'
    tabla      VARCHAR(100),   -- ej: 'res_users'
    registro_id INT,           -- ID del registro afectado
    row_data   JSONB           -- Datos completos de la fila
);
```

---

## Cuándo Ejecutarlo

El script se aplica **una sola vez** durante el aprovisionamiento de `vm-postgres`.
Si se necesita reaplicar manualmente:

```bash
# Conectarse a la VM de PostgreSQL
vagrant ssh vm-postgres

# O desde vm-odoo / cualquier host con acceso a la BD
psql -h 192.168.40.10 -U odoo -d odooerp -f /ruta/al/sql/audit_triggers.sql
```

> ⚠️ La BD debe existir y Odoo debe haber iniciado al menos una vez para que la tabla `res_users` esté creada antes de aplicar los triggers.

---

## Validación

Tras crear un usuario en Odoo, verificar que el trigger funciona:

```sql
-- Conectarse a la BD
psql -h 192.168.40.10 -U odoo -d odooerp

-- Ver últimas entradas de auditoría
SELECT * FROM v_audit_resumen ORDER BY audit_id DESC LIMIT 5;

-- Resultado esperado:
-- audit_id | fecha | operacion | tabla | registro_id | login | name
-- 1 | 2026-05-15 ... | CREACION_USUARIO | res_users | 8 | jdoe@empresa.com | Juan Doe
```

---

*Historial de implementación: [`docs/HISTORIAL_IMPLEMENTACION.md`](../docs/HISTORIAL_IMPLEMENTACION.md)*
*Diagrama de red: [`docs/diagrama_red.md`](../docs/diagrama_red.md)*
