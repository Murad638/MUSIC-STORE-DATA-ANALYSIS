-- Question Set 1


--/////////////////////////////////////////////////


/* Q1: Who is the senior most employee based on job title? */

-- Solution 1 / using subquery based on hire_date

SELECT *
FROM employee
WHERE TO_DATE(hire_date, 'DD-MM-YYYY HH24:MI') = (
    SELECT MIN(TO_DATE(hire_date, 'DD-MM-YYYY HH24:MI'))
    FROM employee
);

-- solution 2 / using limit based Seniority level

SELECT CONCAT_WS(' ', first_name, last_name) AS Name, title
FROM employee
ORDER BY levels DESC
LIMIT 1;


/* Q2: Which countries have the most Invoices?*/

SELECT billing_country, 
		DENSE_RANK() OVER (ORDER BY COUNT(invoice_id) DESC) AS dense_ranking,
           COUNT(invoice_id) AS cnt
 FROM invoice
 GROUP BY billing_country


/* Q3: What are top 3 values of total invoice?*/

WITH CTE AS (
    SELECT total, DENSE_RANK() OVER (ORDER BY total DESC) AS ran
    FROM invoice
)

SELECT DISTINCT total AS Top_3_values
FROM CTE
WHERE ran IN (1, 2, 3)
ORDER BY total DESC;


/* Q4: Which city has the best customers? We would like to throw a promotional Music
Festival in the city we made the most money. Write a query that returns one city that
has the highest sum of invoice totals. Return both the city name & sum of all invoice
totals*/

SELECT billing_city, SUM(total) AS InvoiceTotal
FROM invoice
GROUP BY billing_city
ORDER BY InvoiceTotal DESC
LIMIT 1;



/* Q5: Who is the best customer? The customer who has spent the most money will be
declared the best customer. Write a query that returns the person who has spent the
most money */


SELECT C.customer_id,
       CONCAT_WS(' ', C.first_name, C.last_name) AS Cust_Name,
       SUM(I.total) AS TotalSpent
FROM customer C
INNER JOIN invoice I ON C.customer_id = I.customer_id
GROUP BY C.customer_id, C.first_name, C.last_name
ORDER BY TotalSpent DESC
LIMIT 1;


-- Question Set 2


--/////////////////////////////////////////////////


/* Q1: Write query to return the first name, last name, email & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */

SELECT DISTINCT C.first_name, C.last_name, C.email, G.name AS genre_name
FROM customer C
INNER JOIN invoice I ON C.customer_id = I.customer_id
INNER JOIN invoice_line IL ON I.invoice_id = IL.invoice_id
INNER JOIN track T ON IL.track_id = T.track_id
INNER JOIN genre G ON T.genre_id = G.genre_id
WHERE G.name = 'Rock'
ORDER BY C.email;


/* Q2: Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */

-- take a look again

SELECT A.name AS ArtistName, COUNT(P.playlist_id) AS total_track_count
FROM artist A
INNER JOIN album AL ON A.artist_id = AL.artist_id
INNER JOIN track T ON AL.album_id = T.album_id
INNER JOIN playlist_track P ON T.track_id = P.track_id
INNER JOIN genre G ON T.genre_id = G.genre_id
WHERE G.name ='Rock'
GROUP BY A.name
ORDER BY total_track_count DESC
LIMIT 10;


/* Q3: Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */

--take a look again

SELECT name, milliseconds
FROM track
WHERE milliseconds > (SELECT AVG(milliseconds) FROM track)
ORDER BY milliseconds DESC;




-- Question Set 3


--/////////////////////////////////////////////////


/* Q1: Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent */

--take a look again

SELECT CONCAT_WS(' ', C.first_name, C.last_name) AS cust_name,
       A.name AS artist_name,
       SUM(IL.unit_price * IL.quantity) AS total_spent
FROM customer C
INNER JOIN invoice I ON C.customer_id = I.customer_id
INNER JOIN invoice_line IL ON I.invoice_id = IL.invoice_id
INNER JOIN track T ON IL.track_id = T.track_id
INNER JOIN album AL ON T.album_id = AL.album_id
INNER JOIN artist A ON AL.artist_id = A.artist_id
GROUP BY C.first_name, C.last_name, A.name
ORDER BY total_spent DESC;




