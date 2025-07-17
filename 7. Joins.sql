
-- 1. Ver productos con la empresa que los vende (INNER JOIN)
SELECT p.nombre AS producto, cp.precio, c.nombre AS empresa
FROM companyproducts cp
INNER JOIN products p ON cp.id_producto = p.id
INNER JOIN companies c ON cp.id_empresa = c.id;

-- 2. Mostrar productos favoritos con su empresa y categoría (JOIN múltiples)
SELECT p.nombre AS producto, c.nombre AS empresa , f.nombre_lista AS categoria
FROM favorites f
JOIN details_favorites df ON f.id = df.id_lista
JOIN products p ON df.id_producto_empresa = p.id
JOIN companyproducts cp ON p.id = cp.id_producto
JOIN companies c ON cp.id_empresa = c.id
WHERE f.id_cliente = 1; -- Reemplazar con ID del cliente

-- 3. Ver empresas aunque no tengan productos (LEFT JOIN)
SELECT c.nombre AS empresa, p.nombre AS producto
FROM companies c
LEFT JOIN companyproducts cp ON c.id = cp.id_empresa
LEFT JOIN products p ON cp.id_producto = p.id;

-- 4. Ver productos que fueron calificados (o no) (RIGHT JOIN)
SELECT p.nombre AS producto, r.puntuacion AS calificacion
FROM rates r
RIGHT JOIN products p ON r.id_producto_empresa = p.id;

-- 5. Ver productos con promedio de calificación y empresa
SELECT p.nombre AS producto, c.nombre AS empresa, AVG(r.puntuacion) AS promedio
FROM products p
JOIN companyproducts cp ON p.id = cp.id_producto
JOIN companies c ON cp.id_empresa = c.id
LEFT JOIN rates r ON r.id_producto_empresa = p.id
GROUP BY p.id, c.id;

-- 6. Ver clientes y sus calificaciones (LEFT JOIN)
SELECT cu.nombre AS cliente, r.puntuacion AS calificacion
FROM customers cu
LEFT JOIN rates r ON cu.id = r.id_cliente;

-- 7. Ver favoritos con la última calificación del cliente
SELECT p.nombre AS producto, r.puntuacion AS ultima_calificacion
FROM favorites f
JOIN details_favorites df ON f.id = df.id_lista
JOIN products p ON df.id_producto_empresa = p.id
LEFT JOIN rates r ON r.id_producto_empresa = p.id AND r.id_cliente = f.id_cliente
WHERE r.fecha = (
    SELECT MAX(r2.fecha)
    FROM rates r2
    WHERE r2.id_producto_empresa = p.id AND r2.id_cliente = f.id_cliente
);

-- 8. Ver beneficios incluidos en cada plan de membresía
SELECT m.nombre AS plan, b.nombre AS beneficio
FROM membershipbenefits mb
JOIN memberships m ON mb.membresia_id = m.id
JOIN benefits b ON mb.beneficio_id = b.id;

-- 9. Ver clientes con membresía activa y sus beneficios
SELECT cu.nombre, m.nombre AS membresia, b.descripcion AS beneficio
FROM customers cu
JOIN memberships m ON cu.id_membresia = m.id
JOIN membershipperiods mp ON m.id = mp.id_membresia
JOIN membershipbenefits mb ON m.id = mb.id_membresia
JOIN benefits b ON mb.id_beneficio = b.id
WHERE mp.status = 'ACTIVA' AND NOW() BETWEEN mp.inicio AND mp.fin;

-- 10. Ver ciudades con cantidad de empresas
SELECT cm.nombre AS ciudad, COUNT(c.id) AS total_empresas
FROM citiesormunicipalities cm
LEFT JOIN companies c ON cm.id = c.id_ciudad
GROUP BY cm.id;

-- 11. Ver encuestas con calificaciones
SELECT p.titulo AS encuesta, r.resultado AS calificacion
FROM polls p
JOIN quality_products r ON p.id = r.id_encuesta;

-- 12. Ver productos evaluados con datos del cliente
SELECT p.nombre AS producto, r.fecha, cu.nombre AS cliente
FROM rates r
JOIN products p ON r.id_producto_empresa = p.id
JOIN customers cu ON r.id_cliente = cu.id;

-- 13. Ver productos con audiencia de la empresa
SELECT p.nombre AS producto, a.descripcion AS audiencia
FROM products p
JOIN companyproducts cp ON p.id = cp.id_producto
JOIN companies c ON cp.id_empresa = c.id
JOIN audiences a ON c.id_audiencia = a.id;

-- 14. Ver clientes con sus productos favoritos
SELECT cu.nombre AS cliente, p.nombre AS producto
FROM customers cu
JOIN favorites f ON cu.id = f.id_cliente
JOIN details_favorites df ON f.id = df.id_lista
JOIN products p ON df.id_producto_empresa = p.id;

-- 15. Ver planes, periodos, precios y beneficios
SELECT m.nombre AS plan, mp.inicio, mp.fin, mp.costo, b.descripcion AS beneficio
FROM memberships m
JOIN membershipperiods mp ON m.id = mp.id_membresia
LEFT JOIN membershipbenefits mb ON m.id = mb.id_membresia
LEFT JOIN benefits b ON mb.id_beneficio = b.id;

-- 16. Ver combinaciones empresa-producto-cliente calificados
SELECT c.nombre AS empresa, p.nombre AS producto, cu.nombre AS cliente, r.puntuacion
FROM rates r
JOIN products p ON r.id_producto_empresa = p.id
JOIN customers cu ON r.id_cliente = cu.id
JOIN companyproducts cp ON p.id = cp.id_producto
JOIN companies c ON cp.id_empresa = c.id;

-- 17. Comparar favoritos con productos calificados
SELECT p.nombre AS producto, r.puntuacion
FROM details_favorites df
JOIN favorites f ON df.id_lista = f.id
JOIN products p ON df.id_producto_empresa = p.id
JOIN rates r ON p.id = r.id_producto_empresa AND r.id_cliente = f.id_cliente;

-- 18. Ver productos ordenados por categoría
SELECT cat.nombre AS categoria, p.nombre AS producto
FROM categories cat
JOIN products p ON cat.id = p.categoria_id
ORDER BY cat.nombre;

-- 19. Ver beneficios por audiencia, incluso vacíos
SELECT a.descripcion AS audiencia, b.descripcion AS beneficio
FROM audiences a
LEFT JOIN audiencebenefits ab ON a.id = ab.id_audiencia
LEFT JOIN benefits b ON ab.id_beneficio = b.id;

-- 20. Ver datos cruzados entre calificaciones, encuestas, productos y clientes
SELECT cu.nombre AS cliente, p.nombre AS producto, r.puntuacion, pl.titulo AS encuesta
FROM rates r
JOIN customers cu ON r.id_cliente = cu.id
JOIN products p ON r.id_producto_empresa = p.id
JOIN polls pl ON r.encuesta_id = pl.id;
