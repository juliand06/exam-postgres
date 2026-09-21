-- ============================================================================
-- PROYECTO ACADÉMICO: GESTIÓN MULTI-TENANT SST & PESV
-- AUTOR: Julian Andrey Ricaurte (juliand06)
-- ARCHIVO: sql/consultas.sql
-- DESCRIPCIÓN: Banco completo de consultas (Básicas, Intermedias, Avanzadas y Vistas)
-- ============================================================================

-- ============================================================================
-- 1. CONSULTAS SQL BÁSICAS (15 Consultas)
-- ============================================================================

-- 1.1 Consultar todos los registros almacenados en la tabla tenants
SELECT 
    id, nit, name, email, phone, address, municipality_id, 
    tenant_size_id, is_active, compliance_percentage, created_at, updated_at
FROM tenants;

-- 1.2 Consultar nombre, correo de contacto y teléfono de todas las organizaciones
SELECT 
    name AS organizacion,
    email AS correo_contacto,
    phone AS telefono
FROM tenants;

-- 1.3 Listar personas registradas mostrando nombres, apellidos y correo electrónico
SELECT 
    first_name AS nombres,
    last_name AS apellidos,
    email AS correo_electronico
FROM persons;

-- 1.4 Consultar personas cuyo estado se encuentre activo
SELECT 
    id, identification_number, first_name, last_name, email, tenant_id, position_id
FROM persons
WHERE is_active = TRUE;

-- 1.5 Obtener organizaciones cuyo nombre contenga una determinada palabra ('Oriente')
SELECT 
    id, nit, name, email, phone
FROM tenants
WHERE name ILIKE '%Oriente%';

-- 1.6 Listar todos los países ordenados alfabéticamente por nombre
SELECT 
    id, code, name
FROM countries
ORDER BY name ASC;

-- 1.7 Consultar los departamentos pertenecientes a un país determinado (Colombia = ID 1)
SELECT 
    id, code, name
FROM departments
WHERE country_id = 1
ORDER BY name ASC;

-- 1.8 Listar municipios correspondientes a un departamento específico (Santander = ID 1)
SELECT 
    id, code, name
FROM municipalities
WHERE department_id = 1
ORDER BY name ASC;

-- 1.9 Consultar todos los cargos registrados en positions ordenados por nombre/descripción
SELECT 
    id, tenant_id, name, description, is_active
FROM positions
ORDER BY name ASC;

-- 1.10 Consultar personas que pertenezcan a una organización determinada (Tenant ID = 1)
SELECT 
    id, identification_number, first_name, last_name, email, position_id
FROM persons
WHERE tenant_id = 1;

-- 1.11 Obtener organizaciones que actualmente se encuentren activas en el sistema
SELECT 
    id, nit, name, email, compliance_percentage
FROM tenants
WHERE is_active = TRUE;

-- 1.12 Identificar organizaciones registradas dentro de un período determinado
SELECT 
    id, nit, name, created_at
FROM tenants
WHERE created_at BETWEEN '2026-01-01 00:00:00' AND CURRENT_TIMESTAMP;

-- 1.13 Listar los diferentes tamaños de empresa almacenados en tenant_sizes
SELECT 
    id, name, min_employees, max_employees, description
FROM tenant_sizes
ORDER BY min_employees ASC;

-- 1.14 Consultar los diferentes tipos de sistemas normativos en type_system_sst
SELECT 
    id, code, name, description
FROM type_system_sst;

-- 1.15 Listar módulos registrados mostrando título, descripción y orden de presentación
SELECT 
    id, system_sst_id, title, description, presentation_order
FROM modules
ORDER BY presentation_order ASC;

-- ============================================================================
-- 2. CONSULTAS SQL INTERMEDIAS (20 Consultas)
-- ============================================================================

-- 2.1 Personas registradas con su nombre completo y el nombre de su organización
SELECT 
    p.id AS person_id,
    CONCAT(p.first_name, ' ', p.last_name) AS nombre_completo,
    p.email,
    t.name AS organizacion
FROM persons p
INNER JOIN tenants t ON p.tenant_id = t.id;

