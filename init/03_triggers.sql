-- ============================================================================
-- PROYECTO ACADÉMICO: GESTIÓN MULTI-TENANT SST & PESV
-- AUTOR: Julian Andrey Ricaurte (juliand06)
-- ARCHIVO: 03_triggers.sql - Triggers de Integridad, Validación y Auditoría
-- ============================================================================

-- ============================================================================
-- 1. TRIGGER: Actualización automática de updated_at en tenants
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_trg_tenants_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_tenants_updated_at ON tenants;
CREATE TRIGGER trg_tenants_updated_at
BEFORE UPDATE ON tenants
FOR EACH ROW
EXECUTE FUNCTION fn_trg_tenants_updated_at();

-- ============================================================================
-- 2. TRIGGER: Actualización automática de updated_at en persons
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_trg_persons_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_persons_updated_at ON persons;
CREATE TRIGGER trg_persons_updated_at
BEFORE UPDATE ON persons
FOR EACH ROW
EXECUTE FUNCTION fn_trg_persons_updated_at();

-- ============================================================================
-- 3. TRIGGER: Impedir registrar personas en organizaciones inactivas
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_trg_prevent_person_inactive_tenant()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_is_active BOOLEAN;
BEGIN
    SELECT is_active INTO v_is_active FROM tenants WHERE id = NEW.tenant_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'La organización ID % no existe.', NEW.tenant_id;
    END IF;

    IF v_is_active IS FALSE THEN
        RAISE EXCEPTION 'No es posible registrar trabajadores en una organización inactiva (Tenant ID %).', NEW.tenant_id;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_person_inactive_tenant ON persons;
CREATE TRIGGER trg_prevent_person_inactive_tenant
BEFORE INSERT ON persons
FOR EACH ROW
EXECUTE FUNCTION fn_trg_prevent_person_inactive_tenant();

-- ============================================================================
-- 4. TRIGGER: Impedir asignación duplicada de módulos a organizaciones
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_trg_prevent_duplicate_tenant_module()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM tenant_modules 
        WHERE tenant_id = NEW.tenant_id AND module_id = NEW.module_id AND id <> COALESCE(NEW.id, -1)
    ) THEN
        RAISE EXCEPTION 'El módulo ID % ya se encuentra asignado a la organización ID %.', NEW.module_id, NEW.tenant_id;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_duplicate_tenant_module ON tenant_modules;
CREATE TRIGGER trg_prevent_duplicate_tenant_module
BEFORE INSERT OR UPDATE ON tenant_modules
FOR EACH ROW
EXECUTE FUNCTION fn_trg_prevent_duplicate_tenant_module();

-- ============================================================================
-- 5. TRIGGER: Impedir asignación de plantillas a organizaciones inactivas
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_trg_prevent_template_inactive_tenant()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_is_active BOOLEAN;
BEGIN
    SELECT is_active INTO v_is_active FROM tenants WHERE id = NEW.tenant_id;
    IF v_is_active IS FALSE THEN
        RAISE EXCEPTION 'No se pueden asignar plantillas a una organización con estado inactivo (Tenant ID %).', NEW.tenant_id;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_template_inactive_tenant ON tenanttemplates;
CREATE TRIGGER trg_prevent_template_inactive_tenant
BEFORE INSERT ON tenanttemplates
FOR EACH ROW
EXECUTE FUNCTION fn_trg_prevent_template_inactive_tenant();

-- ============================================================================
-- 6. TRIGGER: Validar que el cargo asignado pertenezca a la misma organización
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_trg_validate_person_position_tenant()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_position_tenant_id INT;
BEGIN
    SELECT tenant_id INTO v_position_tenant_id FROM positions WHERE id = NEW.position_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'El cargo ID % no existe en la base de datos.', NEW.position_id;
    END IF;

    IF v_position_tenant_id <> NEW.tenant_id THEN
        RAISE EXCEPTION 'Inconsistencia multi-tenant: el cargo ID % pertenece a la organización ID %, pero la persona está siendo asignada a la organización ID %.',
            NEW.position_id, v_position_tenant_id, NEW.tenant_id;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_person_position_tenant ON persons;
CREATE TRIGGER trg_validate_person_position_tenant
BEFORE INSERT OR UPDATE OF position_id, tenant_id ON persons
FOR EACH ROW
EXECUTE FUNCTION fn_trg_validate_person_position_tenant();

-- ============================================================================
-- 7. TRIGGER: Registro automático de updated_at al modificar plantillas
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_trg_tenanttemplates_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_tenanttemplates_updated_at ON tenanttemplates;
CREATE TRIGGER trg_tenanttemplates_updated_at
BEFORE UPDATE ON tenanttemplates
FOR EACH ROW
EXECUTE FUNCTION fn_trg_tenanttemplates_updated_at();

-- ============================================================================
-- 8. TRIGGER: Impedir eliminación de organización si tiene personas asociadas
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_trg_prevent_delete_tenant_with_persons()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_count INT;
BEGIN
    SELECT COUNT(*) INTO v_count FROM persons WHERE tenant_id = OLD.id;
    IF v_count > 0 THEN
        RAISE EXCEPTION 'Operación denegada: La organización "%" (ID %) posee % personas vinculadas. Debe desvincular o trasladar el personal previamente.',
            OLD.name, OLD.id, v_count;
    END IF;
    RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_delete_tenant_with_persons ON tenants;
CREATE TRIGGER trg_prevent_delete_tenant_with_persons
BEFORE DELETE ON tenants
FOR EACH ROW
EXECUTE FUNCTION fn_trg_prevent_delete_tenant_with_persons();

