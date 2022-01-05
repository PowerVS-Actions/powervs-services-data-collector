FROM quay.io/rpsene/ibmcloud-ops:powervs-base-image

LABEL authors="Rafael Sene - rpsene@br.ibm.com"

WORKDIR /input

COPY ./insert.py .
COPY ./postgres.ini .
COPY ./ssl.crt .

ENTRYPOINT ["/usr/bin/python3", "./insert.py"]