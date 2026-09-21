-- ============================================================================
-- PROYECTO ACADÉMICO: GESTIÓN MULTI-TENANT SST & PESV
-- AUTOR: Julian Andrey Ricaurte (juliand06)
-- BASE DE DATOS: PostgreSQL 16
-- ARCHIVO: 01_ddl.sql - Definición del Esquema Físico (DDL)
-- ============================================================================

-- Configuración de zona horaria y codificación
SET client_encoding = 'UTF8';
SET timezone = 'America/Bogota';

-- Limpieza preventiva en orden inverso de dependencias
DROP TABLE IF EXISTS editing_locks CASCADE;
DROP TABLE IF EXISTS tenant_templates_audit CASCADE;
DROP TABLE IF EXISTS tenants_audit CASCADE;
DROP TABLE IF EXISTS tenanttemplates CASCADE;
DROP TABLE IF EXISTS formats_sst CASCADE;
DROP TABLE IF EXISTS phva_stages CASCADE;
DROP TABLE IF EXISTS tenant_modules CASCADE;
DROP TABLE IF EXISTS modules CASCADE;
DROP TABLE IF EXISTS tenantsystems CASCADE;
DROP TABLE IF EXISTS type_system_sst CASCADE;
DROP TABLE IF EXISTS persons CASCADE;
DROP TABLE IF EXISTS positions CASCADE;
DROP TABLE IF EXISTS tenants CASCADE;
DROP TABLE IF EXISTS tenant_sizes CASCADE;
DROP TABLE IF EXISTS municipalities CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP TABLE IF EXISTS countries CASCADE;

-- ============================================================================
-- 1. ESTRUCTURAS GEOGRÁFICAS Y LOCALIZACIÓN
-- ============================================================================

