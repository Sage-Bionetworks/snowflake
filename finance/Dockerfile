FROM python:3.10

COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt
COPY mip_raw_elt_batch.py mip_raw_elt_batch.py

CMD python3 mip_raw_elt_batch.py
