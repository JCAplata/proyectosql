## A continuacion se mostrara aspectos fundamentales de este proyecto como (consultas, subconsultas, entre otros) 

# 0. creacion de la base de datos

# Consultas SQL Especializadas

## 1. Como analista, quiero listar todos los productos con su empresa asociada y el precio más bajo por ciudad.
-SELECT c.nombre AS ciudad, p.nombre AS producto, e.nombre AS empresa, MIN(cp.precio) AS precio_minimo
-FROM companyproducts cp
-JOIN companies e ON cp.id_empresa = e.id
-JOIN products p ON cp.id_producto = p.id
-JOIN citiesormunicipalities c ON e.id_ciudad = c.id
-GROUP BY c.nombre, p.nombre, e.nombre;

## 2. Como administrador, deseo obtener el top 5 de clientes que más productos han calificado en los últimos 6 meses.
SELECT cu.nombre, COUNT(r.id) AS total_calificaciones
FROM rates r
JOIN customers cu ON r.id_cliente = cu.id
WHERE r.fecha >= CURDATE() - INTERVAL 6 MONTH
GROUP BY cu.id
ORDER BY total_calificaciones DESC
LIMIT 5;

## 3. Como gerente de ventas, quiero ver la distribución de productos por categoría y unidad de medida.
SELECT p.categoria, cp.unidad_medida, COUNT(*) AS total
FROM companyproducts cp
JOIN products p ON cp.id_producto = p.id
GROUP BY p.categoria, cp.unidad_medida;

## 4. Como cliente, quiero saber qué productos tienen calificaciones superiores al promedio general.
SELECT p.nombre, AVG(r.puntuacion) AS promedio_producto
FROM rates r
JOIN companyproducts cp ON r.id_producto_empresa = cp.id
JOIN products p ON cp.id_producto = p.id
GROUP BY p.id
HAVING promedio_producto > (SELECT AVG(puntuacion) FROM rates);

## 5. Como auditor, quiero conocer todas las empresas que no han recibido ninguna calificación.
SELECT e.nombre
FROM companies e
LEFT JOIN companyproducts cp ON e.id = cp.id_empresa
LEFT JOIN rates r ON r.id_producto_empresa = cp.id
WHERE r.id IS NULL;

## 6. Como operador, deseo obtener los productos que han sido añadidos como favoritos por más de 10 clientes distintos.
SELECT p.nombre, COUNT(DISTINCT f.id_cliente) AS total_clientes
FROM details_favorites df
JOIN favorites f ON df.id_lista = f.id
JOIN companyproducts cp ON df.id_producto_empresa = cp.id
JOIN products p ON cp.id_producto = p.id
GROUP BY p.id
HAVING total_clientes > 10;

## 7. Como gerente regional, quiero obtener todas las empresas activas por ciudad y categoría.
SELECT c.nombre AS ciudad, e.categoria, COUNT(*) AS total_empresas
FROM companies e
JOIN citiesormunicipalities c ON e.id_ciudad = c.id
GROUP BY c.nombre, e.categoria;

## 8. Como especialista en marketing, deseo obtener los 10 productos más calificados en cada ciudad.
SELECT ciudad, nombre_producto, puntuacion_promedio FROM (
  SELECT c.nombre AS ciudad, p.nombre AS nombre_producto,
         AVG(r.puntuacion) AS puntuacion_promedio,
         RANK() OVER (PARTITION BY c.nombre ORDER BY AVG(r.puntuacion) DESC) AS ranking
  FROM rates r
  JOIN companyproducts cp ON r.id_producto_empresa = cp.id
  JOIN products p ON cp.id_producto = p.id
  JOIN companies e ON cp.id_empresa = e.id
  JOIN citiesormunicipalities c ON e.id_ciudad = c.id
  GROUP BY c.nombre, p.nombre
) AS sub
WHERE ranking <= 10;

## 9. Como técnico, quiero identificar productos sin unidad de medida asignada.
SELECT p.nombre
FROM companyproducts cp
JOIN products p ON cp.id_producto = p.id
WHERE cp.unidad_medida IS NULL OR cp.unidad_medida = '';

## 10. Como gestor de beneficios, deseo ver los planos de membresía sin beneficios registrados.
SELECT m.nombre
FROM memberships m
LEFT JOIN membershipbenefits mb ON m.id = mb.id_membresia
WHERE mb.id IS NULL;

## 11. Como supervisor, quiero obtener los productos de una categoría específica con su promedio de calificación.
SELECT p.nombre, p.categoria, AVG(r.puntuacion) AS promedio
FROM products p
JOIN companyproducts cp ON cp.id_producto = p.id
JOIN rates r ON r.id_producto_empresa = cp.id
-- WHERE p.categoria = 'Electrodomésticos' -- puedes cambiar esta categoría
GROUP BY p.id;

## 12. Como asesor, deseo obtener los clientes que han comprado productos de más de una empresa.
SELECT r.id_cliente, COUNT(DISTINCT cp.id_empresa) AS empresas_distintas
FROM rates r
JOIN companyproducts cp ON r.id_producto_empresa = cp.id
GROUP BY r.id_cliente
HAVING empresas_distintas > 1;

## 13. Como director, quiero identificar las ciudades con más clientes activos.
SELECT c.nombre, COUNT(*) AS total_clientes
FROM customers cu
JOIN citiesormunicipalities c ON cu.id_ciudad = c.id
GROUP BY c.id
ORDER BY total_clientes DESC;

## 14. Como analista de calidad, deseo obtener el ranking de productos por empresa basado en los medios de comunicación quality_products.
SELECT e.nombre AS empresa, p.nombre AS producto,
       AVG(CAST(q.resultado->>'$.calidad' AS SIGNED)) AS promedio_calidad
