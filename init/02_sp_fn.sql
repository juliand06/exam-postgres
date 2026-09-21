-- ============================================================================
-- PROYECTO ACADÉMICO: GESTIÓN MULTI-TENANT SST & PESV
-- AUTOR: Julian Andrey Ricaurte (juliand06)
-- ARCHIVO: 02_sp_fn.sql - Procedimientos y Funciones Almacenadas (PL/pgSQL)
-- ============================================================================

-- ============================================================================
-- SECCIÓN A: PROCEDIMIENTOS ALMACENADOS (15 Procedimientos)
-- ============================================================================

-- SP 1: Registrar nueva organización validando NIT
CREATE OR REPLACE PROCEDURE sp_register_tenant(
    p_nit VARCHAR,
    p_name VARCHAR,
    p_email VARCHAR,
    p_phone VARCHAR,
    p_address VARCHAR,
    p_municipality_id INT,
    p_tenant_size_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM tenants WHERE nit = p_nit) THEN
        RAISE EXCEPTION 'La organización con NIT % ya se encuentra registrada en el sistema.', p_nit;
    END IF;

    INSERT INTO tenants (nit, name, email, phone, address, municipality_id, tenant_size_id)
    VALUES (p_nit, p_name, p_email, p_phone, p_address, p_municipality_id, p_tenant_size_id);

    RAISE NOTICE 'Organización "%" registrada exitosamente.', p_name;
END;
$$;

-- SP 2: Registrar nueva persona vinculada a organización y cargo
CREATE OR REPLACE PROCEDURE sp_register_person(
    p_identification_number VARCHAR,
    p_first_name VARCHAR,
    p_last_name VARCHAR,
    p_email VARCHAR,
    p_phone VARCHAR,
    p_tenant_id INT,
    p_position_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM persons WHERE identification_number = p_identification_number) THEN
        RAISE EXCEPTION 'La persona con identificación % ya existe en el sistema.', p_identification_number;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM positions WHERE id = p_position_id AND tenant_id = p_tenant_id) THEN
        RAISE EXCEPTION 'El cargo % no pertenece a la organización asignada (Tenant ID %).', p_position_id, p_tenant_id;
    END IF;

    INSERT INTO persons (identification_number, first_name, last_name, email, phone, tenant_id, position_id)
    VALUES (p_identification_number, p_first_name, p_last_name, p_email, p_phone, p_tenant_id, p_position_id);

    RAISE NOTICE 'Persona % % registrada exitosamente.', p_first_name, p_last_name;
END;
$$;

-- SP 3: Cambiar estado de una organización entre activa e inactiva
CREATE OR REPLACE PROCEDURE sp_toggle_tenant_status(
    p_tenant_id INT,
    p_is_active BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tenants WHERE id = p_tenant_id) THEN
        RAISE EXCEPTION 'Organización con ID % no encontrada.', p_tenant_id;
    END IF;

    UPDATE tenants 
    SET is_active = p_is_active, updated_at = CURRENT_TIMESTAMP
    WHERE id = p_tenant_id;

    RAISE NOTICE 'Estado de la organización ID % actualizado a: %', p_tenant_id, p_is_active;
END;
$$;

-- SP 4: Asignar módulo a una organización evitando duplicados
CREATE OR REPLACE PROCEDURE sp_assign_module_to_tenant(
    p_tenant_id INT,
    p_module_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM tenant_modules WHERE tenant_id = p_tenant_id AND module_id = p_module_id) THEN
        RAISE NOTICE 'El módulo ID % ya está asignado a la organización ID %.', p_module_id, p_tenant_id;
        RETURN;
    END IF;

    INSERT INTO tenant_modules (tenant_id, module_id, is_active)
    VALUES (p_tenant_id, p_module_id, TRUE);

    RAISE NOTICE 'Módulo ID % asignado correctamente a la organización ID %.', p_module_id, p_tenant_id;
END;
$$;

