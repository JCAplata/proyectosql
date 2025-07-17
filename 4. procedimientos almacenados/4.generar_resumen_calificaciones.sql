----------------------------------------------------------------------------------------------------------------------------------------------------------
--Generar resumen mensual de calificaciones por empresa
--"Como gestor, deseo un procedimiento que genere un resumen mensual de calificaciones por empresa."
--🧠 Explicación: Hace una consulta agregada con AVG(rating) por empresa, y guarda los resultados en una tabla de resumen tipo resumen_calificaciones.
----------------------------------------------------------------------------------------------------------------------------------------------------------


/*==============================================================
  1.  Tabla de acumulados mensuales de calificaciones por empresa
==============================================================*/
CREATE TABLE IF NOT EXISTS resumen_calificaciones (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    id_empresa      INT          NOT NULL,
    anio            INT          NOT NULL,
    mes             INT          NOT NULL,
    promedio_rating DECIMAL(4,2) NOT NULL,
    total_ratings   INT          NOT NULL,
    UNIQUE KEY uk_empresa_mes (id_empresa, anio, mes),
    FOREIGN KEY (id_empresa) REFERENCES companies(id)
) ENGINE = InnoDB;

/*==============================================================
  2.  Procedimiento: generar_resumen_calificaciones
==============================================================*/
DELIMITER //

CREATE PROCEDURE generar_resumen_calificaciones (
    IN p_anio INT,
    IN p_mes  INT
)
BEGIN
    -- --------------------------------------------------------------
    -- Validación simple
    -- --------------------------------------------------------------
    IF p_mes < 1 OR p_mes > 12 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El mes debe estar entre 1 y 12.';
    END IF;

    -- --------------------------------------------------------------
    -- Eliminar resúmenes previos del mismo periodo (idempotencia)
    -- --------------------------------------------------------------
    DELETE FROM resumen_calificaciones
    WHERE anio = p_anio
      AND mes  = p_mes;

    -- --------------------------------------------------------------
    -- Insertar nuevos datos agregados
    -- --------------------------------------------------------------
    INSERT INTO resumen_calificaciones (id_empresa, anio, mes, promedio_rating, total_ratings)
    SELECT
        cp.id_empresa,
        p_anio        AS anio,
        p_mes         AS mes,
        AVG(r.puntuacion) AS promedio_rating,
        COUNT(*)          AS total_ratings
    FROM rates r
    JOIN companyproducts cp ON r.id_producto_empresa = cp.id
    WHERE YEAR(r.fecha)  = p_anio
      AND MONTH(r.fecha) = p_mes
    GROUP BY cp.id_empresa;

    -- --------------------------------------------------------------
    -- Resultado informativo (opcional)
    -- --------------------------------------------------------------
    SELECT ROW_COUNT() AS filas_insertadas;
END;
//
DELIMITER ;

CALL generar_resumen_calificaciones(2025, 7);