FROM quality_products q
JOIN companyproducts cp ON q.id_producto_empresa = cp.id
JOIN products p ON cp.id_producto = p.id
JOIN companies e ON cp.id_empresa = e.id
GROUP BY e.id, p.id
ORDER BY promedio_calidad DESC;

## 15. Como administrador, quiero listar empresas que ofrecen más de cinco productos distintos.
SELECT e.nombre, COUNT(DISTINCT cp.id_producto) AS total_productos
FROM companies e
JOIN companyproducts cp ON cp.id_empresa = e.id
GROUP BY e.id
HAVING total_productos > 5;

## 16. Como cliente, deseo visualizar los productos favoritos que aún no han sido calificados.
SELECT DISTINCT p.nombre
FROM details_favorites df
JOIN favorites f ON df.id_lista = f.id
JOIN companyproducts cp ON df.id_producto_empresa = cp.id
JOIN products p ON cp.id_producto = p.id
LEFT JOIN rates r ON r.id_producto_empresa = cp.id AND r.id_cliente = f.id_cliente
WHERE r.id IS NULL;

## 17. Como desarrollador, deseo consultar los beneficios asignados a cada audiencia junto con su descripción.
SELECT a.descripcion AS audiencia, b.descripcion AS beneficio
FROM audiencebenefits ab
JOIN audiences a ON ab.id_audiencia = a.id
JOIN benefits b ON ab.id_beneficio = b.id;

## 18. Como operador logístico, quiero saber en qué ciudades hay empresas sin productos asociados.
SELECT c.nombre
FROM citiesormunicipalities c
JOIN companies e ON c.id = e.id_ciudad
LEFT JOIN companyproducts cp ON e.id = cp.id_empresa
WHERE cp.id IS NULL;

## 19. Como técnico, deseo obtener todas las empresas con productos duplicados por nombre.
SELECT e.nombre, p.nombre, COUNT(*) AS total
FROM companies e
JOIN companyproducts cp ON cp.id_empresa = e.id
JOIN products p ON cp.id_producto = p.id
GROUP BY e.id, p.nombre
HAVING total > 1;

## 20. Como analista, quiero una vista resumen de clientes, productos favoritos y promedio de calificación recibida.
SELECT cu.nombre AS cliente, p.nombre AS producto,
       AVG(r.puntuacion) AS promedio_calificacion
FROM favorites f
JOIN customers cu ON f.id_cliente = cu.id
JOIN details_favorites df ON df.id_lista = f.id
JOIN companyproducts cp ON df.id_producto_empresa = cp.id
JOIN products p ON cp.id_producto = p.id
LEFT JOIN rates r ON r.id_producto_empresa = cp.id
GROUP BY cu.id, p.id;

# Subconsultas
## 1. Como gerente, quiero ver los productos cuyo precio esté por encima del promedio de su categoría.
SELECT p.nombre, p.categoria, cp.precio
FROM products p
JOIN companyproducts cp ON p.id = cp.id_producto
WHERE cp.precio > (
  SELECT AVG(cp2.precio)
  FROM companyproducts cp2
  JOIN products p2 ON cp2.id_producto = p2.id
  WHERE p2.categoria = p.categoria
);

## 2. Como administrador, deseo listar las empresas que tienen más productos que la media de empresas.
SELECT e.nombre, COUNT(DISTINCT cp.id_producto) AS total_productos
FROM companies e
JOIN companyproducts cp ON e.id = cp.id_empresa
GROUP BY e.id
HAVING total_productos > (
  SELECT AVG(productos_empresa)
  FROM (
    SELECT COUNT(DISTINCT cp2.id_producto) AS productos_empresa
    FROM companies e2
    JOIN companyproducts cp2 ON e2.id = cp2.id_empresa
    GROUP BY e2.id
  ) AS sub
);

## 3. Como cliente, quiero ver mis productos favoritos que han sido calificados por otros clientes.
SELECT DISTINCT p.nombre
FROM favorites f
JOIN details_favorites df ON f.id = df.id_lista
JOIN companyproducts cp ON df.id_producto_empresa = cp.id
JOIN products p ON cp.id_producto = p.id
JOIN rates r ON r.id_producto_empresa = cp.id
WHERE f.id_cliente = 1 
AND r.id_cliente <> f.id_cliente;

## 4. Como supervisor, deseo obtener los productos con el mayor número de veces añadidos como favoritos.
SELECT p.nombre, COUNT(*) AS total_favoritos
FROM details_favorites df
JOIN companyproducts cp ON df.id_producto_empresa = cp.id
JOIN products p ON cp.id_producto = p.id
GROUP BY p.id
ORDER BY total_favoritos DESC;

## 5. Como técnico, quiero listar los clientes cuyo correo no aparece en la tabla ratesni en quality_products.
SELECT cu.nombre, cu.correo
FROM customers cu
WHERE cu.correo NOT IN (
  SELECT cu1.correo
  FROM customers cu1
  JOIN rates r ON cu1.id = r.id_cliente
)
AND cu.correo NOT IN (
  SELECT cu2.correo
  FROM customers cu2
  JOIN quality_products q ON cu2.id = q.id_cliente
);

## 6. Como gestor de calidad, quiero obtener los productos con una calificación inferior al mínimo de su categoría.
SELECT p.nombre, AVG(r.puntuacion) AS promedio
FROM products p
JOIN companyproducts cp ON p.id = cp.id_producto
JOIN rates r ON r.id_producto_empresa = cp.id
GROUP BY p.id
HAVING promedio < (
  SELECT MIN(cat_prom)
  FROM (
    SELECT p2.categoria, AVG(r2.puntuacion) AS cat_prom
    FROM products p2
    JOIN companyproducts cp2 ON p2.id = cp2.id_producto
    JOIN rates r2 ON r2.id_producto_empresa = cp2.id
    GROUP BY p2.categoria
  ) AS sub
);

