-- ============================================================================
-- PROYECTO ACADÉMICO: GESTIÓN MULTI-TENANT SST & PESV
-- AUTOR: Julian Andrey Ricaurte (juliand06)
-- ARCHIVO: 04_seed_data.sql - Carga de Datos de Prueba (Seed Data)
-- ============================================================================

-- 1. PAÍSES
INSERT INTO countries (code, name) VALUES 
('COL', 'Colombia'),
('MEX', 'México'),
('CHL', 'Chile'),
('PER', 'Perú')
ON CONFLICT (code) DO NOTHING;

-- 2. DEPARTAMENTOS
INSERT INTO departments (country_id, code, name) VALUES 
(1, 'SAN', 'Santander'),
(1, 'CUN', 'Cundinamarca'),
(1, 'ANT', 'Antioquia'),
(1, 'VAL', 'Valle del Cauca'),
(1, 'ATL', 'Atlántico')
ON CONFLICT (country_id, code) DO NOTHING;

-- 3. MUNICIPIOS
INSERT INTO municipalities (department_id, code, name) VALUES 
(1, '68001', 'Bucaramanga'),
(1, '68276', 'Floridablanca'),
(1, '68547', 'Piedecuesta'),
(2, '11001', 'Bogotá D.C.'),
(3, '05001', 'Medellín'),
(4, '76001', 'Cali'),
(5, '08001', 'Barranquilla')
ON CONFLICT (department_id, code) DO NOTHING;

-- 4. TAMAÑOS DE EMPRESA
INSERT INTO tenant_sizes (name, min_employees, max_employees, description) VALUES 
('Microempresa', 1, 10, 'Empresas con nómina de hasta 10 trabajadores.'),
('Pequeña Empresa', 11, 50, 'Empresas medianas con nómina de 11 a 50 trabajadores.'),
('Mediana Empresa', 51, 200, 'Empresas con nómina de 51 a 200 colaboradores.'),
('Gran Empresa', 201, NULL, 'Organizaciones de gran escala con más de 200 colaboradores.')
ON CONFLICT (name) DO NOTHING;

-- 5. TIPOS DE SISTEMAS NORMATIVOS
INSERT INTO type_system_sst (code, name, description) VALUES 
('SST', 'Sistema de Gestión de Seguridad y Salud en el Trabajo', 'Normativa Decreto 1072/2015 y Resolución 0312/2019.'),
('PESV', 'Plan Estratégico de Seguridad Vial', 'Normativa Resolución 40595 de 2022 del Ministerio de Transporte.')
ON CONFLICT (code) DO NOTHING;

-- 6. ETAPAS DEL CICLO PHVA
INSERT INTO phva_stages (code, name, sequence_order, description) VALUES 
('PLAN', 'Planear', 1, 'Definición de directrices, políticas, recursos e identificación de riesgos.'),
('DO', 'Hacer', 2, 'Ejecución de programas de capacitación, medidas preventivas y planes de trabajo.'),
('CHECK', 'Verificar', 3, 'Auditorías, inspecciones de seguridad, indicadores y revisión por la dirección.'),
('ACT', 'Actuar', 4, 'Planes de mejoramiento continuo y acciones correctivas/preventivas.')
ON CONFLICT (code) DO NOTHING;