-- 2.2 Cada persona junto con el cargo que desempeña dentro de su organización
SELECT 
    CONCAT(p.first_name, ' ', p.last_name) AS colaborador,
    pos.name AS cargo,
    t.name AS organizacion
FROM persons p
INNER JOIN positions pos ON p.position_id = pos.id
INNER JOIN tenants t ON p.tenant_id = t.id;

-- 2.3 Cada organización junto con el tamaño de empresa asignado
SELECT 
    t.id AS tenant_id,
    t.name AS organizacion,
    ts.name AS tamano_empresa,
    ts.min_employees AS min_trabajadores,
    ts.max_employees AS max_trabajadores
FROM tenants t
INNER JOIN tenant_sizes ts ON t.tenant_size_id = ts.id;

-- 2.4 Organización con ciudad, departamento y país donde está registrada
SELECT 
    t.name AS organizacion,
    m.name AS municipio,
    d.name AS departamento,
    c.name AS pais
FROM tenants t
INNER JOIN municipalities m ON t.municipality_id = m.id
INNER JOIN departments d ON m.department_id = d.id
INNER JOIN countries c ON d.country_id = c.id;

-- 2.5 Determinar cuántas personas se encuentran registradas en cada organización
SELECT 
    t.id AS tenant_id,
    t.name AS organizacion,
    COUNT(p.id) AS total_personas
FROM tenants t
LEFT JOIN persons p ON t.id = p.tenant_id
GROUP BY t.id, t.name
ORDER BY total_personas DESC;

-- 2.6 Identificar organizaciones que tengan más de 2 personas registradas
SELECT 
    t.id AS tenant_id,
    t.name AS organizacion,
    COUNT(p.id) AS total_personas
FROM tenants t
INNER JOIN persons p ON t.id = p.tenant_id
GROUP BY t.id, t.name
HAVING COUNT(p.id) > 2;

-- 2.7 Consultar módulos habilitados para cada organización
SELECT 
    t.name AS organizacion,
    m.title AS modulo,
    ts.code AS sistema
FROM tenant_modules tm
INNER JOIN tenants t ON tm.tenant_id = t.id
INNER JOIN modules m ON tm.module_id = m.id
INNER JOIN type_system_sst ts ON m.system_sst_id = ts.id
WHERE tm.is_active = TRUE
ORDER BY t.name, m.presentation_order;

-- 2.8 Determinar cuántos módulos tiene habilitados cada organización
SELECT 
    t.id AS tenant_id,
    t.name AS organizacion,
    COUNT(tm.id) AS modulos_habilitados
FROM tenants t
LEFT JOIN tenant_modules tm ON t.id = tm.tenant_id AND tm.is_active = TRUE
GROUP BY t.id, t.name
ORDER BY modulos_habilitados DESC;

-- 2.9 Consultar sistemas normativos habilitados para cada organización
SELECT 
    t.name AS organizacion,
    ts.code AS codigo_sistema,
    ts.name AS nombre_sistema,
    tns.enabled_at
FROM tenantsystems tns
INNER JOIN tenants t ON tns.tenant_id = t.id
INNER JOIN type_system_sst ts ON tns.system_sst_id = ts.id
WHERE tns.is_active = TRUE;

-- 2.10 Mostrar módulos existentes junto con el sistema normativo al cual pertenecen
SELECT 
    m.id AS module_id,
    m.title AS modulo,
    ts.code AS sistema,
    ts.name AS descripcion_sistema
FROM modules m
INNER JOIN type_system_sst ts ON m.system_sst_id = ts.id
ORDER BY ts.code, m.presentation_order;

-- 2.11 Formatos registrados en formats_sst mostrando el módulo al cual pertenece
SELECT 
    f.code AS codigo_formato,
    f.name AS nombre_formato,
    f.version,
    m.title AS modulo_asociado
FROM formats_sst f
INNER JOIN modules m ON f.module_id = m.id;

-- 2.12 Determinar cuántos formatos se encuentran asociados a cada módulo
SELECT 
    m.id AS module_id,
    m.title AS modulo,
    COUNT(f.id) AS total_formatos
