# sql/ — Auditoría de Base de Datos

Esta carpeta contiene los scripts SQL y PL/pgSQL para la **auditoría de operaciones críticas** en la base de datos de Odoo.

> [!NOTE]
> Todos los scripts de esta carpeta operan contra la **VM externa PostgreSQL** (`vm-postgres`, `192.168.40.10`, VLAN 40). No usar `localhost` ni ningún contenedor.

---

## Contenido

| Archivo | Descripción |
|:--------|:------------|
| `audit_triggers.sql` | Crea la tabla `asir_audit_log`, la función `func_audit_users()` y el trigger `trg_audit_new_odoo_user` sobre la tabla `res_users` de Odoo |

---

## Qué hace `audit_triggers.sql`

### Tabla `asir_audit_log`

```sql
CREATE TABLE asir_audit_log (
    audit_id    SERIAL PRIMARY KEY,
    accion      VARCHAR(50),   -- 'CREACION_USUARIO', 'MODIFICACION', etc.
    tabla       VARCHAR(100),  -- Tabla afectada
    fila_id     INTEGER,       -- ID del registro afectado
    usuario_pg  TEXT,          -- Usuario de PostgreSQL que ejecutó la operación
    fecha_hora  TIMESTAMPTZ DEFAULT now(),
    row_data    JSONB          -- Snapshot completo del registro en JSON
);
```

### Trigger `trg_audit_new_odoo_user`

Se dispara **AFTER INSERT** en `res_users`. Registra automáticamente cada nuevo usuario creado en Odoo, incluyendo un snapshot JSONB completo de la fila con campos como `login` y `name`.

### Vista `v_audit_resumen`

Facilita la consulta del log extrayendo `login` y `name` del campo JSONB:

```sql
SELECT * FROM v_audit_resumen ORDER BY fecha_hora DESC LIMIT 20;
```

---

## Cómo aplicar

```bash
# Conectar a la BD externa y ejecutar el script
psql -h 192.168.40.10 -U odoo -d odooerp -f sql/audit_triggers.sql

# O directamente desde vagrant
vagrant ssh vm-postgres
psql -U odoo -d odooerp -f /vagrant/sql/audit_triggers.sql
```

> El script se aplica automáticamente durante el aprovisionamiento de `vm-postgres` (ver `vagrant/provision_postgres.sh`).

---

## Verificar que funciona

```bash
psql -h 192.168.40.10 -U odoo -d odooerp
```

```sql
-- Crear un usuario en Odoo y luego comprobar:
SELECT * FROM asir_audit_log ORDER BY fecha_hora DESC LIMIT 5;
-- Resultado esperado: audit_id=1, accion='CREACION_USUARIO', tabla='res_users' ✅

-- Vista resumen
SELECT * FROM v_audit_resumen ORDER BY fecha_hora DESC;
```

---

## Relación con el módulo académico

Este script cubre el módulo de **Gestión de Bases de Datos** del ciclo ASIR, aplicando:

- Triggers PL/pgSQL sobre tablas de aplicaciones reales
- Auditoría con campo JSONB para snapshots completos de filas
- Separación de la lógica de auditoría de la aplicación (Odoo no sabe que existe el trigger)

---

*TFC ASIR 2025/2026 — IES Cañaveral*
