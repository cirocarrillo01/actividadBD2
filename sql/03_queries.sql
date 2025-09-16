
/* ============================
   queries.sql  (MySQL 8.0+)
   ============================ */

-- Q0: Crear y usar la base de datos
#CREATE DATABASE IF NOT EXISTS proyectos_informaticos;

-- Q1: Proyectos y su docente jefe

/* Usando los datos de la base de datos proyectos informaticos, se selecciona id de proyecto,
 * nombre de proyecto que se le coloca el alias proyecto y nombres de docente con el alias
 * docente_jefe de la tabla proyecto donde se conbina los datos de las dos tablas: 
 * se muestra el id del proyecto, el proyecto y docente jefe en la tabla al ejecutar.
 *  */

USE proyectos_informaticos;
SELECT p.proyecto_id, p.nombre AS proyecto, d.nombres AS docente_jefe
FROM proyecto p
JOIN docente d ON d.docente_id = p.docente_id_jefe;

-- Q2: Promedio de presupuesto por docente (UDF)

/*Usando los datos de la base de datos proyectos informaticos, se selecciona de la tabla docente
 * la id del docente y el nombre, donde fn_promedio_presupuesto_por_docente se pone el alias
 * promedio_presupuesto almacenado en el docente con su respectivo id
 * la tabla muestra: el docente id, nombre y el presupuesto
 * 
 * se hace un llamado a la funcion de promedio presupuesto alojada en schema, donde se lee
 * los datos de la tabla proyecto, tomando el los datos de presupuesto aplicando avg y almacenado
 * en v_from para su llamado al declarar la funcion, donde se vinculan los datos de las dos tablas por el id del docente
 * lo cual muestra sus datos en la tabla
 * */

USE proyectos_informaticos;
SELECT d.docente_id, d.nombres,
       fn_promedio_presupuesto_por_docente(d.docente_id) AS promedio_presupuesto
FROM docente d;


-- Q3: Verificar trigger UPDATE (auditoría)

/*Usando los datos de la base de datos proyectos informaticos, seleciona todos los datos
 * de copia_actualizados_docente donde se ordenan los resultado de la consulta por id auditoria
 * de forma decendente con un limite de 10
 * tabla muestra: todos los datos o atributos de la tabla copia_actualizados_docente y
 * los docentes almacenados
 * */

USE proyectos_informaticos;
SELECT * FROM copia_actualizados_docente
ORDER BY auditoria_id DESC
LIMIT 10;

-- Q4: Verificar trigger DELETE (auditoría)
/*Usando los datos de la base de datos proyectos informaticos, seleciona todos los datos
 * de copia_eliminados_docente donde se ordenan los resultado de la consulta por id auditoria
 * de forma decendente con un limite de 10
 * tabla muestra: todos los datos o atributos de la tabla copia_eliminados_docente y
 * los docentes eliminados
 * */

USE proyectos_informaticos;
SELECT * FROM copia_eliminados_docente
ORDER BY auditoria_id DESC
LIMIT 10;

-- Q5: Validar CHECKs
/* Usando los datos de la base de datos proyectos informaticos, de proyecto se evalua las
 * condiciones especificas(checks) si los datos almacenados en fecha de final e inicial 
 * sean coerentes como que la fecha inicial no este antes que la final o que el valor de 
 * la fecha final este en ausencia de valor equivale que el proyecto aun se esta ejecutando,
 * y que los valores no sean menores a 0 en presupuesto y horas 
 * la tabla muestra: id proyecto, nombre, fecha inifial, fecha final, presupuesto, horas
 * */
-- IS NULL = para compararlo si hay ausencia de valor

USE proyectos_informaticos;
SELECT proyecto_id, nombre, fecha_inicial, fecha_final, presupuesto, horas
FROM proyecto
WHERE (fecha_final IS NULL OR fecha_final >= fecha_inicial)
  AND presupuesto >= 0
  AND horas >= 0;

