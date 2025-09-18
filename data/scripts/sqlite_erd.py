#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
@name: sqlite_erd.py
@author: Finbarrs Oketunji
@contact: f@finbarrs.eu
@time: Thursday September 18 12:12:12 2025
@desc: SQLite Textual ERD.
@run: python3 -m sqlite_erd northwind.db
"""

import sqlite3, textwrap, sys

db = sqlite3.connect(sys.argv[1])
db.row_factory = sqlite3.Row

# ---- tables ----
for tbl, sql in db.execute(
        "SELECT name, sql FROM sqlite_master WHERE type='table' AND NOT name LIKE 'sqlite_%'"):
    print(f"\nTABLE: {tbl}")
    for row in db.execute(f"PRAGMA table_info('{tbl}')"):
        print(f"  {row['name']:20} {row['type']:10} {'PK' if row['pk'] else ''}")
    # ---- foreign keys ----
    for fk in db.execute(f"PRAGMA foreign_key_list('{tbl}')"):
        print(f"  FK {tbl}.{fk['from']} -> {fk['table']}.{fk['to']}")