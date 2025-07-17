----------------------------------------------------------------------------------------------------------------------------------------------------
--Generar el top 10 de productos más calificados por ciudad
--"Como gerente, quiero un procedimiento que genere el top 10 de productos más calificados por ciudad."
--🧠 Explicación: Agrupa las calificaciones por ciudad (a través de la empresa que lo vende) y selecciona los 10 productos con más evaluaciones.
----------------------------------------------------------------------------------------------------------------------------------------------------

DELIMITER //

CREATE PROCEDURE top10_productos_por_ciudad ()
BEGIN
    /* 
       Usamos ROW_NUMBER() para enumerar los productos más calificados por ciudad
       y luego filtramos solo los TOP 10 por ciudad.
    */
    SELECT *
    FROM (
        SELECT 
            c.id                 AS id_ciudad,
            c.nombre             AS ciudad,
            p.id                 AS id_producto,
            p.nombre             AS producto,
            COUNT(r.id)          AS total_calificaciones,
            ROW_NUMBER() OVER (
                PARTITION BY c.id
                ORDER BY COUNT(r.id) DESC
            ) AS ranking
        FROM rates r
        JOIN companyproducts cp ON r.id_producto_empresa = cp.id
        JOIN products p         ON cp.id_producto = p.id
        JOIN companies e        ON cp.id_empresa = e.id
        JOIN citiesormunicipalities c ON e.id_ciudad = c.id
        GROUP BY c.id, p.id
    ) AS sub
    WHERE sub.ranking <= 10
    ORDER BY sub.ciudad, sub.ranking;
END;
//
DELIMITER ;

CALL top10_productos_por_ciudad();