## 7. Como desarrollador, deseo listar las ciudades que no tienen clientes registrados.
SELECT c.nombre
FROM citiesormunicipalities c
LEFT JOIN customers cu ON cu.id_ciudad = c.id
WHERE cu.id IS NULL;

## 8. Como administrador, quiero ver los productos que no han sido evaluados en ninguna encuesta.
SELECT DISTINCT p.nombre
FROM products p
JOIN companyproducts cp ON cp.id_producto = p.id
LEFT JOIN quality_products q ON cp.id = q.id_producto_empresa
WHERE q.id IS NULL;

## 9. Como auditor, quiero listar los beneficios que no están asignados a ninguna audiencia.
SELECT b.descripcion
FROM benefits b
LEFT JOIN audiencebenefits ab ON b.id = ab.id_beneficio
WHERE ab.id IS NULL;

## 10. Como cliente, deseo obtener mis productos favoritos que no están disponibles actualmente en ninguna empresa.
SELECT DISTINCT p.nombre
FROM favorites f
JOIN details_favorites df ON df.id_lista = f.id
JOIN companyproducts cp ON df.id_producto_empresa = cp.id
JOIN products p ON cp.id_producto = p.id
LEFT JOIN companyproducts cp2 ON p.id = cp2.id_producto
WHERE f.id_cliente = 1 AND cp2.id IS NULL;

## 11. Como director, deseo consultar los productos vendidos en empresas cuya ciudad tenga menos de tres empresas registradas.
SELECT DISTINCT p.nombre
FROM companies e
JOIN citiesormunicipalities c ON e.id_ciudad = c.id
JOIN companyproducts cp ON cp.id_empresa = e.id
JOIN products p ON cp.id_producto = p.id
WHERE c.id IN (
  SELECT id_ciudad
  FROM companies
  GROUP BY id_ciudad
  HAVING COUNT(*) < 3
);

## 12. Como analista, quiero ver los productos con calidad superior al promedio de todos los productos.
SELECT p.nombre, AVG(CAST(q.resultado->>'$.calidad' AS UNSIGNED)) AS promedio
FROM quality_products q
JOIN companyproducts cp ON cp.id = q.id_producto_empresa
JOIN products p ON cp.id_producto = p.id
GROUP BY p.id
HAVING promedio > (
  SELECT AVG(CAST(resultado->>'$.calidad' AS UNSIGNED)) FROM quality_products
);

## 13. Como gestor, quiero ver empresas que sólo venden productos de una única categoría.
SELECT e.nombre
FROM companies e
JOIN companyproducts cp ON e.id = cp.id_empresa
JOIN products p ON cp.id_producto = p.id
GROUP BY e.id
HAVING COUNT(DISTINCT p.categoria) = 1;

## 14. Como gerente comercial, quiero consultar los productos con el mayor precio entre todas las empresas.
SELECT p.nombre, MAX(cp.precio) AS precio_maximo
FROM products p
JOIN companyproducts cp ON cp.id_producto = p.id
GROUP BY p.id
ORDER BY precio_maximo DESC;

## 15. Como cliente, quiero saber si algún producto de mis favoritos ha sido calificado por otro cliente con más de 4 estrellas.
SELECT DISTINCT p.nombre
FROM favorites f
JOIN details_favorites df ON df.id_lista = f.id
JOIN companyproducts cp ON df.id_producto_empresa = cp.id
JOIN products p ON cp.id_producto = p.id
JOIN rates r ON r.id_producto_empresa = cp.id
WHERE f.id_cliente = 1 
AND r.id_cliente <> f.id_cliente AND r.puntuacion > 4;

## 16. Como operador, quiero saber qué productos no tienen imagen asignada pero sí han sido calificados.
SELECT DISTINCT p.nombre
FROM products p
JOIN companyproducts cp ON cp.id_producto = p.id
JOIN rates r ON r.id_producto_empresa = cp.id
WHERE (p.imagen IS NULL OR p.imagen = '');

## 17. Como auditor, quiero ver los planos de membresía sin período vigente.
SELECT m.nombre
FROM memberships m
LEFT JOIN membershipperiods mp ON m.id = mp.id_membresia
WHERE CURDATE() not between mp.inicio and mp.fin;

## 18. Como especialista, quiero identificar los beneficios compartidos por más de una audiencia.
SELECT b.descripcion, COUNT(DISTINCT ab.id_audiencia) AS total_audiencias
FROM audiencebenefits ab
JOIN benefits b ON ab.id_beneficio = b.id
GROUP BY b.id
HAVING total_audiencias > 1;

## 19. Como técnico, quiero encontrar empresas cuyos productos no tengan unidad de medida definida.
SELECT DISTINCT e.nombre
FROM companies e
JOIN companyproducts cp ON cp.id_empresa = e.id
WHERE cp.unidad_medida IS NULL OR cp.unidad_medida = '';

## 20. Como gestor de campañas, deseo obtener los clientes con membresía activa y sin productos favoritos.
SELECT cu.nombre
FROM customers cu
JOIN membershipperiods mp ON mp.inicio <= CURDATE() AND mp.fin >= CURDATE()
LEFT JOIN favorites f ON f.id_cliente = cu.id
WHERE f.id IS NULL;

# Funciones Agregadas

