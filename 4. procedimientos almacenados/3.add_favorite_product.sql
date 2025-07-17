------------------------------------------------------------------------------------------------------------------------------------------------------
--Añadir producto favorito validando duplicados
--"Como cliente, quiero un procedimiento que añada un producto favorito y verifique duplicados."
--🧠 Explicación: Verifica si el producto ya está en favoritos (details_favorites). Si no lo está, lo inserta. Evita duplicaciones silenciosamente.
------------------------------------------------------------------------------------------------------------------------------------------------------

/*=============================================================
  Procedimiento: add_favorite_product
  Función      : Inserta un producto en una lista de favoritos evitando duplicados.
  Parámetros   :
      p_id_lista             INT  – ID de la lista de favoritos
      p_id_producto_empresa  INT  – ID del registro en companyproducts
=============================================================*/
DELIMITER //

CREATE PROCEDURE add_favorite_product (
    IN p_id_lista            INT,
    IN p_id_producto_empresa INT
)
BEGIN
    -- Si la combinación ya existe, no inserta nada
    IF NOT EXISTS (
        SELECT 1
        FROM details_favorites
        WHERE id_lista = p_id_lista
          AND id_producto_empresa = p_id_producto_empresa
    ) THEN
        INSERT INTO details_favorites (id_lista, id_producto_empresa)
        VALUES (p_id_lista, p_id_producto_empresa);
    END IF;
END;
//
DELIMITER ;

CALL add_favorite_product(3, 7);