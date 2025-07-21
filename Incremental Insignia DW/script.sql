-- ====================================================================
-- PHASE 1: CLEANUP & TABLE CREATION
-- This section drops old objects to ensure a clean, repeatable setup.
-- ====================================================================
DROP FUNCTION IF EXISTS master_etl_run();
DROP FUNCTION IF EXISTS load_fact_sales(BIGINT);
DROP FUNCTION IF EXISTS load_dim_customer(BIGINT);

DROP TABLE IF EXISTS public.fact_sales CASCADE;
DROP TABLE IF EXISTS public.dim_date CASCADE;
DROP TABLE IF EXISTS public.dim_customer CASCADE;
DROP TABLE IF EXISTS public.dim_employee CASCADE;
DROP TABLE IF EXISTS public.dim_stock_item CASCADE;
DROP TABLE IF EXISTS public.dim_geography CASCADE;
DROP TABLE IF EXISTS public.lineage CASCADE;
DROP TABLE IF EXISTS public.insignia_staging CASCADE;
DROP TABLE IF EXISTS public.insignia_staging_copy CASCADE;


-- Create the 34-column staging table with lowercase_with_underscores names
CREATE TABLE public.insignia_staging (
    invoice_id INT, description VARCHAR(100), quantity INT, unit_price NUMERIC(10,2), tax_rate NUMERIC(5,2), total_excluding_tax NUMERIC(10,2), tax_amount NUMERIC(10,2), profit NUMERIC(10,2), total_including_tax NUMERIC(10,2),
    employee_id INT, employee_first_name VARCHAR(50), employee_last_name VARCHAR(50), is_salesperson BOOLEAN,
    stock_item_id INT, stock_item_name VARCHAR(100), stock_item_color VARCHAR(30), stock_item_size VARCHAR(10), item_size NUMERIC(5,2), stock_item_price NUMERIC(10,2),
    customer_id INT, customer_name VARCHAR(100), customer_category VARCHAR(50), customer_contact_name VARCHAR(100), customer_postal_code VARCHAR(20), customer_contact_number VARCHAR(20),
    city_id INT, city VARCHAR(50), state_province VARCHAR(50), country VARCHAR(50), continent VARCHAR(50), sales_territory VARCHAR(50), region VARCHAR(50), subregion VARCHAR(50), latest_recorded_population BIGINT
);

CREATE TABLE public.insignia_staging_copy AS TABLE public.insignia_staging WITH NO DATA;

-- Create all data warehouse tables
CREATE TABLE public.lineage (
    lineage_id BIGSERIAL PRIMARY KEY, source_system VARCHAR(100), load_start_datetime TIMESTAMP, load_end_datetime TIMESTAMP, rows_at_source INT, rows_at_destination_fact INT, load_status BOOLEAN
);
CREATE TABLE public.dim_date (
    date_key INT PRIMARY KEY, "date" DATE NOT NULL, day_number INT NOT NULL, month_name VARCHAR(20) NOT NULL, short_month CHAR(3) NOT NULL, calendar_month_number INT NOT NULL, calendar_year INT NOT NULL, fiscal_month_number INT NOT NULL, fiscal_year INT NOT NULL, week_number INT NOT NULL
);
CREATE TABLE public.dim_customer (
    customer_key BIGSERIAL PRIMARY KEY, customer_id INT NOT NULL, customer_name VARCHAR(100), customer_category VARCHAR(50), is_active BOOLEAN NOT NULL, start_date DATE NOT NULL, end_date DATE NULL, lineage_id BIGINT NOT NULL
);
CREATE TABLE public.dim_employee (
    employee_key BIGSERIAL PRIMARY KEY, employee_id INT NOT NULL, employee_name VARCHAR(101), is_salesperson BOOLEAN, is_active BOOLEAN NOT NULL, start_date DATE NOT NULL, end_date DATE NULL, lineage_id BIGINT NOT NULL
);
CREATE TABLE public.dim_stock_item (
    stock_item_key BIGSERIAL PRIMARY KEY, stock_item_id INT NOT NULL, stock_item_name VARCHAR(100), stock_item_color VARCHAR(30), stock_item_price NUMERIC(10,2), lineage_id BIGINT NOT NULL
);
CREATE TABLE public.dim_geography (
    geography_key BIGSERIAL PRIMARY KEY, city_id INT NOT NULL, city VARCHAR(50), state_province VARCHAR(50), country VARCHAR(50), current_population BIGINT, previous_population BIGINT, lineage_id BIGINT NOT NULL
);
CREATE TABLE public.fact_sales (
    sales_key BIGSERIAL PRIMARY KEY, date_key INT NOT NULL, customer_key BIGINT NOT NULL, employee_key BIGINT NOT NULL, stock_item_key BIGINT NOT NULL, geography_key BIGINT NOT NULL, invoice_id INT, quantity INT, unit_price NUMERIC(10,2), total_sale_amount NUMERIC(10,2), lineage_id BIGINT NOT NULL
);

