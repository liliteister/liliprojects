import pandas as pd 
from dash.dependencies import Input, Output, State
from dash import Dash, html, dcc, callback
from dash.exceptions import PreventUpdate
import plotly.express as px 
from static.queries import *
import dash_bootstrap_components as dbc
from supermarket_layout import layout

datafile = 'static/supermarket_sales.csv'
database = 'supermarket_webapp.db'
table_name = 'invoicesFact'

app = Dash(__name__, external_stylesheets=[dbc.themes.PULSE],suppress_callback_exceptions=True)
app.layout = layout

@app.callback(
    Output('loading-bars','children'),
    Output('chart1','children'),
    Output('chart2','children'),
    Input('run-data','n_clicks'),
    State('city','value'),
    State('branch','value'),
    State('products','value'),
    Input('metric','value'),
    Input('grouper','value')
)
def return_chart1(clicks, city, branch, products, metric, grouper):
    if clicks == 0:
        raise PreventUpdate

    conn = create_supermarket_database(datafile, database, table_name)
    df = pull_data_aggs(conn, city, branch, products)

    plot = create_x_plot(df, metric, grouper)
    plot_div = dcc.Graph(figure=plot)

    plot2 = create_weekly_plot(df, metric, grouper)
    plot2_div = dcc.Graph(figure=plot2)



    return [
        True, 
        plot_div,
        plot2_div
    ]




if __name__ == '__main__':
    app.run_server()