-- Habilitar el programador de eventos si no está activo
SET GLOBAL event_scheduler = ON;

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--1. Borrar productos sin actividad cada 6 meses
--Historia: Como administrador, quiero un evento que borre productos sin actividad cada 6 meses.
--🧠 Explicación: Algunos productos pueden haber sido creados pero nunca calificados, marcados como favoritos ni asociados a una empresa. Este evento eliminaría esos productos cada 6 meses.
--🛠️ Se usaría un DELETE sobre products donde no existan registros en rates, favorites ni companyproducts.
--📅 Frecuencia del evento: EVERY 6 MONTH
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE EVENT IF NOT EXISTS ev_eliminar_productos_huerfanos
ON SCHEDULE EVERY 6 MONTH
STARTS CURRENT_TIMESTAMP
DO
  CALL eliminar_productos_huerfanos();
  
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--2. Recalcular el promedio de calificaciones semanalmente
--Historia: Como supervisor, deseo un evento semanal que recalcula el promedio de calificaciones.
--🧠 Explicación: Se puede tener una tabla product_metrics que almacena promedios pre-calculados para rapidez. El evento actualizaría esa tabla con nuevos promedios.
--🛠️ Usa UPDATE con AVG(rating) agrupado por producto.
--📅 Frecuencia: EVERY 1 WEEK
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE EVENT IF NOT EXISTS ev_recalcular_promedios
ON SCHEDULE EVERY 1 WEEK
STARTS CURRENT_TIMESTAMP
DO
  /* Pre‑crea product_metrics(id_producto, avg_precio) si no existe */
  REPLACE INTO product_metrics (id_producto, avg_precio)
  SELECT p.id,
         ROUND(AVG(r.precio),2)
  FROM products p
  JOIN rates r ON r.id_producto_empresa = p.id
  GROUP BY p.id;

----------------------------------------------------------------------------------------------------------------
--3. Actualizar precios según inflación mensual
--Historia: Como operador, quiero un evento mensual que actualice los precios de productos por inflación.
--🧠 Explicación: Aplicar un porcentaje de aumento (por ejemplo, 3%) a los precios de todos los productos.
--🛠️ UPDATE companyproducts SET price = price * 1.03;
--📅 Frecuencia: EVERY 1 MONTH
--------------------------------------------------------------------------------------------------------------
CREATE EVENT IF NOT EXISTS ev_ajustar_precios_inflacion
ON SCHEDULE EVERY 1 MONTH
STARTS CURRENT_TIMESTAMP
DO
  UPDATE companyproducts
  SET price = ROUND(price * 1.03, 2);

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--4. Crear backups lógicos diariamente
--Historia: Como auditor, deseo un evento que genere un backup lógico cada medianoche.
--🧠 Explicación: Este evento no ejecuta comandos del sistema, pero puede volcar datos clave a una tabla temporal o de respaldo (products_backup, rates_backup, etc.).
--📅 EVERY 1 DAY STARTS '00:00:00'
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 DELIMITER $$
CREATE EVENT IF NOT EXISTS ev_backup_logico_diario
ON SCHEDULE EVERY 1 DAY
STARTS TIMESTAMP(CURRENT_DATE, '00:00:00')
DO
BEGIN
  -- Copia datos esenciales a tablas backup con marca de fecha
  INSERT INTO products_backup SELECT *, NOW() AS backup_at FROM products;
  INSERT INTO rates_backup    SELECT *, NOW() FROM rates;
END;
$$

----------------------------------------------------------------------------------------------------------------------------------------
--5. Notificar sobre productos favoritos sin calificar
--Historia: Como cliente, quiero un evento que me recuerde los productos que tengo en favoritos y no he calificado.
--🧠 Explicación: Genera una lista (user_reminders) de product_id donde el cliente tiene el producto en favoritos pero no hay rate.
--🛠️ Requiere INSERT INTO recordatorios usando un LEFT JOIN y WHERE rate IS NULL.
---------------------------------------------------------------------------------------------------------------------------------------
CREATE EVENT IF NOT EXISTS ev_recordar_favoritos_sin_precio
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO
  INSERT IGNORE INTO user_reminders (customer_id, product_id, created_at)
  SELECT f.id_cliente,
         df.id_producto_empresa,
         NOW()
  FROM favorites f
  JOIN details_favorites df ON df.id_lista = f.id
  LEFT JOIN rates r
         ON r.id_producto_empresa = df.id_producto_empresa
        AND r.id_cliente = f.id_cliente
  WHERE r.id IS NULL;

