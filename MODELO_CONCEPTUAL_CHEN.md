# Modelo Conceptual - Notación de Chen 📐🛡️
### *Sistema Multi-Tenant de Gestión SST & PESV en PostgreSQL 16*
**Autor:** Julian Andrey Ricaurte ([@juliand06](https://github.com/juliand06))

---

## 📌 1. Simbología Formal de Chen Utilizada

| Elemento | Símbolo en Notación Chen | Representación en el Diagrama | Descripción |
| :--- | :---: | :---: | :--- |
| **Entidad Fuerte** | Rectángulo | `[ Entidad ]` | Objeto del mundo real con existencia independiente y clave primaria propia. |
| **Relación** | Rombo | `{ Relación }` | Asociación lógica entre dos o más entidades. |
| **Cardinalidad** | `(1) / (N) / (M)` | Etiquetas sobre los arcos | Determina cuántas instancias de una entidad pueden asociarse con otra. |
| **Clave Primaria (PK)** | Subrayado / `[PK]` | Resaltado en negrita y etiqueta | Atributo único e irrepetible que identifica la tupla. |
| **Clave Foránea (FK)** | Línea discontinua / `[FK]` | Resaltado con etiqueta `[FK]` | Atributo que garantiza la integridad referencial con la entidad padre. |

---

## 🏛️ 2. Diagrama Conceptual Completo (Notación Chen)

El siguiente diagrama utiliza la notación estándar de Peter Chen mediante bloques semánticos para evitar sobreposición de líneas:

```mermaid
flowchart TD
    %% ==========================================================
    %% ESTILOS VISUALES PROFESIONALES
    %% ==========================================================
    classDef entidad fill:#1E293B,stroke:#38BDF8,stroke-width:2px,color:#F8FAFC,font-weight:bold;
    classDef relacion fill:#0F172A,stroke:#F59E0B,stroke-width:2px,color:#FDE68A,font-weight:bold;
    classDef auditoria fill:#1E293B,stroke:#EC4899,stroke-width:2px,color:#FCE7F3,font-weight:bold;

    %% ==========================================================
    %% 1. MÓDULO GEOGRÁFICO
    %% ==========================================================
    subgraph GEO ["🌍 Localización Geográfica"]
        E_Country["PAÍSES (countries)<br/>• PK: id<br/>• code, name"]:::entidad
        R_Dep{"Compone"}:::relacion
        E_Dep["DEPARTAMENTOS (departments)<br/>• PK: id<br/>• FK: country_id<br/>• code, name"]:::entidad
        R_Mun{"Subdivide"}:::relacion
        E_Mun["MUNICIPIOS (municipalities)<br/>• PK: id<br/>• FK: department_id<br/>• code, name"]:::entidad
    end

    E_Country ---|1| R_Dep ---|N| E_Dep
    E_Dep ---|1| R_Mun ---|N| E_Mun

    %% ==========================================================
    %% 2. NÚCLEO ORGANIZACIONAL (MULTI-TENANT)
    %% ==========================================================
    subgraph ORG ["🏢 Estructura Organizacional Multi-Tenant"]
        E_Size["TAMAÑOS EMPRESA (tenant_sizes)<br/>• PK: id<br/>• name, min_emp, max_emp"]:::entidad
        R_Size{"Clasifica"}:::relacion
        E_Tenant["ORGANIZACIONES (tenants)<br/>• PK: id<br/>• nit, name, email<br/>• FK: municipality_id<br/>• FK: tenant_size_id"]:::entidad
        
        R_Pos{"Define"}:::relacion
        E_Pos["CARGOS (positions)<br/>• PK: id<br/>• FK: tenant_id<br/>• name, description"]:::entidad

        R_Emp{"Emplea"}:::relacion
        R_Asig{"Asigna"}:::relacion
        E_Person["TRABAJADORES (persons)<br/>• PK: id<br/>• identification_number<br/>• first_name, last_name<br/>• FK: tenant_id<br/>• FK: position_id"]:::entidad
    end

    R_Loc{"Radica"}:::relacion
    E_Mun ---|1| R_Loc ---|N| E_Tenant
    E_Size ---|1| R_Size ---|N| E_Tenant

    E_Tenant ---|1| R_Pos ---|N| E_Pos
    E_Tenant ---|1| R_Emp ---|N| E_Person
    E_Pos ---|1| R_Asig ---|N| E_Person

    %% ==========================================================
    %% 3. SISTEMAS NORMATIVOS SST & PESV Y MÓDULOS
    %% ==========================================================
    subgraph NORM ["🛡️ Marco Normativo y Módulos"]
        E_Sys["SISTEMAS NORMATIVOS (type_system_sst)<br/>• PK: id<br/>• code: 'SST' | 'PESV'<br/>• name, description"]:::entidad
        R_Mod{"Estructura"}:::relacion
        E_Mod["MÓDULOS (modules)<br/>• PK: id<br/>• FK: system_sst_id<br/>• title, order"]:::entidad
        R_Fmt{"Estandariza"}:::relacion
        E_Fmt["FORMATOS (formats_sst)<br/>• PK: id<br/>• FK: module_id<br/>• code, name, version"]:::entidad
    end

    E_Sys ---|1| R_Mod ---|N| E_Mod
    E_Mod ---|1| R_Fmt ---|N| E_Fmt

    %% RELACIONES MUCHOS A MUCHOS (N:M)
    R_HabSys{"Habilita"}:::relacion
    E_Tenant ---|N| R_HabSys ---|M| E_Sys

    R_AsigMod{"Configura"}:::relacion
    E_Tenant ---|N| R_AsigMod ---|M| E_Mod

    %% ==========================================================
    %% 4. CICLO PHVA, PLANTILLAS DOCUMENTALES Y CONCURRENCIA
    %% ==========================================================
    subgraph DOCS ["📋 Gestión Documental PHVA & Control"]
        E_PHVA["ETAPAS PHVA (phva_stages)<br/>• PK: id<br/>• code: PLAN, DO, CHECK, ACT<br/>• sequence_order: 1..4"]:::entidad
        
        E_Tpl["PLANTILLAS (tenanttemplates)<br/>• PK: id<br/>• FK: tenant_id<br/>• FK: system_sst_id<br/>• FK: phva_stage_id<br/>• FK: format_id<br/>• status, version"]:::entidad

        R_Lock{"Protege"}:::relacion
        R_LockUser{"Retiene"}:::relacion
        E_Lock["BLOQUEOS EDICIÓN (editing_locks)<br/>• PK: id<br/>• FK: tenant_id<br/>• FK: template_id<br/>• FK: person_id<br/>• expires_at, is_active"]:::entidad
    end

    R_Dil{"Diligencia"}:::relacion
    R_Enmar{"Enmarca"}:::relacion
    R_Orig{"Origina"}:::relacion
    R_Reg{"Regula"}:::relacion

    E_Tenant ---|1| R_Dil ---|N| E_Tpl
    E_PHVA ---|1| R_Enmar ---|N| E_Tpl
    E_Fmt ---|1| R_Orig ---|N| E_Tpl
    E_Sys ---|1| R_Reg ---|N| E_Tpl

    E_Tpl ---|1| R_Lock ---|N| E_Lock
    E_Person ---|1| R_LockUser ---|N| E_Lock

    %% ==========================================================
    %% 5. SISTEMAS DE AUDITORÍA
    %% ==========================================================
    subgraph AUDIT ["🔒 Trazabilidad y Auditoría"]
        E_AuditT["AUDITORÍA EMPRESAS (tenants_audit)<br/>• PK: id<br/>• FK: tenant_id<br/>• old_data, new_data [JSONB]<br/>• changed_by, changed_at"]:::auditoria
        E_AuditDoc["AUDITORÍA PLANTILLAS (tenant_templates_audit)<br/>• PK: id<br/>• FK: template_id<br/>• old_status, new_status<br/>• modified_by, modified_at"]:::auditoria
    end

    R_AudT{"Bitácora"}:::relacion
    R_AudD{"Histórico"}:::relacion

    E_Tenant ---|1| R_AudT ---|N| E_AuditT
    E_Tpl ---|1| R_AudD ---|N| E_AuditDoc
```

---

## 🔍 3. Matriz Semántica de Entidades, Relaciones y Cardinalidades

| Entidad Origen | Relación (Rombo) | Entidad Destino | Cardinalidad | Clave Foránea (`FK`) Involucrada | Regla de Negocio / Semántica |
| :--- | :---: | :--- | :---: | :--- | :--- |
| **`countries`** | `{Compone}` | `departments` | **$1:N$** | `departments.country_id` | Un país contiene múltiples departamentos o regiones territoriales. |
| **`departments`** | `{Subdivide}` | `municipalities` | **$1:N$** | `municipalities.department_id` | Un departamento se subdivide en varios municipios. |
| **`municipalities`** | `{Radica}` | `tenants` | **$1:N$** | `tenants.municipality_id` | Cada organización radica legalmente en un municipio. |
| **`tenant_sizes`** | `{Clasifica}` | `tenants` | **$1:N$** | `tenants.tenant_size_id` | Clasificación por volumen de empleados (Micro, Pequeña, Mediana, Gran). |
| **`tenants`** | `{Define}` | `positions` | **$1:N$** | `positions.tenant_id` | Aislamiento multi-tenant: los cargos pertenecen exclusivamente a su tenant. |
| **`tenants`** | `{Emplea}` | `persons` | **$1:N$** | `persons.tenant_id` | Cada trabajador está adscrito a una organización tenant. |
| **`positions`** | `{Asigna}` | `persons` | **$1:N$** | `persons.position_id` | Un trabajador tiene un cargo asignado (validado por trigger multi-tenant). |
| **`tenants`** | `{Habilita}` | `type_system_sst` | **$N:M$** | `tenantsystems` *(tabla puente)* | Una empresa puede habilitar SST, PESV o ambos sistemas simultáneamente. |
| **`type_system_sst`**| `{Estructura}` | `modules` | **$1:N$** | `modules.system_sst_id` | Cada sistema normativo organiza sus requisitos en módulos temáticos. |
| **`tenants`** | `{Configura}` | `modules` | **$N:M$** | `tenant_modules` *(tabla puente)* | Cada empresa suscribe los módulos específicos que requiere operar. |
| **`modules`** | `{Estandariza}`| `formats_sst` | **$1:N$** | `formats_sst.module_id` | Los formatos normalizados se agrupan por módulo funcional. |
| **`phva_stages`** | `{Enmarca}` | `tenanttemplates` | **$1:N$** | `tenanttemplates.phva_stage_id` | Cada documento pertenece a una etapa continua (Planear, Hacer, Verificar, Actuar). |
| **`formats_sst`** | `{Origina}` | `tenanttemplates` | **$1:N$** | `tenanttemplates.format_id` | Una plantilla documental se origina a partir de un formato institucional. |
| **`tenants`** | `{Diligencia}` | `tenanttemplates` | **$1:N$** | `tenanttemplates.tenant_id` | Las plantillas pertenecen de forma aislada a cada empresa. |
| **`tenanttemplates`**| `{Protege}` | `editing_locks` | **$1:N$** | `editing_locks.template_id` | Control de concurrencia: bloqueos temporales por documento. |
| **`persons`** | `{Retiene}` | `editing_locks` | **$1:N$** | `editing_locks.person_id` | Identifica qué trabajador posee el bloqueo activo de edición. |
| **`tenants`** | `{Bitácora}` | `tenants_audit` | **$1:N$** | `tenants_audit.tenant_id` | Histórico de cambios en datos y estado en formato JSONB. |
| **`tenanttemplates`**| `{Histórico}` | `tenant_templates_audit`| **$1:N$** | `tenant_templates_audit.template_id`| Trazabilidad de estados (borrador $\rightarrow$ pendiente $\rightarrow$ finalizado). |

---

## 🎯 4. Reglas de Integridad y Aislamiento Multi-Tenant

1. **Aislamiento de Cargos y Personal (Trigger `trg_validate_person_position_tenant`):**  
   Una persona solo puede ser vinculada a un cargo (`position_id`) cuya propiedad pertenezca al mismo `tenant_id`. No se permiten cruces entre organizaciones distintas.
2. **Ciclo PHVA Integral:**  
   Las plantillas documentales se vinculan obligatoriamente a una de las cuatro fases del ciclo (`sequence_order` 1 a 4), garantizando que las consultas de avance porcentual puedan agrupar y ponderar cada etapa del proceso de mejora continua.
3. **Control de Concurrencia Optimista/Pesimista:**  
   La entidad `editing_locks` contiene una restricción de chequeo (`expires_at > locked_at`) y un trigger de desactivación automática para asegurar que ningún recurso quede retenido de forma permanente.
