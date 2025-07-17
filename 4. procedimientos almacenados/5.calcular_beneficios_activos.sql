-------------------------------------------------------------------------------------------------------------------------------------------------
--Calcular beneficios activos por membresía
--"Como supervisor, quiero un procedimiento que calcule beneficios activos por membresía."
--🧠 Explicación: Consulta membershipbenefits junto con membershipperiods, y devuelve una lista de beneficios vigentes según la fecha actual.
-------------------------------------------------------------------------------------------------------------------------------------------------

DELIMITER //

CREATE PROCEDURE calcular_beneficios_activos ()
BEGIN
    -- Devuelve los beneficios activos por membresía según la fecha actual
    SELECT 
        m.id                  AS id_membresia,
        m.nombre              AS nombre_membresia,
        b.id                  AS id_beneficio,
        b.descripcion         AS descripcion_beneficio,
        mp.inicio             AS inicio_vigencia,
        mp.fin                AS fin_vigencia
    FROM membershipbenefits mb
    JOIN memberships m         ON mb.id_membresia = m.id
    JOIN benefits b            ON mb.id_beneficio = b.id
    JOIN membershipperiods mp  ON mp.id_membresia = m.id
    WHERE CURDATE() BETWEEN mp.inicio AND mp.fin
    ORDER BY m.nombre, b.descripcion;
END;
//
DELIMITER ;

CALL calcular_beneficios_activos();