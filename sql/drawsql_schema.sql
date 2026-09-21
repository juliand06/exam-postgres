-- ============================================================================
-- DRAWSQL SCHEMA — Gestión Multi-Tenant SST & PESV
-- Autor      : Julian Andrey Ricaurte (@juliand06)
-- Motor      : PostgreSQL 16
-- Normaliz.  : Cuarta Forma Normal (4NF)
-- Tablas     : 17  |  Relaciones FK : 20
-- ============================================================================
-- INSTRUCCIONES:
--   1. Abre https://drawsql.app  → New Diagram → Import SQL
--   2. Pega TODO este archivo y haz clic en "Run"
--   3. Todas las tablas y flechas de relacion aparecen automaticamente
-- ============================================================================


-- ─────────────────────────────────────────────────────────────────────────────
-- BLOQUE 1 · GEOGRAFIA  (countries → departments → municipalities)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE countries (
    id         INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    code       VARCHAR(10)  NOT NULL UNIQUE,
    name       VARCHAR(100) NOT NULL,
    created_at TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE departments (
    id         INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    country_id INT          NOT NULL,
    code       VARCHAR(10)  NOT NULL,
    name       VARCHAR(100) NOT NULL,
    created_at TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_dep_country FOREIGN KEY (country_id) REFERENCES countries(id)
);

CREATE TABLE municipalities (
    id            INT         NOT NULL AUTO_INCREMENT PRIMARY KEY,
    department_id INT         NOT NULL,
    code          VARCHAR(10) NOT NULL,
    name          VARCHAR(100) NOT NULL,
    created_at    TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_mun_department FOREIGN KEY (department_id) REFERENCES departments(id)
);


-- ─────────────────────────────────────────────────────────────────────────────
-- BLOQUE 2 · TAMANO DE EMPRESA
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE tenant_sizes (
    id            INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name          VARCHAR(50)  NOT NULL UNIQUE,
    min_employees INT          NOT NULL,
    max_employees INT,
    description   TEXT
);


-- ─────────────────────────────────────────────────────────────────────────────
-- BLOQUE 3 · ORGANIZACIONES / TENANTS
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE tenants (
    id                    INT             NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nit                   VARCHAR(20)     NOT NULL UNIQUE,
    name                  VARCHAR(150)    NOT NULL,
    email                 VARCHAR(120)    NOT NULL,
    phone                 VARCHAR(30),
    address               VARCHAR(200),
    municipality_id       INT             NOT NULL,
    tenant_size_id        INT             NOT NULL,
    is_active             TINYINT(1)      NOT NULL DEFAULT 1,
    compliance_percentage DECIMAL(5,2)    NOT NULL DEFAULT 0.00,
    created_at            TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    updated_at            TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_tenant_municipality FOREIGN KEY (municipality_id) REFERENCES municipalities(id),
    CONSTRAINT fk_tenant_size         FOREIGN KEY (tenant_size_id)  REFERENCES tenant_sizes(id)
);


-- ─────────────────────────────────────────────────────────────────────────────
-- BLOQUE 4 · ESTRUCTURA ORGANIZACIONAL (positions → persons)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE positions (
    id          INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    tenant_id   INT          NOT NULL,
    name        VARCHAR(100) NOT NULL,
    description TEXT,
    is_active   TINYINT(1)   NOT NULL DEFAULT 1,
    created_at  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pos_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id)
);

CREATE TABLE persons (
    id                    INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    identification_number VARCHAR(25)  NOT NULL UNIQUE,
    first_name            VARCHAR(60)  NOT NULL,
    last_name             VARCHAR(60)  NOT NULL,
    email                 VARCHAR(120) NOT NULL,
    phone                 VARCHAR(30),
    tenant_id             INT          NOT NULL,
    position_id           INT          NOT NULL,
    is_active             TINYINT(1)   NOT NULL DEFAULT 1,
    created_at            TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    updated_at            TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_person_tenant   FOREIGN KEY (tenant_id)   REFERENCES tenants(id),
    CONSTRAINT fk_person_position FOREIGN KEY (position_id) REFERENCES positions(id)
);


-- ─────────────────────────────────────────────────────────────────────────────
-- BLOQUE 5 · SISTEMAS NORMATIVOS SST & PESV
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE type_system_sst (
    id          INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    code        VARCHAR(20)  NOT NULL UNIQUE,
    name        VARCHAR(120) NOT NULL,
    description TEXT,
    is_active   TINYINT(1)   NOT NULL DEFAULT 1
);

CREATE TABLE tenantsystems (
    id            INT       NOT NULL AUTO_INCREMENT PRIMARY KEY,
    tenant_id     INT       NOT NULL,
    system_sst_id INT       NOT NULL,
    enabled_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active     TINYINT(1) NOT NULL DEFAULT 1,
    CONSTRAINT fk_ts_tenant FOREIGN KEY (tenant_id)     REFERENCES tenants(id),
    CONSTRAINT fk_ts_system FOREIGN KEY (system_sst_id) REFERENCES type_system_sst(id)
);