-- 7. ORGANIZACIONES (TENANTS)
INSERT INTO tenants (nit, name, email, phone, address, municipality_id, tenant_size_id, is_active, compliance_percentage) VALUES 
('901.458.120-3', 'Transportes & Carga del Oriente S.A.S.', 'gerencia@transportesoriente.com', '3157894512', 'Cra 27 # 45-18 Zona Industrial', 1, 3, TRUE, 80.00),
('900.832.741-5', 'Constructora Andina de Santander S.A.', 'sst@constructoraandina.com.co', '3104561230', 'Autopista Floridablanca Km 4', 2, 4, TRUE, 66.67),
('890.312.905-1', 'Salud & Vida Integral IPS S.A.S.', 'calidad@saludvidaintegral.com', '3189012345', 'Calle 50 # 32-15 El Poblado', 5, 3, TRUE, 100.00),
('901.764.339-8', 'Logística Express del Caribe S.A.S.', 'operaciones@logisticaexpress.co', '3001239874', 'Vía 40 # 70-80 Parque Logístico', 7, 2, TRUE, 40.00),
('860.024.118-2', 'Manufacturas del Calzado Santander Ltda.', 'contacto@calzadosantander.com', '3176549821', 'Calle 34 # 16-20 Centro', 1, 2, TRUE, 50.00),
('901.992.845-0', 'Agropecuaria del Valle S.A.', 'seguridad@agrodelvalle.com', '3128905643', 'Av. Cañasgordas Km 12', 6, 4, TRUE, 75.00),
('900.551.234-9', 'Soluciones Cloud & Tech S.A.S.', 'info@cloudtechcolombia.com', '3209876543', 'Calle 93B # 12-40 Chicó', 4, 1, FALSE, 0.00)
ON CONFLICT (nit) DO NOTHING;

-- 8. CARGOS POR ORGANIZACIÓN (POSITIONS)
-- Tenant 1: Transportes & Carga (IDs generados: 1, 2, 3, 4)
INSERT INTO positions (tenant_id, name, description) VALUES 
(1, 'Gerente de Operaciones', 'Dirección logística y flota vehicular.'),
(1, 'Coordinador SST & PESV', 'Líder de seguridad vial y salud ocupacional.'),
(1, 'Conductor de Carga Pesada', 'Operador de tractomulas y transporte intermunicipal.'),
(1, 'Técnico de Mantenimiento', 'Mantenimiento preventivo y correctivo de flota.');

-- Tenant 2: Constructora Andina (IDs generados: 5, 6, 7, 8)
INSERT INTO positions (tenant_id, name, description) VALUES 
(2, 'Director de Obras', 'Supervisión general de proyectos constructivos.'),
(2, 'Especialista en Seguridad Industrial', 'Control de trabajo en alturas y riesgos críticos.'),
(2, 'Maestro Mayor de Obra', 'Coordinación directa de cuadrillas de construcción.'),
(2, 'Operador de Maquinaria Pesada', 'Manejo de retroexcavadoras y grúas torre.');

-- Tenant 3: Salud & Vida Integral (IDs generados: 9, 10, 11)
INSERT INTO positions (tenant_id, name, description) VALUES 
(3, 'Director Médico', 'Gestión técnico-asistencial de la IPS.'),
(3, 'Líder de Epidemiología y SST', 'Control de riesgos biológicos y químicos.'),
(3, 'Enfermero(a) Jefe Ocupacional', 'Atención de emergencias y exámenes periódicos.');

-- Tenant 4: Logística Express del Caribe (IDs generados: 12, 13)
INSERT INTO positions (tenant_id, name, description) VALUES 
(4, 'Jefe de Despachos', 'Coordinación de rutas marítimas y terrestres.'),
(4, 'Inspector Vial PESV', 'Revisión preoperacional de camiones.');

-- Tenant 5: Manufacturas del Calzado (IDs generados: 14, 15)
INSERT INTO positions (tenant_id, name, description) VALUES 
(5, 'Jefe de Planta', 'Supervisión de líneas de corte y confección.'),
(5, 'Vigía SST', 'Promoción de ergonomía y prevención de riesgos.');

-- Tenant 6: Agropecuaria del Valle (IDs generados: 16, 17)
INSERT INTO positions (tenant_id, name, description) VALUES 
(6, 'Administrador de Hacienda', 'Dirección general agroindustrial.'),
(6, 'Supervisor de Seguridad en Campo', 'Manejo seguro de agroquímicos y maquinaria agrícola.');

