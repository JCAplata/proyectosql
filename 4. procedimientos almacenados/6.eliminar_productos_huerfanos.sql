----------------------------------------------------------------------------------------------------------------------
--Eliminar productos huérfanos
--"Como técnico, deseo un procedimiento que elimine productos sin calificación ni empresa asociada."
--🧠 Explicación: Elimina productos de la tabla products que no tienen relación ni en rates ni en companyproducts.
---------------------------------------------------------------------------------------------------------------------

DELIMITER //

CREATE PROCEDURE eliminar_productos_huerfanos ()
BEGIN
    DELETE FROM products
    WHERE id NOT IN (SELECT DISTINCT id_producto FROM companyproducts)
      AND id NOT IN (
          SELECT DISTINCT cp.id_producto
          FROM companyproducts cp
          JOIN rates r ON r.id_producto_empresa = cp.id
      );
END;
//
DELIMITER ;

CALL eliminar_productos_huerfanos();