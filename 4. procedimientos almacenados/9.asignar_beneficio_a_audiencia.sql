--------------------------------------------------------------------------------------------------------------------------------------
--Asignar beneficios a nuevas audiencias
--"Como desarrollador, quiero un procedimiento que asigne beneficios a nuevas audiencias."
--🧠 Explicación: Recibe un benefit_id y audience_id, verifica si ya existe el registro, y si no, lo inserta en audiencebenefits.
--------------------------------------------------------------------------------------------------------------------------------------

DELIMITER //

CREATE PROCEDURE asignar_beneficio_a_audiencia (
    IN p_id_beneficio INT,
    IN p_id_audiencia INT
)
BEGIN
    -- Verificar si ya existe la relación
    IF NOT EXISTS (
        SELECT 1
        FROM audiencebenefits
        WHERE id_beneficio = p_id_beneficio
          AND id_audiencia = p_id_audiencia
    ) THEN
        -- Insertar si no existe
        INSERT INTO audiencebenefits (id_audiencia, id_beneficio)
        VALUES (p_id_audiencia, p_id_beneficio);
    END IF;
END;
//
DELIMITER ;

CALL asignar_beneficio_a_audiencia(3, 7);