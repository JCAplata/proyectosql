--------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Eliminar favoritos antiguos sin calificaciones
--"Como técnico, deseo un procedimiento que borre favoritos antiguos no calificados en más de un año."
--🧠 Explicación: Filtra productos favoritos que no tienen calificaciones recientes y fueron añadidos hace más de 12 meses, y los elimina de details_favorites.
--------------------------------------------------------------------------------------------------------------------------------------------------------------------

DELIMITER //

CREATE PROCEDURE eliminar_favoritos_antiguos_sin_calificacion ()
BEGIN
    DELETE df
    FROM details_favorites df
    JOIN favorites f ON f.id = df.id_lista
    LEFT JOIN rates r
        ON r.id_producto_empresa = df.id_producto_empresa
       AND r.fecha > DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
    WHERE f.fecha_creacion < DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
      AND r.id IS NULL;  -- No ha sido calificado en el último año

    -- Resultado opcional
    SELECT ROW_COUNT() AS favoritos_eliminados;
END;
//
DELIMITER ;

CALL eliminar_favoritos_antiguos_sin_calificacion();