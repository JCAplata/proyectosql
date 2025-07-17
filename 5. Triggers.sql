DELIMITER //

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 1. Actualizar la fecha de modificación de un producto
--"Como desarrollador, deseo un trigger que actualice la fecha de modificación cuando se actualice un producto."
--🧠 Explicación: Cada vez que se actualiza un producto, queremos que el campo updated_at se actualice automáticamente con la fecha actual (NOW()), sin tener que hacerlo manualmente desde la app.
--🔁 Se usa un BEFORE UPDATE.
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TRIGGER trg_update_product_updated_at
BEFORE UPDATE ON products
FOR EACH ROW
BEGIN
  SET NEW.updated_at = NOW();
END;

DELIMITER //

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 2. Registrar log cuando un cliente califica un producto
--"Como administrador, quiero un trigger que registre en log cuando un cliente califica un producto."
--🧠 Explicación: Cuando alguien inserta una fila en rates, el trigger crea automáticamente un registro en log_acciones con la información del cliente y producto calificado.
--🔁 Se usa un AFTER INSERT sobre rates.
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TRIGGER trg_log_calificacion
AFTER INSERT ON rates
FOR EACH ROW
BEGIN
  INSERT INTO log_acciones (entidad, id_entidad, descripcion, fecha)
  VALUES ('rates', NEW.id, CONCAT('Cliente ', NEW.id_cliente, ' calificó producto ', NEW.id_producto_empresa), NOW());
END;

DELIMITER //

-----------------------------------------------------------------------------------------------------------------------------------
-- 3. Impedir insertar productos sin unidad de medida
--"Como técnico, deseo un trigger que impida insertar productos sin unidad de medida."
--🧠 Explicación: Antes de guardar un nuevo producto, el trigger revisa si unit_id es NULL. Si lo es, lanza un error con SIGNAL.
--🔁 Se usa un BEFORE INSERT.
-----------------------------------------------------------------------------------------------------------------------------------
CREATE TRIGGER trg_no_unit_producto
BEFORE INSERT ON products
FOR EACH ROW
BEGIN
  IF NEW.unidad_medida IS NULL THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'El producto debe tener unidad de medida';
  END IF;
END;

DELIMITER //

--------------------------------------------------------------------------------------------------------------------------------------
-- 4. Validar calificaciones no mayores a 5
--"Como auditor, quiero un trigger que verifique que las calificaciones no superen el valor máximo permitido."
--🧠 Explicación: Si alguien intenta insertar una calificación de 6 o más, se bloquea automáticamente. Esto evita errores o trampa.
--🔁 Se usa un BEFORE INSERT.
--------------------------------------------------------------------------------------------------------------------------------------
CREATE TRIGGER trg_valida_rating
BEFORE INSERT ON rates
FOR EACH ROW
BEGIN
  IF NEW.puntuacion > 5 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'La calificación no puede superar 5';
  END IF;
END;

DELIMITER //

------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 5. Actualizar estado de membresía cuando vence
--"Como supervisor, deseo un trigger que actualice automáticamente el estado de membresía al vencer el periodo."
--🧠 Explicación: Cuando se actualiza un periodo de membresía (membershipperiods), si end_date ya pasó, se puede cambiar el campo status a 'INACTIVA'.
--🔁 AFTER UPDATE o BEFORE UPDATE dependiendo de la lógica.
---------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TRIGGER trg_update_estado_membresia
BEFORE UPDATE ON membershipperiods
FOR EACH ROW
BEGIN
  IF NEW.fin < NOW() THEN
    SET NEW.status = 'INACTIVA';
  END IF;
END;

DELIMITER //

---------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 6. Evitar duplicados de productos por empresa
--"Como operador, quiero un trigger que evite duplicar productos por nombre dentro de una misma empresa."
--🧠 Explicación: Antes de insertar un nuevo producto en companyproducts, el trigger puede consultar si ya existe uno con el mismo product_id y company_id.
--🔁 BEFORE INSERT.
--------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TRIGGER trg_no_duplicado_producto_empresa
BEFORE INSERT ON companyproducts
FOR EACH ROW
BEGIN
  IF EXISTS (
    SELECT 1 FROM companyproducts
    WHERE id_empresa = NEW.id_empresa AND id_producto = NEW.id_producto
  ) THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Este producto ya está asociado a esta empresa';
  END IF;
END;

DELIMITER //

--------------------------------------------------------------------------------------------------------------------------
-- 7. Enviar notificación al añadir un favorito
--"Como cliente, deseo un trigger que envíe notificación cuando añado un producto como favorito."
--🧠 Explicación: Después de un INSERT en details_favorites, el trigger agrega un mensaje a una tabla notificaciones.
--🔁 AFTER INSERT.
--------------------------------------------------------------------------------------------------------------------------
CREATE TRIGGER trg_notificacion_favorito
AFTER INSERT ON details_favorites
FOR EACH ROW
BEGIN
  DECLARE v_client INT;
  SET v_client = (SELECT id_cliente FROM favorites WHERE id = NEW.id_lista LIMIT 1);
    
  INSERT INTO notificaciones (cliente_id, mensaje, fecha)
  VALUES (v_client, CONCAT('Has añadido el producto ', NEW.id_producto_empresa, ' a favoritos'), NOW());
