---------------------------------------------------------------------------------------------------------------------------------------------
--Registrar encuesta y sus preguntas asociadas
--"Como gestor, quiero un procedimiento que registre una encuesta y sus preguntas asociadas."
--🧠 Explicación: Inserta la encuesta principal en polls y luego cada una de sus preguntas en otra tabla relacionada como poll_questions.
---------------------------------------------------------------------------------------------------------------------------------------------

CREATE TABLE poll_questions (
    id             INT AUTO_INCREMENT PRIMARY KEY,
    id_encuesta    INT NOT NULL,
    texto_pregunta TEXT NOT NULL,
    FOREIGN KEY (id_encuesta) REFERENCES polls(id)
) ENGINE = InnoDB;


DELIMITER //

CREATE PROCEDURE registrar_encuesta_con_preguntas (
    IN p_titulo       VARCHAR(100),
    IN p_descripcion  TEXT,
    IN p_preguntas_json JSON  -- Ejemplo: '["¿Qué opinas?", "¿Recomendarías?"]'
)
BEGIN
    DECLARE v_id_encuesta INT;
    DECLARE v_index INT DEFAULT 0;
    DECLARE v_total INT;
    DECLARE v_pregunta TEXT;

    -- 1. Insertar encuesta principal
    INSERT INTO polls (titulo, descripcion)
    VALUES (p_titulo, p_descripcion);

    SET v_id_encuesta = LAST_INSERT_ID();

    -- 2. Contar elementos del array JSON
    SET v_total = JSON_LENGTH(p_preguntas_json);

    -- 3. Bucle para insertar cada pregunta
    WHILE v_index < v_total DO
        SET v_pregunta = JSON_UNQUOTE(JSON_EXTRACT(p_preguntas_json, CONCAT('$[', v_index, ']')));
        
        INSERT INTO poll_questions (id_encuesta, texto_pregunta)
        VALUES (v_id_encuesta, v_pregunta);

        SET v_index = v_index + 1;
    END WHILE;

    -- 4. Confirmar
    SELECT v_id_encuesta AS encuesta_creada;
END;
//
DELIMITER ;

CALL registrar_encuesta_con_preguntas(
    'Satisfacción del servicio',
    'Encuesta para conocer la percepción del cliente',
    '["¿El producto cumplió sus expectativas?", "¿Recomendarías este producto?", "¿Cómo calificarías la atención?"]'
);