FROM modules m
LEFT JOIN formats_sst f ON m.id = f.module_id
GROUP BY m.id, m.title
ORDER BY total_formatos DESC;

-- 2.13 Consultar plantillas asignadas a cada organización mediante tenanttemplates
SELECT 
    t.name AS organizacion,
    tt.id AS template_id,
    tt.name AS nombre_plantilla,
    tt.status AS estado,
    tt.version
FROM tenanttemplates tt
INNER JOIN tenants t ON tt.tenant_id = t.id
ORDER BY t.name, tt.name;

-- 2.14 Mostrar cada plantilla indicando organización, sistema y etapa PHVA
SELECT 
    tt.name AS plantilla,
    t.name AS organizacion,
    ts.code AS sistema,
    ps.name AS etapa_phva,
    tt.status AS estado
FROM tenanttemplates tt
INNER JOIN tenants t ON tt.tenant_id = t.id
INNER JOIN type_system_sst ts ON tt.system_sst_id = ts.id
INNER JOIN phva_stages ps ON tt.phva_stage_id = ps.id;

-- 2.15 Determinar cuántas plantillas tiene asignadas cada organización
SELECT 
    t.id AS tenant_id,
    t.name AS organizacion,
    COUNT(tt.id) AS total_plantillas
FROM tenants t
LEFT JOIN tenanttemplates tt ON t.id = tt.tenant_id
GROUP BY t.id, t.name
ORDER BY total_plantillas DESC;

-- 2.16 Organizaciones que actualmente no tengan personas registradas
SELECT 
    t.id, t.nit, t.name, t.email
FROM tenants t
LEFT JOIN persons p ON t.id = p.tenant_id
WHERE p.id IS NULL;

-- 2.17 Módulos que todavía no hayan sido asignados a ninguna organización
SELECT 
    m.id, m.title, m.presentation_order
FROM modules m
LEFT JOIN tenant_modules tm ON m.id = tm.module_id
WHERE tm.id IS NULL;

-- 2.18 Etapas PHVA mostrando el número de plantillas asociadas a cada una
SELECT 
    ps.id AS stage_id,
    ps.name AS etapa_phva,
    COUNT(tt.id) AS total_plantillas
FROM phva_stages ps
LEFT JOIN tenanttemplates tt ON ps.id = tt.phva_stage_id
GROUP BY ps.id, ps.name, ps.sequence_order
ORDER BY ps.sequence_order;

-- 2.19 Cantidad de organizaciones registradas por municipio
SELECT 
    m.name AS municipio,
    COUNT(t.id) AS total_empresas
FROM municipalities m
LEFT JOIN tenants t ON m.id = t.municipality_id
GROUP BY m.id, m.name
ORDER BY total_empresas DESC;

-- 2.20 Cargos existentes por organización y número de personas que los ocupan
SELECT 
    t.name AS organizacion,
    pos.name AS cargo,
    COUNT(p.id) AS total_ocupantes
FROM positions pos
INNER JOIN tenants t ON pos.tenant_id = t.id
LEFT JOIN persons p ON pos.id = p.position_id
GROUP BY t.name, pos.name
ORDER BY t.name, total_ocupantes DESC;

-- ============================================================================
-- 3. CONSULTAS SQL AVANZADAS (25 Consultas)
-- ============================================================================

-- 3.1 Organización con la mayor cantidad de personas registradas
SELECT 
    t.id AS tenant_id,
    t.name AS organizacion,
    COUNT(p.id) AS total_personas
FROM tenants t
INNER JOIN persons p ON t.id = p.tenant_id
GROUP BY t.id, t.name
ORDER BY total_personas DESC
LIMIT 1;

-- 3.2 Organizaciones con cantidad de personas superior al promedio general
SELECT 
    t.id AS tenant_id,
    t.name AS organizacion,
    COUNT(p.id) AS total_personas
FROM tenants t
INNER JOIN persons p ON t.id = p.tenant_id
GROUP BY t.id, t.name
HAVING COUNT(p.id) > (
    SELECT AVG(person_count) 
    FROM (
        SELECT COUNT(id) AS person_count 
        FROM persons 
        GROUP BY tenant_id
    ) sub
);