END;

DELIMITER //

------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 8. Insertar fila en quality_products tras calificación
--"Como técnico, quiero un trigger que inserte una fila en quality_products cuando se registra una calificación."
--🧠 Explicación: Al insertar una nueva calificación en rates, se crea automáticamente un registro en quality_products para mantener métricas de calidad.
--🔁 AFTER INSERT.
------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TRIGGER trg_insert_quality
AFTER INSERT ON rates
FOR EACH ROW
BEGIN
  INSERT INTO quality_products (id_encuesta, id_producto_empresa, id_cliente, puntuacion)
  VALUES (1, NEW.id_producto_empresa, NEW.id_cliente, NEW.puntuacion);
END;

DELIMITER //

---------------------------------------------------------------------------------------------------------------------------------
-- 9. Eliminar favoritos si se elimina el producto
--"Como desarrollador, deseo un trigger que elimine los favoritos si se elimina el producto."
--🧠 Explicación: Cuando se borra un producto, el trigger elimina las filas en details_favorites donde estaba ese producto.
--🔁 AFTER DELETE en products.
-------------------------------------------------------------------------------------------------------------------------------
CREATE TRIGGER trg_delete_favoritos_con_producto
AFTER DELETE ON products
FOR EACH ROW
BEGIN
  DELETE FROM details_favorites WHERE product_id = OLD.id;
END;

DELIMITER //

--------------------------------------------------------------------------------------------------------------------------
-- 10. Bloquear modificación de audiencias activas
--"Como administrador, quiero un trigger que bloquee la modificación de audiencias activas."
--🧠 Explicación: Si un usuario intenta modificar una audiencia que está en uso, el trigger lanza un error con SIGNAL.
--🔁 BEFORE UPDATE.
--------------------------------------------------------------------------------------------------------------------------
CREATE TRIGGER trg_bloquear_audiencia_activa
BEFORE UPDATE ON audiences
FOR EACH ROW
BEGIN
  IF EXISTS (
    SELECT 1 FROM customers
    WHERE id_audiencia = OLD.id
  ) THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Esta audiencia esta en uso y no se puede modificar';
  END IF;
END;

DELIMITER //

----------------------------------------------------------------------------------------------------------------------------
-- 11. Recalcular promedio de calidad del producto tras nueva evaluación
--"Como gestor, deseo un trigger que actualice el promedio de calidad del producto tras una nueva evaluación."
--🧠 Explicación: Después de insertar en rates, el trigger actualiza el campo average_rating del producto usando AVG().
--🔁 AFTER INSERT.
-----------------------------------------------------------------------------------------------------------------------------
CREATE TRIGGER trg_update_promedio_rating
AFTER INSERT ON rates
FOR EACH ROW
BEGIN
  UPDATE products p
  JOIN companyproducts cp ON cp.id_producto = p.id
  SET p.prom_califica = (
    SELECT ROUND(AVG(r.puntuacion),2)
    FROM rates r
    WHERE r.id_producto_empresa = cp.id
  )
  WHERE cp.id = NEW.id_producto_empresa;
END;

DELIMITER //

-------------------------------------------------------------------------------------------------------------------
-- 12. Registrar asignación de nuevo beneficio
--Como auditor, quiero un trigger que registre cada vez que se asigna un nuevo beneficio."
--🧠 Explicación: Cuando se hace INSERT en membershipbenefits o audiencebenefits, se agrega un log en bitacora.
--------------------------------------------------------------------------------------------------------------------
CREATE TRIGGER trg_log_beneficio_membresia
AFTER INSERT ON membershipbenefits
FOR EACH ROW
BEGIN
  INSERT INTO log_acciones (entidad, id_entidad, descripcion, fecha)
  VALUES ('memberships', NEW.id, CONCAT('Se asignó beneficio ', NEW.id_beneficio, ' al plan '), NOW());
END;

DELIMITER //

-------------------------------------------------------------------------------------------------------------------------------------
-- 13. Impedir doble calificación por parte del cliente
--"Como cliente, deseo un trigger que me impida calificar el mismo producto dos veces seguidas."
--🧠 Explicación: Antes de insertar en rates, el trigger verifica si ya existe una calificación de ese customer_id y product_id.
-----------------------------------------------------------------------------------------------------------------------------------
CREATE TRIGGER trg_no_doble_calificacion
BEFORE INSERT ON rates
FOR EACH ROW
BEGIN
  IF EXISTS (
    SELECT 1 FROM rates
    WHERE id_cliente = NEW.id_cliente AND id_producto_empresa = NEW.id_producto_empresa
  ) THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Este cliente ya calificó este producto';
  END IF;
