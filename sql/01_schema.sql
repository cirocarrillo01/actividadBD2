-- schema.sql (MySQL 8.0+)
-- vinculacion
/* selecciona la base de datos con la que se va atrabajar el codigo */
USE proyectos_informaticos;

-- LIMPIEZA ---
/* eliminacion preventiva de triggers y tablas pre existentes, para evitar conflictos:
 * Drop = Eliminar objeto de la base de datos, se aplica en DATABASE, TABLE, VIEW, INDEX,
 * FUNTION, PROCEDURE, LOGIN, DEFAULT*/
-- trigger = es un disparador automatico, se ejecuta antes o despues que ocurre algo en la tabla (insert,delete,update)

-- elimina trigger docente despues de actualizar
DROP TRIGGER IF EXISTS tr_docente_after_update;
-- elimina trigger docente despues de eliminar
DROP TRIGGER IF EXISTS tr_docente_after_delete;
-- elimina tabla de copia_eliminados_docente
DROP TABLE IF EXISTS copia_eliminados_docente;
-- elimina tabla de copia_actualizados_docente
DROP TABLE IF EXISTS copia_actualizados_docente;
-- elimina tabla de proyecto
DROP TABLE IF EXISTS proyecto;
-- elimina tabla de docente
DROP TABLE IF EXISTS docente;

-- TABLA BASE ---
/*Esta tabla docente contiene; docente id con clave primaria y auto incremento,
 *  numero de documento, nombre, titulo,años de experiencia, dirección, tipo
 *  de docente con sus especificaciones, restriciones a un numero de documento único(unique) y
 *  una condicion especifica(check) para los años de experiencia sea > o = 0 evita negativos.*/

-- int = entero, varchar = cadena de texto o numeros(se leen como texto)
-- constraint= restrincion para mantener integridad.
-- not null= evita valores nulos (en blanco)

CREATE TABLE docente (
  docente_id        INT AUTO_INCREMENT PRIMARY KEY,
  numero_documento  VARCHAR(20)  NOT NULL,#20 caracteres
  nombres           VARCHAR(120) NOT NULL,#120 caracteres
  titulo            VARCHAR(120),#120 caracteres
  anios_experiencia INT          NOT NULL DEFAULT 0,
  direccion         VARCHAR(180),#120 caracteres
  tipo_docente      VARCHAR(40),#40 caracteres
  CONSTRAINT uq_docente_documento UNIQUE (numero_documento),
  CONSTRAINT ck_docente_anios CHECK (anios_experiencia >= 0)
) ENGINE=InnoDB;

/* tabla proyecto contiene; proyecto id con clave primaria y auto incremento, nombre,
 * descripcion, fecha inicial, fecha final, presupuesto, horas, docente id jefe 
 * con sus especificaciones, evalua que las horas no sea un valor negativo,
 * evalua que el presupuesto no sea un valor negativo, se evalua que la fecha final tenga datos y
 * no sea antes de la inical, clave foranea se vincula docente_id_jefe con docente_id de la tabla docente*/
-- OR condicional

