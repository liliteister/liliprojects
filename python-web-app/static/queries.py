from turtle import width
import pandas as pd 
import plotly.express as px
import sqlite3
import os
from datetime import datetime

datafile = 'static/supermarket_sales.csv'
database = 'supermarket_webapp.db'
table_name = 'invoicesFact'


def create_supermarket_database(filename, dbname, table):
    # creates the database and table if it doesn't already exist

    # spin up database for storing data as table - if exists will connect, if not will create
    conn = sqlite3.connect(dbname)
    c = conn.cursor()

    # load table
    tables_query = f'''
        SELECT name 
        FROM sqlite_master
        WHERE type='table' 
        '''
    table_result = pd.read_sql_query(tables_query, conn)

    if table not in table_result.name.unique().tolist():
        # get data from csv
        super_df = pd.read_csv(filename)
        super_df = super_df[
            ['Invoice ID','Branch','City','Customer type',
            'Gender','Product line','Unit price','Quantity',
            'Tax 5%','Total','Date','Payment']
        ]
        super_df['Date'] = pd.to_datetime(super_df['Date'])
        super_df['Week'] = super_df['Date'] - pd.to_timedelta(super_df['Date'].dt.dayofweek, unit='d')

        super_df.rename(columns={
            'Invoice ID':'invoice_id','Branch':'branch','City':'city',
            'Customer type':'customer_type','Gender':'gender',
            'Product line':'product_line','Unit price':'unit_price',
            'Quantity':'quantity','Tax 5%':'tax5','Total':'total',
            'Date':'date','Payment':'payment_type'
        }, inplace=True)

        # create table in database
        table_invoices = f'''
        create table if not exists {table} (
            invoice_id varchar(100) primary key,
            branch varchar(2),
            city varchar(100),
            customer_type varchar(100),
            gender varchar(100),
            product_line varchar(100),
            unit_price numeric,
            quantity int,
            tax5 numeric,
            total numeric,
            date datetime,
            week datetime,
            payment_type varchar(100)
        )
        ''' 

        # load data to table
        c.execute(table_invoices)
        super_df.to_sql(table, conn, if_exists='append', index=False)
        conn.commit()

    return conn



def get_unique_city(c):
    query = '''
    select distinct city from invoicesFact
    '''
    df = pd.read_sql_query(query, c)
    return sorted(df.city.unique().tolist())


def get_unique_productline(c):
    query = '''
    select distinct product_line from invoicesFact
    '''
    df = pd.read_sql_query(query, c)
    return sorted(df.product_line.unique().tolist())

def pull_data_aggs(conn, city, branch, products):
    if products == None:
        product_filter = 'True'
    else:
        in_st = ','.join(f"'{i}'" for i in products)
        product_filter = f'''
            product_line in ({in_st})
        '''

    branch_filter = ','.join(f"'{i}'" for i in branch)
    city_filter = ','.join(f"'{i}'" for i in city)

    # cool, sqlite has like no date functions
    query = f"""
        select 
            customer_type
            , gender
            , product_line
            , payment_type
            , week
            , sum(total) as total_sales
            , sum(quantity) as total_units
            , count(distinct invoice_id) as invoices
        from 
            invoicesFact 
        where 
            city in ({city_filter})
            and branch in ({branch_filter})
            and {product_filter}
        group by 
            customer_type, gender, product_line, payment_type, week
    """

    df = pd.read_sql_query(query, conn)
    return df


def create_x_plot(df, metric, grouper):
    if metric == 'Sales':
        y_metric = 'total_sales'
    else:
        y_metric = 'total_units'

    ylabels = {
        'customer_type':'Customer Type',
        'gender':'Gender',
        'product_line':'Product Line',
        'payment_type':'Payment Type'
    }

    p = px.histogram(
        df,
        y=grouper,
        x=y_metric,
        width=600,
        height=300
    )
    p.update_layout(
        title_text=f'Total {metric} by {ylabels[grouper]}',
        yaxis_title=f'{ylabels[grouper]}',
        xaxis_title=metric
    )
    return p

def create_weekly_plot(df, metric, grouper):
    df['week'] = pd.to_datetime(df['week'])
    df.sort_values(by='week', inplace=True)

    if metric == 'Sales':
        y_metric = 'total_sales'
    else:
        y_metric = 'total_units'

    df_agg = df.groupby(['week',grouper]).agg({y_metric: "sum"}).reset_index()

    xlabels = {
        'customer_type':'Customer Type',
        'gender':'Gender',
        'product_line':'Product Line',
        'payment_type':'Payment Type'
    }

    p = px.line(
        df_agg,
        x='week',
        y=y_metric,
        color=grouper,
        width=1200,
        height=500
    )
    p.update_layout(
        title_text=f'Weekly {metric} by {xlabels[grouper]}',
        xaxis_title='Week',
        yaxis_title=metric,
        legend_title_text=f'{xlabels[grouper]}'
    )
    return p


conn= create_supermarket_database(datafile, database, table_name)
query = f"""
        select 
            customer_type
            , gender
            , product_line
            , payment_type
            , week
            , sum(total) as total_sales
            , sum(quantity) as total_units
            , count(distinct invoice_id) as invoices
        from 
            invoicesFact 
        group by 
            customer_type, gender, product_line, payment_type, week
    """

df = pd.read_sql_query(query, conn)
df['week'] = pd.to_datetime(df['week'])
df.sort_values(by='week', inplace=True)

df_agg =  df.groupby(['week','gender']).agg({'total_sales': "sum"})
print(df_agg.reset_index())