-- 9. TRABAJADORES (PERSONS) - Respetando tenant_id y position_id
INSERT INTO persons (identification_number, first_name, last_name, email, phone, tenant_id, position_id, is_active) VALUES 
-- Tenant 1 (pos 1, 2, 3, 4)
('1098745612', 'Julian Andrey', 'Ricaurte', 'j.ricaurte@transportesoriente.com', '3157894512', 1, 2, TRUE),
('1095823490', 'Carlos Eduardo', 'Mendoza', 'c.mendoza@transportesoriente.com', '3168901234', 1, 1, TRUE),
('63489120', 'Hernando', 'Gómez Plata', 'h.gomez@transportesoriente.com', '3114567890', 1, 3, TRUE),
('1098654321', 'Mauricio', 'Velandia', 'm.velandia@transportesoriente.com', '3123456789', 1, 4, TRUE),

-- Tenant 2 (pos 5, 6, 7, 8)
('1098234567', 'Laura Marcela', 'Duarte', 'l.duarte@constructoraandina.com.co', '3104561230', 2, 6, TRUE),
('91283940', 'Jorge Iván', 'Peña', 'j.pena@constructoraandina.com.co', '3145678901', 2, 5, TRUE),
('1097654321', 'Pedro Nel', 'Cárdenas', 'p.cardenas@constructoraandina.com.co', '3134567890', 2, 7, TRUE),

-- Tenant 3 (pos 9, 10, 11)
('52890123', 'Dra. Patricia', 'Montoya', 'p.montoya@saludvidaintegral.com', '3189012345', 3, 9, TRUE),
('1096543210', 'Andrés Felipe', 'Castro', 'a.castro@saludvidaintegral.com', '3190123456', 3, 10, TRUE),

-- Tenant 4 (pos 12, 13)
('1045678901', 'Ricardo José', 'Barrios', 'r.barrios@logisticaexpress.co', '3001239874', 4, 12, TRUE),
('72890123', 'Guillermo', 'Orozco', 'g.orozco@logisticaexpress.co', '3012345678', 4, 13, TRUE),

-- Tenant 5 (pos 14, 15)
('63543210', 'Esperanza', 'Jaimes', 'e.jaimes@calzadosantander.com', '3176549821', 5, 15, TRUE),

-- Tenant 6 (pos 16, 17)
('1113456789', 'Mateo', 'Echeverry', 'm.echeverry@agrodelvalle.com', '3128905643', 6, 17, TRUE);

-- 10. HABILITACIÓN DE SISTEMAS NORMATIVOS POR TENANT
INSERT INTO tenantsystems (tenant_id, system_sst_id, is_active) VALUES 
(1, 1, TRUE), -- Transportes: SST
(1, 2, TRUE), -- Transportes: PESV
(2, 1, TRUE), -- Constructora: SST
(3, 1, TRUE), -- Salud Integral: SST
(4, 1, TRUE), -- Logística Caribe: SST
(4, 2, TRUE), -- Logística Caribe: PESV
(5, 1, TRUE), -- Manufacturas: SST
(6, 1, TRUE), -- Agropecuaria: SST
(6, 2, TRUE); -- Agropecuaria: PESV

-- 11. MÓDULOS DEL SISTEMA
INSERT INTO modules (system_sst_id, title, description, presentation_order, is_active) VALUES 
-- Módulos SST (IDs: 1 a 5)
(1, 'Liderazgo, Política y Objetivos SST', 'Compromiso gerencial y asignación de recursos normativos.', 1, TRUE),
(1, 'Identificación de Peligros y Matriz GTC 45', 'Metodología para valoración y control preventivo de riesgos.', 2, TRUE),
(1, 'Plan de Capacitación y Competencias', 'Formación de brigadas y entrenamiento del personal.', 3, TRUE),
(1, 'Investigación de Accidentes e Incidentes', 'Metodología árbol de causas y reporte ARL.', 4, TRUE),
(1, 'Auditoría Interna y Revisión por la Dirección', 'Evaluación anual y ciclo de mejoramiento.', 5, TRUE),

