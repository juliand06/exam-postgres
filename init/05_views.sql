-- ============================================================================
-- PROYECTO ACADÉMICO: GESTIÓN MULTI-TENANT SST & PESV
-- AUTOR: Julian Andrey Ricaurte (juliand06)
-- ARCHIVO: 05_views.sql - Vistas Estándar y Vistas Materializadas
-- ============================================================================

-- ============================================================================
-- 1. VISTA 1: Organizaciones con sus Personas y Cargos
-- ============================================================================
CREATE OR REPLACE VIEW vw_tenant_persons AS
SELECT 
    t.id AS tenant_id,
    t.nit,
    t.name AS organizacion,
    p.id AS person_id,
    p.identification_number AS identificacion,
    CONCAT(p.first_name, ' ', p.last_name) AS nombre_completo,
    p.email AS correo_trabajador,
    p.phone AS telefono_trabajador,
    pos.id AS position_id,
    pos.name AS cargo,
    p.is_active AS persona_activa
FROM tenants t
INNER JOIN persons p ON t.id = p.tenant_id
INNER JOIN positions pos ON p.position_id = pos.id;

-- ============================================================================
-- 2. VISTA 2: Consolidado Geográfico de las Organizaciones
-- ============================================================================
CREATE OR REPLACE VIEW vw_tenant_geographic_info AS
SELECT 
    t.id AS tenant_id,
    t.nit,
    t.name AS organizacion,
    t.address AS direccion,
    m.id AS municipality_id,
    m.name AS municipio,
    d.id AS department_id,
    d.name AS departamento,
    c.id AS country_id,
    c.name AS pais,
    c.code AS codigo_pais
FROM tenants t
INNER JOIN municipalities m ON t.municipality_id = m.id
INNER JOIN departments d ON m.department_id = d.id
INNER JOIN countries c ON d.country_id = c.id;

-- ============================================================================
-- 3. VISTA 3: Módulos Habilitados por Organización y su Sistema SST/PESV
-- ============================================================================
CREATE OR REPLACE VIEW vw_tenant_modules_system AS
SELECT 
    t.id AS tenant_id,
    t.name AS organizacion,
    m.id AS module_id,
    m.title AS modulo,
    m.presentation_order,
    ts.id AS system_sst_id,
    ts.name AS sistema_normativo,
    ts.code AS codigo_sistema,
    tm.assigned_at AS fecha_asignacion
FROM tenants t
INNER JOIN tenant_modules tm ON t.id = tm.tenant_id
INNER JOIN modules m ON tm.module_id = m.id
INNER JOIN type_system_sst ts ON m.system_sst_id = ts.id
WHERE tm.is_active = TRUE;

-- ============================================================================
-- 4. VISTA 4: Cantidad de Plantillas por Organización y Etapa PHVA
-- ============================================================================
CREATE OR REPLACE VIEW vw_tenant_phva_templates AS
SELECT 
    t.id AS tenant_id,
    t.name AS organizacion,
    ps.id AS stage_id,
    ps.name AS etapa_phva,
    ps.sequence_order AS orden_etapa,
    COUNT(tt.id) AS total_plantillas
FROM tenants t
CROSS JOIN phva_stages ps
LEFT JOIN tenanttemplates tt ON t.id = tt.tenant_id AND ps.id = tt.phva_stage_id
GROUP BY t.id, t.name, ps.id, ps.name, ps.sequence_order;

-- ============================================================================
-- 5. VISTA 5: Total de Personas Existentes por Organización y Cargo
-- ============================================================================
CREATE OR REPLACE VIEW vw_tenant_positions_count AS
SELECT 
    t.id AS tenant_id,
    t.name AS organizacion,
    pos.id AS position_id,
    pos.name AS cargo,
    COUNT(p.id) AS total_personas
FROM positions pos
INNER JOIN tenants t ON pos.tenant_id = t.id
LEFT JOIN persons p ON pos.id = p.position_id
GROUP BY t.id, t.name, pos.id, pos.name;