--------------------------------------------------------------------------------------------------------------------------
--6. Revisar inconsistencias entre empresa y productos
--Historia: Como técnico, deseo un evento que revise inconsistencias entre empresas y productos cada domingo.
--🧠 Explicación: Detecta productos sin empresa, o empresas sin productos, y los registra en una tabla de anomalías.
--🛠️ Puede usar NOT EXISTS y JOIN para llenar una tabla errores_log.
--📅 EVERY 1 WEEK ON SUNDAY
------------------------------------------------------------------------------------------------------------------------
CREATE EVENT IF NOT EXISTS ev_revisar_inconsistencias
ON SCHEDULE EVERY 1 WEEK
STARTS TIMESTAMP(CURRENT_DATE + INTERVAL (7 - DAYOFWEEK(CURRENT_DATE)) DAY, '02:00:00')
DO
BEGIN
  -- Productos sin empresa
  INSERT IGNORE INTO errores_log (entidad, id_entidad, tipo_error, fecha)
  SELECT 'products', p.id, 'SIN_EMPRESA', NOW()
  FROM products p
  WHERE NOT EXISTS (SELECT 1 FROM companyproducts cp WHERE cp.id_producto = p.id);

  -- Empresas sin productos
  INSERT IGNORE INTO errores_log (entidad, id_entidad, tipo_error, fecha)
  SELECT 'companies', c.id, 'SIN_PRODUCTOS', NOW()
  FROM companies c
  WHERE NOT EXISTS (SELECT 1 FROM companyproducts cp WHERE cp.id_empresa = c.id);
END;

--------------------------------------------------------------------------------------
--7. Archivar membresías vencidas diariamente
--Historia: Como administrador, quiero un evento que archive membresías vencidas.
--🧠 Explicación: Cambia el estado de la membresía cuando su end_date ya pasó.
--🛠️ UPDATE membershipperiods SET status = 'INACTIVA' WHERE end_date < CURDATE();
--------------------------------------------------------------------------------------
CREATE EVENT IF NOT EXISTS ev_archivar_membresias_vencidas
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO
  UPDATE membershipperiods
  SET status = 'INACTIVA'
  WHERE fin < CURDATE();

----------------------------------------------------------------------------------------------------------------------------
--8. Notificar beneficios nuevos a usuarios semanalmente
--Historia: Como supervisor, deseo un evento que notifique por correo sobre beneficios nuevos.
--🧠 Explicación: Detecta registros nuevos en la tabla benefits desde la última semana y los inserta en notificaciones.
--🛠️ INSERT INTO notificaciones SELECT ... WHERE created_at >= NOW() - INTERVAL 7 DAY
----------------------------------------------------------------------------------------------------------------------------
CREATE EVENT IF NOT EXISTS ev_notificar_beneficios_nuevos
ON SCHEDULE EVERY 1 WEEK
STARTS CURRENT_TIMESTAMP
DO
  INSERT INTO notificaciones (mensaje, fecha)
  SELECT CONCAT('Nuevo beneficio: ', descripcion),
         NOW()
  FROM benefits
  WHERE created_at >= NOW() - INTERVAL 7 DAY;

------------------------------------------------------------------------------------------------------------------------------------------
--9. Calcular cantidad de favoritos por cliente mensualmente
--Historia: Como operador, quiero un evento que calcule el total de favoritos por cliente y lo guarde.
--🧠 Explicación: Cuenta los productos favoritos por cliente y guarda el resultado en una tabla de resumen mensual (favoritos_resumen).
--🛠️ INSERT INTO favoritos_resumen SELECT customer_id, COUNT(*) ... GROUP BY customer_id
-------------------------------------------------------------------------------------------------------------------------------------------
CREATE EVENT IF NOT EXISTS ev_resumen_favoritos_mensual
ON SCHEDULE EVERY 1 MONTH
STARTS CURRENT_TIMESTAMP
DO
  INSERT INTO favoritos_resumen (customer_id, total_favoritos, periodo)
  SELECT f.id_cliente,
         COUNT(df.id_producto_empresa),
         DATE_FORMAT(CURDATE(), '%Y-%m') AS periodo
  FROM favorites f
  JOIN details_favorites df ON f.id = df.id_lista
  GROUP BY f.id_cliente;

------------------------------------------------------------------------------------------------------------------------------------------------------------------
--10. Validar claves foráneas semanalmente
--Historia: Como auditor, deseo un evento que valide claves foráneas semanalmente y reporte errores.
--🧠 Explicación: Comprueba que cada product_id, customer_id, etc., tengan correspondencia en sus tablas. Si no, se registra en una tabla inconsistencias_fk.
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE EVENT IF NOT EXISTS ev_validar_fk
ON SCHEDULE EVERY 1 WEEK
STARTS CURRENT_TIMESTAMP
DO
BEGIN
  -- Ejemplo FK: rates.product_id debe existir en products
  INSERT IGNORE INTO inconsistencias_fk (tabla, id_registro, detalle, fecha)
  SELECT 'rates', r.id,
         CONCAT('product_id inválido: ', r.id_producto_empresa),
         NOW()
  FROM rates r
  LEFT JOIN products p ON p.id = r.id_producto_empresa
  WHERE p.id IS NULL;
