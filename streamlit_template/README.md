## Introduction
This area of the repository serves as a template for developing your own Streamlit application for internal use within Sage Bionetworks.
The template is designed to source data from the databases in Snowflake and compose a dashboard using the various tools provided by Streamlit.

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

### Setup and Enabling Access to Snowflake 

1. Create a fork of this repository under your GitHub user account
2. Within the `.streamlit` folder, you will need a file called `secrets.toml` which will be read by Streamlit before making communications with Snowflake.
Use the contents in `example_secrets.toml` as a syntax guide for how `secrets.toml` should be set up. See the [Snowflake documentation](https://docs.snowflake.com/en/user-guide/admin-account-identifier#using-an-account-name-as-an-identifier) for how to find your
account name.
3. Test your connection to Snowflake by running the example Streamlit app at the base of this directory. This will launch the application on port 8501, the default port for Streamlit applications.
   
   ```
   streamlit run app.py
   ```

### Build your Queries

4. Once you've configured your access to Snowflake, you can begin working on your queries

### Build your Widgets

### Build your Application

### Test your Application

### Dockerize your Application

### Launch your Application on AWS EC2