## 1.  Obtener el promedio de calificación por producto "Como analista, quiero obtener el promedio de calificación por producto". 🔍 Explicación para dummies: La persona encargada de revisar el rendimiento quiere saber qué tan bien calificado está cada producto . Con AVG(rating)agrupado por product_id, puede verlo de forma resumida.

SELECT p.nombre, AVG(r.puntuacion) AS promedio
FROM rates r
JOIN companyproducts cp ON r.id_producto_empresa = cp.id
JOIN products p ON cp.id_producto = p.id
GROUP BY p.id;

## 2. Contar cuántos productos ha calificado cada cliente "Como gerente, desea cuántos productos ha calificado cada cliente". 🔍 Explicación: Aquí se quiere saber quiénes están activos opinando . Se usa COUNT(*)sobre rates, agrupando por customer_id.

SELECT cu.nombre, COUNT(*) AS total_calificados
FROM rates r
JOIN customers cu ON r.id_cliente = cu.id
GROUP BY cu.id;

## 3. Sumar el total de beneficios asignados por audiencia "Como auditor, quiere sumar el total de beneficios asignados por audiencia". 🔍 Explicación: El auditor busca cuántos beneficios tiene cada tipo de usuario . Con COUNT(*)agrupado por audience_iden audiencebenefits, lo obtiene.

SELECT a.descripcion AS audiencia, COUNT(*) AS total_beneficios
FROM audiencebenefits ab
JOIN audiences a ON ab.id_audiencia = a.id
GROUP BY ab.id_audiencia;

## 4. Calcular los medios de productos por empresa "Como administrador, desea conocer los medios de productos de la empresa." 🔍 Explicación: El administrador quiere saber si las empresas están ofreciendo pocos o muchos productos . Cuenta los productos por empresa y saca el promedio con AVG(cantidad).

SELECT id_empresa, c.nombre, AVG(productos) AS media_productos 
FROM (
  SELECT cp.id_empresa, COUNT(cp.id_producto) AS productos
  FROM companyproducts cp
  GROUP BY cp.id_empresa
) AS sub
JOIN companies AS c ON c.id = sub.id_empresa
GROUP BY id_empresa, c.nombre;

## 5. Contar el total de empresas por ciudad "Como supervisor, quiere ver el total de empresas por ciudad".  🔍 Explicación: La idea es ver en qué ciudades hay más movimiento empresarial . Se usa COUNT(*)en companies, agrupando por city_id.

SELECT c.nombre AS ciudad, COUNT(*) AS total_empresas
FROM companies e
JOIN citiesormunicipalities c ON e.id_ciudad = c.id
GROUP BY c.id;

## 6. Calcular el promedio de precios por unidad de medida "Como técnico, desea obtener el promedio de precios de productos por unidad de medida." 🔍 Explicación: Se necesita saber si los precios son coherentes según el tipo de medida . Con AVG(price)agrupado por unit_id, se compara cuánto el litro, kilo, unidad, etc.

SELECT unidad_medida, AVG(precio) AS promedio_precio
FROM companyproducts
GROUP BY unidad_medida;

## 7. Contar cuántos clientes hay por ciudad "Como gerente, quiere ver el número de clientes registrados por cada ciudad". 🔍 Explicación: Con COUNT(*)agrupado por city_iden la tabla customers, se obtiene la cantidad de clientes que hay en cada zona .

SELECT c.nombre AS ciudad, COUNT(*) AS total_clientes
FROM customers cu
JOIN citiesormunicipalities c ON cu.id_ciudad = c.id
GROUP BY c.id;

## 8. Calcular planes de membresía por periodo "Como operador, desea contar cuántos planes de membresía existen por período." 🔍 Explicación: Sirve para ver qué tantos aviones están vigentes cada mes o trimestre . Se agrupa por periodo ( start_date, end_date) y se cuenta cuántos registros hay.

SELECT inicio, fin, COUNT(*) AS total_planes
FROM membershipperiods
GROUP BY inicio, fin;

## 9. Ver el promedio de calificaciones dadas por un cliente a sus favoritos "Como cliente, quiere ver el promedio de calificaciones que ha otorgado a sus productos favoritos". 🔍 Explicación: El cliente quiere saber cómo ha calificado lo que más le gusta . Se hace un JOINentre favoritos y calificaciones, y se saca AVG(rating).

SELECT cu.nombre, AVG(r.puntuacion) AS promedio_favoritos
FROM favorites f
JOIN customers cu ON f.id_cliente = cu.id
JOIN details_favorites df ON df.id_lista = f.id
JOIN companyproducts cp ON cp.id = df.id_producto_empresa
JOIN rates r ON r.id_producto_empresa = cp.id AND r.id_cliente = cu.id
GROUP BY cu.id;

## 10.  Consultar la fecha más reciente en que se calificó un producto "Como auditor, desea obtener la fecha más reciente en la que se calificó un producto." 🔍 Explicación: Busca el MAX(created_at)agrupado por producto. Así sabe cuál fue la última vez que se evaluó cada uno .

SELECT p.nombre, MAX(r.fecha) AS ultima_calificacion
FROM rates r
JOIN companyproducts cp ON r.id_producto_empresa = cp.id
JOIN products p ON cp.id_producto = p.id
GROUP BY p.id;

## 11. Obtener la desviación estándar de precios por categoría "Como desarrollador, quiere conocer la variación de precios por categoría de producto". 🔍 Explicación: Usando STDDEV(price)en companyproductsagrupado por category_id, se puede ver si hay mucha diferencia de precios dentro de una categoría .

SELECT p.categoria, STDDEV(cp.precio) AS desviacion_precio
FROM products p
JOIN companyproducts cp ON cp.id_producto = p.id
GROUP BY p.categoria;

