from dash import Dash, html, dcc, dash_table
import dash_bootstrap_components as dbc
import warnings
warnings.simplefilter(action='ignore',category=UserWarning)
from static.queries import *


datafile = 'static/supermarket_sales.csv'
database = 'supermarket_webapp.db'
table_name = 'invoicesFact'
db_conn = create_supermarket_database(datafile, database, table_name)

city_list = get_unique_city(db_conn)
branch_list = ['A','B','C']
product_list = get_unique_productline(db_conn)
feature_list = [
    {'label':'Gender', 'value':'gender'},
    {'label':'Customer Type', 'value':'customer_type'},
    {'label':'Payment Type', 'value':'payment_type'},
    {'label':'Product Line', 'value':'product_line'}
]


layout = html.Div(children=[
    html.Div(
        id='page-header',
        className='header',
        children=[
            dcc.Markdown('## Supermarket Web App'),
            dcc.Markdown('Simple filters and data visualization of invoicing data from Jan-March 2019'),
        ]
        ),
    html.Div(
        className='row mh-100',
        children=[
            # inputs in left panel
            html.Div(
                id='filters',
                className='left-pane col-2 mh-100',
                children=[
                    "Select City(s):",
                    dcc.Dropdown(id='city',options=city_list,placeholder='Select cities',multi=True),
                    html.Br(),
                    "Select Branch(s):",
                    dcc.Dropdown(id='branch',options=branch_list,placeholder='Select branches',multi=True),
                    html.Br(),
                    "Select product line(s) or leave blank for all:",
                    dcc.Dropdown(id='products',options=product_list,placeholder='All products',multi=True), # this is ok to be None
                    html.Br(),
                    html.Div(
                        id='plot-options',
                        children=[
                            dcc.Markdown("**Adjust X and Y axes dynamically:**"),
                            "Summarize total sales or total units?",
                            dcc.RadioItems(id='metric',options=['Sales','Units'],value='Sales',labelStyle={'display':'block'}),
                            "Select plot feature:",
                            dcc.Dropdown(id='grouper',options=feature_list,multi=False,placeholder='Select feature to group'),
                        ]
                        ),
                    html.Br(),
                    dbc.Button('Run Analysis',id='run-data',className='query_button',n_clicks=0),
                ]
            ),
            # output in right panel
            html.Div(
                id='outputs',
                className='right-pane col-10 mh-100',
                children=[
                    dcc.Loading(id='loading',type='default',children=html.Div(id='loading-bars')),
                    html.Div(id='chart1',children=[]),
                    html.Div(id='chart2',children=[])
                ]
            )
        ]
    )                   
],
style={'margin':'20px'}
)