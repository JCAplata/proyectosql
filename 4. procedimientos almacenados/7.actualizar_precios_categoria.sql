-------------------------------------------------------------------------------------------------------------------------------------------------------
--Actualizar precios de productos por categoría
--"Como operador, quiero un procedimiento que actualice precios de productos por categoría."
--🧠 Explicación: Recibe un categoria_id y un factor (por ejemplo 1.05), y multiplica todos los precios por ese factor en la tabla companyproducts.
-------------------------------------------------------------------------------------------------------------------------------------------------------

/*==============================================================
  Procedimiento: actualizar_precios_categoria
  Función     : Multiplica los precios de companyproducts
                por un factor dado para todos los productos
                de la categoría indicada.
==============================================================*/
DELIMITER //

CREATE PROCEDURE actualizar_precios_categoria (
    IN p_categoria VARCHAR(50),      -- Nombre de la categoría (ej. 'Electrodomésticos')
    IN p_factor    DECIMAL(6,3)      -- Factor multiplicador (>0). Ej. 1.05 = +5 %
)
BEGIN
    -- --------------------------------------------------------------
    -- Validación simple del factor
    -- --------------------------------------------------------------
    IF p_factor <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El factor debe ser mayor que 0.';
    END IF;

    -- --------------------------------------------------------------
    -- Actualizar precios
    -- --------------------------------------------------------------
    UPDATE companyproducts   cp
    JOIN   products          p  ON p.id = cp.id_producto
    SET    cp.precio = ROUND(cp.precio * p_factor, 2)
    WHERE  p.categoria = p_categoria;

    -- --------------------------------------------------------------
    -- Informe opcional: filas afectadas
    -- --------------------------------------------------------------
    SELECT ROW_COUNT() AS filas_actualizadas;
END;
//
DELIMITER ;

CALL actualizar_precios_categoria('Electrodomésticos', 1.10);