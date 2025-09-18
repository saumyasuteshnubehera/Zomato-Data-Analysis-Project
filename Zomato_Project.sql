CREATE TABLE restaurants (
    restaurant_id BIGINT,
    restaurant_name TEXT,
    country_code INT,
    city TEXT,
    address TEXT,
    locality TEXT,
    locality_verbose TEXT,
    longitude FLOAT,
    latitude FLOAT,
    cuisines TEXT,
    average_cost_for_two FLOAT,
    currency TEXT,
    has_table_booking TEXT,
    has_online_delivery TEXT,
    is_delivering_now TEXT,
    switch_to_order_menu TEXT,
    price_range FLOAT,
    aggregate_rating FLOAT,
    rating_color TEXT,
    rating_text TEXT,
    votes FLOAT,
    has_table_booking_flag INT,
    has_online_delivery_flag INT,
    is_delivering_now_flag INT,
    main_cuisine TEXT,
    cuisine_count INT,
    price_per_person FLOAT,
    rating_category TEXT,
    high_rating INT
);

select * from restaurants

-- Basic Exploration --
-- 1. Total restaurants and cities
SELECT COUNT(restaurant_id) AS total_restaurants,
       COUNT(DISTINCT city) AS total_cities
FROM restaurants;

-- 2. Top 10 cities by number of restaurants
SELECT city, COUNT(restaurant_id) AS total_restaurants
FROM restaurants
GROUP BY city
ORDER BY total_restaurants DESC
LIMIT 10;

-- 3. Top 10 cuisines
SELECT main_cuisine, COUNT(*) AS n_restaurants
FROM restaurants
GROUP BY main_cuisine
ORDER BY n_restaurants DESC
LIMIT 10;

-- 4. Price bucket analysis (low, medium, high cost per person)
SELECT CASE
           WHEN price_per_person < 200 THEN 'Low'
           WHEN price_per_person BETWEEN 200 AND 500 THEN 'Medium'
           ELSE 'High'
       END AS price_bucket,
       COUNT(*) AS restaurants,
       ROUND(AVG(aggregate_rating)::numeric, 2) AS avg_rating
FROM restaurants
GROUP BY price_bucket
ORDER BY restaurants DESC;

-- 5. High price but low rating restaurants (risk for churn)
with price_bucketed_restaurants as (
SELECT restaurant_name, city, price_per_person, high_rating,
CASE
           WHEN price_per_person < 200 THEN 'Low'
           WHEN price_per_person BETWEEN 200 AND 500 THEN 'Medium'
           ELSE 'High'
       END AS price_bucket
FROM restaurants
)
select restaurant_name, city from price_bucketed_restaurants
WHERE price_bucket = 'High'
  AND high_rating=0
ORDER BY price_per_person DESC
LIMIT 15;

-- 6. Restaurants with high votes but poor rating (need intervention)
SELECT restaurant_name, city, aggregate_rating, votes
FROM restaurants
WHERE aggregate_rating < 3 AND votes > 100
ORDER BY votes DESC
LIMIT 20;

-- 7. Percentage of high-rated restaurants by city
SELECT city,
       COUNT(*) AS total,
       SUM(CASE WHEN high_rating = 1 THEN 1 ELSE 0 END) AS high_rated,
       ROUND(
           (SUM(CASE WHEN high_rating = 1 THEN 1 ELSE 0 END)::numeric * 100.0 / COUNT(*)),
           2
       ) AS pct_high_rated
FROM restaurants
GROUP BY city
ORDER BY pct_high_rated DESC
LIMIT 10;

-- 8. Top cuisines by estimated revenue proxy (votes × price_per_person)
SELECT main_cuisine,
       SUM(votes*price_per_person) AS revenue_proxy,
       COUNT(*) AS n_restaurants
FROM restaurants
GROUP BY main_cuisine
ORDER BY revenue_proxy DESC
LIMIT 15;

-- 9. Average rating by cuisine (for cuisines with >50 restaurants)
SELECT main_cuisine,
       ROUND(AVG(aggregate_rating)::numeric,2) AS avg_rating,
       COUNT(*) AS n_restaurants
FROM restaurants
GROUP BY main_cuisine
HAVING COUNT(*) > 50
ORDER BY avg_rating DESC
LIMIT 15;

-- 10. Best cities for Zomato expansion (large base + good ratings)
SELECT city,
       COUNT(*) AS n_restaurants,
       ROUND(AVG(aggregate_rating)::numeric,2) AS avg_rating
FROM restaurants
GROUP BY city
HAVING COUNT(*) > 50
ORDER BY avg_rating DESC, n_restaurants DESC;

-- 11. Worst-performing cities (need service improvement)
SELECT city,
       ROUND(AVG(aggregate_rating)::numeric,2) AS avg_rating
FROM restaurants
GROUP BY city
ORDER BY avg_rating ASC;

-- 12. Online delivery vs rating (is delivery hurting quality?)
SELECT has_online_delivery_flag,
       ROUND(AVG(aggregate_rating)::numeric,2) AS avg_rating,
       COUNT(*) AS n_restaurants
FROM restaurants
GROUP BY has_online_delivery_flag;

-- 13. Table booking vs average cost
SELECT has_table_booking_flag,
       ROUND(AVG(average_cost_for_two)::numeric,2) AS avg_cost,
       COUNT(*) AS n_restaurants
FROM restaurants
GROUP BY has_table_booking_flag;

