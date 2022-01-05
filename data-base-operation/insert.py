#!/usr/bin/python3
# -*- coding: utf-8 -*-

"""
Copyright (C) 2021 IBM Corporation
Licensed under the Apache License, Version 2.0 (the “License”);
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an “AS IS” BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
    Contributors:
        * Rafael Sene <rpsene@br.ibm.com>
"""

import os
import sys
import psycopg2
from datetime import datetime
from configparser import ConfigParser


def get_db_config(filename='postgres.ini', section='postgresql'):
    '''Reads and parses the postgres.ini file.'''
    # create a parser
    parser = ConfigParser()
    # read config file
    parser.read(filename)
    # get section, default to postgresql
    db = {}
    if parser.has_section(section):
        params = parser.items(section)
        for param in params:
            db[param[0]] = param[1]
    else:
        raise Exception('Section {0} not found in the {1} file'.format(section, filename))
    return db


def connect_db():
    '''Returns a new database connection'''
    conn = None
    try:
        # read database configuration
        params = get_db_config()
        # connect to the PostgreSQL database
        conn = psycopg2.connect(**params)
    except (Exception, psycopg2.DatabaseError) as error:
        print(error)
    return conn


def execute_sql_command(sql):
    '''Runs any SQL command'''
    conn = connect_db()
    try:
        cur = conn.cursor()
        # execute the INSERT statement
        cur.execute(sql)
        # get the powervs_id back
        conn.commit()
        # close communication with the database
        cur.close()
    except (Exception, psycopg2.DatabaseError) as error:
        print(error)
    finally:
        if conn is not None:
            conn.close()


def drop_view(view_name):
    sql = "DROP VIEW IF EXISTS " + view_name + ";"
    execute_sql_command(sql)


def create_view(view_name, source_table):
    sql="CREATE VIEW " + view_name + " AS (SELECT * FROM " + source_table + ");"
    execute_sql_command(sql)


def create_table(base_table,table_name):
    sql="CREATE TABLE " + table_name + " AS (SELECT * FROM " + base_table + " ) with no data;"
    execute_sql_command(sql)


def delete_table(table_name):
    sql="DROP TABLE IF EXISTS " + table_name + ";"
    execute_sql_command(sql)


def copy_data(table,csv_file):
    '''Copies a full csv file into a db table.'''
    conn = None
    try:
        conn = connect_db()
        cur = conn.cursor()
        with open(csv_file, 'r') as csv:
            cur.copy_from(csv,table,sep=',')
        conn.commit()
        cur.close()
    except (Exception, psycopg2.DatabaseError) as error:
        delete_table(table)
        print(error)
        conn.close()
        exit(1)
    finally:
        if conn is not None:
            conn.close()


if __name__ == '__main__':

    if len(sys.argv) > 1:
        all_vms_csv_file=sys.argv[1]
    else:
        print ("ERROR: the csv file with all VMs was not set as parameter.")
        print ("       python3 ./insert.py all_services.csv")
        exit(1)
    if os.path.exists(all_vms_csv_file):
        today = datetime.today().strftime('%Y%m%d')
        new_table = "all_powervs_services_" + today
        drop_view("pvsdata_all_services")
        delete_table(new_table)
        create_table("powervs_services_base_table",new_table)
        copy_data(new_table,all_vms_csv_file)
        create_view("pvsdata_all_services",new_table)
    else:
        print ("ERROR: could not locate the required .csv file")
        exit(1)