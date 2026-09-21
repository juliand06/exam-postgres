-- ============================================================================
-- SCRIPT MAESTRO DE INICIALIZACIÓN COMPLETA
-- ============================================================================

-- 1. DDL: Tablas, restricciones e índices
\i /docker-entrypoint-initdb.d/scripts/fase1_ddl.sql

-- 2. PL/pgSQL: Procedimientos y Funciones Almacenadas
\i /docker-entrypoint-initdb.d/scripts/fase3_sp_fn.sql

-- 3. PL/pgSQL: Triggers de Integridad, Automatización y Auditoría
\i /docker-entrypoint-initdb.d/scripts/fase4_triggers.sql

-- 4. Datos de Prueba (Seed Data)
\i /docker-entrypoint-initdb.d/scripts/seed_data.sql

-- 5. Consultas, Vistas y Vistas Materializadas
\i /docker-entrypoint-initdb.d/scripts/fase2_consultas.sql