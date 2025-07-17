-- 1. Como gerente, quiero ver los productos cuyo precio esté por encima del promedio de su categoría.
SELECT p.nombre, p.categoria, cp.precio
FROM products p
JOIN companyproducts cp ON p.id = cp.id_producto
WHERE cp.precio > (
  SELECT AVG(cp2.precio)
  FROM companyproducts cp2
  JOIN products p2 ON cp2.id_producto = p2.id
  WHERE p2.categoria = p.categoria
);

-- 2. Como administrador, deseo listar las empresas que tienen más productos que la media de empresas.
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

-- 3. Como cliente, quiero ver mis productos favoritos que han sido calificados por otros clientes.
SELECT DISTINCT p.nombre
FROM favorites f
JOIN details_favorites df ON f.id = df.id_lista
JOIN companyproducts cp ON df.id_producto_empresa = cp.id
JOIN products p ON cp.id_producto = p.id
JOIN rates r ON r.id_producto_empresa = cp.id
WHERE f.id_cliente = 1 
AND r.id_cliente <> f.id_cliente;

-- 4. Como supervisor, deseo obtener los productos con el mayor número de veces añadidos como favoritos.
SELECT p.nombre, COUNT(*) AS total_favoritos
FROM details_favorites df
JOIN companyproducts cp ON df.id_producto_empresa = cp.id
JOIN products p ON cp.id_producto = p.id
GROUP BY p.id
ORDER BY total_favoritos DESC;

-- 5. Como técnico, quiero listar los clientes cuyo correo no aparece en la tabla ratesni en quality_products.
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

-- 6. Como gestor de calidad, quiero obtener los productos con una calificación inferior al mínimo de su categoría.
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

-- 7. Como desarrollador, deseo listar las ciudades que no tienen clientes registrados.
SELECT c.nombre
FROM citiesormunicipalities c
LEFT JOIN customers cu ON cu.id_ciudad = c.id
WHERE cu.id IS NULL;

-- 8. Como administrador, quiero ver los productos que no han sido evaluados en ninguna encuesta.
SELECT DISTINCT p.nombre
FROM products p
JOIN companyproducts cp ON cp.id_producto = p.id
LEFT JOIN quality_products q ON cp.id = q.id_producto_empresa
WHERE q.id IS NULL;

-- 9. Como auditor, quiero listar los beneficios que no están asignados a ninguna audiencia.
SELECT b.descripcion
FROM benefits b
LEFT JOIN audiencebenefits ab ON b.id = ab.id_beneficio
WHERE ab.id IS NULL;

-- 10. Como cliente, deseo obtener mis productos favoritos que no están disponibles actualmente en ninguna empresa.
SELECT DISTINCT p.nombre
FROM favorites f
JOIN details_favorites df ON df.id_lista = f.id
JOIN companyproducts cp ON df.id_producto_empresa = cp.id
JOIN products p ON cp.id_producto = p.id
LEFT JOIN companyproducts cp2 ON p.id = cp2.id_producto
WHERE f.id_cliente = 1 AND cp2.id IS NULL;

-- 11. Como director, deseo consultar los productos vendidos en empresas cuya ciudad tenga menos de tres empresas registradas.
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

-- 12. Como analista, quiero ver los productos con calidad superior al promedio de todos los productos.
SELECT p.nombre, AVG(CAST(q.resultado->>'$.calidad' AS UNSIGNED)) AS promedio
FROM quality_products q
JOIN companyproducts cp ON cp.id = q.id_producto_empresa
JOIN products p ON cp.id_producto = p.id
GROUP BY p.id
HAVING promedio > (
  SELECT AVG(CAST(resultado->>'$.calidad' AS UNSIGNED)) FROM quality_products
);

-- 13. Como gestor, quiero ver empresas que sólo venden productos de una única categoría.
SELECT e.nombre
FROM companies e
JOIN companyproducts cp ON e.id = cp.id_empresa
JOIN products p ON cp.id_producto = p.id
GROUP BY e.id
HAVING COUNT(DISTINCT p.categoria) = 1;

-- 14. Como gerente comercial, quiero consultar los productos con el mayor precio entre todas las empresas.
SELECT p.nombre, MAX(cp.precio) AS precio_maximo
FROM products p
JOIN companyproducts cp ON cp.id_producto = p.id
GROUP BY p.id
ORDER BY precio_maximo DESC;

-- 15. Como cliente, quiero saber si algún producto de mis favoritos ha sido calificado por otro cliente con más de 4 estrellas.
SELECT DISTINCT p.nombre
FROM favorites f
JOIN details_favorites df ON df.id_lista = f.id
JOIN companyproducts cp ON df.id_producto_empresa = cp.id
JOIN products p ON cp.id_producto = p.id
JOIN rates r ON r.id_producto_empresa = cp.id
WHERE f.id_cliente = 1 
AND r.id_cliente <> f.id_cliente AND r.puntuacion > 4;

-- 16. Como operador, quiero saber qué productos no tienen imagen asignada pero sí han sido calificados.
SELECT DISTINCT p.nombre
FROM products p
JOIN companyproducts cp ON cp.id_producto = p.id
JOIN rates r ON r.id_producto_empresa = cp.id
WHERE (p.imagen IS NULL OR p.imagen = '');

-- 17. Como auditor, quiero ver los planos de membresía sin período vigente.
SELECT m.nombre
FROM memberships m
LEFT JOIN membershipperiods mp ON m.id = mp.id_membresia
WHERE CURDATE() not between mp.inicio and mp.fin;

-- 18. Como especialista, quiero identificar los beneficios compartidos por más de una audiencia.
SELECT b.descripcion, COUNT(DISTINCT ab.id_audiencia) AS total_audiencias
FROM audiencebenefits ab
JOIN benefits b ON ab.id_beneficio = b.id
GROUP BY b.id
HAVING total_audiencias > 1;

-- 19. Como técnico, quiero encontrar empresas cuyos productos no tengan unidad de medida definida.
SELECT DISTINCT e.nombre
FROM companies e
JOIN companyproducts cp ON cp.id_empresa = e.id
WHERE cp.unidad_medida IS NULL OR cp.unidad_medida = '';

-- 20. Como gestor de campañas, deseo obtener los clientes con membresía activa y sin productos favoritos.
SELECT cu.nombre
FROM customers cu
JOIN membershipperiods mp ON mp.inicio <= CURDATE() AND mp.fin >= CURDATE()
LEFT JOIN favorites f ON f.id_cliente = cu.id
WHERE f.id IS NULL;
