-- 1. Como analista, quiero listar todos los productos con su empresa asociada y el precio más bajo por ciudad.
SELECT c.nombre AS ciudad, p.nombre AS producto, e.nombre AS empresa, MIN(cp.precio) AS precio_minimo
FROM companyproducts cp
JOIN companies e ON cp.id_empresa = e.id
JOIN products p ON cp.id_producto = p.id
JOIN citiesormunicipalities c ON e.id_ciudad = c.id
GROUP BY c.nombre, p.nombre, e.nombre;

-- 2. Como administrador, deseo obtener el top 5 de clientes que más productos han calificado en los últimos 6 meses.
SELECT cu.nombre, COUNT(r.id) AS total_calificaciones
FROM rates r
JOIN customers cu ON r.id_cliente = cu.id
WHERE r.fecha >= CURDATE() - INTERVAL 6 MONTH
GROUP BY cu.id
ORDER BY total_calificaciones DESC
LIMIT 5;

-- 3. Como gerente de ventas, quiero ver la distribución de productos por categoría y unidad de medida.
SELECT p.categoria, cp.unidad_medida, COUNT(*) AS total
FROM companyproducts cp
JOIN products p ON cp.id_producto = p.id
GROUP BY p.categoria, cp.unidad_medida;

-- 4. Como cliente, quiero saber qué productos tienen calificaciones superiores al promedio general.
SELECT p.nombre, AVG(r.puntuacion) AS promedio_producto
FROM rates r
JOIN companyproducts cp ON r.id_producto_empresa = cp.id
JOIN products p ON cp.id_producto = p.id
GROUP BY p.id
HAVING promedio_producto > (SELECT AVG(puntuacion) FROM rates);

-- 5. Como auditor, quiero conocer todas las empresas que no han recibido ninguna calificación.
SELECT e.nombre
FROM companies e
LEFT JOIN companyproducts cp ON e.id = cp.id_empresa
LEFT JOIN rates r ON r.id_producto_empresa = cp.id
WHERE r.id IS NULL;

-- 6. Como operador, deseo obtener los productos que han sido añadidos como favoritos por más de 10 clientes distintos.
SELECT p.nombre, COUNT(DISTINCT f.id_cliente) AS total_clientes
FROM details_favorites df
JOIN favorites f ON df.id_lista = f.id
JOIN companyproducts cp ON df.id_producto_empresa = cp.id
JOIN products p ON cp.id_producto = p.id
GROUP BY p.id
HAVING total_clientes > 10;

-- 7. Como gerente regional, quiero obtener todas las empresas activas por ciudad y categoría.
SELECT c.nombre AS ciudad, e.categoria, COUNT(*) AS total_empresas
FROM companies e
JOIN citiesormunicipalities c ON e.id_ciudad = c.id
GROUP BY c.nombre, e.categoria;

-- 8. Como especialista en marketing, deseo obtener los 10 productos más calificados en cada ciudad.
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

-- 9. Como técnico, quiero identificar productos sin unidad de medida asignada.
SELECT p.nombre
FROM companyproducts cp
JOIN products p ON cp.id_producto = p.id
WHERE cp.unidad_medida IS NULL OR cp.unidad_medida = '';

-- 10. Como gestor de beneficios, deseo ver los planos de membresía sin beneficios registrados.
SELECT m.nombre
FROM memberships m
LEFT JOIN membershipbenefits mb ON m.id = mb.id_membresia
WHERE mb.id IS NULL;

-- 11. Como supervisor, quiero obtener los productos de una categoría específica con su promedio de calificación.
SELECT p.nombre, p.categoria, AVG(r.puntuacion) AS promedio
FROM products p
JOIN companyproducts cp ON cp.id_producto = p.id
JOIN rates r ON r.id_producto_empresa = cp.id
-- WHERE p.categoria = 'Electrodomésticos' -- puedes cambiar esta categoría
GROUP BY p.id;

-- 12. Como asesor, deseo obtener los clientes que han comprado productos de más de una empresa.
SELECT r.id_cliente, COUNT(DISTINCT cp.id_empresa) AS empresas_distintas
FROM rates r
JOIN companyproducts cp ON r.id_producto_empresa = cp.id
GROUP BY r.id_cliente
HAVING empresas_distintas > 1;

-- 13. Como director, quiero identificar las ciudades con más clientes activos.
SELECT c.nombre, COUNT(*) AS total_clientes
FROM customers cu
JOIN citiesormunicipalities c ON cu.id_ciudad = c.id
GROUP BY c.id
ORDER BY total_clientes DESC;

-- 14. Como analista de calidad, deseo obtener el ranking de productos por empresa basado en los medios de comunicación quality_products.
SELECT e.nombre AS empresa, p.nombre AS producto,
       AVG(CAST(q.resultado->>'$.calidad' AS SIGNED)) AS promedio_calidad
FROM quality_products q
JOIN companyproducts cp ON q.id_producto_empresa = cp.id
JOIN products p ON cp.id_producto = p.id
JOIN companies e ON cp.id_empresa = e.id
GROUP BY e.id, p.id
ORDER BY promedio_calidad DESC;

-- 15. Como administrador, quiero listar empresas que ofrecen más de cinco productos distintos.
SELECT e.nombre, COUNT(DISTINCT cp.id_producto) AS total_productos
FROM companies e
JOIN companyproducts cp ON cp.id_empresa = e.id
GROUP BY e.id
HAVING total_productos > 5;

-- 16. Como cliente, deseo visualizar los productos favoritos que aún no han sido calificados.
SELECT DISTINCT p.nombre
FROM details_favorites df
JOIN favorites f ON df.id_lista = f.id
JOIN companyproducts cp ON df.id_producto_empresa = cp.id
JOIN products p ON cp.id_producto = p.id
LEFT JOIN rates r ON r.id_producto_empresa = cp.id AND r.id_cliente = f.id_cliente
WHERE r.id IS NULL;

-- 17. Como desarrollador, deseo consultar los beneficios asignados a cada audiencia junto con su descripción.
SELECT a.descripcion AS audiencia, b.descripcion AS beneficio
FROM audiencebenefits ab
JOIN audiences a ON ab.id_audiencia = a.id
JOIN benefits b ON ab.id_beneficio = b.id;

-- 18. Como operador logístico, quiero saber en qué ciudades hay empresas sin productos asociados.
SELECT c.nombre
FROM citiesormunicipalities c
JOIN companies e ON c.id = e.id_ciudad
LEFT JOIN companyproducts cp ON e.id = cp.id_empresa
WHERE cp.id IS NULL;

-- 19. Como técnico, deseo obtener todas las empresas con productos duplicados por nombre.
SELECT e.nombre, p.nombre, COUNT(*) AS total
FROM companies e
JOIN companyproducts cp ON cp.id_empresa = e.id
JOIN products p ON cp.id_producto = p.id
GROUP BY e.id, p.nombre
HAVING total > 1;

-- 20. Como analista, quiero una vista resumen de clientes, productos favoritos y promedio de calificación recibida.
SELECT cu.nombre AS cliente, p.nombre AS producto,
       AVG(r.puntuacion) AS promedio_calificacion
FROM favorites f
JOIN customers cu ON f.id_cliente = cu.id
JOIN details_favorites df ON df.id_lista = f.id
JOIN companyproducts cp ON df.id_producto_empresa = cp.id
JOIN products p ON cp.id_producto = p.id
LEFT JOIN rates r ON r.id_producto_empresa = cp.id
GROUP BY cu.id, p.id;
