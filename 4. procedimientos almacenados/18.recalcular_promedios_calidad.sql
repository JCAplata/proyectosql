---------------------------------------------------------------------------------------------------------
--Recalcular promedios de calidad semanalmente
--"Como supervisor, quiero un procedimiento que recalcule todos los promedios de calidad cada semana."
--🧠 Explicación: Hace un AVG(rating) agrupado por producto y lo actualiza en products.
----------------------------------------------------------------------------------------------------------

/*==============================================================
  Procedimiento: recalcular_promedios_calidad
  Función      : Calcula AVG(r.puntuacion) por producto
                 y actualiza products.prom_califica.
==============================================================*/
DELIMITER //

CREATE PROCEDURE recalcular_promedios_calidad ()
BEGIN
    -- --------------------------------------------------------------
    -- 1. Actualiza promedio para productos que sí tienen calificaciones
    -- --------------------------------------------------------------
    UPDATE products p
    JOIN (
        SELECT cp.id_producto              AS id_producto,
               ROUND(AVG(r.puntuacion), 2) AS promedio
        FROM rates r
        JOIN companyproducts cp ON r.id_producto_empresa = cp.id
        GROUP BY cp.id_producto
    ) AS sub ON p.id = sub.id_producto
    SET p.prom_califica = sub.promedio;

    -- --------------------------------------------------------------
    -- 2. Opcional: pone a NULL (o 0) los productos sin calificación
    -- --------------------------------------------------------------
    UPDATE products
    SET prom_califica = NULL
    WHERE id NOT IN (
        SELECT DISTINCT cp.id_producto
        FROM companyproducts cp
        JOIN rates r ON r.id_producto_empresa = cp.id
    );

    -- 3. Resultado informativo
    SELECT ROW_COUNT() AS filas_actualizadas;
END;
//
DELIMITER ;

CALL recalcular_promedios_calidad();