## 12. Contar cuantas veces un producto fue favorito "Como técnico, desea contar cuántas veces un producto fue marcado como favorito." 🔍 Explicación: Con COUNT(*)en details_favorites, agrupado por product_id, se obtiene cuáles productos son los más populares entre los clientes .

SELECT p.nombre, COUNT(*) AS total_favorito
FROM details_favorites df
JOIN companyproducts cp ON df.id_producto_empresa = cp.id
JOIN products p ON cp.id_producto = p.id
GROUP BY p.id;

## 13. Calcular el porcentaje de productos evaluados "Como director, quiere saber qué porcentaje de productos han sido calificados al menos una vez." 🔍 Explicación: Cuenta cuántos productos hay en total y cuántos han sido evaluados ( rates). Luego calcula (evaluados / total) * 100.  

SELECT 
  (SELECT COUNT(DISTINCT cp.id_producto) FROM companyproducts cp JOIN rates r ON cp.id = r.id_producto_empresa) 
  / 
  (SELECT COUNT(*) FROM products) * 100 AS porcentaje_evaluados;

## 14. Ver el promedio de rating por encuesta "Como analista, deseo conocer el promedio de rating por encuesta." 🔍 Explicación: Agrupa por poll_iden rates, y calcula el AVG(rating)para ver cómo se comporta cada encuesta .

SELECT po.titulo, AVG(CAST(q.resultado->>'$.calidad' AS UNSIGNED)) AS promedio
FROM quality_products q
JOIN polls po ON q.id_encuesta = po.id
GROUP BY po.id;

## 15. Calcular el promedio y total de beneficios por plan "Como gestor, quiere obtener el promedio y el total de beneficios asignados a cada plan de membresía". 🔍 Explicación: Agrupa por membership_iden membershipbenefits, y usa COUNT(*)y AVG(beneficio)si aplica (si hay ponderación).

SELECT m.nombre, COUNT(mb.id_beneficio) AS total_beneficios
FROM memberships m
LEFT JOIN membershipbenefits mb ON m.id = mb.id_membresia
GROUP BY m.id;

## 16. Obtener media y variación de precios por empresa "Como gerente, desea obtener la media y la variación del precio de productos por empresa." 🔍 Explicación: Se agrupa por company_idy se usa AVG(price)y VARIANCE(price)para saber qué tan consistentes son los precios por empresa .

SELECT e.nombre, AVG(cp.precio) AS media_precio, VARIANCE(cp.precio) AS varianza_precio
FROM companies e
JOIN companyproducts cp ON cp.id_empresa = e.id
GROUP BY e.id;

## 17. Ver total de productos disponibles en la ciudad del cliente "Como cliente, quiere ver cuántos productos están disponibles en su ciudad". 🔍 Explicación: Hace un JOINentre companies, companyproductsy citiesormunicipalities, filtrando por la ciudad del cliente. Luego se cuenta.

SELECT cu.nombre AS cliente, COUNT(DISTINCT cp.id_producto) AS total_productos
FROM customers cu
JOIN companies e ON cu.id_ciudad = e.id_ciudad
JOIN companyproducts cp ON cp.id_empresa = e.id
WHERE cu.id = 1
GROUP BY cu.id;

## 18. Contar productos únicos por tipo de empresa "Como administrador, desea contar los productos únicos por tipo de empresa." 🔍 Explicación: Agrupa por company_type_idy cuenta cuántos productos diferentes tiene cada tipo de empresa.

SELECT e.tipo, COUNT(DISTINCT cp.id_producto) AS productos_unicos
FROM companies e
JOIN companyproducts cp ON cp.id_empresa = e.id
GROUP BY e.tipo;

## 19. Ver total de clientes sin correo electrónico registrado "Como operador, quiere saber cuántos clientes no han registrado su correo". 🔍 Explicación: Filtra customers WHERE email IS NULLy hace un COUNT(*). Esto ayuda a mejorar la base de datos para campañas.

SELECT COUNT(*) AS total_sin_correo
FROM customers
WHERE correo IS NULL OR correo = '';


## 20. Empresa con más productos calificados "Como especialista, desea obtener la empresa con el mayor número de productos calificados." 🔍 Explicación: Hace un JOINentre companies, companyproducts, y rates, grupo por empresa y usa COUNT(DISTINCT product_id), ordenando en orden descendente y tomando solo el primero.

SELECT e.nombre, COUNT(DISTINCT cp.id_producto) AS total_calificados
FROM companies e
JOIN companyproducts cp ON e.id = cp.id_empresa
JOIN rates r ON r.id_producto_empresa = cp.id
GROUP BY e.id
ORDER BY total_calificados DESC
LIMIT 1;

# Triggers 

DELIMITER //

## 1. Actualizar la fecha de modificación de un producto "Como desarrollador, deseo un trigger que actualice la fecha de modificación cuando se actualice un producto." 🧠 Explicación: Cada vez que se actualiza un producto, queremos que el campo updated_at se actualice automáticamente con la fecha actual (NOW()), sin tener que hacerlo manualmente desde la app. 🔁 Se usa un BEFORE UPDATE.

CREATE TRIGGER trg_update_product_updated_at
BEFORE UPDATE ON products
FOR EACH ROW
BEGIN
  SET NEW.updated_at = NOW();
END;

DELIMITER //

## 2. Registrar log cuando un cliente califica un producto "Como administrador, quiero un trigger que registre en log cuando un cliente califica un producto." 🧠 Explicación: Cuando alguien inserta una fila en rates, el trigger crea automáticamente un registro en log_acciones con la información del cliente y producto calificado. 🔁 Se usa un AFTER INSERT sobre rates.

