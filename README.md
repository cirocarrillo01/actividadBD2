# Proyectos Informáticos – MySQL (CRUD + UDF + Triggers)

Repositorio listo para ejecutar en **Visual Studio Code** (o cualquier editor) y validar en **MySQL 8.0+**.

**Institución:** IUDigital de Antioquia  
**Curso:** Base de Datos  
**Docente:** Julian Loaiza

---

## 🎯 Objetivo
Implementar en **MySQL**:
- CRUD por procedimientos almacenados para 2 tablas (`docente` y `proyecto`).
- 1 **UDF** con operación matemática (promedio de presupuesto).
- **Triggers** de auditoría para ACTUALIZADOS y ELIMINADOS.

---
ASD
## 📂 Estructura
```
proyectos_informaticos_mysql/
├─ README.md
├─ landing/
│  └─ index.html
├─ sql/
│  ├─ 00_create_database.sql
│  ├─ 01_schema.sql
│  ├─ 02_seed.sql
│  ├─ 03_queries.sql
│  └─ extras/
│     ├─ inserts_directos.sql
│     └─ ejemplos_adicionales.sql
└─ docs/
   └─ diagrama_logico.md
```

---

## 🚀 Ejecución rápida (MySQL Workbench o CLI)
En la consola de MySQL, estando en la carpeta del proyecto:
```sql
SOURCE sql/00_create_database.sql;
SOURCE sql/01_schema.sql;
SOURCE sql/02_seed.sql;
SOURCE sql/03_queries.sql;
```

> Requiere **MySQL 8.0.16+** para que los `CHECK` se apliquen.

---

## 🧩 Solución implementada
- **Tablas:** `docente`, `proyecto` (1:N).
- **Procedimientos:** `sp_docente_*`, `sp_proyecto_*`.
- **UDF:** `fn_promedio_presupuesto_por_docente` (AVG).
- **Triggers:** `tr_docente_after_update`, `tr_docente_after_delete`.
- **Consultas:** `03_queries.sql` incluye **Q0–Q9** (creación BD, inserciones vía SP y directas, auditoría y validaciones).

---

## 🌐 Landing
Abrir `landing/index.html` con Live Server (VS Code) o cualquier servidor estático:
```
cd landing
# ejemplo con Python
python -m http.server 8080
# abre http://localhost:8080
```

---

## 📜 Licencia
Uso académico.

# Actividad 2 Base de Datos

📂 - Archivos SQL utilizados en la actividad:

- schema.sql   → estructura (tablas, constraints, procedimientos)
- seed.sql     → datos iniciales o pruebas
- queries.sql  → pruebas temporales, selects, debug

## Proyecto Base de Datos – Gestión de Docentes y Proyectos

### 📄Contenido

- Tablas con restricciones de integridad
- Procedimientos almacenados (CRUD)
- Función escalar (UDF)
- Triggers de auditoría
- Pruebas de integridad y errores controlados
- Índices para optimización

### 📄Queries presentes

1. Query 1 Proyectos y su docente jefe
2. Query 2 Promedio de presupuesto por docente (UDF)
3. Query 3 Verificar trigger UPDATE (auditoría)
4. Query 4 Verificar trigger DELETE (auditoría)
5. Query 5 Validar CHECKs
6. Query 6 Docentes con sus proyectos
7. Query 7 Total de horas por docente
8. Query 8 Inserciones vía procedimientos
9. Query 9 Inserciones directas (opcional)
10. Query 10 Cantidad de proyectos manejados por un docente y su presupuesto
11. Query 11 identificar proyectos activos

### 📄Autor
- Nombre: ciro antonio carrillo mendoza
- Curso: Base de Datos
- Semestre: 3
- Año: 2025

