----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Registrar una nueva calificación y actualizar el promedio
--"Como desarrollador, quiero un procedimiento que registre una calificación y actualice el promedio del producto."
--🧠 Explicación: Este procedimiento recibe product_id, customer_id y rating, inserta la nueva fila en rates, y recalcula automáticamente el promedio en la tabla products (campo average_rating).
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

DELIMITER //
CREATE PROCEDURE registrar_calificacion (
    IN p_producto_id  INT,
    IN p_cliente_id   INT,
    IN p_rating       INT               -- se espera 1‑5
)
BEGIN
   DECLARE v_company_prod_id INT;
   DECLARE v_avg DOUBLE;
    -- ----------------------------------------------------------------
    -- Obtener la oferta (companyproducts.id) donde registrar la nota
    -- ----------------------------------------------------------------
    

    SELECT cp.id
      INTO v_company_prod_id
      FROM companyproducts cp
     WHERE cp.id_producto = p_producto_id
  ORDER BY cp.precio           -- (u otro criterio)
     LIMIT 1;
    
    -- ----------------------------------------------------------------
    -- Insertar la nueva calificación
    -- ----------------------------------------------------------------
    INSERT INTO rates (id_cliente,
                       id_producto_empresa,
                       puntuacion,
                       fecha)
         VALUES (p_cliente_id,
                 v_company_prod_id,
                 p_rating,
                 CURDATE());

    -- ----------------------------------------------------------------
    -- Recalcular el promedio de calificación del producto
    -- ----------------------------------------------------------------

    SELECT AVG(r.puntuacion)
      INTO v_avg
      FROM rates r
      JOIN companyproducts cp ON r.id_producto_empresa = cp.id
     WHERE cp.id_producto = p_producto_id;

    UPDATE products
       SET prom_califica = v_avg
     WHERE id = p_producto_id;
END;
//

CALL registrar_calificacion( /*product_id*/ 1, /*customer_id*/ 2, /*rating*/ 4 );