CREATE TRIGGER trg_log_calificacion
AFTER INSERT ON rates
FOR EACH ROW
BEGIN
  INSERT INTO log_acciones (entidad, id_entidad, descripcion, fecha)
  VALUES ('rates', NEW.id, CONCAT('Cliente ', NEW.id_cliente, ' calificó producto ', NEW.id_producto_empresa), NOW());
END;

DELIMITER //

## 3. Impedir insertar productos sin unidad de medida "Como técnico, deseo un trigger que impida insertar productos sin unidad de medida." 🧠 Explicación: Antes de guardar un nuevo producto, el trigger revisa si unit_id es NULL. Si lo es, lanza un error con SIGNAL. 🔁 Se usa un BEFORE INSERT.

CREATE TRIGGER trg_no_unit_producto
BEFORE INSERT ON products
FOR EACH ROW
BEGIN
  IF NEW.unidad_medida IS NULL THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'El producto debe tener unidad de medida';
  END IF;
END;

DELIMITER //

## 4. Validar calificaciones no mayores a 5 "Como auditor, quiero un trigger que verifique que las calificaciones no superen el valor máximo permitido." 🧠 Explicación: Si alguien intenta insertar una calificación de 6 o más, se bloquea automáticamente. Esto evita errores o trampa. 🔁 Se usa un BEFORE INSERT.

CREATE TRIGGER trg_valida_rating
BEFORE INSERT ON rates
FOR EACH ROW
BEGIN
  IF NEW.puntuacion > 5 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'La calificación no puede superar 5';
  END IF;
END;

DELIMITER //

## 5. Actualizar estado de membresía cuando vence "Como supervisor, deseo un trigger que actualice automáticamente el estado de membresía al vencer el periodo." 🧠 Explicación: Cuando se actualiza un periodo de membresía (membershipperiods), si end_date ya pasó, se puede cambiar el campo status a 'INACTIVA'. 🔁 AFTER UPDATE o BEFORE UPDATE dependiendo de la lógica.

CREATE TRIGGER trg_update_estado_membresia
BEFORE UPDATE ON membershipperiods
FOR EACH ROW
BEGIN
  IF NEW.fin < NOW() THEN
    SET NEW.status = 'INACTIVA';
  END IF;
END;

DELIMITER //

## 6. Evitar duplicados de productos por empresa "Como operador, quiero un trigger que evite duplicar productos por nombre dentro de una misma empresa." 🧠 Explicación: Antes de insertar un nuevo producto en companyproducts, el trigger puede consultar si ya existe uno con el mismo product_id y company_id. 🔁 BEFORE INSERT.

CREATE TRIGGER trg_no_duplicado_producto_empresa
BEFORE INSERT ON companyproducts
FOR EACH ROW
BEGIN
  IF EXISTS (
    SELECT 1 FROM companyproducts
    WHERE id_empresa = NEW.id_empresa AND id_producto = NEW.id_producto
  ) THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Este producto ya está asociado a esta empresa';
  END IF;
END;

DELIMITER //

## 7. Enviar notificación al añadir un favorito "Como cliente, deseo un trigger que envíe notificación cuando añado un producto como favorito." 🧠 Explicación: Después de un INSERT en details_favorites, el trigger agrega un mensaje a una tabla notificaciones. 🔁 AFTER INSERT.

CREATE TRIGGER trg_notificacion_favorito
AFTER INSERT ON details_favorites
FOR EACH ROW
BEGIN
  DECLARE v_client INT;
  SET v_client = (SELECT id_cliente FROM favorites WHERE id = NEW.id_lista LIMIT 1);
    
  INSERT INTO notificaciones (cliente_id, mensaje, fecha)
  VALUES (v_client, CONCAT('Has añadido el producto ', NEW.id_producto_empresa, ' a favoritos'), NOW());
END;

DELIMITER //

## 8. Insertar fila en quality_products tras calificación "Como técnico, quiero un trigger que inserte una fila en quality_products cuando se registra una calificación." 🧠 Explicación: Al insertar una nueva calificación en rates, se crea automáticamente un registro en quality_products para mantener métricas de calidad. 🔁 AFTER INSERT.

CREATE TRIGGER trg_insert_quality
AFTER INSERT ON rates
FOR EACH ROW
BEGIN
  INSERT INTO quality_products (id_encuesta, id_producto_empresa, id_cliente, puntuacion)
  VALUES (1, NEW.id_producto_empresa, NEW.id_cliente, NEW.puntuacion);
END;

DELIMITER //
## 9. Eliminar favoritos si se elimina el producto "Como desarrollador, deseo un trigger que elimine los favoritos si se elimina el producto." 🧠 Explicación: Cuando se borra un producto, el trigger elimina las filas en details_favorites donde estaba ese producto. 🔁 AFTER DELETE en products.

CREATE TRIGGER trg_delete_favoritos_con_producto
AFTER DELETE ON products
FOR EACH ROW
BEGIN
  DELETE FROM details_favorites WHERE product_id = OLD.id;
END;

DELIMITER //

## 10. Bloquear modificación de audiencias activas "Como administrador, quiero un trigger que bloquee la modificación de audiencias activas." 🧠 Explicación: Si un usuario intenta modificar una audiencia que está en uso, el trigger lanza un error con SIGNAL. 🔁 BEFORE UPDATE.

CREATE TRIGGER trg_bloquear_audiencia_activa
BEFORE UPDATE ON audiences
FOR EACH ROW
BEGIN
  IF EXISTS (
    SELECT 1 FROM customers
    WHERE id_audiencia = OLD.id
  ) THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Esta audiencia esta en uso y no se puede modificar';
  END IF;
END;

DELIMITER //

