FROM quay.io/rpsene/ibmcloud-ops:powervs-base-image

LABEL authors="Rafael Sene - rpsene@br.ibm.com"

WORKDIR /output

ENV API_KEY=""
ENV IBMCLOUD_ID=""
ENV IBMCLOUD_NAME=""
ENV LANG=en_US.UTF-8

COPY collect.sh /collect.sh

ENTRYPOINT ["/usr/bin/bash", "/collect.sh"]
