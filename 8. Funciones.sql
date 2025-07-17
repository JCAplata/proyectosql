-- 1.  Obtener el promedio de calificación por producto
DELIMITER $$
CREATE FUNCTION calcular_promedio_ponderado(pid INT)
RETURNS DECIMAL(5,2)
DETERMINISTIC
BEGIN
  DECLARE resultado DECIMAL(5,2);
  SELECT SUM(r.puntuacion * (1 / DATEDIFF(CURDATE(), r.fecha))) / 
         SUM(1 / DATEDIFF(CURDATE(), r.fecha))
  INTO resultado
  FROM rates r
  WHERE r.id_producto_empresa = pid;
  RETURN IFNULL(resultado, 0);
END$$

DELIMITER $$
-- 2. ¿Es calificación reciente?
CREATE FUNCTION es_calificacion_reciente(fecha DATE)
RETURNS BOOLEAN
DETERMINISTIC
RETURN DATEDIFF(CURDATE(), fecha) <= 30
$$

DELIMITER $$
-- 3. Obtener nombre de empresa que vende el producto
CREATE FUNCTION obtener_empresa_producto(pid INT)
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
  DECLARE nombre_empresa VARCHAR(255);
  SELECT c.nombre INTO nombre_empresa
  FROM companyproducts cp
  JOIN companies c ON cp.id_empresa = c.id
  WHERE cp.id_producto = pid
  LIMIT 1;
  RETURN nombre_empresa;
END$$

DELIMITER $$
-- 4. ¿Cliente con membresía activa?
CREATE FUNCTION tiene_membresia_activa(cid INT)
RETURNS BOOLEAN
DETERMINISTIC
RETURN EXISTS (
  SELECT 1 
  FROM membershipperiods mp
  JOIN customers c ON c.id_membresia = mp.id_membresia
  WHERE c.id = cid
  AND CURDATE() BETWEEN inicio AND fin
  AND status = 'ACTIVA'
)$$

DELIMITER $$
-- 5. ¿Ciudad supera X empresas?
CREATE FUNCTION ciudad_supera_empresas(cid INT, limite INT)
RETURNS BOOLEAN
DETERMINISTIC
RETURN (
  (SELECT COUNT(*) FROM companies WHERE id_ciudad = cid) > limite
)$$

DELIMITER $$
-- 6. Descripción textual de calificación
CREATE FUNCTION descripcion_calificacion(valor INT)
RETURNS VARCHAR(20)
DETERMINISTIC
RETURN CASE
  WHEN valor = 5 THEN 'Excelente'
  WHEN valor = 4 THEN 'Bueno'
  WHEN valor = 3 THEN 'Regular'
  WHEN valor = 2 THEN 'Malo'
  ELSE 'Muy malo'
END$$

DELIMITER $$
-- 7. Estado del producto según su evaluación
CREATE FUNCTION estado_producto(pid INT)
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
  DECLARE promedio DECIMAL(5,2);
  SELECT AVG(puntuacion) INTO promedio FROM rates WHERE id_producto_empresa = pid;
  RETURN CASE
    WHEN promedio >= 4.5 THEN 'Óptimo'
    WHEN promedio >= 3.0 THEN 'Aceptable'
    ELSE 'Crítico'
  END;
END$$

DELIMITER $$
-- 8. ¿Es producto favorito del cliente?
CREATE FUNCTION es_favorito(cid INT, pid INT)
RETURNS BOOLEAN
DETERMINISTIC
RETURN EXISTS (
  SELECT 1 FROM favorites f
  JOIN details_favorites df ON f.id = df.id_lista
  WHERE f.id_cliente = cid AND df.id_producto_empresa = pid
)$$

DELIMITER $$
-- 9. ¿Beneficio asignado a audiencia?
CREATE FUNCTION beneficio_asignado_audiencia(bid INT, aid INT)
RETURNS BOOLEAN
DETERMINISTIC
RETURN EXISTS (
  SELECT 1 FROM audiencebenefits
  WHERE id_beneficio = bid AND id_audiencia = aid
)$$

