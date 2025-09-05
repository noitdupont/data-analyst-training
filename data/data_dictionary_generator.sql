-- ###############################################################################
-- #                                                                             #
-- #  Description:  MySQL Data Dictionary Generator                              #
-- #                                                                             #
-- #  Version History:                                                           #
-- #-----------------------------------------------------------------------------#
-- #  Version |  Date  |  Developer            |  Tracker                        #
-- #-----------------------------------------------------------------------------#
-- #  1.0     |10/02/20|  Finbarrs Oketunji    |  Original Version (FIN-***)     #
-- #  2.0     |04/06/21|  Finbarrs Oketunji    |  Original Version (FIN-***)     #
-- ###############################################################################

-- Set to 1 to include views, 0 to exclude
SET @include_views = 0;

-- Set to 1 to include stored procedures/functions, 0 to exclude  
SET @include_procedures = 0;

-- Query for all tables (excluding views and procedures by default)
SELECT 
    t.TABLE_SCHEMA AS 'Database Name',
    t.TABLE_NAME AS 'Table Name',
    t.TABLE_TYPE AS 'Object Type',
    c.COLUMN_NAME AS 'Field Name',
    c.COLUMN_TYPE AS 'Data Type',
    c.IS_NULLABLE AS 'Allow Empty',
    CASE 
        WHEN c.COLUMN_KEY = 'PRI' THEN 'PRIMARY KEY'
        WHEN c.COLUMN_KEY = 'UNI' THEN 'UNIQUE'
        WHEN c.COLUMN_KEY = 'MUL' THEN 'INDEX'
        ELSE ''
    END AS 'Key Type',
    c.EXTRA AS 'Extra Properties',
    COALESCE(c.COLUMN_COMMENT, '') AS 'Field Description',
    c.COLUMN_DEFAULT AS 'Default Value',
    c.ORDINAL_POSITION AS 'Column Position'
FROM 
    INFORMATION_SCHEMA.TABLES t
    INNER JOIN INFORMATION_SCHEMA.COLUMNS c 
        ON t.TABLE_SCHEMA = c.TABLE_SCHEMA 
        AND t.TABLE_NAME = c.TABLE_NAME
WHERE 
    t.TABLE_SCHEMA = DATABASE()  -- Current database only. Remember to set your preferred database as default.
    AND (
        -- Always include base tables
        t.TABLE_TYPE = 'BASE TABLE'
        -- Include views only if enabled
        OR (@include_views = 1 AND t.TABLE_TYPE = 'VIEW')
    )
ORDER BY 
    t.TABLE_NAME, 
    c.ORDINAL_POSITION;

-- Optional: Query for stored procedures and functions (when enabled)
-- Uncomment and run this section if @include_procedures = 1

/*
SELECT 
    r.ROUTINE_SCHEMA AS 'Database Name',
    r.ROUTINE_NAME AS 'Routine Name',
    r.ROUTINE_TYPE AS 'Object Type',
    '' AS 'Field Name',
    '' AS 'Data Type',
    '' AS 'Allow Empty',
    '' AS 'Key Type',
    '' AS 'Extra Properties',
    COALESCE(r.ROUTINE_COMMENT, '') AS 'Description',
    '' AS 'Default Value',
    0 AS 'Position'
FROM 
    INFORMATION_SCHEMA.ROUTINES r
WHERE 
    r.ROUTINE_SCHEMA = DATABASE()
    AND @include_procedures = 1
ORDER BY 
    r.ROUTINE_NAME;
*/

-- Alternative: Single query for specific table
-- Replace 'your_table_name' with actual table name
/*
SELECT 
    c.COLUMN_NAME AS 'Field Name',
    c.COLUMN_TYPE AS 'Data Type',
    c.IS_NULLABLE AS 'Allow Empty',
    CASE 
        WHEN c.COLUMN_KEY = 'PRI' THEN 'PRIMARY KEY'
        WHEN c.COLUMN_KEY = 'UNI' THEN 'UNIQUE'
        WHEN c.COLUMN_KEY = 'MUL' THEN 'INDEX'
        ELSE c.EXTRA
    END AS 'Key/Extra',
    COALESCE(c.COLUMN_COMMENT, '') AS 'Field Description',
    c.COLUMN_DEFAULT AS 'Default Value'
FROM 
    INFORMATION_SCHEMA.COLUMNS c
WHERE 
    c.TABLE_SCHEMA = DATABASE()
    AND c.TABLE_NAME = 'your_table_name'
ORDER BY 
    c.ORDINAL_POSITION;
*/