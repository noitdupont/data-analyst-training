-- ###############################################################################
-- #                                                                             #
-- #  Description:  MySQL Data Dictionary Generator                              #
-- #                                                                             #
-- #  Version History:                                                           #
-- #-----------------------------------------------------------------------------#
-- #  Version |  Date     |  Developer            |  Tracker                     #
-- #-----------------------------------------------------------------------------#
-- #  1.0     |  10/02/20 |  Finbarrs Oketunji    |  Original Version (FIN-***)  #
-- #  2.0     |  04/06/21 |  Finbarrs Oketunji    |  Original Version (FIN-***)  #
-- #  3.0     |  06/09/25 |  Finbarrs Oketunji    |  Original Version (FIN-***)  #
-- ###############################################################################

-- Configuration variables for object types to include
SET @include_views = 1;           -- Set to 1 to include views, 0 to exclude
SET @include_procedures = 1;      -- Set to 1 to include stored procedures/functions, 0 to exclude

-- Main query for database objects structure
SELECT 
    t.TABLE_SCHEMA AS 'Database Name',
    t.TABLE_NAME AS 'Object Name',
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
    t.TABLE_SCHEMA = DATABASE()  -- Current database only
    AND (
        -- Always include base tables
        t.TABLE_TYPE = 'BASE TABLE'
        -- Include views if enabled
        OR (@include_views = 1 AND t.TABLE_TYPE = 'VIEW')
    )

UNION ALL

-- Query for stored procedures and functions (if enabled)
SELECT 
    p.ROUTINE_SCHEMA AS 'Database Name',
    p.ROUTINE_NAME AS 'Object Name',
    CASE 
        WHEN p.ROUTINE_TYPE = 'PROCEDURE' THEN 'STORED PROCEDURE'
        WHEN p.ROUTINE_TYPE = 'FUNCTION' THEN 'STORED FUNCTION'
    END AS 'Object Type',
    CASE 
        WHEN pm.PARAMETER_NAME IS NOT NULL THEN pm.PARAMETER_NAME
        ELSE '(Return Type)'
    END AS 'Field Name',
    CASE 
        WHEN pm.PARAMETER_NAME IS NOT NULL THEN pm.DTD_IDENTIFIER
        ELSE p.DTD_IDENTIFIER
    END AS 'Data Type',
    CASE 
        WHEN pm.PARAMETER_MODE IS NOT NULL THEN pm.PARAMETER_MODE
        ELSE 'RETURNS'
    END AS 'Allow Empty',
    '' AS 'Key Type',
    '' AS 'Extra Properties',
    COALESCE(p.ROUTINE_COMMENT, '') AS 'Field Description',
    '' AS 'Default Value',
    COALESCE(pm.ORDINAL_POSITION, 0) AS 'Column Position'
FROM 
    INFORMATION_SCHEMA.ROUTINES p
    LEFT JOIN INFORMATION_SCHEMA.PARAMETERS pm 
        ON p.ROUTINE_SCHEMA = pm.SPECIFIC_SCHEMA 
        AND p.ROUTINE_NAME = pm.SPECIFIC_NAME
WHERE 
    p.ROUTINE_SCHEMA = DATABASE()
    AND @include_procedures = 1
    AND p.ROUTINE_TYPE IN ('PROCEDURE', 'FUNCTION')

ORDER BY 
    'Object Name', 
    'Column Position';

-- Optional: Detailed stored procedures and functions with parameters (when enabled)
-- Provides comprehensive routine information including input/output parameters
/*
SELECT
    r.ROUTINE_SCHEMA AS 'Database Name',
    r.ROUTINE_NAME AS 'Routine Name',
    CASE 
        WHEN r.ROUTINE_TYPE = 'PROCEDURE' THEN 'STORED PROCEDURE'
        WHEN r.ROUTINE_TYPE = 'FUNCTION' THEN 'STORED FUNCTION'
    END AS 'Object Type',
    COALESCE(p.PARAMETER_NAME, '(Return Value)') AS 'Parameter Name',
    CASE 
        WHEN p.PARAMETER_NAME IS NOT NULL THEN p.DTD_IDENTIFIER
        WHEN r.ROUTINE_TYPE = 'FUNCTION' THEN r.DTD_IDENTIFIER
        ELSE ''
    END AS 'Data Type',
    COALESCE(p.PARAMETER_MODE, 'RETURNS') AS 'Parameter Mode',
    '' AS 'Key Type',
    r.SECURITY_TYPE AS 'Security Type',
    COALESCE(r.ROUTINE_COMMENT, '') AS 'Routine Description',
    '' AS 'Default Value',
    COALESCE(p.ORDINAL_POSITION, 0) AS 'Parameter Position',
    r.CREATED AS 'Created Date',
    r.LAST_ALTERED AS 'Last Modified'
FROM
    INFORMATION_SCHEMA.ROUTINES r
    LEFT JOIN INFORMATION_SCHEMA.PARAMETERS p 
        ON r.ROUTINE_SCHEMA = p.SPECIFIC_SCHEMA 
        AND r.ROUTINE_NAME = p.SPECIFIC_NAME
        AND r.ROUTINE_TYPE = p.ROUTINE_TYPE
WHERE
    r.ROUTINE_SCHEMA = DATABASE()
    AND @include_procedures = 1
    AND r.ROUTINE_TYPE IN ('PROCEDURE', 'FUNCTION')
ORDER BY
    r.ROUTINE_NAME, p.ORDINAL_POSITION;
*/

-- Alternative: Single table analysis query
-- Replace 'your_table_name' with the actual table name you want to examine
-- Uncomment the section below and modify the table name as needed
/*
SELECT
    c.COLUMN_NAME AS 'Field Name',
    c.COLUMN_TYPE AS 'Data Type',
    c.IS_NULLABLE AS 'Nullable',
    CASE
        WHEN c.COLUMN_KEY = 'PRI' THEN 'PRIMARY KEY'
        WHEN c.COLUMN_KEY = 'UNI' THEN 'UNIQUE KEY'
        WHEN c.COLUMN_KEY = 'MUL' THEN 'INDEX'
        ELSE ''
    END AS 'Key Type',
    c.EXTRA AS 'Extra Properties',
    COALESCE(c.COLUMN_COMMENT, '') AS 'Field Description',
    c.COLUMN_DEFAULT AS 'Default Value',
    c.ORDINAL_POSITION AS 'Position',
    c.COLLATION_NAME AS 'Collation',
    c.PRIVILEGES AS 'Column Privileges'
FROM
    INFORMATION_SCHEMA.COLUMNS c
WHERE
    c.TABLE_SCHEMA = DATABASE()
    AND c.TABLE_NAME = 'your_table_name'  -- Replace with actual table name
ORDER BY
    c.ORDINAL_POSITION;
*/

-- Quick reference: Available configuration options
-- SET @include_views = 1;        -- Include database views in results
-- SET @include_procedures = 1;   -- Include stored procedures and functions