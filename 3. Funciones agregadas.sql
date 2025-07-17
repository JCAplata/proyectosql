----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 1.  Obtener el promedio de calificación por producto
--"Como analista, quiero obtener el promedio de calificación por producto".
--🔍 Explicación para dummies: La persona encargada de revisar el rendimiento quiere saber qué tan bien calificado está cada producto . Con AVG(rating)agrupado por product_id, puede verlo de forma resumida.
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT p.nombre, AVG(r.puntuacion) AS promedio
FROM rates r
JOIN companyproducts cp ON r.id_producto_empresa = cp.id
JOIN products p ON cp.id_producto = p.id
GROUP BY p.id;

--------------------------------------------------------------------------------------------------------------------------------
-- 2. Contar cuántos productos ha calificado cada cliente
--"Como gerente, desea cuántos productos ha calificado cada cliente".
--🔍 Explicación: Aquí se quiere saber quiénes están activos opinando . Se usa COUNT(*)sobre rates, agrupando por customer_id.
-------------------------------------------------------------------------------------------------------------------------------
SELECT cu.nombre, COUNT(*) AS total_calificados
FROM rates r
JOIN customers cu ON r.id_cliente = cu.id
GROUP BY cu.id;

---------------------------------------------------------------------------------------------------------------------------------------------------------
-- 3. Sumar el total de beneficios asignados por audiencia
--"Como auditor, quiere sumar el total de beneficios asignados por audiencia".
--🔍 Explicación: El auditor busca cuántos beneficios tiene cada tipo de usuario . Con COUNT(*)agrupado por audience_iden audiencebenefits, lo obtiene.
--------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT a.descripcion AS audiencia, COUNT(*) AS total_beneficios
FROM audiencebenefits ab
JOIN audiences a ON ab.id_audiencia = a.id
GROUP BY ab.id_audiencia;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 4. Calcular los medios de productos por empresa
--"Como administrador, desea conocer los medios de productos de la empresa."
--🔍 Explicación: El administrador quiere saber si las empresas están ofreciendo pocos o muchos productos . Cuenta los productos por empresa y saca el promedio con AVG(cantidad).
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT id_empresa, c.nombre, AVG(productos) AS media_productos 
FROM (
  SELECT cp.id_empresa, COUNT(cp.id_producto) AS productos
  FROM companyproducts cp
  GROUP BY cp.id_empresa
) AS sub
JOIN companies AS c ON c.id = sub.id_empresa
GROUP BY id_empresa, c.nombre;

----------------------------------------------------------------------------------------------------------------------------------------
-- 5. Contar el total de empresas por ciudad
--"Como supervisor, quiere ver el total de empresas por ciudad".
--🔍 Explicación: La idea es ver en qué ciudades hay más movimiento empresarial . Se usa COUNT(*)en companies, agrupando por city_id.
----------------------------------------------------------------------------------------------------------------------------------------
SELECT c.nombre AS ciudad, COUNT(*) AS total_empresas
FROM companies e
JOIN citiesormunicipalities c ON e.id_ciudad = c.id
GROUP BY c.id;

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 6. Calcular el promedio de precios por unidad de medida
--"Como técnico, desea obtener el promedio de precios de productos por unidad de medida."
--🔍 Explicación: Se necesita saber si los precios son coherentes según el tipo de medida . Con AVG(price)agrupado por unit_id, se compara cuánto el litro, kilo, unidad, etc.
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT unidad_medida, AVG(precio) AS promedio_precio
FROM companyproducts
GROUP BY unidad_medida;