-- ─────────────────────────────────────────────────────────────────────────────
-- BLOQUE 6 · MODULOS (type_system_sst → modules → tenant_modules)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE modules (
    id                 INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    system_sst_id      INT          NOT NULL,
    title              VARCHAR(120) NOT NULL,
    description        TEXT,
    presentation_order INT          NOT NULL DEFAULT 1,
    is_active          TINYINT(1)   NOT NULL DEFAULT 1,
    CONSTRAINT fk_mod_system FOREIGN KEY (system_sst_id) REFERENCES type_system_sst(id)
);

CREATE TABLE tenant_modules (
    id          INT       NOT NULL AUTO_INCREMENT PRIMARY KEY,
    tenant_id   INT       NOT NULL,
    module_id   INT       NOT NULL,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active   TINYINT(1) NOT NULL DEFAULT 1,
    CONSTRAINT fk_tm_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id),
    CONSTRAINT fk_tm_module FOREIGN KEY (module_id) REFERENCES modules(id)
);


-- ─────────────────────────────────────────────────────────────────────────────
-- BLOQUE 7 · CICLO PHVA
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE phva_stages (
    id             INT         NOT NULL AUTO_INCREMENT PRIMARY KEY,
    code           VARCHAR(10) NOT NULL UNIQUE,
    name           VARCHAR(50) NOT NULL,
    sequence_order INT         NOT NULL UNIQUE,
    description    TEXT
);


-- ─────────────────────────────────────────────────────────────────────────────
-- BLOQUE 8 · FORMATOS DOCUMENTALES SST (modules → formats_sst)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE formats_sst (
    id          INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    module_id   INT          NOT NULL,
    code        VARCHAR(30)  NOT NULL UNIQUE,
    name        VARCHAR(150) NOT NULL,
    description TEXT,
    version     INT          NOT NULL DEFAULT 1,
    is_active   TINYINT(1)   NOT NULL DEFAULT 1,
    created_at  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_fmt_module FOREIGN KEY (module_id) REFERENCES modules(id)
);


-- ─────────────────────────────────────────────────────────────────────────────
-- BLOQUE 9 · PLANTILLAS POR TENANT (tabla central — 4 FK de entrada)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE tenanttemplates (
    id               INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    tenant_id        INT          NOT NULL,
    system_sst_id    INT          NOT NULL,
    phva_stage_id    INT          NOT NULL,
    format_id        INT,
    name             VARCHAR(180) NOT NULL,
    status           VARCHAR(30)  NOT NULL DEFAULT 'no_iniciado',
    document_content TEXT,
    version          INT          NOT NULL DEFAULT 1,
    created_at       TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_tt_tenant  FOREIGN KEY (tenant_id)     REFERENCES tenants(id),
    CONSTRAINT fk_tt_system  FOREIGN KEY (system_sst_id) REFERENCES type_system_sst(id),
    CONSTRAINT fk_tt_phva    FOREIGN KEY (phva_stage_id) REFERENCES phva_stages(id),
    CONSTRAINT fk_tt_format  FOREIGN KEY (format_id)     REFERENCES formats_sst(id)
);


-- ─────────────────────────────────────────────────────────────────────────────
-- BLOQUE 10 · CONTROL DE CONCURRENCIA (editing_locks)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE editing_locks (
    id          INT       NOT NULL AUTO_INCREMENT PRIMARY KEY,
    tenant_id   INT       NOT NULL,
    template_id INT       NOT NULL,
    person_id   INT       NOT NULL,
    locked_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at  TIMESTAMP NOT NULL,
    is_active   TINYINT(1) NOT NULL DEFAULT 1,
    CONSTRAINT fk_lock_tenant   FOREIGN KEY (tenant_id)   REFERENCES tenants(id),
    CONSTRAINT fk_lock_template FOREIGN KEY (template_id) REFERENCES tenanttemplates(id),
    CONSTRAINT fk_lock_person   FOREIGN KEY (person_id)   REFERENCES persons(id)
);


-- ─────────────────────────────────────────────────────────────────────────────
-- BLOQUE 11 · AUDITORIA (con FK para que DrawSQL dibuje las flechas)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE tenants_audit (
    id         INT         NOT NULL AUTO_INCREMENT PRIMARY KEY,
    tenant_id  INT         NOT NULL,
    action     VARCHAR(20) NOT NULL,
    old_data   TEXT,
    new_data   TEXT,
    changed_by VARCHAR(80) DEFAULT 'system',
    changed_at TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_audit_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id)
);

CREATE TABLE tenant_templates_audit (
    id          INT         NOT NULL AUTO_INCREMENT PRIMARY KEY,
    template_id INT         NOT NULL,
    action      VARCHAR(20) NOT NULL,
    old_status  VARCHAR(30),
    new_status  VARCHAR(30),
    modified_by VARCHAR(80) DEFAULT 'system',
    modified_at TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_audit_template FOREIGN KEY (template_id) REFERENCES tenanttemplates(id)
);
