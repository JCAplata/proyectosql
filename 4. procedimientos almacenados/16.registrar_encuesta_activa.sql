------------------------------------------------------------------------------------------------------------------
--Registrar encuesta activa automáticamente
--"Como desarrollador, quiero un procedimiento que registre automáticamente una nueva encuesta activa."
--🧠 Explicación: Inserta una encuesta en polls con el campo status = 'activa' y una fecha de inicio en NOW().
-------------------------------------------------------------------------------------------------------------------

DELIMITER //

CREATE PROCEDURE registrar_encuesta_activa (
    IN p_titulo       VARCHAR(100),
    IN p_descripcion  TEXT
)
BEGIN
    INSERT INTO polls (titulo, descripcion, fecha_inicio, status)
    VALUES (p_titulo, p_descripcion, NOW(), 'ACTIVA');

    -- Opcional: devolver ID creado
    SELECT LAST_INSERT_ID() AS encuesta_creada;
END;
//
DELIMITER ;

CALL registrar_encuesta_activa(
    'Satisfacción del cliente - Julio',
    'Encuesta mensual para evaluar la experiencia de los usuarios.'
);