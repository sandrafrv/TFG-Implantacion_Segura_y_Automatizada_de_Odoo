-- ====================================================================================
-- SCRIPT DE AUDITORÍA AVANZADA PARA ODOO 17 (PostgreSQL 16)
-- TFG ASIR - Control de Usuarios y Seguridad en Base de Datos
-- ====================================================================================

-- 1. CREACIÓN DE LA TABLA DE AUDITORÍA (Logs)
-- Esta tabla actuará como un "Log Intocable" donde el Trigger escribirá qué está pasando.
CREATE TABLE IF NOT EXISTS asir_audit_log (
    audit_id SERIAL PRIMARY KEY,
    action_type VARCHAR(50) NOT NULL,
    table_name VARCHAR(50) NOT NULL,
    record_id INT,
    db_user_actor VARCHAR(50),
    action_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- Un comentario descriptivo para la Base de Datos
COMMENT ON TABLE asir_audit_log IS 'Tabla de auditoria de seguridad (TFG ASIR) - Registro de creaciones en tablas criticas';

-- 2. FUNCIÓN PL/pgSQL (El código que se ejecutará en respuesta al evento)
-- Usamos 'OR REPLACE' para poder actualizar el script tantas veces como queramos
CREATE OR REPLACE FUNCTION func_audit_users()
RETURNS TRIGGER AS $$
BEGIN
    -- Comprobamos si el evento disparado es exactamente un INSERT (creación)
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO asir_audit_log (action_type, table_name, record_id, db_user_actor)
        -- NEW.id es la clave primaria que Odoo le acaba de dar al usuario creado
        -- current_user captura mágicamente qué cuenta técnica de PostgreSQL ha hecho la acción
        VALUES ('CREACION USUARIO (Security)', TG_TABLE_NAME, NEW.id, current_user);
        
        -- Obligatorio devolver NEW para que la fila original se guarde en res_users
        RETURN NEW;
    END IF;
    
    -- Si por lo que sea entra otro evento (UPDATE, DELETE), no hacemos nada y devolvemos la fila
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 3. CREACIÓN DEL DISPARADOR (TRIGGER)
-- Primero borramos el trigger si ya existía (por si ejecutamos este script 2 veces)
DROP TRIGGER IF EXISTS trg_audit_new_odoo_user ON res_users;

-- Creamos el Trigger amarrado a la tabla de Odoo 'res_users' (Los usuarios que hacen login al ERP)
CREATE TRIGGER trg_audit_new_odoo_user
AFTER INSERT ON res_users
FOR EACH ROW
EXECUTE FUNCTION func_audit_users();

-- ====================================================================================
-- USO Y COMPROBACIÓN POSTERIOR EN LA DEFENSA DEL TFG:
-- ====================================================================================
-- Para demostrar al tribunal que funciona:
-- 1. Ejecutar este script en la Base de Datos desde un Gestor Gráfico (pgAdmin, DBeaver) o Terminal.
-- 2. Loguearse en la web de Odoo con el usuario 'admin'.
-- 3. Ir a Ajustes -> Usuarios -> Crear Usuario, y dar de alta a "Javier Cordoba".
-- 4. Ejecutar en DBeaver: SELECT * FROM asir_audit_log;
-- 5. Se mostrará una fila detallando a qué segundo exacto y en qué tabla ha nacido ese usuario.
