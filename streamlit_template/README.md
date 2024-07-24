## Introduction
This area of the repository serves as a template for developing your own Streamlit application for internal use within Sage Bionetworks.
The template is designed to source data from the databases in Snowflake and compose a dashboard using the various tools provided by [Streamlit](https://docs.streamlit.io/)
and plotly.

Below is the directory structure for all the components within `streamlit_template`. In the following section we will break down the purpose for
each component within `streamlit_template`, and how to use these components to design your own application and deploy via an AWS EC2 instance.

```
streamlit_template/
├── .streamlit/
│   ├── config.toml
│   └── example_secrets.toml
├── tests/
│   ├── __init__.py
│   └── test_app.py
├── toolkit/
│   ├── __init__.py
│   ├── queries.py
│   ├── utils.py
|   └── widgets.py
├── Dockerfile
├── app.py
├── requirements.txt
└── style.css
```

## Create your own Streamlit application

### 1. Setup and Enable Access to Snowflake 

- Create a fork of this repository under your GitHub user account.
- Within the `.streamlit` folder, you will need a file called `secrets.toml` which will be read by Streamlit before making communications with Snowflake.
Use the contents in `example_secrets.toml` as a syntax guide for how `secrets.toml` should be set up. See the [Snowflake documentation](https://docs.snowflake.com/en/user-guide/admin-account-identifier#using-an-account-name-as-an-identifier) for how to find your
account name.
- Test your connection to Snowflake by running the example Streamlit app at the base of this directory. This will launch the application on port 8501, the default port for Streamlit applications.
   
   ```
   streamlit run app.py
   ```

> [!CAUTION]
> Do not commit your `secrets.toml` file to your forked repository. Keep your credentials secure and do not expose them to the public.

### 2. Build your Queries

Once you've completed the setup above, you can begin working on your SQL queries.
- Navigate to `queries.py` under the `toolkit/` folder.
- Your queries will be string objects. Assign each of them an easy-to-remember variable name, as they will be imported into `app.py` later on.
- It is encouraged that you test these queries in a SQL Worksheet on Snowflake's Snowsight before running them on your application.

Example:
```
QUERY_NUMBER_OF_FILES = """

select
    count(*) as number_of_files
from
    node_latest
where 
    project_id = '53214489'
and
    node_type = 'file' // we want files, not folders or any other entity
and
    annotations is not NULL;
"""
```

### 3. Build your Widgets

Your widgets will be the main visual component of your Streamlit application.

- Navigate to `widgets.py` under the `toolkit/` folder.
- Modify the imports as necessary. By default we are using `plotly` to design our widgets.
- Create a function for each widget. For guidance, follow one of the examples in `widgets.py`.

### 4. Build your Application

Here is where all your work on `queries.py` and `widgets.py` come together.
- Navigate to `app.py` to begin developing.
- Import the queries you developed in Step 2.
- Import the widgets you developed in Step 3.
- 

### 5. Test your Application

### 6. Dockerize your Application

### 7. Launch your Application on AWS EC2