-- ====================================================================
-- PHASE 2: POPULATE PREREQUISITE DATA
-- ====================================================================

-- Populate DimDate
DO $$
DECLARE
    v_current_date DATE := '2000-01-01';
BEGIN
    WHILE v_current_date <= '2023-12-31' LOOP
        INSERT INTO public.dim_date (date_key, "date", day_number, month_name, short_month, calendar_month_number, calendar_year, fiscal_month_number, fiscal_year, week_number)
        VALUES (
            TO_CHAR(v_current_date, 'YYYYMMDD')::INT, v_current_date, EXTRACT(DAY FROM v_current_date),TRIM(TO_CHAR(v_current_date, 'Month')), TRIM(TO_CHAR(v_current_date, 'Mon')), EXTRACT(MONTH FROM v_current_date), EXTRACT(YEAR FROM v_current_date),
            CASE WHEN EXTRACT(MONTH FROM v_current_date) >= 7 THEN EXTRACT(MONTH FROM v_current_date) - 6 ELSE EXTRACT(MONTH FROM v_current_date) + 6 END,
            CASE WHEN EXTRACT(MONTH FROM v_current_date) >= 7 THEN EXTRACT(YEAR FROM v_current_date) ELSE EXTRACT(YEAR FROM v_current_date) - 1 END,
            EXTRACT(WEEK FROM v_current_date)
        );
        v_current_date := v_current_date + INTERVAL '1 day';
    END LOOP;
END $$;

-- Add Unknown Records for late-arriving data
INSERT INTO public.dim_customer (customer_id, customer_name, customer_category, is_active, start_date, end_date, lineage_id) VALUES (-1, 'Unknown', 'N/A', TRUE, '1900-01-01', NULL, -1);
INSERT INTO public.dim_employee (employee_id, employee_name, is_salesperson, is_active, start_date, end_date, lineage_id) VALUES (-1, 'Unknown', NULL, TRUE, '1900-01-01', NULL, -1);
INSERT INTO public.dim_stock_item (stock_item_id, stock_item_name, stock_item_color, stock_item_price, lineage_id) VALUES (-1, 'Unknown', 'N/A', 0, -1);
INSERT INTO public.dim_geography (city_id, city, state_province, country, current_population, previous_population, lineage_id) VALUES (-1, 'Unknown', 'N/A', 'N/A', 0, 0, -1);


-- ====================================================================
-- PHASE 3: CREATE ETL FUNCTIONS (THE LOGIC)
-- ====================================================================

-- SCD Type 2 logic for the Customer dimension
CREATE OR REPLACE FUNCTION load_dim_customer(p_lineage_id BIGINT) RETURNS VOID AS $$
BEGIN
    -- Find changed customers
    CREATE TEMP TABLE changed_customers AS
    SELECT stage.*
    FROM public.insignia_staging_copy AS stage
    JOIN public.dim_customer AS dim ON stage.customer_id = dim.customer_id AND dim.is_active = TRUE
    WHERE dim.customer_name <> stage.customer_name OR dim.customer_category <> stage.customer_category;

    -- Expire old records for customers that have changed
    UPDATE public.dim_customer dim SET is_active = FALSE, end_date = CURRENT_DATE
    WHERE EXISTS (SELECT 1 FROM changed_customers temp WHERE temp.customer_id = dim.customer_id) AND dim.is_active = TRUE;

    -- Insert the new version of changed records
    INSERT INTO public.dim_customer (customer_id, customer_name, customer_category, is_active, start_date, lineage_id)
    SELECT customer_id, customer_name, customer_category, TRUE, CURRENT_DATE, p_lineage_id FROM changed_customers;

    -- Insert brand new customers
    INSERT INTO public.dim_customer (customer_id, customer_name, customer_category, is_active, start_date, lineage_id)
    SELECT stage.customer_id, stage.customer_name, stage.customer_category, TRUE, CURRENT_DATE, p_lineage_id
    FROM public.insignia_staging_copy AS stage
    WHERE NOT EXISTS (SELECT 1 FROM public.dim_customer dim WHERE dim.customer_id = stage.customer_id);

    DROP TABLE changed_customers;
