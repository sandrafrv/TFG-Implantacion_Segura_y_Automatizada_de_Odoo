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