DELIMITER $$
-- 10. ¿Fecha dentro de membresía activa?
CREATE FUNCTION fecha_en_membresia(fecha DATE, cid INT)
RETURNS BOOLEAN
DETERMINISTIC
RETURN EXISTS (
  SELECT 1 
  FROM membershipperiods mp
  JOIN customers c ON mp.id_membresia = c.id_membresia
  WHERE c.id = cid
    AND fecha BETWEEN mp.inicio AND mp.fin
)$$

DELIMITER $$
-- 11. Porcentaje de calificaciones positivas
CREATE FUNCTION porcentaje_positivas(pid INT)
RETURNS DECIMAL(5,2)
DETERMINISTIC
BEGIN
  DECLARE total INT;
  DECLARE positivas INT;
  SELECT COUNT(*) INTO total FROM rates WHERE id_producto_empresa = pid;
  SELECT COUNT(*) INTO positivas FROM rates WHERE id_producto_empresa = pid AND puntuacion >= 4;
  RETURN IFNULL((positivas / total) * 100, 0);
END$$

DELIMITER $$
-- 12. Edad de una calificación (en días)
CREATE FUNCTION edad_calificacion(fecha DATE)
RETURNS INT
DETERMINISTIC
RETURN DATEDIFF(CURDATE(), fecha)$$

DELIMITER $$
-- 13. Productos por empresa
CREATE FUNCTION productos_por_empresa(cid INT)
RETURNS INT
DETERMINISTIC
RETURN (
  SELECT COUNT(DISTINCT id_producto)
  FROM companyproducts
  WHERE id_empresa = cid
)$$

DELIMITER $$
-- 14. Nivel de actividad del cliente
CREATE FUNCTION nivel_actividad_cliente(cid INT)
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
  DECLARE total INT;
  SELECT COUNT(*) INTO total FROM rates WHERE id_cliente = cid;
  RETURN CASE
    WHEN total >= 10 THEN 'Frecuente'
    WHEN total >= 3 THEN 'Esporádico'
    ELSE 'Inactivo'
  END;
END$$