CREATE TABLE countries (
    id SERIAL PRIMARY KEY,
    code VARCHAR(10) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE departments (
    id SERIAL PRIMARY KEY,
    country_id INT NOT NULL REFERENCES countries(id) ON DELETE RESTRICT,
    code VARCHAR(10) NOT NULL,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_dep_country_code UNIQUE (country_id, code)
);

CREATE TABLE municipalities (
    id SERIAL PRIMARY KEY,
    department_id INT NOT NULL REFERENCES departments(id) ON DELETE RESTRICT,
    code VARCHAR(10) NOT NULL,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_mun_dep_code UNIQUE (department_id, code)
);

-- ============================================================================
-- 2. GESTIÓN MULTI-TENANT (ORGANIZACIONES)
-- ============================================================================

CREATE TABLE tenant_sizes (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    min_employees INT NOT NULL CHECK (min_employees >= 0),
    max_employees INT CHECK (max_employees IS NULL OR max_employees >= min_employees),
    description TEXT
);

CREATE TABLE tenants (
    id SERIAL PRIMARY KEY,
    nit VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    email VARCHAR(120) NOT NULL,
    phone VARCHAR(30),
    address VARCHAR(200),
    municipality_id INT NOT NULL REFERENCES municipalities(id) ON DELETE RESTRICT,
    tenant_size_id INT NOT NULL REFERENCES tenant_sizes(id) ON DELETE RESTRICT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    compliance_percentage NUMERIC(5, 2) NOT NULL DEFAULT 0.00 CHECK (compliance_percentage BETWEEN 0.00 AND 100.00),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 3. ESTRUCTURA ORGANIZACIONAL (CARGOS Y PERSONAS)
-- ============================================================================

CREATE TABLE positions (
    id SERIAL PRIMARY KEY,
    tenant_id INT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_tenant_position_name UNIQUE (tenant_id, name)
);

CREATE TABLE persons (
    id SERIAL PRIMARY KEY,
    identification_number VARCHAR(25) NOT NULL UNIQUE,
    first_name VARCHAR(60) NOT NULL,
    last_name VARCHAR(60) NOT NULL,
    email VARCHAR(120) NOT NULL,
    phone VARCHAR(30),
    tenant_id INT NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
    position_id INT NOT NULL REFERENCES positions(id) ON DELETE RESTRICT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 4. SISTEMAS NORMATIVOS SST & PESV Y MÓDULOS
-- ============================================================================

CREATE TABLE type_system_sst (
    id SERIAL PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(120) NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE tenantsystems (
    id SERIAL PRIMARY KEY,
    tenant_id INT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    system_sst_id INT NOT NULL REFERENCES type_system_sst(id) ON DELETE RESTRICT,
    enabled_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_tenant_system UNIQUE (tenant_id, system_sst_id)
);

CREATE TABLE modules (
    id SERIAL PRIMARY KEY,
    system_sst_id INT NOT NULL REFERENCES type_system_sst(id) ON DELETE CASCADE,
    title VARCHAR(120) NOT NULL,
    description TEXT,
    presentation_order INT NOT NULL DEFAULT 1 CHECK (presentation_order > 0),
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE tenant_modules (
    id SERIAL PRIMARY KEY,
    tenant_id INT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    module_id INT NOT NULL REFERENCES modules(id) ON DELETE CASCADE,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_tenant_module UNIQUE (tenant_id, module_id)
);

-- ============================================================================
-- 5. CICLO PHVA, FORMATOS Y PLANTILLAS DOCUMENTALES
-- ============================================================================

CREATE TABLE phva_stages (
    id SERIAL PRIMARY KEY,
    code VARCHAR(10) NOT NULL UNIQUE,
    name VARCHAR(50) NOT NULL,
    sequence_order INT NOT NULL UNIQUE CHECK (sequence_order BETWEEN 1 AND 4),
    description TEXT
);

CREATE TABLE formats_sst (
    id SERIAL PRIMARY KEY,
    module_id INT NOT NULL REFERENCES modules(id) ON DELETE CASCADE,
    code VARCHAR(30) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    version INT NOT NULL DEFAULT 1 CHECK (version >= 1),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE tenanttemplates (
    id SERIAL PRIMARY KEY,
    tenant_id INT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    system_sst_id INT NOT NULL REFERENCES type_system_sst(id) ON DELETE RESTRICT,
    phva_stage_id INT NOT NULL REFERENCES phva_stages(id) ON DELETE RESTRICT,
    format_id INT REFERENCES formats_sst(id) ON DELETE SET NULL,
    name VARCHAR(180) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'no_iniciado' 
        CHECK (status IN ('no_iniciado', 'borrador', 'pendiente', 'finalizado')),
    document_content TEXT,
    version INT NOT NULL DEFAULT 1 CHECK (version >= 1),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 6. CONTROL DE CONCURRENCIA (BLOQUEOS DE EDICIÓN)
-- ============================================================================

CREATE TABLE editing_locks (
    id SERIAL PRIMARY KEY,
    tenant_id INT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    template_id INT NOT NULL REFERENCES tenanttemplates(id) ON DELETE CASCADE,
    person_id INT NOT NULL REFERENCES persons(id) ON DELETE CASCADE,
    locked_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT chk_lock_expiration CHECK (expires_at > locked_at)
);

-- ============================================================================
-- 7. PISTAS DE AUDITORÍA (AUDIT LOGS)
-- ============================================================================

CREATE TABLE tenants_audit (
    id SERIAL PRIMARY KEY,
    tenant_id INT NOT NULL,
    action VARCHAR(20) NOT NULL,
    old_data JSONB,
    new_data JSONB,
    changed_by VARCHAR(80) DEFAULT CURRENT_USER,
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE tenant_templates_audit (
    id SERIAL PRIMARY KEY,
    template_id INT NOT NULL,
    action VARCHAR(20) NOT NULL,
    old_status VARCHAR(30),
    new_status VARCHAR(30),
    modified_by VARCHAR(80) DEFAULT CURRENT_USER,
    modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 8. ÍNDICES DE RENDIMIENTO E INTEGRIDAD MULTI-TENANT
-- ============================================================================

CREATE INDEX idx_tenants_muni ON tenants(municipality_id);
CREATE INDEX idx_tenants_active ON tenants(is_active);
CREATE INDEX idx_positions_tenant ON positions(tenant_id);
CREATE INDEX idx_persons_tenant ON persons(tenant_id);
CREATE INDEX idx_persons_position ON persons(position_id);
CREATE INDEX idx_persons_active ON persons(is_active);
CREATE INDEX idx_tenant_modules_tenant ON tenant_modules(tenant_id);
CREATE INDEX idx_tenant_systems_tenant ON tenantsystems(tenant_id);
CREATE INDEX idx_templates_tenant ON tenanttemplates(tenant_id);
CREATE INDEX idx_templates_status ON tenanttemplates(status);
CREATE INDEX idx_templates_phva ON tenanttemplates(phva_stage_id);
CREATE INDEX idx_templates_system ON tenanttemplates(system_sst_id);
CREATE INDEX idx_locks_active_expires ON editing_locks(is_active, expires_at);
CREATE INDEX idx_tenants_audit_tenant ON tenants_audit(tenant_id);
CREATE INDEX idx_templates_audit_tpl ON tenant_templates_audit(template_id);