/* Q2: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */

-- take a look again

WITH CTE AS (
    SELECT I.billing_country AS Country,
           G.name AS Genre_name,
           SUM(IL.quantity) AS No_of_purchase,
           DENSE_RANK() OVER (PARTITION BY I.billing_country ORDER BY SUM(IL.quantity) DESC) AS ran
    FROM invoice I
    INNER JOIN invoice_line IL ON I.invoice_id = IL.invoice_id
    INNER JOIN track T ON IL.track_id = T.track_id
    INNER JOIN genre G ON T.genre_id = G.genre_id
    GROUP BY I.billing_country, G.name
)

SELECT Country, Genre_name, ran
FROM CTE
WHERE ran = 1; -- check condition one more time
--order by ran desc;




/* Q3: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

-- need to take a look for sure


WITH CTE AS (
    SELECT I.billing_country AS country,
           CONCAT_WS(' ', C.first_name, C.last_name) AS cust_name,
           SUM(I.total) AS total_spendings,
           DENSE_RANK() OVER (PARTITION BY I.billing_country ORDER BY SUM(I.total) DESC) AS ran
    FROM customer C
    INNER JOIN invoice I ON C.customer_id = I.customer_id
    GROUP BY I.billing_country, C.first_name, C.last_name
)

SELECT country, cust_name, total_spendings
FROM CTE
WHERE ran = 1
ORDER BY country;




-- Question Set 4


--/////////////////////////////////////////////////


/* Q1: Identify the top 5 customers who have purchased the most tracks in each genre,
along with the total amount they spent on each genre. */

WITH CustomerGenreSpending AS (
    SELECT
        cus.customer_id,
        cus.first_name,
        cus.last_name,
        g.name AS genre_name,
        SUM(I.total) AS total_spent,
        DENSE_RANK() OVER (PARTITION BY g.genre_id ORDER BY SUM(I.total) DESC) AS rank
    FROM
        customer cus
        INNER JOIN invoice I ON cus.customer_id = I.customer_id
        INNER JOIN invoice_line IL ON I.invoice_id = IL.invoice_id
        INNER JOIN track t ON IL.track_id = t.track_id
        INNER JOIN genre g ON t.genre_id = g.genre_id
    GROUP BY
        cus.customer_id, cus.first_name, cus.last_name, g.genre_id, g.name
)

SELECT
    first_name,
    last_name,
    genre_name,
    total_spent
FROM
    CustomerGenreSpending
WHERE
    rank <= 5
ORDER BY
    genre_name,
    total_spent DESC;



/* Q2: Find the average, minimum, and maximum amount spent per genre by customers in
each country, along with the customer's first and last name.
 */
 
 
 WITH CustomerGenreCountrySpending AS (
    SELECT
        cus.first_name,
        cus.last_name,
        g.name AS genre_name,
        I.billing_country,
        SUM(I.total) AS total_spent
    FROM
        customer cus
        INNER JOIN invoice I ON cus.customer_id = I.customer_id
        INNER JOIN invoice_line IL ON I.invoice_id = IL.invoice_id
        INNER JOIN track t ON IL.track_id = t.track_id
        INNER JOIN genre g ON t.genre_id = g.genre_id
    GROUP BY
        cus.customer_id, cus.first_name, cus.last_name, g.name, I.billing_country
)

SELECT
    billing_country,
    genre_name,
    AVG(total_spent) AS avg_spent,
    MIN(total_spent) AS min_spent,
    MAX(total_spent) AS max_spent
FROM
    CustomerGenreCountrySpending
GROUP BY
    billing_country, genre_name
ORDER BY
    billing_country, genre_name;




/* Q3: Determine the top 3 artists whose tracks are included in the most playlists, along
with the total number of playlists and total track count. */


