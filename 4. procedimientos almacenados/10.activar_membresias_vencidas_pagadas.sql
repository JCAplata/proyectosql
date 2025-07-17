----------------------------------------------------------------------------------------------------------------------------------------------------
--Activar planes de membresía vencidos con pago confirmado
--"Como administrador, deseo un procedimiento que active planes de membresía vencidos si el pago fue confirmado."
--🧠 Explicación: Actualiza el campo status a 'ACTIVA' en membershipperiods donde la fecha haya vencido pero el campo pago_confirmado sea TRUE.
----------------------------------------------------------------------------------------------------------------------------------------------------

DELIMITER //

CREATE PROCEDURE activar_membresias_vencidas_pagadas ()
BEGIN
    UPDATE membershipperiods
    SET status = 'ACTIVA'
    WHERE fin < CURDATE()
      AND pago_confirmado = TRUE
      AND status <> 'ACTIVA';

    -- Opcional: devolver cuántos registros fueron actualizados
    SELECT ROW_COUNT() AS membresias_activadas;
END;
//
DELIMITER ;

CALL activar_membresias_vencidas_pagadas();