--------------------------------------------------------------------------------------------------------------------------------------
-- 7. Contar cuántos clientes hay por ciudad
--"Como gerente, quiere ver el número de clientes registrados por cada ciudad".
--🔍 Explicación: Con COUNT(*)agrupado por city_iden la tabla customers, se obtiene la cantidad de clientes que hay en cada zona .
--------------------------------------------------------------------------------------------------------------------------------------
SELECT c.nombre AS ciudad, COUNT(*) AS total_clientes
FROM customers cu
JOIN citiesormunicipalities c ON cu.id_ciudad = c.id
GROUP BY c.id;

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 8. Calcular planes de membresía por periodo
--"Como operador, desea contar cuántos planes de membresía existen por período."
--🔍 Explicación: Sirve para ver qué tantos aviones están vigentes cada mes o trimestre . Se agrupa por periodo ( start_date, end_date) y se cuenta cuántos registros hay.
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT inicio, fin, COUNT(*) AS total_planes
FROM membershipperiods
GROUP BY inicio, fin;

------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 9. Ver el promedio de calificaciones dadas por un cliente a sus favoritos
--"Como cliente, quiere ver el promedio de calificaciones que ha otorgado a sus productos favoritos".
--🔍 Explicación: El cliente quiere saber cómo ha calificado lo que más le gusta . Se hace un JOINentre favoritos y calificaciones, y se saca AVG(rating).
------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT cu.nombre, AVG(r.puntuacion) AS promedio_favoritos
FROM favorites f
JOIN customers cu ON f.id_cliente = cu.id
JOIN details_favorites df ON df.id_lista = f.id
JOIN companyproducts cp ON cp.id = df.id_producto_empresa
JOIN rates r ON r.id_producto_empresa = cp.id AND r.id_cliente = cu.id
GROUP BY cu.id;

---------------------------------------------------------------------------------------------------------------------------
-- 10.  Consultar la fecha más reciente en que se calificó un producto
--"Como auditor, desea obtener la fecha más reciente en la que se calificó un producto."
--🔍 Explicación: Busca el MAX(created_at)agrupado por producto. Así sabe cuál fue la última vez que se evaluó cada uno .
--------------------------------------------------------------------------------------------------------------------------
SELECT p.nombre, MAX(r.fecha) AS ultima_calificacion
FROM rates r
JOIN companyproducts cp ON r.id_producto_empresa = cp.id
JOIN products p ON cp.id_producto = p.id
GROUP BY p.id;

---------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 11. Obtener la desviación estándar de precios por categoría
--"Como desarrollador, quiere conocer la variación de precios por categoría de producto".
--🔍 Explicación: Usando STDDEV(price)en companyproductsagrupado por category_id, se puede ver si hay mucha diferencia de precios dentro de una categoría .
---------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT p.categoria, STDDEV(cp.precio) AS desviacion_precio
FROM products p
JOIN companyproducts cp ON cp.id_producto = p.id
GROUP BY p.categoria;

-------------------------------------------------------------------------------------------------------------------------------------------------------
-- 12. Contar cuantas veces un producto fue favorito
--"Como técnico, desea contar cuántas veces un producto fue marcado como favorito."
--🔍 Explicación: Con COUNT(*)en details_favorites, agrupado por product_id, se obtiene cuáles productos son los más populares entre los clientes .
-------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT p.nombre, COUNT(*) AS total_favorito
FROM details_favorites df
JOIN companyproducts cp ON df.id_producto_empresa = cp.id
JOIN products p ON cp.id_producto = p.id
GROUP BY p.id;

-------------------------------------------------------------------------------------------------------------------------------------------
-- 13. Calcular el porcentaje de productos evaluados
--"Como director, quiere saber qué porcentaje de productos han sido calificados al menos una vez."
--🔍 Explicación: Cuenta cuántos productos hay en total y cuántos han sido evaluados ( rates). Luego calcula (evaluados / total) * 100.
-------------------------------------------------------------------------------------------------------------------------------------------
SELECT 
  (SELECT COUNT(DISTINCT cp.id_producto) FROM companyproducts cp JOIN rates r ON cp.id = r.id_producto_empresa) 
  / 
  (SELECT COUNT(*) FROM products) * 100 AS porcentaje_evaluados;