-- Q6: Docentes con sus proyectos
/*Usando los datos de la base de datos proyectos informaticos de la tabla docente, 
 * donde se maneja los datos de id docente y su nombre, y los datos de id proyecto y su nombre
 * se aplica left join entre la tabla docente y proyecto por las id que tiene clave foranea
 * se usa left join para evaluar las filas de la izquierda coincidencia con las de la derecha,
 * agregue otro elemento de proyecto como descripcion para comparar
 * */

USE proyectos_informaticos;
SELECT d.docente_id, d.nombres, p.proyecto_id, p.nombre, p.descripcion
FROM docente d
LEFT JOIN proyecto p ON d.docente_id = p.docente_id_jefe
ORDER BY d.docente_id;

-- LIMITADO A 10 DATOS --

USE proyectos_informaticos;
SELECT d.docente_id, d.nombres, p.proyecto_id, p.nombre, p.descripcion
FROM docente d
LEFT JOIN proyecto p ON d.docente_id = p.docente_id_jefe
ORDER BY d.docente_id LIMIT 10;

-- Q7: Total de horas por docente
/*Usando los datos de la base de datos proyectos informaticos de la tabla docente, 
 * selecionamos docente id, nombres y horas que se comparan las tablas docente y proyecto
 * llmando los datos del mismo id establecidos en el vinculo con la llave foranea
 * la tabla muestra: el docente id, el nombre y las horas totales aplicadas por el docente
 * en el proyecto, recordad que si no pones sum a p.horas genera error
 * */

USE proyectos_informaticos;
SELECT d.docente_id, d.nombres, SUM(p.horas) AS total_horas
FROM docente d
LEFT JOIN proyecto p ON d.docente_id = p.docente_id_jefe
GROUP BY d.docente_id, d.nombres;

-- Q8: Inserciones vía procedimientos

USE proyectos_informaticos;
-- Elimina posibles duplicados previos
/*esto para hacer las pruebas sin generar errores de duplicacion con el "numero de identidad"*/

DELETE FROM proyecto WHERE docente_id_jefe IN (
  SELECT docente_id FROM docente WHERE numero_documento IN ('CC1001', 'CC1002')
);
DELETE FROM docente WHERE numero_documento IN ('CC1001', 'CC1002');

-- Inserta docentes
/*con call ejecutamo el procedimiento almacenado, de crear docente añadiendo los datos a los
 * atributos establecidos en la tabla docente, salvo el id que por auto incremento se le asigna*/

USE proyectos_informaticos;
CALL sp_docente_crear('CC1001', 'Ana Gómez', 'MSc. Ing. Sistemas', 6, 'Cra 10 # 5-55', 'Tiempo completo');
CALL sp_docente_crear('CC1002', 'Carlos Ruiz', 'Ing. Informático', 3, 'Cll 20 # 4-10', 'Cátedra');
-- para mirar docente
SELECT * FROM docente;

-- Obtener IDs

/*guarda valores para reutilizarlos posteriormente*/
SET @id_ana    := (SELECT docente_id FROM docente WHERE numero_documento='CC1001');
-- para mirar id de este docente
SELECT @id_ana;

SET @id_carlos := (SELECT docente_id FROM docente WHERE numero_documento='CC1002');
-- para mirar id de este docente
SELECT @id_carlos;

-- Insertar proyectos
/*con call ejecutamo el procedimiento almacenado, de crear proyecto añadiendo los datos a los
 * atributos establecidos en la tabla proyecto, salvo el id que por auto incremento se le asigna*/

USE proyectos_informaticos;
CALL sp_proyecto_crear('Plataforma Académica', 'Módulos de matrícula', '2025-01-01', NULL, 25000000, 800, @id_ana);
CALL sp_proyecto_crear('Chat Soporte TI', 'Chat universitario', '2025-02-01', '2025-06-30', 12000000, 450, @id_carlos);
CALL sp_proyecto_crear('Chat Soporte TI 2', 'Chat universitario 2', '2025-02-01', '2025-05-10', 22000000, 550, @id_carlos);
-- para mirar proyecto
SELECT * FROM proyecto;