-- Módulos PESV (IDs: 6 a 9)
(2, 'Planificación y Diagnóstico Vial', 'Caracterización de flota, conductores y factores de riesgo.', 1, TRUE),
(2, 'Comportamiento Humano y Selección de Conductores', 'Pruebas teórico-prácticas y control de hábitos viales.', 2, TRUE),
(2, 'Inspección Preoperacional y Mantenimiento Seguro', 'Protocolos técnicos de vehículos y rutas seguras.', 3, TRUE),
(2, 'Atención y Respuesta ante Siniestros Viales', 'Protocolos PAS ante accidentes en corredores viales.', 4, TRUE);

-- 12. ASIGNACIÓN DE MÓDULOS A TENANTS
INSERT INTO tenant_modules (tenant_id, module_id, is_active) VALUES 
(1, 1, TRUE), (1, 2, TRUE), (1, 3, TRUE), (1, 6, TRUE), (1, 7, TRUE), (1, 8, TRUE),
(2, 1, TRUE), (2, 2, TRUE), (2, 3, TRUE), (2, 4, TRUE),
(3, 1, TRUE), (3, 2, TRUE), (3, 3, TRUE), (3, 5, TRUE),
(4, 1, TRUE), (4, 6, TRUE), (4, 7, TRUE),
(5, 1, TRUE), (5, 2, TRUE),
(6, 1, TRUE), (6, 2, TRUE), (6, 6, TRUE), (6, 8, TRUE);

-- 13. FORMATOS ASOCIADOS A MÓDULOS
INSERT INTO formats_sst (module_id, code, name, description, version) VALUES 
(1, 'FMT-POL-01', 'Declaración de Política SST', 'Formato base para firma de gerencia.', 2),
(2, 'FMT-MAT-01', 'Matriz de Riesgos GTC 45', 'Planilla técnica de identificación de peligros.', 3),
(3, 'FMT-CAP-01', 'Registro de Asistencia y Evaluación', 'Control de horas de capacitación laboral.', 1),
(4, 'FMT-INC-01', 'Reporte Preliminar Furat / Furep', 'Investigación técnica de siniestros laborales.', 2),
(6, 'FMT-PESV-DIAG', 'Diagnóstico Integral de Movilidad', 'Encuesta de hábitos y exposición a rutas.', 1),
(7, 'FMT-PESV-COND', 'Ficha del Conductor y Exámenes', 'Registro de historial de comparendos y psicotécnicos.', 2),
(8, 'FMT-PESV-PREOP', 'Lista de Chequeo Preoperacional Diario', 'Revisión tecno-mecánica antes de despacho.', 4);

-- 14. PLANTILLAS Y DOCUMENTOS GENERADOS
INSERT INTO tenanttemplates (tenant_id, system_sst_id, phva_stage_id, format_id, name, status, document_content, version) VALUES 
-- Tenant 1: Transportes del Oriente (Cumplimiento alto: 4 de 5 finalizadas = 80%)
(1, 1, 1, 1, 'Política SST Transportes Oriente 2026', 'finalizado', 'Política aprobada y firmada por Gerencia General.', 2),
(1, 1, 1, 2, 'Matriz GTC 45 Terminal y Rutas Nacionales', 'finalizado', 'Matriz completa con valoración de riesgo biomecánico y vial.', 1),
(1, 1, 2, 3, 'Programa Capacitación Manejo Defensivo 2026', 'finalizado', 'Cronograma y registro de 40 conductores capacitados.', 1),
(1, 2, 1, 5, 'Diagnóstico PESV Nivel Avanzado', 'finalizado', 'Diagnóstico vehicular de 25 cabezotes de tractomula.', 2),
(1, 2, 2, 7, 'Planilla de Inspecciones Preoperacionales Septiembre', 'pendiente', 'Pendiente revisión técnica de llantas de remolques.', 1),