-- ============================================================================
-- 6. VISTA MATERIALIZADA: Resumen Integral de Cumplimiento Documental
-- ============================================================================
DROP MATERIALIZED VIEW IF EXISTS vm_template_compliance_summary CASCADE;
CREATE MATERIALIZED VIEW vm_template_compliance_summary AS
SELECT 
    t.id AS tenant_id,
    t.nit,
    t.name AS organizacion,
    COUNT(tt.id) AS total_documentos,
    COUNT(tt.id) FILTER (WHERE tt.status = 'finalizado') AS documentos_finalizados,
    COUNT(tt.id) FILTER (WHERE tt.status = 'pendiente') AS documentos_pendientes,
    COUNT(tt.id) FILTER (WHERE tt.status = 'borrador') AS documentos_borrador,
    COUNT(tt.id) FILTER (WHERE tt.status = 'no_iniciado') AS documentos_no_iniciados,
    COALESCE(
        ROUND((COUNT(tt.id) FILTER (WHERE tt.status = 'finalizado')::NUMERIC / NULLIF(COUNT(tt.id), 0)) * 100.0, 2),
        0.00
    ) AS porcentaje_cumplimiento,
    CURRENT_TIMESTAMP AS fecha_corte
FROM tenants t
LEFT JOIN tenanttemplates tt ON t.id = tt.tenant_id
GROUP BY t.id, t.nit, t.name;

CREATE UNIQUE INDEX idx_vm_compliance_tenant_id ON vm_template_compliance_summary(tenant_id);

-- ============================================================================
-- 7. VISTA MATERIALIZADA: Cumplimiento Documental Específico SST
-- ============================================================================
DROP MATERIALIZED VIEW IF EXISTS vm_template_sst_docs_summary CASCADE;
CREATE MATERIALIZED VIEW vm_template_sst_docs_summary AS
SELECT 
    t.id AS tenant_id,
    t.name AS organizacion,
    COUNT(tt.id) AS total_documentos_sst,
    COUNT(tt.id) FILTER (WHERE tt.status = 'finalizado') AS finalizados_sst,
    COUNT(tt.id) FILTER (WHERE tt.status = 'pendiente') AS pendientes_sst,
    COALESCE(
        ROUND((COUNT(tt.id) FILTER (WHERE tt.status = 'finalizado')::NUMERIC / NULLIF(COUNT(tt.id), 0)) * 100.0, 2),
        0.00
    ) AS porcentaje_cumplimiento_sst
FROM tenants t
LEFT JOIN tenanttemplates tt ON t.id = tt.tenant_id AND tt.system_sst_id = 1
GROUP BY t.id, t.name;

CREATE UNIQUE INDEX idx_vm_sst_docs_tenant_id ON vm_template_sst_docs_summary(tenant_id);

-- ============================================================================
-- 8. VISTA MATERIALIZADA: Cumplimiento Documental Específico PESV
-- ============================================================================
DROP MATERIALIZED VIEW IF EXISTS vm_template_pesv_docs_summary CASCADE;
CREATE MATERIALIZED VIEW vm_template_pesv_docs_summary AS
SELECT 
    t.id AS tenant_id,
    t.name AS organizacion,
    COUNT(tt.id) AS total_documentos_pesv,
    COUNT(tt.id) FILTER (WHERE tt.status = 'finalizado') AS finalizados_pesv,
    COUNT(tt.id) FILTER (WHERE tt.status = 'pendiente') AS pendientes_pesv,
    COALESCE(
        ROUND((COUNT(tt.id) FILTER (WHERE tt.status = 'finalizado')::NUMERIC / NULLIF(COUNT(tt.id), 0)) * 100.0, 2),
        0.00
    ) AS porcentaje_cumplimiento_pesv
FROM tenants t
LEFT JOIN tenanttemplates tt ON t.id = tt.tenant_id AND tt.system_sst_id = 2
GROUP BY t.id, t.name;

CREATE UNIQUE INDEX idx_vm_pesv_docs_tenant_id ON vm_template_pesv_docs_summary(tenant_id);