-- SP 5: Habilitar sistema SST/PESV para una organización
CREATE OR REPLACE PROCEDURE sp_enable_system_to_tenant(
    p_tenant_id INT,
    p_system_sst_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM tenantsystems WHERE tenant_id = p_tenant_id AND system_sst_id = p_system_sst_id) THEN
        RAISE NOTICE 'El sistema ID % ya está habilitado para la organización ID %.', p_system_sst_id, p_tenant_id;
        RETURN;
    END IF;

    INSERT INTO tenantsystems (tenant_id, system_sst_id, is_active)
    VALUES (p_tenant_id, p_system_sst_id, TRUE);

    RAISE NOTICE 'Sistema ID % habilitado exitosamente para la organización ID %.', p_system_sst_id, p_tenant_id;
END;
$$;

-- SP 6: Asignar plantilla indicando sistema, etapa PHVA y formato
CREATE OR REPLACE PROCEDURE sp_assign_template_to_tenant(
    p_tenant_id INT,
    p_system_sst_id INT,
    p_phva_stage_id INT,
    p_format_id INT,
    p_name VARCHAR,
    p_status VARCHAR DEFAULT 'no_iniciado'
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO tenanttemplates (tenant_id, system_sst_id, phva_stage_id, format_id, name, status)
    VALUES (p_tenant_id, p_system_sst_id, p_phva_stage_id, p_format_id, p_name, p_status);

    RAISE NOTICE 'Plantilla "%" asignada a la organización ID %.', p_name, p_tenant_id;
END;
$$;

-- SP 7: Cambiar el cargo de una persona dentro de su organización
CREATE OR REPLACE PROCEDURE sp_change_person_position(
    p_person_id INT,
    p_new_position_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_tenant_id INT;
BEGIN
    SELECT tenant_id INTO v_tenant_id FROM persons WHERE id = p_person_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Persona con ID % no existe.', p_person_id;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM positions WHERE id = p_new_position_id AND tenant_id = v_tenant_id) THEN
        RAISE EXCEPTION 'El cargo % no pertenece a la organización del trabajador.', p_new_position_id;
    END IF;

    UPDATE persons 
    SET position_id = p_new_position_id, updated_at = CURRENT_TIMESTAMP
    WHERE id = p_person_id;

    RAISE NOTICE 'Cargo actualizado para la persona ID % al cargo ID %.', p_person_id, p_new_position_id;
END;
$$;

-- SP 8: Trasladar persona de una organización a otra
CREATE OR REPLACE PROCEDURE sp_transfer_person(
    p_person_id INT,
    p_new_tenant_id INT,
    p_new_position_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM positions WHERE id = p_new_position_id AND tenant_id = p_new_tenant_id) THEN
        RAISE EXCEPTION 'El nuevo cargo % no pertenece a la organización receptora (Tenant ID %).', p_new_position_id, p_new_tenant_id;
    END IF;

    UPDATE persons
    SET tenant_id = p_new_tenant_id,
        position_id = p_new_position_id,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_person_id;

    RAISE NOTICE 'Persona ID % trasladada satisfactoriamente a Tenant ID %.', p_person_id, p_new_tenant_id;
END;
$$;

-- SP 9: Deshabilitar todos los módulos de una organización inactiva
CREATE OR REPLACE PROCEDURE sp_deactivate_tenant_modules(
    p_tenant_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_is_active BOOLEAN;
BEGIN
    SELECT is_active INTO v_is_active FROM tenants WHERE id = p_tenant_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Organización ID % no encontrada.', p_tenant_id;
    END IF;

    IF v_is_active THEN
        RAISE EXCEPTION 'La organización ID % aún está activa. Solo se pueden suspender módulos de organizaciones inactivas.', p_tenant_id;
    END IF;

    UPDATE tenant_modules 
    SET is_active = FALSE 
    WHERE tenant_id = p_tenant_id;

    RAISE NOTICE 'Módulos deshabilitados para la organización inactiva ID %.', p_tenant_id;
END;
$$;

-- SP 10: Eliminar asignación de módulo validando dependencias
CREATE OR REPLACE PROCEDURE sp_delete_module_assignment(
    p_tenant_id INT,
    p_module_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM tenanttemplates tt
        INNER JOIN formats_sst f ON tt.format_id = f.id
        WHERE tt.tenant_id = p_tenant_id AND f.module_id = p_module_id
    ) THEN
        RAISE EXCEPTION 'No se puede remover el módulo ID % porque la organización tiene plantillas asociadas a formatos de este módulo.', p_module_id;
    END IF;

    DELETE FROM tenant_modules 
    WHERE tenant_id = p_tenant_id AND module_id = p_module_id;

    RAISE NOTICE 'Asignación del módulo ID % eliminada para la organización ID %.', p_module_id, p_tenant_id;
END;
$$;

-- SP 11: Contar total de plantillas de una organización y emitir aviso
CREATE OR REPLACE PROCEDURE sp_count_tenant_templates(
    p_tenant_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total INT := 0;
    v_tenant_name VARCHAR(150);
BEGIN
    SELECT name INTO v_tenant_name FROM tenants WHERE id = p_tenant_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Organización ID % inexistente.', p_tenant_id;
    END IF;

    SELECT COUNT(*) INTO v_total FROM tenanttemplates WHERE tenant_id = p_tenant_id;

    RAISE NOTICE 'La organización "%" (ID %) cuenta con un total de % plantillas asignadas.', v_tenant_name, p_tenant_id, v_total;
END;
$$;

-- SP 12: Calcular y persistir porcentaje de cumplimiento documental
CREATE OR REPLACE PROCEDURE sp_calculate_tenant_compliance(
    p_tenant_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total INT;
    v_finalizados INT;
    v_pct NUMERIC(5,2);
BEGIN
    SELECT COUNT(*), COUNT(*) FILTER (WHERE status = 'finalizado')
    INTO v_total, v_finalizados
    FROM tenanttemplates
    WHERE tenant_id = p_tenant_id;

    IF v_total = 0 THEN
        v_pct := 0.00;
    ELSE
        v_pct := ROUND((v_finalizados::NUMERIC / v_total::NUMERIC) * 100.0, 2);
    END IF;

    UPDATE tenants 
    SET compliance_percentage = v_pct, updated_at = CURRENT_TIMESTAMP
    WHERE id = p_tenant_id;

    RAISE NOTICE 'Porcentaje de cumplimiento de Tenant ID % actualizado a: %% %', p_tenant_id, v_pct;
END;
$$;

-- SP 13: Contar documentos por organización y etapa PHVA
CREATE OR REPLACE PROCEDURE sp_count_templates_by_phva(
    p_tenant_id INT,
    p_phva_stage_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_count INT;
    v_stage_name VARCHAR(50);
BEGIN
    SELECT name INTO v_stage_name FROM phva_stages WHERE id = p_phva_stage_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Etapa PHVA ID % inexistente.', p_phva_stage_id;
    END IF;

    SELECT COUNT(*) INTO v_count 
    FROM tenanttemplates 
    WHERE tenant_id = p_tenant_id AND phva_stage_id = p_phva_stage_id;

    RAISE NOTICE 'Tenant ID % tiene % documentos en la etapa "%".', p_tenant_id, v_count, v_stage_name;
END;
$$;

-- SP 14: Modificar datos de contacto de una organización
CREATE OR REPLACE PROCEDURE sp_update_tenant_contact(
    p_tenant_id INT,
    p_email VARCHAR,
    p_phone VARCHAR,
    p_address VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE tenants
    SET email = p_email,
        phone = p_phone,
        address = p_address,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_tenant_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Organización ID % no encontrada.', p_tenant_id;
    END IF;

    RAISE NOTICE 'Datos de contacto para Tenant ID % actualizados correctamente.', p_tenant_id;
END;
$$;

-- SP 15: Asignación segura de plantilla con control de excepciones
CREATE OR REPLACE PROCEDURE sp_safe_assign_template(
    p_tenant_id INT,
    p_system_sst_id INT,
    p_phva_stage_id INT,
    p_format_id INT,
    p_name VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tenants WHERE id = p_tenant_id AND is_active = TRUE) THEN
        RAISE EXCEPTION 'La organización ID % no existe o se encuentra inactiva.', p_tenant_id;
    END IF;

    INSERT INTO tenanttemplates (tenant_id, system_sst_id, phva_stage_id, format_id, name, status)
    VALUES (p_tenant_id, p_system_sst_id, p_phva_stage_id, p_format_id, p_name, 'no_iniciado');

    RAISE NOTICE 'Plantilla "%" asignada en modo seguro a Tenant ID %.', p_name, p_tenant_id;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error durante la asignación de plantilla: % (SQLSTATE: %)', SQLERRM, SQLSTATE;
END;
$$;

-- ============================================================================
-- SECCIÓN B: FUNCIONES ALMACENADAS (8 Funciones)
-- ============================================================================

-- FN 1: Total de personas registradas en una organización
CREATE OR REPLACE FUNCTION fn_total_persons_by_tenant(p_tenant_id INT)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_total INT;
BEGIN
    SELECT COUNT(*) INTO v_total FROM persons WHERE tenant_id = p_tenant_id;
    RETURN v_total;
END;
$$;

-- FN 2: Porcentaje de cumplimiento documental de una organización
CREATE OR REPLACE FUNCTION fn_tenant_compliance_percentage(p_tenant_id INT)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    v_total INT;
    v_done INT;
BEGIN
    SELECT COUNT(*), COUNT(*) FILTER (WHERE status = 'finalizado')
    INTO v_total, v_done
    FROM tenanttemplates
    WHERE tenant_id = p_tenant_id;

    IF v_total = 0 THEN
        RETURN 0.00;
    END IF;

    RETURN ROUND((v_done::NUMERIC / v_total::NUMERIC) * 100.0, 2);
END;
$$;

-- FN 3: Determinar si una organización tiene habilitado un módulo (Booleano)
CREATE OR REPLACE FUNCTION fn_has_module_enabled(p_tenant_id INT, p_module_id INT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM tenant_modules 
        WHERE tenant_id = p_tenant_id AND module_id = p_module_id AND is_active = TRUE
    );
END;
$$;

-- FN 4: Obtener nombre completo de una persona
CREATE OR REPLACE FUNCTION fn_get_person_full_name(p_person_id INT)
RETURNS VARCHAR
LANGUAGE plpgsql
AS $$
DECLARE
    v_name VARCHAR(150);
BEGIN
    SELECT CONCAT(first_name, ' ', last_name) INTO v_name
    FROM persons 
    WHERE id = p_person_id;
    RETURN COALESCE(v_name, 'No encontrada');
END;
$$;

-- FN 5: Cantidad de plantillas existentes para organización y etapa PHVA
CREATE OR REPLACE FUNCTION fn_count_templates_by_stage(p_tenant_id INT, p_stage_id INT)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_count INT;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM tenanttemplates
    WHERE tenant_id = p_tenant_id AND phva_stage_id = p_stage_id;
    RETURN v_count;
END;
$$;

-- FN 6: Función tabular: módulos habilitados para una organización
CREATE OR REPLACE FUNCTION fn_get_tenant_modules(p_tenant_id INT)
RETURNS TABLE (
    module_id INT,
    module_title VARCHAR,
    system_code VARCHAR,
    presentation_order INT,
    assigned_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        m.id, m.title, ts.code, m.presentation_order, tm.assigned_at
    FROM tenant_modules tm
    INNER JOIN modules m ON tm.module_id = m.id
    INNER JOIN type_system_sst ts ON m.system_sst_id = ts.id
    WHERE tm.tenant_id = p_tenant_id AND tm.is_active = TRUE
    ORDER BY m.presentation_order ASC;
END;
$$;

-- FN 7: Función tabular: personas y cargos de una organización
CREATE OR REPLACE FUNCTION fn_get_tenant_persons_positions(p_tenant_id INT)
RETURNS TABLE (
    person_id INT,
    identification VARCHAR,
    full_name TEXT,
    email VARCHAR,
    position_name VARCHAR,
    is_active BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.identification_number,
        CONCAT(p.first_name, ' ', p.last_name)::TEXT,
        p.email,
        pos.name,
        p.is_active
    FROM persons p
    INNER JOIN positions pos ON p.position_id = pos.id
    WHERE p.tenant_id = p_tenant_id
    ORDER BY p.last_name, p.first_name;
END;
$$;

-- FN 8: Clasificar nivel de cumplimiento (Bajo, Medio, Alto)
CREATE OR REPLACE FUNCTION fn_classify_compliance_level(p_percentage NUMERIC)
RETURNS VARCHAR
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_percentage >= 85.00 THEN
        RETURN 'Alto';
    ELSIF p_percentage >= 60.00 THEN
        RETURN 'Medio';
    ELSE
        RETURN 'Bajo';
    END IF;
END;
$$;