-------------------------------------------------------------------------------------------------------------------
-- 14. Ver el promedio de rating por encuesta
--"Como analista, deseo conocer el promedio de rating por encuesta."
--🔍 Explicación: Agrupa por poll_iden rates, y calcula el AVG(rating)para ver cómo se comporta cada encuesta .
-------------------------------------------------------------------------------------------------------------------
SELECT po.titulo, AVG(CAST(q.resultado->>'$.calidad' AS UNSIGNED)) AS promedio
FROM quality_products q
JOIN polls po ON q.id_encuesta = po.id
GROUP BY po.id;

----------------------------------------------------------------------------------------------------------------------------------
-- 15. Calcular el promedio y total de beneficios por plan
--"Como gestor, quiere obtener el promedio y el total de beneficios asignados a cada plan de membresía".
--🔍 Explicación: Agrupa por membership_iden membershipbenefits, y usa COUNT(*)y AVG(beneficio)si aplica (si hay ponderación).
----------------------------------------------------------------------------------------------------------------------------------
SELECT m.nombre, COUNT(mb.id_beneficio) AS total_beneficios
FROM memberships m
LEFT JOIN membershipbenefits mb ON m.id = mb.id_membresia
GROUP BY m.id;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 16. Obtener media y variación de precios por empresa
--"Como gerente, desea obtener la media y la variación del precio de productos por empresa."
--🔍 Explicación: Se agrupa por company_idy se usa AVG(price)y VARIANCE(price)para saber qué tan consistentes son los precios por empresa .
----------------------------------------------------------------------------------------------------------------------------------------------
SELECT e.nombre, AVG(cp.precio) AS media_precio, VARIANCE(cp.precio) AS varianza_precio
FROM companies e
JOIN companyproducts cp ON cp.id_empresa = e.id
GROUP BY e.id;

-------------------------------------------------------------------------------------------------------------------------------------------------
-- 17. Ver total de productos disponibles en la ciudad del cliente
--"Como cliente, quiere ver cuántos productos están disponibles en su ciudad".
--🔍 Explicación: Hace un JOINentre companies, companyproductsy citiesormunicipalities, filtrando por la ciudad del cliente. Luego se cuenta.
-------------------------------------------------------------------------------------------------------------------------------------------------
SELECT cu.nombre AS cliente, COUNT(DISTINCT cp.id_producto) AS total_productos
FROM customers cu
JOIN companies e ON cu.id_ciudad = e.id_ciudad
JOIN companyproducts cp ON cp.id_empresa = e.id
WHERE cu.id = 1
GROUP BY cu.id;

----------------------------------------------------------------------------------------------------------------
-- 18. Contar productos únicos por tipo de empresa
--"Como administrador, desea contar los productos únicos por tipo de empresa."
--🔍 Explicación: Agrupa por company_type_idy cuenta cuántos productos diferentes tiene cada tipo de empresa.
----------------------------------------------------------------------------------------------------------------
SELECT e.tipo, COUNT(DISTINCT cp.id_producto) AS productos_unicos
FROM companies e
JOIN companyproducts cp ON cp.id_empresa = e.id
GROUP BY e.tipo;

----------------------------------------------------------------------------------------------------------------------------------
-- 19. Ver total de clientes sin correo electrónico registrado
--"Como operador, quiere saber cuántos clientes no han registrado su correo".
--🔍 Explicación: Filtra customers WHERE email IS NULLy hace un COUNT(*). Esto ayuda a mejorar la base de datos para campañas.
----------------------------------------------------------------------------------------------------------------------------------
SELECT COUNT(*) AS total_sin_correo
FROM customers
WHERE correo IS NULL OR correo = '';

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 20. Empresa con más productos calificados
--"Como especialista, desea obtener la empresa con el mayor número de productos calificados."
--🔍 Explicación: Hace un JOINentre companies, companyproducts, y rates, grupo por empresa y usa COUNT(DISTINCT product_id), ordenando en orden descendente y tomando solo el primero.
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT e.nombre, COUNT(DISTINCT cp.id_producto) AS total_calificados
FROM companies e
JOIN companyproducts cp ON e.id = cp.id_empresa
JOIN rates r ON r.id_producto_empresa = cp.id
GROUP BY e.id
ORDER BY total_calificados DESC
LIMIT 1;