WITH ArtistPlaylistCounts AS (
    SELECT
        A.artist_id,
        A.name AS artist_name,
        COUNT(DISTINCT P.playlist_id) AS total_playlists,
        COUNT(T.track_id) AS total_tracks
    FROM
        artist A
        INNER JOIN album AL ON A.artist_id = AL.artist_id
        INNER JOIN track T ON AL.album_id = T.album_id
        INNER JOIN playlist_track PT ON T.track_id = PT.track_id
        INNER JOIN playlist P ON PT.playlist_id = P.playlist_id
    GROUP BY
        A.artist_id, A.name
)

SELECT
    artist_name,
    total_playlists,
    total_tracks
FROM
    ArtistPlaylistCounts
ORDER BY
    total_playlists DESC,
    total_tracks DESC
LIMIT 3;




/* Q4: Find the customers who have bought tracks from the top 3 most popular
albums, along with the total amount they spent on these albums. */

WITH TopAlbums AS ( -- To find out which albums are most popular based on number of purchased tracks
    SELECT
        AL.album_id,
        AL.title AS album_title,
        COUNT(T.track_id) AS total_purchases
    FROM
        album AL
        INNER JOIN track T ON AL.album_id = T.album_id
        INNER JOIN invoice_line IL ON T.track_id = IL.track_id
    GROUP BY
        AL.album_id, AL.title
    ORDER BY
        total_purchases DESC
    LIMIT 3 -- top 3
),

CustomerPurchases AS ( -- customers who have bought from these 3 albums
    SELECT
        C.customer_id,
        CONCAT_WS(' ', C.first_name, C.last_name) AS customer_name,
        AL.album_id,
        AL.title AS album_title,
        SUM(IL.unit_price * IL.quantity) AS total_spent 
    FROM
        customer C
        INNER JOIN invoice I ON C.customer_id = I.customer_id
        INNER JOIN invoice_line IL ON I.invoice_id = IL.invoice_id
        INNER JOIN track T ON IL.track_id = T.track_id
        INNER JOIN album AL ON T.album_id = AL.album_id
    WHERE
        AL.album_id IN (SELECT album_id FROM TopAlbums)
    GROUP BY
        C.customer_id, C.first_name, C.last_name, AL.album_id, AL.title
)

SELECT
    customer_id,
    customer_name,
    album_title,
    total_spent
FROM
    CustomerPurchases
ORDER BY
    total_spent DESC;






/* Q5: Calculate the total revenue generated by each genre in each country and deter-
mine the top revenue-generating genre for each country. Include the customer's
first and last name who contributed the most to this genre. */

WITH GenreRevenue AS (
    SELECT
        I.billing_country,
        G.genre_id,
        G.name AS genre_name,
        SUM(IL.unit_price * IL.quantity) AS total_revenue
    FROM
        invoice I
        INNER JOIN invoice_line IL ON I.invoice_id = IL.invoice_id
        INNER JOIN track T ON IL.track_id = T.track_id
        INNER JOIN genre G ON T.genre_id = G.genre_id
    GROUP BY
        I.billing_country, G.genre_id, G.name
),

TopGenreByCountry AS (
    SELECT
        billing_country,
        genre_id,
        genre_name,
        total_revenue,
        DENSE_RANK() OVER (PARTITION BY billing_country ORDER BY total_revenue DESC) AS rank
    FROM
        GenreRevenue
),

TopGenreCustomer AS (
    SELECT
        I.billing_country,
        G.genre_id,
        G.name AS genre_name,
        C.customer_id,
        CONCAT_WS(' ', C.first_name, C.last_name) AS customer_name,
        SUM(IL.unit_price * IL.quantity) AS customer_revenue
    FROM
        invoice I
        INNER JOIN customer C ON I.customer_id = C.customer_id
        INNER JOIN invoice_line IL ON I.invoice_id = IL.invoice_id
        INNER JOIN track T ON IL.track_id = T.track_id
        INNER JOIN genre G ON T.genre_id = G.genre_id
    GROUP BY
        I.billing_country, G.genre_id, G.name, C.customer_id, C.first_name, C.last_name
),

