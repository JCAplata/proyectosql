----------------------------------------------------------------------------------------------------------------------
--Actualizar unidad de medida de productos sin afectar ventas
--"Como técnico, deseo un procedimiento que actualice la unidad de medida de productos sin afectar si hay ventas."
--🧠 Explicación: Verifica si el producto no ha sido vendido, y si es así, permite actualizar su unit_id.
-----------------------------------------------------------------------------------------------------------------------

DELIMITER //

CREATE PROCEDURE actualizar_unidad_si_no_vendido (
    IN p_id_producto_empresa INT,
    IN p_nueva_unidad     	 varchar(30)
)
BEGIN
    DECLARE v_uso INT;

    -- Verificar si ha sido calificado (usado en ventas)
    SELECT COUNT(*) INTO v_uso
    FROM rates
    WHERE id_producto_empresa = p_id_producto_empresa;

    -- Si no hay uso, se permite actualizar
    IF v_uso = 0 THEN
        UPDATE companyproducts
        SET unidad_medida = p_nueva_unidad
        WHERE id = p_id_producto_empresa;

        SELECT 'Unidad de medida actualizada correctamente' AS mensaje;
    ELSE
        SELECT 'No se puede actualizar: el producto ya fue utilizado en ventas o calificaciones' AS mensaje;
    END IF;
END;
//
DELIMITER ;

CALL actualizar_unidad_si_no_vendido(15, 3);