CREATE TABLE proyecto (
  proyecto_id      INT AUTO_INCREMENT PRIMARY KEY,
  nombre           VARCHAR(120) NOT NULL,#120 caracteres
  descripcion      VARCHAR(400),#caracteres
  fecha_inicial    DATE NOT NULL,
  fecha_final      DATE,
  presupuesto      DECIMAL(12,2) NOT NULL DEFAULT 0,#12 cifras y 2 decimales
  horas            INT           NOT NULL DEFAULT 0,
  docente_id_jefe  INT NOT NULL,
  CONSTRAINT ck_proyecto_horas CHECK (horas >= 0),
  CONSTRAINT ck_proyecto_pres CHECK (presupuesto >= 0),
  CONSTRAINT ck_proyecto_fechas CHECK (fecha_final IS NULL OR fecha_final >= fecha_inicial),
  CONSTRAINT fk_proyecto_docente FOREIGN KEY (docente_id_jefe) REFERENCES docente(docente_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- AUDITORIA --

/* copia despues de una actualizacion, tabla contiene; auditoria id con auto incremento,
 * llave primaria, docente id, numero documento, nombres, titulo, años de experiencia,
 * direccion, tipo docente, accion fecha un valor por defecto, usuario sql un valor por defecto  */
-- UTC_TIMESTAMP = hora y fecha excata DEFAULT = un valor por defecto
-- COURRENT_USER = devuelve el usuario de base de datos actual
-- ENGINE=InnoDB = soporta transacciones, integridad referencial y mayor concurrencia


CREATE TABLE copia_actualizados_docente (
  auditoria_id       INT AUTO_INCREMENT PRIMARY KEY,
  docente_id         INT NOT NULL,
  numero_documento   VARCHAR(20)  NOT NULL,#20 caracteres
  nombres            VARCHAR(120) NOT NULL,#120 caracteres
  titulo             VARCHAR(120),#120 caracteres
  anios_experiencia  INT          NOT NULL,
  direccion          VARCHAR(180),#180 caracteres
  tipo_docente       VARCHAR(40),#40 caracteres
  accion_fecha       DATETIME     NOT NULL DEFAULT (UTC_TIMESTAMP()),
  usuario_sql        VARCHAR(128) NOT NULL DEFAULT (CURRENT_USER())#128 caracteres
) ENGINE=InnoDB;

/* copia de los eliminados, tabla contiene; auditoria id con auto incremento,
 * llave primaria, docente id, numero documento, nombres, titulo, años de experiencia,
 * direccion, tipo docente, accion fecha un valor por defecto, usuario sql un valor por defecto */

-- lo mismo que la anterior, pero para ususaario borrados

CREATE TABLE copia_eliminados_docente (
  auditoria_id       INT AUTO_INCREMENT PRIMARY KEY,
  docente_id         INT NOT NULL,
  numero_documento   VARCHAR(20)  NOT NULL,#20 caracteres
  nombres            VARCHAR(120) NOT NULL,#120 caracteres
  titulo             VARCHAR(120),#120 caracteres
  anios_experiencia  INT          NOT NULL,
  direccion          VARCHAR(180),#180 caracteres
  tipo_docente       VARCHAR(40),#40 caracteres
  accion_fecha       DATETIME     NOT NULL DEFAULT (UTC_TIMESTAMP()),
  usuario_sql        VARCHAR(128) NOT NULL DEFAULT (CURRENT_USER())
) ENGINE=InnoDB;

-- ELIMINAR LOS PROCEDIMIENTOS Y FUNCIONES PREVIAS ---
-- PROCEDURE = procedimiento almacenado - IF EXISTS = solo si existe

-- Procedimientos docente eliminados 
DROP PROCEDURE IF EXISTS sp_docente_crear;
-- elimina procedimiento sp_docente_crear
DROP PROCEDURE IF EXISTS sp_docente_leer;
-- elimina procedimiento sp_docente_leer
DROP PROCEDURE IF EXISTS sp_docente_actualizar;
-- elimina procedimiento sp_docente_actualizar
DROP PROCEDURE IF EXISTS sp_docente_eliminar;
-- elimina procedimiento sp_docente_eliminar

-- Procedimientos proyecto eliminados
DROP PROCEDURE IF EXISTS sp_proyecto_crear;
-- elimina procedimiento sp_proyecto_crear
DROP PROCEDURE IF EXISTS sp_proyecto_leer;
-- elimina procedimiento sp_proyecto_leer
DROP PROCEDURE IF EXISTS sp_proyecto_actualizar;
-- elimina procedimiento sp_proyecto_actualizar
DROP PROCEDURE IF EXISTS sp_proyecto_eliminar;
-- elimina procedimiento sp_proyecto_eliminar

-- UDF - FUNCTION = funcion definida por el usuario
DROP FUNCTION IF EXISTS fn_promedio_presupuesto_por_docente;
-- elimina funcion fn_promedio_presupuesto_por_docente

-- PROCEDIMIENTOS PARA DOCENTE ALMACENADO - CRUD

-- DELIMITER = el delimitador de comandos a $$ o // temporalmente

DELIMITER $$
/*se cierra el DELIMITER de nuevo se $$ se retoma el ;*/

-- CREAR

/* creando procedimiento para crear o insertar el nuevo docente (los mismos datos de la tabla docente) sus
 *  valores y condiciones permite remplazar valores nulos por defecto y devuelve el id generado automaticamente*/

-- IN = operador logico, compara valores con una lista o subconsulta
-- BEING Y END = delimitar un bloque de instruciones
-- LAST_INSERT_ID = devuelve el id generado pro auto incremento
-- IFNULL = permite remplazar valores nulos por defecto
-- AS = alias o sobrenombre

CREATE PROCEDURE sp_docente_crear(
  IN p_numero_documento VARCHAR(20),
  IN p_nombres          VARCHAR(120),
  IN p_titulo           VARCHAR(120),
  IN p_anios_experiencia INT,
  IN p_direccion        VARCHAR(180),
  IN p_tipo_docente     VARCHAR(40)
)
BEGIN
  INSERT INTO docente (numero_documento, nombres, titulo, anios_experiencia, direccion, tipo_docente)
  VALUES (p_numero_documento, p_nombres, p_titulo, IFNULL(p_anios_experiencia,0), p_direccion, p_tipo_docente);
  SELECT LAST_INSERT_ID() AS docente_id_creado;
END$$

-- LEER

/* creando procedimiento para leer los datos del docente (los mismos datos de la tabla docente) sus
 * valores y condiciones, usando su ID*/
-- ese asterisco * son todos los datos

CREATE PROCEDURE sp_docente_leer(IN p_docente_id INT)
BEGIN
  SELECT * FROM docente WHERE docente_id = p_docente_id;
END$$

-- ACTUALIZAR

/* creando procedimiento para actualizar al docente (los mismos datos de la tabla docente) sus
 * valores y condiciones, se acualiza todos los datos de un docente y devuelve el registro actualizado*/
-- UPDATE + SET = actualiza registros en una tabla

CREATE PROCEDURE sp_docente_actualizar(
  IN p_docente_id       INT,
  IN p_numero_documento VARCHAR(20),
  IN p_nombres          VARCHAR(120),
  IN p_titulo           VARCHAR(120),
  IN p_anios_experiencia INT,
  IN p_direccion        VARCHAR(180),
  IN p_tipo_docente     VARCHAR(40)
)
BEGIN
  UPDATE docente
     SET numero_documento = p_numero_documento,
         nombres = p_nombres,
         titulo = p_titulo,
         anios_experiencia = IFNULL(p_anios_experiencia,0),
         direccion = p_direccion,
         tipo_docente = p_tipo_docente
   WHERE docente_id = p_docente_id;
  SELECT * FROM docente WHERE docente_id = p_docente_id;
END$$

-- ELIMINAR (╯°□°）╯︵ ┻━┻

/* creando procedimiento para eliminar al docente (los mismos datos de la tabla docente) sus
 * valores y condiciones, se acualiza todos los datos de la tabla docente y devuelve
 * la tabla actualizada, se busca el docente por su id para su eliminacion*/

CREATE PROCEDURE sp_docente_eliminar(IN p_docente_id INT)
BEGIN
  DELETE FROM docente WHERE docente_id = p_docente_id;
END$$

-- PROCEDIMIENTO PARA PROYECTO ALMACENADO - CRUD

-- CREAR

/* creando procedimiento para crear o insertar el nuevo proyecto (los mismos datos de la tabla proyecto) sus
 *  valores y condiciones permite remplazar valores nulos por defecto y devuelve el id generado automaticamente*/

CREATE PROCEDURE sp_proyecto_crear(
  IN p_nombre           VARCHAR(120),
  IN p_descripcion      VARCHAR(400),
  IN p_fecha_inicial    DATE,
  IN p_fecha_final      DATE,
  IN p_presupuesto      DECIMAL(12,2),
  IN p_horas            INT,
  IN p_docente_id_jefe  INT
)
BEGIN
  INSERT INTO proyecto (nombre, descripcion, fecha_inicial, fecha_final, presupuesto, horas, docente_id_jefe)
  VALUES (p_nombre, p_descripcion, p_fecha_inicial, p_fecha_final, IFNULL(p_presupuesto,0), IFNULL(p_horas,0), p_docente_id_jefe);
  SELECT LAST_INSERT_ID() AS proyecto_id_creado;
END$$

-- LEER

/* creando procedimiento para leer los datos del proyecto (los mismos datos de la tabla proyecto) sus
 * valores y condiciones, incluyendo el nombre del docente jefe designado por la clave fornean en la tabla proyecto */
-- ON = condicion de union entre tablas y indica la tabla que dispara el tiggers en este caso

CREATE PROCEDURE sp_proyecto_leer(IN p_proyecto_id INT)
BEGIN
  SELECT p.*, d.nombres AS nombre_docente_jefe
  FROM proyecto p
  JOIN docente d ON d.docente_id = p.docente_id_jefe
  WHERE p.proyecto_id = p_proyecto_id;
END$$

-- ACTUALIZAR

/* creando procedimiento para actualizar el proyecto (los mismos datos de la tabla proyecto) sus
 * valores y condiciones, se acualiza todos los datos del proyecto y muestra los datos actualizados*/
-- CALL = ejecutar un procedimiento almacenado

CREATE PROCEDURE sp_proyecto_actualizar(
  IN p_proyecto_id      INT,
  IN p_nombre           VARCHAR(120),
  IN p_descripcion      VARCHAR(400),
  IN p_fecha_inicial    DATE,
  IN p_fecha_final      DATE,
  IN p_presupuesto      DECIMAL(12,2),
  IN p_horas            INT,
  IN p_docente_id_jefe  INT
)
BEGIN
  UPDATE proyecto
     SET nombre = p_nombre,
         descripcion = p_descripcion,
         fecha_inicial = p_fecha_inicial,
         fecha_final = p_fecha_final,
         presupuesto = IFNULL(p_presupuesto,0),
         horas = IFNULL(p_horas,0),
         docente_id_jefe = p_docente_id_jefe
   WHERE proyecto_id = p_proyecto_id;
  CALL sp_proyecto_leer(p_proyecto_id);
END$$

-- ELIMINAR (╯°□°）╯︵ ┻━┻

/* creando procedimiento para eliminar un proyecto (los mismos datos de la tabla proyecto) sus
 * valores y condiciones, se acualiza todos los datos de la tabla proyecto y devuelve
 * la tabla actualizada, se busca el proyecto por su id para su eliminacion*/

CREATE PROCEDURE sp_proyecto_eliminar(IN p_proyecto_id INT)
BEGIN
  DELETE FROM proyecto WHERE proyecto_id = p_proyecto_id;
END$$

-- UDF

/* Se crea una funcion para el promedio del presupuesto de todos los proyectos por un docente dado
 * el resultado se puede representar con 12 cifras y con 2 decimales*/
-- V_prom = valor promedio o AVG
-- INTO = guarda variable en este caso

CREATE FUNCTION fn_promedio_presupuesto_por_docente(p_docente_id INT)
RETURNS DECIMAL(12,2)
DETERMINISTIC
READS SQL DATA
BEGIN
  DECLARE v_prom DECIMAL(12,2);
  SELECT IFNULL(AVG(presupuesto),0) INTO v_prom
  FROM proyecto
  WHERE docente_id_jefe = p_docente_id;
  RETURN IFNULL(v_prom,0);
END$$

-- TRIGGERS --

-- actualizacion de docente.

/* Crea el trigger para guardar copia de seguridad en la tabla de auditoria de docente,
 * inserta la informacion copia_actualizada_docente con los nuevos valores establecido en
 * el bloque de instruciones*/
-- AFTER = despues de un cambio, registras el cambio
-- NEW = los valores que entra, cuando se usa en insert y update
-- FOR EACH ROW = el trigger corre tantas veces como filas afectadas 

CREATE TRIGGER tr_docente_after_update
AFTER UPDATE ON docente
FOR EACH ROW
BEGIN
  INSERT INTO copia_actualizados_docente
    (docente_id, numero_documento, nombres, titulo, anios_experiencia, direccion, tipo_docente)
  VALUES
    (NEW.docente_id, NEW.numero_documento, NEW.nombres, NEW.titulo, NEW.anios_experiencia, NEW.direccion, NEW.tipo_docente);
END$$

-- eliminacion de docente.

/* Crea el trigger para guardar copia del estado anterior en la tabla de auditoria de docente,
 * inserta la informacion copia_eliminados_docente con los datos del docente anteriores*/
-- OLD = lo que se esta borrando con insert y delete

CREATE TRIGGER tr_docente_after_delete
AFTER DELETE ON docente
FOR EACH ROW
BEGIN
  INSERT INTO copia_eliminados_docente
    (docente_id, numero_documento, nombres, titulo, anios_experiencia, direccion, tipo_docente)
  VALUES
    (OLD.docente_id, OLD.numero_documento, OLD.nombres, OLD.titulo, OLD.anios_experiencia, OLD.direccion, OLD.tipo_docente);
END$$

DELIMITER ;


-- Índices
/* ayuda a mejorar el rendimiento de las consultas, hacelera select
 * con filtros y permite duplicados*/
-- INDEX = estrcutura de datos que permite acelerar la busqueda y el acceso a registros de la tabla

CREATE INDEX ix_proyecto_docente ON proyecto(docente_id_jefe);
CREATE INDEX ix_docente_documento ON docente(numero_documento);
