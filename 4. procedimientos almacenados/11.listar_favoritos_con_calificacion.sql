-----------------------------------------------------------------------------------------------------------------------------------------------------------------
--Listar productos favoritos del cliente con su calificación
--"Como cliente, deseo un procedimiento que me devuelva todos mis productos favoritos con su promedio de rating."
--🧠 Explicación: Consulta todos los productos favoritos del cliente y muestra el promedio de calificación de cada uno, uniendo favorites, rates y products.
-----------------------------------------------------------------------------------------------------------------------------------------------------------------

DELIMITER //

CREATE PROCEDURE listar_favoritos_con_calificacion (
    IN p_id_cliente INT
)
BEGIN
    SELECT 
        p.id                         AS id_producto,
        p.nombre                     AS nombre_producto,
        c.nombre                     AS nombre_empresa,
        df.id_lista,
        ROUND(AVG(r.puntuacion),2)  AS promedio_calificacion
    FROM favorites f
    JOIN details_favorites df         ON f.id = df.id_lista
    JOIN companyproducts cp           ON df.id_producto_empresa = cp.id
    JOIN products p                   ON cp.id_producto = p.id
    JOIN companies c                  ON cp.id_empresa = c.id
    LEFT JOIN rates r                ON r.id_producto_empresa = cp.id
    WHERE f.id_cliente = p_id_cliente
    GROUP BY p.id, c.nombre, df.id_lista;
END;
//
DELIMITER ;

CALL listar_favoritos_con_calificacion(1);