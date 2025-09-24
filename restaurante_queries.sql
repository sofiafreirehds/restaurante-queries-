USE restaurante;

-- ¿Cuál es la cantidad total que gastó cada cliente en el restaurante?
SELECT s.customer_id, SUM(u.price) AS total
FROM sales s 
JOIN menu u ON s.product_id = u.product_id
GROUP BY s.customer_id;

-- ¿Cuántos días ha visitado cada cliente el restaurante?
SELECT customer_id, COUNT(DISTINCT order_date)
FROM sales
GROUP BY customer_id; 


-- ¿Cuál fue el primer artículo del menú comprado por cada cliente?
SELECT s.customer_id, u.product_name, s.order_date
FROM sales s
JOIN menu u ON s.product_id = u.product_id
WHERE (s.customer_id, s.order_date) IN (
    SELECT customer_id, MIN(order_date)
    FROM sales
    GROUP BY customer_id
);

-- ¿Cuál es el artículo más comprado en el menú y cuántas veces lo compraron todos los clientes?
SELECT u.product_name, COUNT(s.product_id) AS times_purchased
FROM menu u 
JOIN sales s ON s.product_id = u.product_id
GROUP BY u.product_name
ORDER BY times_purchased DESC
LIMIT 1; 
WITH compras_por_producto AS (
    SELECT 
        s.customer_id, 
        u.product_name, 
        COUNT(*) AS times_purchased
    FROM sales s
    JOIN menu u ON s.product_id = u.product_id
    GROUP BY s.customer_id, u.product_name
)

SELECT 
    c.customer_id,
    c.product_name,
    c.times_purchased
FROM compras_por_producto c
JOIN (
    SELECT 
        customer_id, 
        MAX(times_purchased) AS max_times
    FROM compras_por_producto
    GROUP BY customer_id
) m ON c.customer_id = m.customer_id AND c.times_purchased = m.max_times
ORDER BY c.customer_id;

-- 5. ¿Qué artículo fue el más popular para cada cliente?
SELECT c.customer_id, c.product_name, c.times_purchased
FROM (
    SELECT s.customer_id, u.product_name, COUNT(*) AS times_purchased
    FROM sales s
    JOIN menu u ON s.product_id = u.product_id
    GROUP BY s.customer_id, u.product_name
) c
JOIN (
    SELECT customer_id, MAX(times_purchased) AS max_times
    FROM (
        SELECT 
            s.customer_id,
            u.product_name,
            COUNT(*) AS times_purchased
        FROM sales s
        JOIN menu u ON s.product_id = u.product_id
        GROUP BY s.customer_id, u.product_name
    ) AS counts
    GROUP BY customer_id
) m ON c.customer_id = m.customer_id AND c.times_purchased = m.max_times
ORDER BY c.customer_id;
	
-- 6. ¿Qué artículo compró primero el cliente después de convertirse en miembro?
SELECT 
    s.customer_id, u.product_name, s.order_date
FROM sales s
JOIN menu u ON s.product_id = u.product_id
JOIN members m ON s.customer_id = m.customer_id
WHERE s.order_date >= m.join_date
  AND s.order_date = (
    SELECT MIN(order_date)
    FROM sales s2
    WHERE s2.customer_id = s.customer_id
      AND s2.order_date >= m.join_date
  )
ORDER BY s.customer_id;

-- 7. ¿Qué artículo se compró justo antes de que el cliente se convirtiera en miembro?
SELECT 
    s.customer_id, 
    u.product_name, 
    s.order_date
FROM sales s
JOIN menu u ON s.product_id = u.product_id
JOIN members m ON s.customer_id = m.customer_id
WHERE s.order_date < m.join_date
  AND s.order_date = (
    SELECT MAX(order_date)
    FROM sales s2
    WHERE s2.customer_id = s.customer_id
      AND s2.order_date < m.join_date
  )
ORDER BY s.customer_id;


-- 8. ¿Cuál es el total de artículos y la cantidad gastada por cada miembro antes de convertirse en miembro?
SELECT 
    m.customer_id,
    COUNT(s.product_id) AS total_articles,
    SUM(u.price) AS total_spent
FROM sales s
JOIN menu u ON s.product_id = u.product_id
JOIN members m ON s.customer_id = m.customer_id
WHERE s.order_date < m.join_date
GROUP BY m.customer_id
ORDER BY m.customer_id;

-- 9. Si cada \$1 gastado equivale a 10 puntos y el sushi tiene un multiplicador de puntos 2x, ¿Cuántos puntos tendría cada cliente?
SELECT 
    s.customer_id,
    SUM(
        u.price * 10 * 
        CASE WHEN u.product_name = 'Sushi' THEN 2 ELSE 1 END
    ) AS total_points
FROM sales s
JOIN menu u ON s.product_id = u.product_id
GROUP BY s.customer_id
ORDER BY total_points DESC;

-- Suposición: Solo los clientes que son miembros reciben puntos al comprar artículos, los puntos los reciben en las órdenes iguales o posteriores a la fecha en la que se convierten en miembros.
-- En la primera semana después de que un cliente se une al programa (incluida la fecha de ingreso), gana el doble de puntos en todos los artículos, no solo en sushi. ¿Cuántos puntos tienen los clientes A y B a fines de enero?

-- Suposición: Solo los clientes que son miembros reciben puntos al comprar artículos, los puntos los reciben en las órdenes iguales o posteriores a la fecha en la que se convierten en miembros. Solo las órdenes de la primera semana en la que se convierten en miembros suman 20 puntos para todos los artículos.