-- Tenant 2: Constructora Andina (2 de 3 finalizadas = 66.67%)
(2, 1, 1, 1, 'Política SST Constructora Andina', 'finalizado', 'Política SST para obras de infraestructura.', 1),
(2, 1, 1, 2, 'Matriz de Peligros Obras Torre Floridablanca', 'finalizado', 'Evaluación de trabajos en alturas y excavaciones profundas.', 2),
(2, 1, 3, 4, 'Informe de Auditoría Interna Semestral 2026', 'pendiente', 'Auditoría en proceso por auditor líder externo.', 1),

-- Tenant 3: Salud & Vida IPS (2 de 2 finalizadas = 100%)
(3, 1, 1, 1, 'Política de Seguridad del Paciente y Trabajador', 'finalizado', 'Enfoque biológico y ergonomía hospitalaria.', 1),
(3, 1, 2, 3, 'Plan de Inducción para Personal de Urgencias', 'finalizado', 'Capacitación en uso de EPP grado médico.', 1),

-- Tenant 4: Logística Express del Caribe (2 de 5 finalizadas = 40%)
(4, 1, 1, 1, 'Política SST Logística Express', 'finalizado', 'Política general aprobada.', 1),
(4, 2, 1, 5, 'Encuesta de Movilidad y Rutas Barranquilla', 'finalizado', 'Consolidado de 18 conductores de furgón.', 1),
(4, 1, 2, 3, 'Programa de Pausas Activas Almacén', 'pendiente', 'Pendiente aprobación de jefatura de bodega.', 1),
(4, 2, 2, 7, 'Bitácora de Preoperacionales Flota Liviana', 'borrador', 'En redacción por inspector vial.', 1),
(4, 2, 3, NULL, 'Matriz de Indicadores de Siniestralidad Trimestre 3', 'no_iniciado', 'Pendiente inicio de consolidación trimestral.', 1),

-- Tenant 5: Manufacturas del Calzado (1 de 2 finalizadas = 50%)
(5, 1, 1, 1, 'Compromiso SST Fábrica de Calzado', 'finalizado', 'Firmado por representante legal.', 1),
(5, 1, 1, 2, 'Matriz de Riesgo Químico y Pegantes', 'borrador', 'En revisión de hojas de seguridad MSDS.', 1),

-- Tenant 6: Agropecuaria del Valle (3 de 4 finalizadas = 75%)
(6, 1, 1, 1, 'Política de Seguridad Agrícola', 'finalizado', 'Aprobada para fincas del grupo.', 1),
(6, 1, 2, 3, 'Capacitación en Aplicación de Plaguicidas', 'finalizado', 'Certificado con apoyo del SENA.', 1),
(6, 2, 2, 7, 'Inspección de Tractores y Remolques', 'finalizado', 'Revisión quincenal al día.', 2),
(6, 2, 4, NULL, 'Plan de Mejoramiento PESV Cosecha 2026', 'pendiente', 'Pendiente asignación presupuestal.', 1);

-- 15. BLOQUEOS DE EDICIÓN CONCURRENTE (EDITING LOCKS)
INSERT INTO editing_locks (tenant_id, template_id, person_id, locked_at, expires_at, is_active) VALUES 
(1, 5, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP + INTERVAL '30 minutes', TRUE),
(2, 8, 5, CURRENT_TIMESTAMP - INTERVAL '2 hours', CURRENT_TIMESTAMP - INTERVAL '1 hour', FALSE);

-- 16. REGISTROS DE AUDITORÍA INICIALES
INSERT INTO tenants_audit (tenant_id, action, old_data, new_data, changed_by) VALUES 
(1, 'CREATION', NULL, '{"name": "Transportes & Carga del Oriente S.A.S.", "nit": "901.458.120-3"}'::jsonb, 'admin_init');