END;
$$ LANGUAGE plpgsql;

-- Logic to load the final Fact table
CREATE OR REPLACE FUNCTION load_fact_sales(p_lineage_id BIGINT) RETURNS INT AS $$
DECLARE
    rows_inserted INT;
    unknown_cust_key BIGINT := (SELECT customer_key FROM public.dim_customer WHERE customer_id = -1);
    unknown_emp_key BIGINT := (SELECT employee_key FROM public.dim_employee WHERE employee_id = -1);
    unknown_item_key BIGINT := (SELECT stock_item_key FROM public.dim_stock_item WHERE stock_item_id = -1);
    unknown_geo_key BIGINT := (SELECT geography_key FROM public.dim_geography WHERE city_id = -1);
BEGIN
    INSERT INTO public.fact_sales (date_key, customer_key, employee_key, stock_item_key, geography_key, invoice_id, quantity, unit_price, total_sale_amount, lineage_id)
    SELECT
        TO_CHAR(CURRENT_DATE, 'YYYYMMDD')::INT,
        COALESCE(c.customer_key, unknown_cust_key),
        COALESCE(e.employee_key, unknown_emp_key),
        COALESCE(si.stock_item_key, unknown_item_key),
        COALESCE(g.geography_key, unknown_geo_key),
        stage.invoice_id, stage.quantity, stage.unit_price, stage.total_including_tax, p_lineage_id
    FROM public.insignia_staging_copy AS stage
    LEFT JOIN public.dim_customer c ON stage.customer_id = c.customer_id AND c.is_active = TRUE
    LEFT JOIN public.dim_employee e ON stage.employee_id = e.employee_id AND e.is_active = TRUE
    LEFT JOIN public.dim_stock_item si ON stage.stock_item_id = si.stock_item_id
    LEFT JOIN public.dim_geography g ON stage.city_id = g.city_id;
    
    GET DIAGNOSTICS rows_inserted = ROW_COUNT;
    RETURN rows_inserted;
END;
$$ LANGUAGE plpgsql;

-- The Master ETL function that runs the entire process
CREATE OR REPLACE FUNCTION master_etl_run() RETURNS VOID AS $$
DECLARE
    v_lineage_id BIGINT;
    v_source_rows INT;
    v_fact_rows INT;
BEGIN
    -- 1. Start Lineage tracking
    INSERT INTO public.lineage (source_system, load_start_datetime, load_status)
    VALUES ('OnlineGiftStore', NOW(), FALSE) RETURNING lineage_id INTO v_lineage_id;

    -- 2. Prepare staging copy (using explicit columns for safety)
    TRUNCATE public.insignia_staging_copy;
    INSERT INTO public.insignia_staging_copy (
        invoice_id, description, quantity, unit_price, tax_rate, total_excluding_tax, tax_amount, profit, total_including_tax,
        employee_id, employee_first_name, employee_last_name, is_salesperson,
        stock_item_id, stock_item_name, stock_item_color, stock_item_size, item_size, stock_item_price,
        customer_id, customer_name, customer_category, customer_contact_name, customer_postal_code, customer_contact_number,
        city_id, city, state_province, country, continent, sales_territory, region, subregion, latest_recorded_population
    )
    SELECT
        invoice_id, description, quantity, unit_price, tax_rate, total_excluding_tax, tax_amount, profit, total_including_tax,
        employee_id, employee_first_name, employee_last_name, is_salesperson,
        stock_item_id, stock_item_name, stock_item_color, stock_item_size, item_size, stock_item_price,
        customer_id, customer_name, customer_category, customer_contact_name, customer_postal_code, customer_contact_number,
        city_id, city, state_province, country, continent, sales_territory, region, subregion, latest_recorded_population
    FROM
        public.insignia_staging;

    GET DIAGNOSTICS v_source_rows = ROW_COUNT;

    -- 3. Load Dimensions
    PERFORM load_dim_customer(v_lineage_id);
    -- Note: This is where you would add calls to other dimension-loading functions.

    -- 4. Load Fact Table
    SELECT load_fact_sales(v_lineage_id) INTO v_fact_rows;

    -- 5. Finalize Lineage
    UPDATE public.lineage
    SET load_end_datetime = NOW(),
        rows_at_source = v_source_rows,
        rows_at_destination_fact = v_fact_rows,
        load_status = TRUE
    WHERE lineage_id = v_lineage_id;
END;
$$ LANGUAGE plpgsql;