## 11. Recalcular promedio de calidad del producto tras nueva evaluación "Como gestor, deseo un trigger que actualice el promedio de calidad del producto tras una nueva evaluación." 🧠 Explicación: Después de insertar en rates, el trigger actualiza el campo average_rating del producto usando AVG(). 🔁 AFTER INSERT.

CREATE TRIGGER trg_update_promedio_rating
AFTER INSERT ON rates
FOR EACH ROW
BEGIN
  UPDATE products p
  JOIN companyproducts cp ON cp.id_producto = p.id
  SET p.prom_califica = (
    SELECT ROUND(AVG(r.puntuacion),2)
    FROM rates r
    WHERE r.id_producto_empresa = cp.id
  )
  WHERE cp.id = NEW.id_producto_empresa;
END;

DELIMITER //

## 12. Registrar asignación de nuevo beneficio Como auditor, quiero un trigger que registre cada vez que se asigna un nuevo beneficio." 🧠 Explicación: Cuando se hace INSERT en membershipbenefits o audiencebenefits, se agrega un log en bitacora.

CREATE TRIGGER trg_log_beneficio_membresia
AFTER INSERT ON membershipbenefits
FOR EACH ROW
BEGIN
  INSERT INTO log_acciones (entidad, id_entidad, descripcion, fecha)
  VALUES ('memberships', NEW.id, CONCAT('Se asignó beneficio ', NEW.id_beneficio, ' al plan '), NOW());
END;

DELIMITER //

## 13. Impedir doble calificación por parte del cliente "Como cliente, deseo un trigger que me impida calificar el mismo producto dos veces seguidas." 🧠 Explicación: Antes de insertar en rates, el trigger verifica si ya existe una calificación de ese customer_id y product_id.

CREATE TRIGGER trg_no_doble_calificacion
BEFORE INSERT ON rates
FOR EACH ROW
BEGIN
  IF EXISTS (
    SELECT 1 FROM rates
    WHERE id_cliente = NEW.id_cliente AND id_producto_empresa = NEW.id_producto_empresa
  ) THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Este cliente ya calificó este producto';
  END IF;
END;

DELIMITER //

## 14. Validar correos duplicados en clientes "Como técnico, quiero un trigger que valide que el email del cliente no se repita." 🧠 Explicación: Verifica, antes del INSERT, si el correo ya existe en la tabla customers. Si sí, lanza un error.

CREATE TRIGGER trg_email_unico_cliente
BEFORE INSERT ON customers
FOR EACH ROW
BEGIN
  IF EXISTS (
    SELECT 1 FROM customers WHERE correo = NEW.correo
  ) THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'El email ya está registrado';
  END IF;
END;

DELIMITER //

## 15.  Eliminar detalles de favoritos huérfanos "Como operador, deseo un trigger que elimine registros huérfanos de details_favorites." 🧠 Explicación: Si se elimina un registro de favorites, se borran automáticamente sus detalles asociados.

CREATE TRIGGER trg_delete_detalles_favoritos
AFTER DELETE ON favorites
FOR EACH ROW
BEGIN
  DELETE FROM details_favorites WHERE id_lista = OLD.id;
END;

DELIMITER //

## 16. Actualizar campo updated_at en companies "Como administrador, quiero un trigger que actualice el campo updated_at en companies." 🧠 Explicación: Como en productos, actualiza automáticamente la fecha de última modificación cada vez que se cambia algún dato.

CREATE TRIGGER trg_update_company_updated_at
BEFORE UPDATE ON companies
FOR EACH ROW
BEGIN
  SET NEW.updated_at = NOW();
END;

DELIMITER //

## 17. Impedir borrar ciudad si hay empresas activas "Como desarrollador, deseo un trigger que impida borrar una ciudad si hay empresas activas en ella." 🧠 Explicación: Antes de hacer DELETE en citiesormunicipalities, el trigger revisa si hay empresas registradas en esa ciudad.

CREATE TRIGGER trg_bloqueo_ciudad_empresas
BEFORE DELETE ON citiesormunicipalities
FOR EACH ROW
BEGIN
  IF EXISTS (
    SELECT 1 FROM companies WHERE id_ciudad = OLD.id
  ) THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'No se puede eliminar una ciudad con empresas registradas';
  END IF;
END;

DELIMITER //

## 18.  Registrar cambios de estado en encuestas "Como auditor, quiero un trigger que registre cambios de estado de encuestas." 🧠 Explicación: Cada vez que se actualiza el campo status en polls, el trigger guarda la fecha, nuevo estado y usuario en un log.

CREATE TRIGGER trg_log_estado_poll
AFTER UPDATE ON polls
FOR EACH ROW
BEGIN
  IF OLD.status <> NEW.status THEN
    INSERT INTO log_estados (entidad, id_entidad, estado_nuevo, fecha)
    VALUES ('polls', NEW.id, NEW.status, NOW());
  END IF;
END;

DELIMITER //

## 19. Sincronizar rates y quality_products "Como supervisor, deseo un trigger que sincronice rates con quality_products al calificar." 🧠 Explicación: Inserta o actualiza la calidad del producto en quality_products cada vez que se inserta una nueva calificación.

CREATE TRIGGER trg_sync_rates_quality
AFTER INSERT ON rates
FOR EACH ROW
BEGIN
  INSERT INTO quality_products (id_encuesta, id_producto_empresa, id_cliente, resultado)
  VALUES (1, NEW.id_producto_empresa, NEW.id_cliente, NEW.puntuacion)
  ON DUPLICATE KEY UPDATE resultado = NEW.puntuacion;
END;

DELIMITER //