END;

------------------------------------------------------------------------------------------------------------------------
--11. Eliminar calificaciones inválidas antiguas
--Historia: Como técnico, quiero un evento que elimine calificaciones con errores antiguos.
--🧠 Explicación: Borra rates donde el valor de rating es NULL o <0 y que hayan sido creadas hace más de 3 meses.
--🛠️ DELETE FROM rates WHERE rating IS NULL AND created_at < NOW() - INTERVAL 3 MONTH
----------------------------------------------------------------------------------------------------------------------
CREATE EVENT IF NOT EXISTS ev_purgar_calificaciones_invalidas
ON SCHEDULE EVERY 1 MONTH
STARTS CURRENT_TIMESTAMP
DO
  DELETE FROM rates
  WHERE (puntuacion IS NULL OR puntuacion < 0)
    AND fecha < NOW() - INTERVAL 3 MONTH;

------------------------------------------------------------------------------------------------------------------------
--12. Cambiar estado de encuestas inactivas automáticamente
--Historia: Como desarrollador, deseo un evento que actualice encuestas que no se han usado en mucho tiempo.
--🧠 Explicación: Cambia el campo status = 'inactiva' si una encuesta no tiene nuevas respuestas en más de 6 meses.
----------------------------------------------------------------------------------------------------------------------------
CREATE EVENT IF NOT EXISTS ev_cerrar_encuestas_inactivas
ON SCHEDULE EVERY 1 MONTH
STARTS CURRENT_TIMESTAMP
DO
  UPDATE polls
  SET status = 'INACTIVA'
  WHERE status = 'ACTIVA'
    AND id NOT IN (
      SELECT DISTINCT poll_id FROM rates
      WHERE created_at >= NOW() - INTERVAL 6 MONTH
    );

-------------------------------------------------------------------------------------------------------------------------------
--13. Registrar auditorías de forma periódica
--Historia: Como administrador, quiero un evento que inserte datos de auditoría periódicamente.
--🧠 Explicación: Cada día, se puede registrar el conteo de productos, usuarios, etc. en una tabla tipo auditorias_diarias.
-------------------------------------------------------------------------------------------------------------------------------
CREATE EVENT IF NOT EXISTS ev_auditoria_diaria
ON SCHEDULE EVERY 1 DAY
STARTS TIMESTAMP(CURRENT_DATE, '23:59:00')
DO
  INSERT INTO auditorias_diarias (fecha, total_productos, total_clientes, total_empresas)
  SELECT CURDATE(),
         (SELECT COUNT(*) FROM products),
         (SELECT COUNT(*) FROM customers),
         (SELECT COUNT(*) FROM companies);

-------------------------------------------------------------------------------------------------------------------------------
--14. Notificar métricas de calidad a empresas
--Historia: Como gestor, deseo un evento que notifique a las empresas sus métricas de calidad cada lunes.
--🧠 Explicación: Genera una tabla o archivo con AVG(rating) por producto y empresa y se registra en notificaciones_empresa.
-------------------------------------------------------------------------------------------------------------------------------
CREATE EVENT IF NOT EXISTS ev_notificar_metricas_calidad
ON SCHEDULE EVERY 1 WEEK
STARTS TIMESTAMP(CURRENT_DATE + INTERVAL (8 - DAYOFWEEK(CURRENT_DATE)) DAY, '06:00:00')
DO
  INSERT INTO notificaciones_empresa (company_id, mensaje, fecha)
  SELECT c.id,
         CONCAT('Promedio de calificación semanal: ',
                ROUND(AVG(r.precio),2)),
         NOW()
  FROM companies c
  JOIN companyproducts cp ON cp.id_empresa = c.id
  JOIN rates r ON r.id_producto_empresa = cp.id_producto
  WHERE r.fecha >= NOW() - INTERVAL 7 DAY
  GROUP BY c.id;