-- ============================================================================
-- 9. TRIGGER: Impedir eliminar un sistema SST si existen empresas usándolo
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_trg_prevent_delete_system_in_use()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_count INT;
BEGIN
    SELECT COUNT(*) INTO v_count FROM tenantsystems WHERE system_sst_id = OLD.id AND is_active = TRUE;
    IF v_count > 0 THEN
        RAISE EXCEPTION 'No se puede eliminar el sistema normativo "%" (ID %) porque se encuentra habilitado para % organizaciones.',
            OLD.name, OLD.id, v_count;
    END IF;
    RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_delete_system_in_use ON type_system_sst;
CREATE TRIGGER trg_prevent_delete_system_in_use
BEFORE DELETE ON type_system_sst
FOR EACH ROW
EXECUTE FUNCTION fn_trg_prevent_delete_system_in_use();

-- ============================================================================
-- 10. TRIGGER: Impedir eliminar un módulo si está asignado a organizaciones
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_trg_prevent_delete_module_in_use()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_count INT;
BEGIN
    SELECT COUNT(*) INTO v_count FROM tenant_modules WHERE module_id = OLD.id;
    IF v_count > 0 THEN
        RAISE EXCEPTION 'No se puede eliminar el módulo "%" (ID %) debido a que está asignado a % empresas.',
            OLD.title, OLD.id, v_count;
    END IF;
    RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_delete_module_in_use ON modules;
CREATE TRIGGER trg_prevent_delete_module_in_use
BEFORE DELETE ON modules
FOR EACH ROW
EXECUTE FUNCTION fn_trg_prevent_delete_module_in_use();

-- ============================================================================
-- 11. TRIGGER: Validar que el porcentaje de cumplimiento esté entre 0 y 100
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_trg_validate_compliance_range()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.compliance_percentage < 0.00 OR NEW.compliance_percentage > 100.00 THEN
        RAISE EXCEPTION 'El porcentaje de cumplimiento % es inválido. Debe situarse en el intervalo [0.00, 100.00].', NEW.compliance_percentage;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_compliance_range ON tenants;
CREATE TRIGGER trg_validate_compliance_range
BEFORE INSERT OR UPDATE OF compliance_percentage ON tenants
FOR EACH ROW
EXECUTE FUNCTION fn_trg_validate_compliance_range();

-- ============================================================================
-- 12. TRIGGER: Auditoría de modificaciones sobre datos principales de tenants
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_trg_audit_tenant_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF (OLD.name <> NEW.name OR OLD.nit <> NEW.nit OR OLD.email <> NEW.email OR OLD.tenant_size_id <> NEW.tenant_size_id) THEN
        INSERT INTO tenants_audit (tenant_id, action, old_data, new_data, changed_by)
        VALUES (
            NEW.id,
            'UPDATE_INFO',
            jsonb_build_object('name', OLD.name, 'nit', OLD.nit, 'email', OLD.email, 'size_id', OLD.tenant_size_id),
            jsonb_build_object('name', NEW.name, 'nit', NEW.nit, 'email', NEW.email, 'size_id', NEW.tenant_size_id),
            CURRENT_USER
        );
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_audit_tenant_changes ON tenants;
CREATE TRIGGER trg_audit_tenant_changes
AFTER UPDATE ON tenants
FOR EACH ROW
EXECUTE FUNCTION fn_trg_audit_tenant_changes();

-- ============================================================================
-- 13. TRIGGER: Auditoría de cambios en el estado activo/inactivo de la empresa
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_trg_audit_tenant_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF OLD.is_active <> NEW.is_active THEN
        INSERT INTO tenants_audit (tenant_id, action, old_data, new_data, changed_by)
        VALUES (
            NEW.id,
            'STATUS_CHANGE',
            jsonb_build_object('is_active', OLD.is_active),
            jsonb_build_object('is_active', NEW.is_active),
            CURRENT_USER
        );
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_audit_tenant_status_change ON tenants;
CREATE TRIGGER trg_audit_tenant_status_change
AFTER UPDATE OF is_active ON tenants
FOR EACH ROW
EXECUTE FUNCTION fn_trg_audit_tenant_status_change();

-- ============================================================================
-- 14. TRIGGER: Auditoría de fecha, usuario y cambio de estado en plantillas
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_trg_audit_template_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF OLD.status <> NEW.status THEN
        INSERT INTO tenant_templates_audit (template_id, action, old_status, new_status, modified_by)
        VALUES (
            NEW.id,
            'STATUS_CHANGE',
            OLD.status,
            NEW.status,
            CURRENT_USER
        );
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_audit_template_changes ON tenanttemplates;
CREATE TRIGGER trg_audit_template_changes
AFTER UPDATE OF status ON tenanttemplates
FOR EACH ROW
EXECUTE FUNCTION fn_trg_audit_template_changes();

-- ============================================================================
-- 15. TRIGGER: Limpieza y marcado de bloqueos de edición vencidos
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_trg_cleanup_expired_editing_locks()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Desactivar cualquier bloqueo de edición previo que haya expirado
    UPDATE editing_locks 
    SET is_active = FALSE 
    WHERE is_active = TRUE AND expires_at <= CURRENT_TIMESTAMP;

    -- Si el nuevo bloqueo ya viene con fecha vencida, cancelarlo
    IF NEW.expires_at <= CURRENT_TIMESTAMP THEN
        NEW.is_active = FALSE;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_cleanup_expired_editing_locks ON editing_locks;
CREATE TRIGGER trg_cleanup_expired_editing_locks
BEFORE INSERT OR UPDATE ON editing_locks
FOR EACH ROW
EXECUTE FUNCTION fn_trg_cleanup_expired_editing_locks();
