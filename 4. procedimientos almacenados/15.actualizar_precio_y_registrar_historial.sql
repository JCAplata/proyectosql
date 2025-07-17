-------------------------------------------------------------------------------------------------------------------------------------------------------------
--Historial de cambios de precio
--"Como administrador, deseo un procedimiento para generar un historial de cambios de precio."
--🧠 Explicación: Cada vez que se cambia un precio, el procedimiento compara el anterior con el nuevo y guarda un registro en una tabla historial_precios.
-------------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS historial_precios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_producto_empresa INT NOT NULL,
    precio_anterior     DECIMAL(10,2) NOT NULL,
    precio_nuevo        DECIMAL(10,2) NOT NULL,
    fecha_cambio        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    usuario             VARCHAR(100) DEFAULT NULL,
    FOREIGN KEY (id_producto_empresa) REFERENCES companyproducts(id)
) ENGINE = InnoDB;


DELIMITER //

CREATE PROCEDURE actualizar_precio_y_registrar_historial (
    IN p_id_producto_empresa INT,
    IN p_nuevo_precio        DECIMAL(10,2),
    IN p_usuario             VARCHAR(100)
)
BEGIN
    DECLARE v_precio_actual DECIMAL(10,2);

    -- Obtener precio actual
    SELECT precio INTO v_precio_actual
    FROM companyproducts
    WHERE id = p_id_producto_empresa;

    -- Solo actualiza si hay un cambio real de precio
    IF v_precio_actual IS NOT NULL AND v_precio_actual <> p_nuevo_precio THEN
        -- Registrar historial
        INSERT INTO historial_precios (
            id_producto_empresa,
            precio_anterior,
            precio_nuevo,
            usuario
        )
        VALUES (
            p_id_producto_empresa,
            v_precio_actual,
            p_nuevo_precio,
            p_usuario
        );

        -- Actualizar el precio
        UPDATE companyproducts
        SET precio = p_nuevo_precio
        WHERE id = p_id_producto_empresa;
    END IF;
END;
//
DELIMITER ;

CALL actualizar_precio_y_registrar_historial(5, 37500, 'admin@empresa.com');