-- ============================================================================
-- DRAWSQL SCHEMA — Gestion Multi-Tenant SST & PESV
-- Autor      : Julian Andrey Ricaurte (@juliand06)
-- Motor      : PostgreSQL 16
-- Normalizacion: Cuarta Forma Normal (4NF)
-- Tablas     : 17  |  Relaciones FK : 20
-- ============================================================================
-- INSTRUCCIONES DrawSQL:
--   1. drawsql.app → New Diagram → Import SQL
--   2. Selecciona el motor: PostgreSQL
--   3. Pega TODO este archivo → Run
--   4. Las 17 tablas y 20 flechas de relacion aparecen automaticamente
-- ============================================================================


-- ─────────────────────────────────────────────────────────────────────────────
-- BLOQUE 1 · GEOGRAFIA
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE countries (
    id         SERIAL       PRIMARY KEY,
    code       VARCHAR(10)  NOT NULL UNIQUE,
    name       VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE departments (
    id         SERIAL       PRIMARY KEY,
    country_id INT          NOT NULL,
    code       VARCHAR(10)  NOT NULL,
    name       VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_dep_country    FOREIGN KEY (country_id)    REFERENCES countries(id),
    CONSTRAINT uq_dep_code       UNIQUE (country_id, code)
);

CREATE TABLE municipalities (
    id            SERIAL       PRIMARY KEY,
    department_id INT          NOT NULL,
    code          VARCHAR(10)  NOT NULL,
    name          VARCHAR(100) NOT NULL,
    created_at    TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_mun_department FOREIGN KEY (department_id) REFERENCES departments(id),
    CONSTRAINT uq_mun_dep_code   UNIQUE (department_id, code)
);


-- ─────────────────────────────────────────────────────────────────────────────
-- BLOQUE 2 · TAMANOS DE EMPRESA
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE tenant_sizes (
    id            SERIAL      PRIMARY KEY,
    name          VARCHAR(50) NOT NULL UNIQUE,
    min_employees INT         NOT NULL,
    max_employees INT,
    description   TEXT
);


-- ─────────────────────────────────────────────────────────────────────────────
-- BLOQUE 3 · ORGANIZACIONES / TENANTS
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE tenants (
    id                    SERIAL         PRIMARY KEY,
    nit                   VARCHAR(20)    NOT NULL UNIQUE,
    name                  VARCHAR(150)   NOT NULL,
    email                 VARCHAR(120)   NOT NULL,
    phone                 VARCHAR(30),
    address               VARCHAR(200),
    municipality_id       INT            NOT NULL,
    tenant_size_id        INT            NOT NULL,
    is_active             BOOLEAN        NOT NULL DEFAULT TRUE,
    compliance_percentage NUMERIC(5,2)   NOT NULL DEFAULT 0.00,
    created_at            TIMESTAMPTZ    DEFAULT CURRENT_TIMESTAMP,
    updated_at            TIMESTAMPTZ    DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_tenant_municipality FOREIGN KEY (municipality_id) REFERENCES municipalities(id),
    CONSTRAINT fk_tenant_size         FOREIGN KEY (tenant_size_id)  REFERENCES tenant_sizes(id)
);


-- ─────────────────────────────────────────────────────────────────────────────
-- BLOQUE 4 · ESTRUCTURA ORGANIZACIONAL (positions → persons)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE positions (
    id          SERIAL       PRIMARY KEY,
    tenant_id   INT          NOT NULL,
    name        VARCHAR(100) NOT NULL,
    description TEXT,
    is_active   BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pos_tenant           FOREIGN KEY (tenant_id) REFERENCES tenants(id),
    CONSTRAINT uq_tenant_position_name UNIQUE (tenant_id, name)
);

CREATE TABLE persons (
    id                    SERIAL       PRIMARY KEY,
    identification_number VARCHAR(25)  NOT NULL UNIQUE,
    first_name            VARCHAR(60)  NOT NULL,
    last_name             VARCHAR(60)  NOT NULL,
    email                 VARCHAR(120) NOT NULL,
    phone                 VARCHAR(30),
    tenant_id             INT          NOT NULL,
    position_id           INT          NOT NULL,
    is_active             BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at            TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
    updated_at            TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_person_tenant   FOREIGN KEY (tenant_id)   REFERENCES tenants(id),
    CONSTRAINT fk_person_position FOREIGN KEY (position_id) REFERENCES positions(id)
);


-- ─────────────────────────────────────────────────────────────────────────────
-- BLOQUE 5 · SISTEMAS NORMATIVOS SST & PESV
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE type_system_sst (
    id          SERIAL       PRIMARY KEY,
    code        VARCHAR(20)  NOT NULL UNIQUE,
    name        VARCHAR(120) NOT NULL,
    description TEXT,
    is_active   BOOLEAN      NOT NULL DEFAULT TRUE
);

CREATE TABLE tenantsystems (
    id            SERIAL      PRIMARY KEY,
    tenant_id     INT         NOT NULL,
    system_sst_id INT         NOT NULL,
    enabled_at    TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    is_active     BOOLEAN     NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_ts_tenant    FOREIGN KEY (tenant_id)     REFERENCES tenants(id),
    CONSTRAINT fk_ts_system    FOREIGN KEY (system_sst_id) REFERENCES type_system_sst(id),
    CONSTRAINT uq_tenant_system UNIQUE (tenant_id, system_sst_id)
);


-- ─────────────────────────────────────────────────────────────────────────────
-- BLOQUE 6 · MODULOS (type_system_sst → modules → tenant_modules)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE modules (
    id                 SERIAL       PRIMARY KEY,
    system_sst_id      INT          NOT NULL,
    title              VARCHAR(120) NOT NULL,
    description        TEXT,
    presentation_order INT          NOT NULL DEFAULT 1,
    is_active          BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_mod_system FOREIGN KEY (system_sst_id) REFERENCES type_system_sst(id)
);

CREATE TABLE tenant_modules (
    id          SERIAL      PRIMARY KEY,
    tenant_id   INT         NOT NULL,
    module_id   INT         NOT NULL,
    assigned_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    is_active   BOOLEAN     NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_tm_tenant     FOREIGN KEY (tenant_id) REFERENCES tenants(id),
    CONSTRAINT fk_tm_module     FOREIGN KEY (module_id) REFERENCES modules(id),
    CONSTRAINT uq_tenant_module UNIQUE (tenant_id, module_id)
);


-- ─────────────────────────────────────────────────────────────────────────────
-- BLOQUE 7 · CICLO PHVA
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE phva_stages (
    id             SERIAL      PRIMARY KEY,
    code           VARCHAR(10) NOT NULL UNIQUE,
    name           VARCHAR(50) NOT NULL,
    sequence_order INT         NOT NULL UNIQUE,
    description    TEXT
);


-- ─────────────────────────────────────────────────────────────────────────────
-- BLOQUE 8 · FORMATOS DOCUMENTALES SST (modules → formats_sst)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE formats_sst (
    id          SERIAL       PRIMARY KEY,
    module_id   INT          NOT NULL,
    code        VARCHAR(30)  NOT NULL UNIQUE,
    name        VARCHAR(150) NOT NULL,
    description TEXT,
    version     INT          NOT NULL DEFAULT 1,
    is_active   BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_fmt_module FOREIGN KEY (module_id) REFERENCES modules(id)
);


-- ─────────────────────────────────────────────────────────────────────────────
-- BLOQUE 9 · PLANTILLAS POR TENANT (tabla central — 4 FK de entrada)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE tenanttemplates (
    id               SERIAL       PRIMARY KEY,
    tenant_id        INT          NOT NULL,
    system_sst_id    INT          NOT NULL,
    phva_stage_id    INT          NOT NULL,
    format_id        INT,
    name             VARCHAR(180) NOT NULL,
    status           VARCHAR(30)  NOT NULL DEFAULT 'no_iniciado',
    document_content TEXT,
    version          INT          NOT NULL DEFAULT 1,
    created_at       TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_tt_tenant  FOREIGN KEY (tenant_id)     REFERENCES tenants(id),
    CONSTRAINT fk_tt_system  FOREIGN KEY (system_sst_id) REFERENCES type_system_sst(id),
    CONSTRAINT fk_tt_phva    FOREIGN KEY (phva_stage_id) REFERENCES phva_stages(id),
    CONSTRAINT fk_tt_format  FOREIGN KEY (format_id)     REFERENCES formats_sst(id)
);


-- ─────────────────────────────────────────────────────────────────────────────
-- BLOQUE 10 · CONTROL DE CONCURRENCIA (editing_locks)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE editing_locks (
    id          SERIAL      PRIMARY KEY,
    tenant_id   INT         NOT NULL,
    template_id INT         NOT NULL,
    person_id   INT         NOT NULL,
    locked_at   TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    expires_at  TIMESTAMPTZ NOT NULL,
    is_active   BOOLEAN     NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_lock_tenant   FOREIGN KEY (tenant_id)   REFERENCES tenants(id),
    CONSTRAINT fk_lock_template FOREIGN KEY (template_id) REFERENCES tenanttemplates(id),
    CONSTRAINT fk_lock_person   FOREIGN KEY (person_id)   REFERENCES persons(id)
);


-- ─────────────────────────────────────────────────────────────────────────────
-- BLOQUE 11 · AUDITORIA (FK explícitas para que DrawSQL dibuje las flechas)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE tenants_audit (
    id         SERIAL      PRIMARY KEY,
    tenant_id  INT         NOT NULL,
    action     VARCHAR(20) NOT NULL,
    old_data   TEXT,
    new_data   TEXT,
    changed_by VARCHAR(80) DEFAULT 'system',
    changed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_audit_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id)
);

CREATE TABLE tenant_templates_audit (
    id          SERIAL      PRIMARY KEY,
    template_id INT         NOT NULL,
    action      VARCHAR(20) NOT NULL,
    old_status  VARCHAR(30),
    new_status  VARCHAR(30),
    modified_by VARCHAR(80) DEFAULT 'system',
    modified_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_audit_template FOREIGN KEY (template_id) REFERENCES tenanttemplates(id)
);