-------------------------------------------------------------------------------------------------------------------------------
--15. Recordar renovación de membresías
--Historia: Como cliente, quiero un evento que me recuerde renovar la membresía próxima a vencer.
--🧠 Explicación: Busca membershipperiods donde end_date esté entre hoy y 7 días adelante, e inserta recordatorios.
-------------------------------------------------------------------------------------------------------------------------------
CREATE EVENT IF NOT EXISTS ev_recordar_renovacion_membresia
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO
  INSERT IGNORE INTO recordatorios (customer_id, mensaje, fecha)
  SELECT customer_id,
         'Tu membresía está próxima a vencer. ¡Renueva ahora!',
         NOW()
  FROM membershipperiods
  WHERE fin BETWEEN CURDATE() AND CURDATE() + INTERVAL 7 DAY;

------------------------------------------------------------------------------------------------------------------------------------------
--16. Reordenar estadísticas generales cada semana
--Historia: Como operador, deseo un evento que reordene estadísticas generales.
--🧠 Explicación: Calcula y actualiza métricas como total de productos activos, clientes registrados, etc., en una tabla estadisticas.
-----------------------------------------------------------------------------------------------------------------------------------------
CREATE EVENT IF NOT EXISTS ev_actualizar_estadisticas
ON SCHEDULE EVERY 1 WEEK
STARTS CURRENT_TIMESTAMP
DO
  REPLACE INTO estadisticas (nombre, valor, fecha)
  VALUES ('productos_activos',
          (SELECT COUNT(*) FROM products WHERE activo = 1),
          NOW()),
         ('clientes_registrados',
          (SELECT COUNT(*) FROM customers),
          NOW());

-------------------------------------------------------------------------------------------------------------------------------
--17. Crear resúmenes temporales de uso por categoría
--Historia: Como técnico, quiero un evento que cree resúmenes temporales por categoría.
--🧠 Explicación: Cuenta cuántos productos se han calificado en cada categoría y guarda los resultados para dashboards.
-------------------------------------------------------------------------------------------------------------------------------
CREATE EVENT IF NOT EXISTS ev_resumen_categoria
ON SCHEDULE EVERY 1 WEEK
STARTS CURRENT_TIMESTAMP
DO
  REPLACE INTO resumen_categoria (categoria, total_calificaciones, fecha)
  SELECT p.categoria,
         COUNT(r.id),
         NOW()
  FROM products p
  LEFT JOIN rates r ON r.id_producto_empresa = p.id
  GROUP BY p.categoria;

-------------------------------------------------------------------------------------------------------------------------------
--18. Actualizar beneficios caducados
--Historia: Como gerente, deseo un evento que desactive beneficios que ya expiraron.
--🧠 Explicación: Revisa si un beneficio tiene una fecha de expiración (campo expires_at) y lo marca como inactivo.
-------------------------------------------------------------------------------------------------------------------------------
CREATE EVENT IF NOT EXISTS ev_desactivar_beneficios_expirados
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO
  UPDATE benefits
  SET activo = 0
  WHERE expires_at IS NOT NULL
    AND expires_at < CURDATE();

-------------------------------------------------------------------------------------------------------------------------------
--19. Alertar productos sin evaluación anual
--Historia: Como auditor, quiero un evento que genere alertas sobre productos sin evaluación anual.
--🧠 Explicación: Busca productos sin rate en los últimos 365 días y genera alertas o registros en alertas_productos.
-------------------------------------------------------------------------------------------------------------------------------
CREATE EVENT IF NOT EXISTS ev_alertar_productos_sin_evaluacion
ON SCHEDULE EVERY 1 MONTH
STARTS CURRENT_TIMESTAMP
DO
  INSERT IGNORE INTO alertas_productos (product_id, mensaje, fecha)
  SELECT p.id,
         'Producto sin calificaciones en los últimos 12 meses',
         NOW()
  FROM products p
  WHERE NOT EXISTS (
    SELECT 1 FROM rates r
    WHERE r.id_producto_empresa = p.id
      AND r.fecha >= NOW() - INTERVAL 365 DAY
  );

--------------------------------------------------------------------------------------------------------------------------------------
--20. Actualizar precios con índice externo
--Historia: Como administrador, deseo un evento que actualice precios según un índice referenciado.
--🧠 Explicación: Se podría tener una tabla inflacion_indice y aplicar ese valor multiplicador a los precios de productos activos.
-------------------------------------------------------------------------------------------------------------------------------------
CREATE EVENT IF NOT EXISTS ev_actualizar_precio_indice
ON SCHEDULE EVERY 1 MONTH
STARTS CURRENT_TIMESTAMP
DO
BEGIN
  DECLARE v_factor DECIMAL(6,4);
  SELECT indice INTO v_factor
  FROM inflacion_indice
  ORDER BY fecha DESC
  LIMIT 1;               -- Usa el índice más reciente

  UPDATE companyproducts
  SET precio = ROUND(precio * v_factor, 2)
  WHERE activo = 1;
END;
