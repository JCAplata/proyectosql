--------------------------------------------------------------------------------------------------------------------------------------------------------
--Validar inconsistencia entre rates y quality_products
--"Como auditor, deseo un procedimiento que liste inconsistencias entre rates y quality_products."
--🧠 Explicación: Busca calificaciones (rates) que no tengan entrada correspondiente en quality_products. Inserta el error en una tabla errores_log.
--------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS errores_log (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    id_entidad    INT            NOT NULL,          -- id del registro con error
    entidad       VARCHAR(50)    NOT NULL,          -- tabla origen (ej. 'rates')
    tipo_error    VARCHAR(100)   NOT NULL,          -- código de error
    detalle       TEXT           NOT NULL,          -- descripción legible
    fecha         TIMESTAMP      DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY ux_error (id_entidad, entidad, tipo_error)  -- evita duplicados
) ENGINE = InnoDB;

DELIMITER //

CREATE PROCEDURE validar_inconsistencia_rates_quality ()
BEGIN
    /*------------------------------------------------------------
      Inserta en errores_log los rate‑ids que no tienen registro
      correspondiente en quality_products para el mismo cliente
      y el mismo producto_empresa.  Se omiten los que ya existan
      en el log gracias al UNIQUE KEY.
    ------------------------------------------------------------*/
    INSERT IGNORE INTO errores_log (id_entidad, entidad, tipo_error, detalle)
    SELECT
        r.id                         AS id_entidad,
        'rates'                      AS entidad,
        'RATES_SIN_QUALITY'          AS tipo_error,
        CONCAT('Rate ID ', r.id,
               ' (cliente ', r.id_cliente,
               ', producto_empresa ', r.id_producto_empresa,
               ') no tiene entrada en quality_products') AS detalle
    FROM rates r
    LEFT JOIN quality_products q
           ON q.id_producto_empresa = r.id_producto_empresa
          AND q.id_cliente         = r.id_cliente
    WHERE q.id IS NULL;   -- la inconsistencia que buscamos

    /*  Resultado opcional: cuántos errores nuevos se registraron */
    SELECT ROW_COUNT() AS errores_registrados;
END;
//
DELIMITER ;

CALL validar_inconsistencia_rates_quality();