-- Q9: Inserciones directas (opcional)

/* se agrega a la tabla docente, los atributos con sus valores. aplicando el insert into con los
 *  atributos de la tabla docente*/

USE proyectos_informaticos;
INSERT INTO docente (numero_documento, nombres, titulo, anios_experiencia, direccion, tipo_docente)
VALUES ('CC2001','María López','Esp. Gestión de Proyectos',7,'Av. Siempre Viva 742','Cátedra');
-- para mirar tabla docente
SELECT * FROM docente;

/* se agrega a la tabla docente, los atributos con sus valores. aplicando el insert into con los
 *  atributos de la tabla docente*/

INSERT INTO proyecto (nombre, descripcion, fecha_inicial, fecha_final, presupuesto, horas, docente_id_jefe)
VALUES ('App Biblioteca','App móvil de préstamos','2025-03-01',NULL, 9000000, 320,
        (SELECT docente_id FROM docente WHERE numero_documento='CC2001'));
-- para mirar tabla proyecto
SELECT * FROM proyecto;

-- Q10: Cantidad de proyectos manejados por un docente y su presupuesto

/*las anteriores queries hacian inserciones por via procedimiento y inserciones directas de datos a proyecto.
 *esta evalua si los proyectos son contabilizados(COUNT) para encontrar que docente a sido vinculado a mas de uno 
 * ordenados de mayor a menor*/

USE proyectos_informaticos;
SELECT d.docente_id, d.nombres, COUNT(p.proyecto_id) AS cantidad_proyectos
FROM docente d
LEFT JOIN proyecto p ON d.docente_id = p.docente_id_jefe
GROUP BY d.docente_id, d.nombres ORDER BY cantidad_proyectos DESC;

-- Listar todos los docentes con su número de proyectos y presupuesto total de mayor a menor
USE proyectos_informaticos;
SELECT d.docente_id, d.nombres, COUNT(p.proyecto_id) AS cantidad_proyectos, SUM(p.presupuesto) AS total_presupuesto
FROM docente d
LEFT JOIN proyecto p ON d.docente_id = p.docente_id_jefe
GROUP BY d.docente_id, d.nombres ORDER BY total_presupuesto DESC;

-- Q11: Borrar datos de tabla para empezar de nuevo

/*reiniciar la tabla con los datos permite, probar de nuevo las queries con entorno mas limpio
 */

-- deactiva la llave foranea
SET FOREIGN_KEY_CHECKS = 0;
-- truncate elimina los datos de las celdas
TRUNCATE TABLE docente;
TRUNCATE TABLE proyecto;
TRUNCATE TABLE copia_actualizados_docente;
TRUNCATE TABLE copia_eliminados_docente;
-- Visualiza la eliminacion de datos
SELECT * FROM docente;
SELECT * FROM proyecto;
SELECT * FROM copia_actualizados_docente;
SELECT * FROM copia_eliminados_docente;
-- Activa la llave foranea
SET FOREIGN_KEY_CHECKS = 1;

-- otra prueba --

/* Usando los datos de la base de datos proyectos_informaticos de la tabla de
 * proyectos que aun no han terminado, solo salen los datos de los proyecto que aun estan 
 * en ejecucion, donde(WHERE) evalua si el valor es nulo en fecha final para
 * mostrar los datos con las mismas caracteristicas
 * tabla muestra: nombre, fecha_inicial, presupuesto
 * ordenado desde la fecha mas reciente
 * */

USE proyectos_informaticos;
SELECT nombre, fecha_inicial, presupuesto
FROM proyecto
WHERE fecha_final IS NULL
ORDER BY fecha_inicial;

-- LIMITANDO CON RANGO DE PRESUPUESTO

USE proyectos_informaticos;
SELECT nombre, fecha_inicial, presupuesto
FROM proyecto
WHERE fecha_final IS NULL AND presupuesto BETWEEN 100000 AND 170000
ORDER BY fecha_inicial;
