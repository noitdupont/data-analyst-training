#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
@name: data_export.py
@author: Finbarrs Oketunji
@contact: f@finbarrs.eu
@time: Sunday August 31 01:18:20 2025
@desc: Export Northwind database tables.
"""

import pymysql
import csv
import logging
from typing import Optional, Dict, Any


class MySQLToCSVExporter:
    """
    Exports MySQL table data to CSV format using comma separation.
    """
    
    def __init__(self, host: str, user: str, password: str, database: str, port: int = 3306):
        """
        Initialise MySQL connection parameters and logging.
        
        Args:
            host: MySQL server hostname
            user: Database username
            password: Database password
            database: Database name
            port: MySQL server port (default: 3306)
        """
        self.connection_params = {
            'host': host,
            'user': user,
            'password': password,
            'database': database,
            'port': port,
            'charset': 'utf8mb4'
        }
        self.connection: Optional[pymysql.Connection] = None
        
        # Configure logging
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.StreamHandler(),
                logging.FileHandler('mysql_export.log')
            ]
        )
        self.logger = logging.getLogger(__name__)
    
    def connect(self) -> None:
        """
        Establish connection to MySQL database.
        """
        try:
            self.logger.info(f"Connecting to MySQL database: {self.connection_params['host']}:{self.connection_params['port']}")
            self.connection = pymysql.connect(**self.connection_params)
            self.logger.info("Successfully connected to MySQL database")
        except pymysql.Error as e:
            self.logger.error(f"Failed to connect to MySQL: {e}")
            raise ConnectionError(f"Failed to connect to MySQL: {e}")
    
    def disconnect(self) -> None:
        """
        Close MySQL connection.
        """
        if self.connection:
            self.connection.close()
            self.connection = None
            self.logger.info("MySQL connection closed")
    
    def export_multiple_tables(self, tables: Dict[str, str]) -> None:
        """
        Export multiple MySQL tables to separate CSV files.
        
        Args:
            tables: Dictionary mapping table names to output file names
        """
        if not self.connection:
            self.connect()
        
        for table_name, output_file in tables.items():
            self.logger.info(f"Starting export of table: {table_name}")
            self.export_single_table(table_name, output_file)
    
    def export_single_table(self, table_name: str, output_file: str) -> None:
        """
        Export single MySQL table to CSV file.
        
        Args:
            table_name: Name of the table to export
            output_file: Path to output CSV file
        """
        query = f"SELECT * FROM {table_name}"
        self.logger.info(f"Executing query: {query}")
        
        try:
            with self.connection.cursor() as cursor:
                # Count total rows first
                count_query = f"SELECT COUNT(*) FROM {table_name}"
                cursor.execute(count_query)
                total_rows = cursor.fetchone()[0]
                self.logger.info(f"Table {table_name}: {total_rows} rows to export")
                
                # Execute main query
                cursor.execute(query)
                
                # Get column names
                columns = [desc[0] for desc in cursor.description]
                self.logger.info(f"Table {table_name} columns: {columns}")
                
                # Write to CSV with proper comma delimiter
                with open(output_file, 'w', newline='', encoding='utf-8') as csvfile:
                    writer = csv.writer(
                        csvfile, 
                        delimiter=',', 
                        quoting=csv.QUOTE_MINIMAL,
                        escapechar='\\'
                    )
                    
                    # Write header
                    writer.writerow(columns)
                    self.logger.info(f"CSV header written for {table_name}")
                    
                    # Write data rows in batches
                    rows_exported = 0
                    while True:
                        rows = cursor.fetchmany(1000)
                        if not rows:
                            break
                        
                        writer.writerows(rows)
                        rows_exported += len(rows)
                        
                        if rows_exported % 5000 == 0:  # Log every 5000 rows
                            self.logger.info(f"Table {table_name}: {rows_exported}/{total_rows} rows exported")
                    
                    self.logger.info(f"Table {table_name}: Export completed - {rows_exported} rows written to {output_file}")
                        
        except pymysql.Error as e:
            self.logger.error(f"Database error during {table_name} export: {e}")
            raise RuntimeError(f"Database error during {table_name} export: {e}")
        except IOError as e:
            self.logger.error(f"File writing error for {table_name}: {e}")
            raise RuntimeError(f"File writing error for {table_name}: {e}")

    def export_table_to_csv(self, table_name: str, output_file: str, 
                           where_clause: str = "", limit: Optional[int] = None) -> None:
        """
        Export MySQL table to CSV file.
        
        Args:
            table_name: Name of the table to export
            output_file: Path to output CSV file
            where_clause: Optional WHERE clause (without 'WHERE' keyword)
            limit: Optional limit on number of rows
        """
        if not self.connection:
            self.connect()
        
        # Build SQL query
        query = f"SELECT * FROM {table_name}"
        if where_clause:
            query += f" WHERE {where_clause}"
        if limit:
            query += f" LIMIT {limit}"
        
        self.logger.info(f"Executing query: {query}")
        
        try:
            with self.connection.cursor() as cursor:
                cursor.execute(query)
                
                # Get column names
                columns = [desc[0] for desc in cursor.description]
                self.logger.info(f"Table columns: {columns}")
                
                # Count total rows first
                count_query = f"SELECT COUNT(*) FROM {table_name}"
                if where_clause:
                    count_query += f" WHERE {where_clause}"
                
                cursor.execute(count_query)
                total_rows = cursor.fetchone()[0]
                self.logger.info(f"Total rows to export: {total_rows}")
                
                # Re-execute main query for data export
                cursor.execute(query)
                
                # Write to CSV with proper comma delimiter
                with open(output_file, 'w', newline='', encoding='utf-8') as csvfile:
                    writer = csv.writer(
                        csvfile, 
                        delimiter=',', 
                        quoting=csv.QUOTE_MINIMAL,
                        escapechar='\\'
                    )
                    
                    # Write header
                    writer.writerow(columns)
                    self.logger.info("CSV header written")
                    
                    # Write data rows in batches
                    rows_exported = 0
                    while True:
                        rows = cursor.fetchmany(1000)
                        if not rows:
                            break
                        
                        writer.writerows(rows)
                        rows_exported += len(rows)
                        self.logger.info(f"Exported {rows_exported} rows so far...")
                    
                    self.logger.info(f"Export completed: {rows_exported} rows written to {output_file}")
                        
        except pymysql.Error as e:
            self.logger.error(f"Database error during export: {e}")
            raise RuntimeError(f"Database error during export: {e}")
        except IOError as e:
            self.logger.error(f"File writing error: {e}")
            raise RuntimeError(f"File writing error: {e}")
    
    def __enter__(self):
        """
        Context manager entry.
        """
        self.connect()
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """
        Context manager exit.
        """
        self.disconnect()


if __name__ == "__main__":
    # Database configuration
    db_config = {
        'host': 'localhost',
        'user': 'root',
        'password': '',
        'database': 'Northwind'
    }
    
    # Define table mappings (table_name -> output_file)
    tables_to_export = {
        'Categories': 'categories.csv',
        'Customers': 'customers.csv',
        'Employees': 'employees.csv',
        'OrderDetails': 'order_details.csv',
        'Orders': 'orders.csv',
        'Products': 'products.csv',
        'Shippers': 'shippers.csv',
        'Suppliers': 'suppliers.csv'
    }
    
    # Export all tables
    try:
        with MySQLToCSVExporter(**db_config) as exporter:
            print("Starting export of all Northwind tables...")
            exporter.export_multiple_tables(tables_to_export)
        
        print("\nAll tables exported successfully!")
        print("Generated files:")
        for table, filename in tables_to_export.items():
            print(f"  {table} -> {filename}")
        
    except Exception as e:
        print(f"Export failed: {e}")
        logging.error(f"Bulk export operation failed: {e}")