TopCustomerByGenre AS (
    SELECT
        TGC.billing_country,
        TGC.genre_id,
        TGC.genre_name,
        TGC.customer_id,
        TGC.customer_name,
        TGC.customer_revenue,
        DENSE_RANK() OVER (PARTITION BY TGC.billing_country, TGC.genre_id ORDER BY TGC.customer_revenue DESC) AS rank
    FROM
        TopGenreCustomer TGC
)

SELECT
    TG.billing_country,
    TG.genre_name,
    TG.total_revenue,
    TC.customer_name,
    TC.customer_revenue
FROM
    TopGenreByCountry TG
    INNER JOIN TopCustomerByGenre TC ON TG.billing_country = TC.billing_country AND TG.genre_id = TC.genre_id
WHERE
    TG.rank = 1 AND TC.rank = 1
ORDER BY
    TG.billing_country, TG.total_revenue DESC;



/* Q6: Find the employees who have managed the highest number of distinct
customers, along with the total amount of invoices generated under their
management.
*/


WITH EmployeeCustomerCounts AS (
    SELECT
        e.employee_id,
        CONCAT_WS(' ', e.first_name, e.last_name) AS employee_name,
        COUNT(DISTINCT c.customer_id) AS num_customers,
        SUM(i.total) AS total_invoices_amount
    FROM
        employee e
        LEFT JOIN customer c ON e.employee_id = c.support_rep_id
        LEFT JOIN invoice i ON c.customer_id = i.customer_id
    GROUP BY
        e.employee_id, e.first_name, e.last_name
)

SELECT
    employee_id,
    employee_name,
    num_customers,
    total_invoices_amount
FROM
    EmployeeCustomerCounts
WHERE
    num_customers IN (SELECT MAX(num_customers) FROM EmployeeCustomerCounts); -- How many employees do you need? I used only max...






/* Q7 Determine the customer that has spent the most on each genre in each country. */


WITH GenreCustomerSpending AS (
    SELECT
        I.billing_country,
        G.genre_id,
        G.name AS genre_name,
        C.customer_id,
        CONCAT_WS(' ', C.first_name, C.last_name) AS customer_name,
        SUM(IL.unit_price * IL.quantity) AS total_spent,
        RANK() OVER (PARTITION BY I.billing_country, G.genre_id ORDER BY SUM(IL.unit_price * IL.quantity) DESC) AS spending_rank
    FROM
        invoice_line IL
        INNER JOIN invoice I ON IL.invoice_id = I.invoice_id
        INNER JOIN customer C ON I.customer_id = C.customer_id
        INNER JOIN track T ON IL.track_id = T.track_id
        INNER JOIN genre G ON T.genre_id = G.genre_id
    GROUP BY
        I.billing_country, G.genre_id, G.name, C.customer_id, C.first_name, C.last_name
)

SELECT
    billing_country,
    genre_name,
    customer_name AS top_customer_name,
    total_spent AS amount_spent
FROM
    GenreCustomerSpending
WHERE
    spending_rank = 1
ORDER BY
    billing_country, genre_name;








/* Q8: Determine the ranking of customers within each genre based on the total amount
they have spent.
*/



WITH CustomerGenreSpending AS (
    SELECT
        G.genre_id,
        G.name AS genre_name,
        C.customer_id,
        CONCAT_WS(' ', C.first_name, C.last_name) AS customer_name,
        SUM(IL.unit_price * IL.quantity) AS total_spent,
        DENSE_RANK() OVER (PARTITION BY G.genre_id ORDER BY SUM(IL.unit_price * IL.quantity) DESC) AS genre_rank
    FROM
        invoice_line IL
        INNER JOIN invoice I ON IL.invoice_id = I.invoice_id
        INNER JOIN customer C ON I.customer_id = C.customer_id
        INNER JOIN track T ON IL.track_id = T.track_id
        INNER JOIN genre G ON T.genre_id = G.genre_id
    GROUP BY
        G.genre_id, G.name, C.customer_id, C.first_name, C.last_name
)

SELECT
    genre_name,
    customer_name,
    total_spent,
    genre_rank
FROM
    CustomerGenreSpending
ORDER BY
    genre_id, genre_rank;