-- 3.3 Organizaciones con todos los módulos existentes para un sistema (SST = ID 1)
SELECT 
    t.id, t.name AS organizacion
FROM tenants t
INNER JOIN tenant_modules tm ON t.id = tm.tenant_id
INNER JOIN modules m ON tm.module_id = m.id
WHERE m.system_sst_id = 1
GROUP BY t.id, t.name
HAVING COUNT(DISTINCT m.id) = (SELECT COUNT(*) FROM modules WHERE system_sst_id = 1);

-- 3.4 Organizaciones con al menos un módulo configurado pero sin plantillas
SELECT 
    t.id, t.name
FROM tenants t
INNER JOIN tenant_modules tm ON t.id = tm.tenant_id
LEFT JOIN tenanttemplates tt ON t.id = tt.tenant_id
WHERE tt.id IS NULL
GROUP BY t.id, t.name;

-- 3.5 Organizaciones con plantillas asociadas a todas las etapas PHVA disponibles
SELECT 
    t.id, t.name AS organizacion
FROM tenants t
INNER JOIN tenanttemplates tt ON t.id = tt.tenant_id
GROUP BY t.id, t.name
HAVING COUNT(DISTINCT tt.phva_stage_id) = (SELECT COUNT(*) FROM phva_stages);

-- 3.6 Plantillas asignadas a cada organización discriminadas por etapa PHVA
SELECT 
    t.name AS organizacion,
    ps.name AS etapa_phva,
    COUNT(tt.id) AS total_plantillas
FROM tenants t
CROSS JOIN phva_stages ps
LEFT JOIN tenanttemplates tt ON t.id = tt.tenant_id AND ps.id = tt.phva_stage_id
GROUP BY t.name, ps.name, ps.sequence_order
ORDER BY t.name, ps.sequence_order;

-- 3.7 Columnas independientes para Planear, Hacer, Verificar y Actuar (Pivot Condicional)
SELECT 
    t.name AS organizacion,
    COUNT(tt.id) FILTER (WHERE ps.code = 'PLAN') AS planear,
    COUNT(tt.id) FILTER (WHERE ps.code = 'DO') AS hacer,
    COUNT(tt.id) FILTER (WHERE ps.code = 'CHECK') AS verificar,
    COUNT(tt.id) FILTER (WHERE ps.code = 'ACT') AS actuar,
    COUNT(tt.id) AS total_documentos
FROM tenants t
LEFT JOIN tenanttemplates tt ON t.id = tt.tenant_id
LEFT JOIN phva_stages ps ON tt.phva_stage_id = ps.id
GROUP BY t.id, t.name
ORDER BY t.name;

-- 3.8 Porcentaje que representa cada etapa PHVA sobre el total de plantillas del tenant
SELECT 
    t.name AS organizacion,
    ps.name AS etapa_phva,
    COUNT(tt.id) AS plantillas_etapa,
    COUNT(tt.id) OVER (PARTITION BY t.id) AS total_tenant,
    ROUND(
        (COUNT(tt.id)::NUMERIC / NULLIF(COUNT(tt.id) OVER (PARTITION BY t.id), 0)) * 100.0,
        2
    ) AS porcentaje_etapa
FROM tenants t
INNER JOIN tenanttemplates tt ON t.id = tt.tenant_id
INNER JOIN phva_stages ps ON tt.phva_stage_id = ps.id
GROUP BY t.id, t.name, ps.id, ps.name, tt.id;

-- 3.9 Etapa PHVA con mayor cantidad de plantillas en cada organización
WITH etapa_conteo AS (
    SELECT 
        t.id AS tenant_id,
        t.name AS organizacion,
        ps.name AS etapa_phva,
        COUNT(tt.id) AS total_docs,
        DENSE_RANK() OVER (PARTITION BY t.id ORDER BY COUNT(tt.id) DESC) as ranking
    FROM tenants t
    INNER JOIN tenanttemplates tt ON t.id = tt.tenant_id
    INNER JOIN phva_stages ps ON tt.phva_stage_id = ps.id
    GROUP BY t.id, t.name, ps.name
)
SELECT organizacion, etapa_phva, total_docs
FROM etapa_conteo
WHERE ranking = 1;

