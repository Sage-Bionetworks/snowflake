import streamlit as st
import plotly.graph_objs as go
import numpy as np

# Generate some data
x = np.linspace(0, 10, 100)
y1 = np.sin(x)  # Sine function
y2 = np.cos(x)  # Cosine function
y3 = 0.1 * x**2 - 1  # Quadratic function

# Create traces
trace1 = go.Scatter(
    x=x,
    y=y1,
    mode='lines',
    name='sin(x)',
    line=dict(width=3),
    opacity=0.5  # Semi-transparent line
)

trace2 = go.Scatter(
    x=x,
    y=y2,
    mode='lines',
    name='cos(x)',
    line=dict(width=3),
    opacity=0.5  # Semi-transparent line
)

trace3 = go.Scatter(
    x=x,
    y=y3,
    mode='lines',
    name='0.1x^2 - 1',
    line=dict(width=3),
    opacity=0.5  # Semi-transparent line
)

data = [trace1, trace2, trace3]

layout = go.Layout(
    title='Line Plot Example',
    xaxis=dict(title='X Axis'),
    yaxis=dict(title='Y Axis'),
    legend=dict(
        itemclick="toggleothers"  # Only show this item on click
    )
)

fig = go.Figure(data=data, layout=layout)

# Show the plot in Streamlit
st.plotly_chart(fig)
