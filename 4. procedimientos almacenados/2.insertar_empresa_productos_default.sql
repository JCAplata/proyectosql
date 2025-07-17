-------------------------------------------------------------------------------------------------------------------------------------------------------
--Insertar empresa y asociar productos por defecto
--"Como administrador, deseo un procedimiento para insertar una empresa y asociar productos por defecto."
--🧠 Explicación: Este procedimiento inserta una empresa en companies, y luego vincula automáticamente productos predeterminados en companyproducts.
------------------------------------------------------------------------------------------------------------------------------------------------------

/*=============================================================
  Procedimiento: insertar_empresa_con_productos_default
  Función     : 1) Crea empresa
                2) Copia productos predeterminados a companyproducts
=============================================================*/
DELIMITER //

CREATE PROCEDURE insertar_empresa_productos_default (
    IN p_nombre        VARCHAR(100),
    IN p_tipo          VARCHAR(50),
    IN p_categoria     VARCHAR(50),
    IN p_id_ciudad     INT,
    IN p_id_audiencia  INT
)
BEGIN
    DECLARE v_empresa_id INT;

    -- 1. Insertar la empresa y capturar su ID
    INSERT INTO companies (nombre, tipo, categoria, id_ciudad, id_audiencia)
    VALUES (p_nombre, p_tipo, p_categoria, p_id_ciudad, p_id_audiencia);

    SET v_empresa_id = LAST_INSERT_ID();

    -- 2. Insertar los productos predeterminados para la nueva empresa
    INSERT INTO companyproducts (id_empresa, id_producto, precio, unidad_medida)
    SELECT  v_empresa_id,
        d.id,
        d.precio,
        'unidad'
    FROM products d
    WHERE id NOT IN (SELECT id_producto FROM companyproducts 
					 WHERE id_empresa = v_empresa_id);

    /* Opcional: devolver el ID nuevo si se necesita en la capa de aplicación */
    SELECT v_empresa_id AS nueva_empresa_id;
END;
//
DELIMITER ;

CALL insertar_empresa_con_productos_default(
    'Comercial XYZ',
    'Retail',
    'Electrodomésticos',
    1,      -- id_ciudad
    4       -- id_audiencia
);