-- 3.10 Porcentaje de documentos finalizados frente al total por organización
SELECT 
    tenant_id,
    organizacion,
    total_documentos,
    documentos_finalizados,
    porcentaje_cumplimiento
FROM vm_template_compliance_summary;

-- 3.11 Organizaciones con cumplimiento por debajo del promedio general
SELECT 
    organizacion,
    porcentaje_cumplimiento
FROM vm_template_compliance_summary
WHERE porcentaje_cumplimiento < (
    SELECT AVG(porcentaje_cumplimiento) FROM vm_template_compliance_summary
);

-- 3.12 Clasificar organizaciones según su porcentaje de cumplimiento mediante CASE
SELECT 
    organizacion,
    porcentaje_cumplimiento,
    CASE 
        WHEN porcentaje_cumplimiento >= 85.00 THEN 'Alto'
        WHEN porcentaje_cumplimiento >= 60.00 THEN 'Medio'
        ELSE 'Bajo'
    END AS clasificacion_nivel
FROM vm_template_compliance_summary
ORDER BY porcentaje_cumplimiento DESC;

-- 3.13 Ranking de organizaciones por cumplimiento documental con función de ventana
SELECT 
    DENSE_RANK() OVER (ORDER BY porcentaje_cumplimiento DESC) AS puesto,
    organizacion,
    total_documentos,
    documentos_finalizados,
    porcentaje_cumplimiento
FROM vm_template_compliance_summary;

-- 3.14 Porcentaje de cumplimiento y diferencia frente al promedio general
SELECT 
    organizacion,
    porcentaje_cumplimiento,
    ROUND(AVG(porcentaje_cumplimiento) OVER (), 2) AS promedio_general,
    ROUND(porcentaje_cumplimiento - AVG(porcentaje_cumplimiento) OVER (), 2) AS desviacion_promedio
FROM vm_template_compliance_summary;

-- 3.15 Cantidad acumulada de documentos finalizados utilizando ventana
SELECT 
    tenant_id,
    organizacion,
    documentos_finalizados,
    SUM(documentos_finalizados) OVER (ORDER BY documentos_finalizados DESC, tenant_id) AS acumulado_finalizados
FROM vm_template_compliance_summary;

-- 3.16 Organizaciones en el mismo municipio con diferente tamaño empresarial (Self-Join)
SELECT 
    t1.name AS empresa_1,
    ts1.name AS tamano_1,
    t2.name AS empresa_2,
    ts2.name AS tamano_2,
    m.name AS municipio
FROM tenants t1
INNER JOIN tenants t2 ON t1.municipality_id = t2.municipality_id AND t1.id < t2.id
INNER JOIN tenant_sizes ts1 ON t1.tenant_size_id = ts1.id
INNER JOIN tenant_sizes ts2 ON t2.tenant_size_id = ts2.id
INNER JOIN municipalities m ON t1.municipality_id = m.id
WHERE t1.tenant_size_id <> t2.tenant_size_id;

-- 3.17 Personas cuyo cargo supera el promedio de ocupación de cargos en su organización
WITH cargo_ocupacion AS (
    SELECT 
        tenant_id,
        position_id,
        COUNT(id) AS personas_cargo
    FROM persons
    GROUP BY tenant_id, position_id
),
promedio_organizacion AS (
    SELECT 
        tenant_id,
        AVG(personas_cargo) AS prom_ocupacion
    FROM cargo_ocupacion
    GROUP BY tenant_id
)
SELECT 
    p.identification_number,
    CONCAT(p.first_name, ' ', p.last_name) AS persona,
    pos.name AS cargo,
    co.personas_cargo,
    ROUND(po.prom_ocupacion, 2) AS prom_cargo_empresa
FROM persons p
INNER JOIN positions pos ON p.position_id = pos.id
INNER JOIN cargo_ocupacion co ON p.tenant_id = co.tenant_id AND p.position_id = co.position_id
INNER JOIN promedio_organizacion po ON p.tenant_id = po.tenant_id
WHERE co.personas_cargo > po.prom_ocupacion;

