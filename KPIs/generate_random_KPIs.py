# generate_random_KPIs.py

import datetime as dt, pandas as pd, numpy as np, math

def get_days_list(start_date, num_days):

    dates = []
    end_date = start_date + dt.timedelta(num_days)
    delta = end_date - start_date

    for i in range(delta.days):
        day = start_date + dt.timedelta(days=i)
        dates.append(day)

    return dates


def get_random_list(num, min, max):

    denominators = np.random.randint(min, max, num)
    percents = np.random.uniform(0.65, 1.0, num)
    numerators = []
    for i in range(0, len(denominators)):
        numerators.append(math.ceil(denominators[i] * percents[i]))

    return denominators, numerators


def make_daily_kpi(
    name, start_date, num_days, min_den, max_den, min_pcnt=0.65, max_pnct=1.0
):

    name_list = [name] * num_days
    denominator, numerator = get_random_list(num_days, min_den, max_den)

    kpi = pd.DataFrame(
        {
            "measureName": name_list,
            "measureDate": get_days_list(start_date, num_days),
            "denominator": denominator,
            "numerator": numerator,
        }
    )

    return kpi


start_date = dt.date(2020, 1, 1)
day_count = 365

my_kpi1 = make_daily_kpi(
    "Belgyrussa Mergdors ala Mutolqueue", start_date, day_count, 1400, 1800
)

my_kpi2 = make_daily_kpi(
        "Usseldortuses Morgiqueaussin Alaf", start_date, day_count, 225, 350
    )

my_kpi3 = make_daily_kpi(
        "Maughan Oylousself Tung ala Youmakan Ghavinte", start_date, day_count, 10000, 16000
    )

my_kpis = pd.concat([my_kpi1, my_kpi2, my_kpi3])

pd.DataFrame.to_csv(my_kpis, "my_kpis.csv")
