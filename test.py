import json
import plotly.express as px
import pandas as pd

d = json.load(open('data/processed/colombia.json', encoding='utf-8'))
df = pd.DataFrame({'id': ['18', '88'], 'val': [10, 20]})

fig = px.choropleth(df, geojson=d, locations='id', color='val', featureidkey='objects.MGN_ANM_DPTOS.geometries.properties.DPTO_CCDGO')
print('Success')