-- 3.18 CTE para calcular personas por organización y seleccionar las que superan el promedio
WITH personas_por_empresa AS (
    SELECT 
        t.id AS tenant_id,
        t.name AS organizacion,
        COUNT(p.id) AS total_empleados
    FROM tenants t
    INNER JOIN persons p ON t.id = p.tenant_id
    GROUP BY t.id, t.name
),
promedio_empleados AS (
    SELECT AVG(total_empleados) AS umbral_promedio FROM personas_por_empresa
)
SELECT 
    pbe.tenant_id,
    pbe.organizacion,
    pbe.total_empleados,
    ROUND(pe.umbral_promedio, 2) AS promedio_sistema
FROM personas_por_empresa pbe
CROSS JOIN promedio_empleados pe
WHERE pbe.total_empleados > pe.umbral_promedio;

-- 3.19 CTE para consolidar cantidad de módulos, plantillas y personas por organización
WITH conteo_personas AS (
    SELECT tenant_id, COUNT(id) AS total_personas FROM persons GROUP BY tenant_id
),
conteo_modulos AS (
    SELECT tenant_id, COUNT(id) AS total_modulos FROM tenant_modules WHERE is_active = TRUE GROUP BY tenant_id
),
conteo_plantillas AS (
    SELECT tenant_id, COUNT(id) AS total_plantillas FROM tenanttemplates GROUP BY tenant_id
)
SELECT 
    t.id AS tenant_id,
    t.name AS organizacion,
    COALESCE(cp.total_personas, 0) AS personas,
    COALESCE(cm.total_modulos, 0) AS modulos_habilitados,
    COALESCE(cpl.total_plantillas, 0) AS plantillas_asignadas
FROM tenants t
LEFT JOIN conteo_personas cp ON t.id = cp.tenant_id
LEFT JOIN conteo_modulos cm ON t.id = cm.tenant_id
LEFT JOIN conteo_plantillas cpl ON t.id = cpl.tenant_id
ORDER BY t.name;

-- 3.20 Organizaciones sin alguna etapa PHVA configurada dentro de sus plantillas
SELECT 
    t.id AS tenant_id,
    t.name AS organizacion,
    ps.name AS etapa_faltante
FROM tenants t
CROSS JOIN phva_stages ps
LEFT JOIN tenanttemplates tt ON t.id = tt.tenant_id AND ps.id = tt.phva_stage_id
WHERE tt.id IS NULL
ORDER BY t.name, ps.sequence_order;

-- 3.21 Última fecha de actualización registrada para cada organización según plantillas
SELECT 
    t.id AS tenant_id,
    t.name AS organizacion,
    MAX(tt.updated_at) AS ultima_actualizacion_documental
FROM tenants t
LEFT JOIN tenanttemplates tt ON t.id = tt.tenant_id
GROUP BY t.id, t.name;

-- 3.22 Organizaciones que presentan registros pendientes usando las vistas materializadas
SELECT 
    t.name AS organizacion,
    COALESCE(vs.pendientes_sst, 0) AS pendientes_sst,
    COALESCE(vp.pendientes_pesv, 0) AS pendientes_pesv
FROM tenants t
LEFT JOIN vm_template_sst_docs_summary vs ON t.id = vs.tenant_id
LEFT JOIN vm_template_pesv_docs_summary vp ON t.id = vp.tenant_id
WHERE COALESCE(vs.pendientes_sst, 0) > 0 OR COALESCE(vp.pendientes_pesv, 0) > 0;

-- 3.23 Informe consolidado completo por organización
SELECT 
    t.id AS tenant_id,
    t.nit,
    t.name AS organizacion,
    COUNT(tt.id) AS total_docs,
    COUNT(tt.id) FILTER (WHERE tt.status = 'finalizado') AS finalizados,
    COUNT(tt.id) FILTER (WHERE tt.status = 'borrador') AS borrador,
    COUNT(tt.id) FILTER (WHERE tt.status = 'no_iniciado') AS no_iniciados,
    COUNT(tt.id) FILTER (WHERE tt.status = 'pendiente') AS pendientes,
    COALESCE(ROUND((COUNT(tt.id) FILTER (WHERE tt.status = 'finalizado')::NUMERIC / NULLIF(COUNT(tt.id), 0)) * 100.0, 2), 0.00) AS pct_cumplimiento