## 20. Eliminar productos sin relación a empresas "Como operador, quiero un trigger que elimine automáticamente productos sin relación a empresas." 🧠 Explicación: Después de borrar la última relación entre un producto y una empresa (companyproducts), el trigger puede eliminar ese producto.

CREATE TRIGGER trg_delete_producto_huerfano
AFTER DELETE ON companyproducts
FOR EACH ROW
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM companyproducts WHERE id_producto = OLD.id_producto
  ) THEN
    DELETE FROM products WHERE id = OLD.id_producto;
  END IF;
END;

//

# Eventos

## 1. Borrar productos sin actividad cada 6 meses. Historia: Como administrador, quiero un evento que borre productos sin actividad cada 6 meses. 🧠 Explicación: Algunos productos pueden haber sido creados pero nunca calificados, marcados como favoritos ni asociados a una empresa. Este evento eliminaría esos productos cada 6 meses. 🛠️ Se usaría un DELETE sobre products donde no existan registros en rates, favorites ni companyproducts. 📅 Frecuencia del evento: EVERY 6 MONTH

CREATE EVENT IF NOT EXISTS ev_eliminar_productos_huerfanos
ON SCHEDULE EVERY 6 MONTH
STARTS CURRENT_TIMESTAMP
DO
  CALL eliminar_productos_huerfanos();
  
## 2. Recalcular el promedio de calificaciones semanalmente. Historia: Como supervisor, deseo un evento semanal que recalcula el promedio de calificaciones. 🧠 Explicación: Se puede tener una tabla product_metrics que almacena promedios pre-calculados para rapidez. El evento actualizaría esa tabla con nuevos promedios. 🛠️ Usa UPDATE con AVG(rating) agrupado por producto. 📅 Frecuencia: EVERY 1 WEEK

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

## 3. Actualizar precios según inflación mensual. Historia: Como operador, quiero un evento mensual que actualice los precios de productos por inflación. 🧠 Explicación: Aplicar un porcentaje de aumento (por ejemplo, 3%) a los precios de todos los productos. 🛠️ UPDATE companyproducts SET price = price * 1.03; 📅 Frecuencia: EVERY 1 MONTH

CREATE EVENT IF NOT EXISTS ev_ajustar_precios_inflacion
ON SCHEDULE EVERY 1 MONTH
STARTS CURRENT_TIMESTAMP
DO
  UPDATE companyproducts
  SET price = ROUND(price * 1.03, 2);

## 4. Crear backups lógicos diariamente. Historia: Como auditor, deseo un evento que genere un backup lógico cada medianoche. 🧠 Explicación: Este evento no ejecuta comandos del sistema, pero puede volcar datos clave a una tabla temporal o de respaldo (products_backup, rates_backup, etc.). 📅 EVERY 1 DAY STARTS '00:00:00'

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

## 5. Notificar sobre productos favoritos sin calificar. Historia: Como cliente, quiero un evento que me recuerde los productos que tengo en favoritos y no he calificado. 🧠 Explicación: Genera una lista (user_reminders) de product_id donde el cliente tiene el producto en favoritos pero no hay rate. 🛠️ Requiere INSERT INTO recordatorios usando un LEFT JOIN y WHERE rate IS NULL.

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

## 6. Revisar inconsistencias entre empresa y productos. Historia: Como técnico, deseo un evento que revise inconsistencias entre empresas y productos cada domingo. 🧠 Explicación: Detecta productos sin empresa, o empresas sin productos, y los registra en una tabla de anomalías. 🛠️ Puede usar NOT EXISTS y JOIN para llenar una tabla errores_log. 📅 EVERY 1 WEEK ON SUNDAY

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

## 7. Archivar membresías vencidas diariamente. Historia: Como administrador, quiero un evento que archive membresías vencidas. 🧠 Explicación: Cambia el estado de la membresía cuando su end_date ya pasó. 🛠️ UPDATE membershipperiods SET status = 'INACTIVA' WHERE end_date < CURDATE();

CREATE EVENT IF NOT EXISTS ev_archivar_membresias_vencidas
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO
  UPDATE membershipperiods
  SET status = 'INACTIVA'
  WHERE fin < CURDATE();

## 8. Notificar beneficios nuevos a usuarios semanalmente. Historia: Como supervisor, deseo un evento que notifique por correo sobre beneficios nuevos. 🧠 Explicación: Detecta registros nuevos en la tabla benefits desde la última semana y los inserta en notificaciones. 🛠️ INSERT INTO notificaciones SELECT ... WHERE created_at >= NOW() - INTERVAL 7 DAY

CREATE EVENT IF NOT EXISTS ev_notificar_beneficios_nuevos
ON SCHEDULE EVERY 1 WEEK
STARTS CURRENT_TIMESTAMP
DO
  INSERT INTO notificaciones (mensaje, fecha)
  SELECT CONCAT('Nuevo beneficio: ', descripcion),
         NOW()
  FROM benefits
  WHERE created_at >= NOW() - INTERVAL 7 DAY;

## 9. Calcular cantidad de favoritos por cliente mensualmente. Historia: Como operador, quiero un evento que calcule el total de favoritos por cliente y lo guarde. 🧠 Explicación: Cuenta los productos favoritos por cliente y guarda el resultado en una tabla de resumen mensual (favoritos_resumen). 🛠️ INSERT INTO favoritos_resumen SELECT customer_id, COUNT(*) ... GROUP BY customer_id

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

## 10. Validar claves foráneas semanalmente. Historia: Como auditor, deseo un evento que valide claves foráneas semanalmente y reporte errores. 🧠 Explicación: Comprueba que cada product_id, customer_id, etc., tengan correspondencia en sus tablas. Si no, se registra en una tabla inconsistencias_fk.

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