END;

DELIMITER //

----------------------------------------------------------------------------------------------------------------------
-- 14. Validar correos duplicados en clientes
--"Como técnico, quiero un trigger que valide que el email del cliente no se repita."
--🧠 Explicación: Verifica, antes del INSERT, si el correo ya existe en la tabla customers. Si sí, lanza un error.
---------------------------------------------------------------------------------------------------------------------
CREATE TRIGGER trg_email_unico_cliente
BEFORE INSERT ON customers
FOR EACH ROW
BEGIN
  IF EXISTS (
    SELECT 1 FROM customers WHERE correo = NEW.correo
  ) THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'El email ya está registrado';
  END IF;
END;

DELIMITER //

----------------------------------------------------------------------------------------------------------------------
-- 15.  Eliminar detalles de favoritos huérfanos
--"Como operador, deseo un trigger que elimine registros huérfanos de details_favorites."
--🧠 Explicación: Si se elimina un registro de favorites, se borran automáticamente sus detalles asociados.
----------------------------------------------------------------------------------------------------------------------
CREATE TRIGGER trg_delete_detalles_favoritos
AFTER DELETE ON favorites
FOR EACH ROW
BEGIN
  DELETE FROM details_favorites WHERE id_lista = OLD.id;
END;

DELIMITER //

-------------------------------------------------------------------------------------------------------------------------------------
-- 16. Actualizar campo updated_at en companies
--"Como administrador, quiero un trigger que actualice el campo updated_at en companies."
--🧠 Explicación: Como en productos, actualiza automáticamente la fecha de última modificación cada vez que se cambia algún dato.
------------------------------------------------------------------------------------------------------------------------------------
CREATE TRIGGER trg_update_company_updated_at
BEFORE UPDATE ON companies
FOR EACH ROW
BEGIN
  SET NEW.updated_at = NOW();
END;

DELIMITER //

-----------------------------------------------------------------------------------------------------------------------------------
-- 17. Impedir borrar ciudad si hay empresas activas
--"Como desarrollador, deseo un trigger que impida borrar una ciudad si hay empresas activas en ella."
--🧠 Explicación: Antes de hacer DELETE en citiesormunicipalities, el trigger revisa si hay empresas registradas en esa ciudad.
----------------------------------------------------------------------------------------------------------------------------------
CREATE TRIGGER trg_bloqueo_ciudad_empresas
BEFORE DELETE ON citiesormunicipalities
FOR EACH ROW
BEGIN
  IF EXISTS (
    SELECT 1 FROM companies WHERE id_ciudad = OLD.id
  ) THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'No se puede eliminar una ciudad con empresas registradas';
  END IF;
END;

DELIMITER //

-----------------------------------------------------------------------------------------------------------------------------------
-- 18.  Registrar cambios de estado en encuestas
--"Como auditor, quiero un trigger que registre cambios de estado de encuestas."
--🧠 Explicación: Cada vez que se actualiza el campo status en polls, el trigger guarda la fecha, nuevo estado y usuario en un log.
-----------------------------------------------------------------------------------------------------------------------------------
CREATE TRIGGER trg_log_estado_poll
AFTER UPDATE ON polls
FOR EACH ROW
BEGIN
  IF OLD.status <> NEW.status THEN
    INSERT INTO log_estados (entidad, id_entidad, estado_nuevo, fecha)
    VALUES ('polls', NEW.id, NEW.status, NOW());
  END IF;
END;

DELIMITER //

-------------------------------------------------------------------------------------------------------------------------------------
-- 19. Sincronizar rates y quality_products
--"Como supervisor, deseo un trigger que sincronice rates con quality_products al calificar."
--🧠 Explicación: Inserta o actualiza la calidad del producto en quality_products cada vez que se inserta una nueva calificación.
------------------------------------------------------------------------------------------------------------------------------------
CREATE TRIGGER trg_sync_rates_quality
AFTER INSERT ON rates
FOR EACH ROW
BEGIN
  INSERT INTO quality_products (id_encuesta, id_producto_empresa, id_cliente, resultado)
  VALUES (1, NEW.id_producto_empresa, NEW.id_cliente, NEW.puntuacion)
  ON DUPLICATE KEY UPDATE resultado = NEW.puntuacion;
END;

DELIMITER //

------------------------------------------------------------------------------------------------------------------------------------------------------
-- 20. Eliminar productos sin relación a empresas
--"Como operador, quiero un trigger que elimine automáticamente productos sin relación a empresas."
--🧠 Explicación: Después de borrar la última relación entre un producto y una empresa (companyproducts), el trigger puede eliminar ese producto.
-----------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TRIGGER trg_delete_producto_huerfano
AFTER DELETE ON companyproducts
FOR EACH ROW
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM companyproducts WHERE id_producto = OLD.id_producto
  ) THEN
    DELETE FROM products WHERE id = OLD.id_producto;
  END IF;
END;

//