FROM tenants t
LEFT JOIN tenanttemplates tt ON t.id = tt.tenant_id
GROUP BY t.id, t.nit, t.name
ORDER BY pct_cumplimiento DESC;

-- 3.24 Comparar porcentaje de cumplimiento SST vs PESV (diferencia superior a 15%)
SELECT 
    t.name AS organizacion,
    COALESCE(vs.porcentaje_cumplimiento_sst, 0.00) AS cumplimiento_sst,
    COALESCE(vp.porcentaje_cumplimiento_pesv, 0.00) AS cumplimiento_pesv,
    ABS(COALESCE(vs.porcentaje_cumplimiento_sst, 0.00) - COALESCE(vp.porcentaje_cumplimiento_pesv, 0.00)) AS brecha_cumplimiento
FROM tenants t
LEFT JOIN vm_template_sst_docs_summary vs ON t.id = vs.tenant_id
LEFT JOIN vm_template_pesv_docs_summary vp ON t.id = vp.tenant_id
WHERE ABS(COALESCE(vs.porcentaje_cumplimiento_sst, 0.00) - COALESCE(vp.porcentaje_cumplimiento_pesv, 0.00)) > 15.00;

-- 3.25 Vista / consulta consolidada de personas, módulos, plantillas y sistemas habilitados
SELECT 
    t.id AS tenant_id,
    t.name AS organizacion,
    COUNT(DISTINCT p.id) AS total_personas,
    COUNT(DISTINCT tm.module_id) AS total_modulos,
    COUNT(DISTINCT tt.id) AS total_plantillas,
    COUNT(DISTINCT ts.system_sst_id) AS sistemas_habilitados
FROM tenants t
LEFT JOIN persons p ON t.id = p.tenant_id
LEFT JOIN tenant_modules tm ON t.id = tm.tenant_id AND tm.is_active = TRUE
LEFT JOIN tenanttemplates tt ON t.id = tt.tenant_id
LEFT JOIN tenantsystems ts ON t.id = ts.tenant_id AND ts.is_active = TRUE
GROUP BY t.id, t.name
ORDER BY t.name;

-- ============================================================================
-- 4. CONSULTAS SOBRE VISTAS Y VISTAS MATERIALIZADAS
-- ============================================================================

-- 4.1 Consulta sobre vw_tenant_persons
SELECT * FROM vw_tenant_persons WHERE persona_activa = TRUE;

-- 4.2 Consulta sobre vw_tenant_geographic_info
SELECT * FROM vw_tenant_geographic_info ORDER BY departamento, municipio;

-- 4.3 Consulta sobre vw_tenant_modules_system
SELECT * FROM vw_tenant_modules_system ORDER BY organizacion, presentation_order;

-- 4.4 Consulta sobre vw_tenant_phva_templates
SELECT * FROM vw_tenant_phva_templates WHERE total_plantillas > 0;

-- 4.5 Consulta sobre vw_tenant_positions_count
SELECT * FROM vw_tenant_positions_count WHERE total_personas > 0;

-- 4.6 Consulta sobre vm_template_compliance_summary
SELECT * FROM vm_template_compliance_summary ORDER BY porcentaje_cumplimiento DESC;

-- 4.7 Refresco de vistas materializadas
REFRESH MATERIALIZED VIEW CONCURRENTLY vm_template_compliance_summary;
REFRESH MATERIALIZED VIEW CONCURRENTLY vm_template_sst_docs_summary;
REFRESH MATERIALIZED VIEW CONCURRENTLY vm_template_pesv_docs_summary;

-- 4.8 Inspección de índices estratégicos sobre vistas materializadas
SELECT indexname, tablename, indexdef 
FROM pg_indexes 
WHERE tablename LIKE 'vm_template%';
