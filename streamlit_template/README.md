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
- Begin developing! Use the pre-existing `app.py` in the template as a guide for structuring your application.

> [!TIP]
> The `utils.py` houses the functions used to connect to Snowflake and run your SQL queries. Make sure to reserve an area
> in the script for using `get_data_from_snowflake` with your queries from Step 2.
>
> Example:
>
> ```
> from toolkit.queries import (QUERY_ENTITY_DISTRIBUTION, QUERY_PROJECT_SIZES,
>                              QUERY_PROJECT_DOWNLOADS, QUERY_UNIQUE_USERS)
>  
>  entity_distribution_df = get_data_from_snowflake(QUERY_ENTITY_DISTRIBUTION)
>  project_sizes_df = get_data_from_snowflake(QUERY_PROJECT_SIZES)
>  project_downloads_df = get_data_from_snowflake(QUERY_PROJECT_DOWNLOADS)
>  unique_users_df = get_data_from_snowflake(QUERY_UNIQUE_USERS)
> ```

### 5. Test your Application

We encourage implementing unit and regression tests in your application, particularly if there are components that involve interacting with the application
to display and/or transform data (e.g. buttons, dropdown menus, sliders, so on).

- Navigate to `tests/test_app.py` to modify the existing script.
- The default tests use [Streamlit's AppTest tool](https://docs.streamlit.io/develop/api-reference/app-testing/st.testing.v1.apptest#run-an-apptest-script) to launch the application and retrieve its components. Please modify these existing tests or create brand new ones
as you see fit.

> [!TIP]
> Make sure to launch the test suite from the base directory of the `streamlit_app/` (i.e `pytest tests/test_app.py`)
> to avoid import issues.

### 6. Dockerize your Application

- Update the `requirements.txt` file with the packages used in any of the scripts above.
- **_(Optional)_** You can choose to push a Docker image to the GitHub Container Registry to pull it directly from the container registry when ready to deploy.
  For instructions on how to deploy your Docker image to the GitHub Container Registry, [see here](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry).

### 7. Launch your Application on AWS EC2

- Create an EC2: Linux Docker product from the Sage Service Catalog.
- Go to _Provisioned Products_ in the menu on the left-hand-side.
- Once your EC2 product's `status` is set to `Available`, click it and navigate to the _Events_ tab.
- Click the URL next to `ConnectionURI` to launch a shell session in your instance.
- Navigate to your home directory (`cd ~`).
- **_(Optional)_** If you chose to push your Docker image to the GitHub Container Registry, pull your image down (`docker pull <image name>`).
- If you chose not to work with the Container Registry, clone your repository in your desired working directory.
- Create your `secrets.toml` file again. The Docker image of your Streamlit application will not have the `secrets.toml` for security reasons.
- 
- Run your Docker container from the image, and make sure to have your `secrets.toml` mounted and the 8501 port specified, like so:
  ```
  docker run -p 8501:8501 \
    -v $PWD/secrets.toml:.streamlit/secrets.toml \
    <image name>
  ```
> [!TIP]
> If you would like to leave the app running indefinitely, even after you close your shell session, be sure to run with the container detached (i.e. Have `-d` somewhere in the `docker run` command)
