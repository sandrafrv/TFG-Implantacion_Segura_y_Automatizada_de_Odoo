# sql/ — Scripts SQL de Auditoría

Esta carpeta contiene los scripts PL/pgSQL que se aplican sobre la base de datos de Odoo para habilitar la auditoría de acciones críticas.

---

## Base de datos objetivo

Todos los scripts apuntan a la BD externa:

| Parámetro | Valor |
|---|---|
| Host | `192.168.40.10` (VM `vm-postgres`, VLAN 40) |
| Puerto | `5432` |
| Base de datos | `odooerp` |
| Usuario | `odoo` |

---

## Archivos

### `audit_triggers.sql`
Crea triggers PL/pgSQL sobre las tablas principales de Odoo para registrar eventos en una tabla de auditoría.

**Qué incluye:**
- Función `func_audit_users()`: registra creación, modificación y borrado de usuarios en `res_users`
- Tabla `asir_audit_log`: almacena los eventos con timestamp, usuario de BD, acción y datos en formato JSONB
- Vista `v_audit_resumen`: consulta rápida de los últimos eventos de auditoría

---

## Cómo aplicar los scripts

```bash
# Desde la VM vm-odoo o cualquier máquina con acceso a VLAN 40
psql -h 192.168.40.10 -U odoo -d odooerp -f sql/audit_triggers.sql

# Verificar que los triggers se crearon
psql -h 192.168.40.10 -U odoo -d odooerp -c "\df func_audit*"

# Consultar el log de auditoría
psql -h 192.168.40.10 -U odoo -d odooerp -c "SELECT * FROM v_audit_resumen LIMIT 20;"
```

---

## Consideraciones de seguridad

- Solo la VLAN 40 y la VLAN 30 (Odoo) tienen acceso al puerto 5432. Ver `docs/reglas_pfsense.md`.
- El usuario `odoo` tiene permisos mínimos necesarios sobre `odooerp`. No usar el usuario `postgres` para conexiones de aplicación.
- Los logs de auditoría deben revisarse periódicamente. Considerar exportarlos con el script de backup.