DELIMITER $$
-- 15. Precio promedio ponderado (favoritos)
CREATE FUNCTION precio_ponderado_favoritos(pid INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
  DECLARE total INT;
  DECLARE suma DECIMAL(10,2);
  SELECT COUNT(*), SUM(cp.precio)
  INTO total, suma
  FROM favorites f
  JOIN details_favorites df ON f.id = df.id_lista
  JOIN companyproducts cp ON cp.id_producto = df.id_producto_empresa
  WHERE df.id_producto_empresa = pid;
  RETURN IFNULL(suma / total, 0);
END$$

DELIMITER $$
-- 16. ¿Beneficio asignado a más de una entidad?
CREATE FUNCTION beneficio_compartido(bid INT)
RETURNS BOOLEAN
DETERMINISTIC
RETURN (
  (SELECT COUNT(*) FROM audiencebenefits WHERE id_beneficio = bid) +
  (SELECT COUNT(*) FROM membershipbenefits WHERE id_beneficio = bid)
) > 1$$

DELIMITER $$
-- 17. Índice de variedad por ciudad
CREATE FUNCTION indice_variedad(ciudad INT)
RETURNS DECIMAL(5,2)
DETERMINISTIC
BEGIN
  DECLARE empresas INT;
  DECLARE productos INT;
  SELECT COUNT(DISTINCT id) INTO empresas FROM companies WHERE id_ciudad = ciudad;
  SELECT COUNT(DISTINCT cp.id_producto)
  INTO productos
  FROM companyproducts cp
  JOIN companies c ON cp.id_empresa = c.id
  WHERE c.id_ciudad = ciudad;
  RETURN IFNULL(productos / empresas, 0);
END$$

DELIMITER $$
-- 18. ¿Debe desactivarse producto por baja calificación?
CREATE FUNCTION debe_desactivarse(pid INT)
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
  DECLARE promedio DECIMAL(5,2);
  SELECT AVG(puntuacion) INTO promedio FROM rates WHERE id_producto_empresa = pid;
  RETURN promedio < 2.5;
END$$

DELIMITER $$
-- 19. Índice de popularidad del producto
CREATE FUNCTION indice_popularidad(pid INT)
RETURNS DECIMAL(5,2)
DETERMINISTIC
BEGIN
  DECLARE favs INT;
  DECLARE califs INT;
  SELECT COUNT(*) INTO favs FROM details_favorites WHERE id_producto_empresa = pid;
  SELECT COUNT(*) INTO califs FROM rates WHERE id_producto_empresa = pid;
  RETURN favs + califs;
END$$

DELIMITER $$
-- 20. Código único para producto
CREATE FUNCTION codigo_unico_producto(nombre VARCHAR(255), fecha DATE)
RETURNS VARCHAR(100)
DETERMINISTIC
RETURN CONCAT(LEFT(REPLACE(nombre, ' ', ''), 5), '_', DATE_FORMAT(fecha, '%Y%m%d'));
$$
DELIMITER ;

-- 1. Promedio ponderado de calidad del producto 1
SELECT calcular_promedio_ponderado(1) AS promedio_ponderado;

-- 2. Verificar si una calificación del 2025-06-01 es reciente
SELECT es_calificacion_reciente('2025-06-01') AS es_reciente;

-- 3. Obtener el nombre de la empresa que vende el producto 1
SELECT obtener_empresa_producto(1) AS empresa_vendedora;

-- 4. Verificar si el cliente tiene una membresía activa
SELECT tiene_membresia_activa(3) AS membresia_activa;

-- 5. Verificar si la ciudad 1 tiene más de 10 empresas
SELECT ciudad_supera_empresas(1, 10) AS supera_empresas;

-- 6. Obtener la descripción de la calificación 4
SELECT descripcion_calificacion(4) AS descripcion;

-- 7. Consultar el estado del producto 1
SELECT estado_producto(1) AS estado_producto;

-- 8. Verificar si el producto 101 está en favoritos del cliente 45
SELECT es_favorito(45, 101) AS en_favoritos;

-- 9. Verificar si el beneficio 2 está asignado a la audiencia 5
SELECT beneficio_asignado_audiencia(2, 5) AS asignado;

-- 10. Verificar si '2025-05-10' está dentro de la membresía activa del cliente 45
SELECT fecha_en_membresia('2025-05-10', 45) AS esta_en_membresia;

-- 11. Calcular porcentaje de calificaciones positivas del producto 101
SELECT porcentaje_positivas(101) AS porcentaje_positivas;

-- 12. Calcular edad en días de una calificación hecha el 2025-06-01
SELECT edad_calificacion('2025-06-01') AS dias_transcurridos;

-- 13. Ver cuántos productos tiene registrados la empresa 20
SELECT productos_por_empresa(20) AS total_productos;

-- 14. Determinar el nivel de actividad del cliente 45
SELECT nivel_actividad_cliente(45) AS actividad;

-- 15. Calcular precio promedio ponderado del producto 101 según favoritos
SELECT precio_ponderado_favoritos(101) AS precio_ponderado;

-- 16. Verificar si el beneficio 2 está asignado a más de una entidad
SELECT beneficio_compartido(2) AS esta_en_multiples;

-- 17. Calcular índice de variedad de la ciudad 3
SELECT indice_variedad(3) AS variedad;

-- 18. Ver si el producto 101 debe ser desactivado por baja calificación
SELECT debe_desactivarse(101) AS desactivar;

-- 19. Ver el índice de popularidad del producto 101
SELECT indice_popularidad(101) AS popularidad;

-- 20. Generar un código único para el producto "Jabón Líquido" creado el 2025-07-01
SELECT codigo_unico_producto('Jabón Líquido', '2025-07-01') AS codigo_generado;

