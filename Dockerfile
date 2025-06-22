FROM python:3.10
#--platform=linux/amd64
# Atualizar os pacotes do sistema e instalar dependências necessárias
RUN apt-get update && apt-get install -y \
    build-essential \
    libhdf5-dev \
    libhdf5-serial-dev \
    libhdf5-103 \
    libblas-dev \
    liblapack-dev \
    gfortran \
    libffi-dev \
    libbz2-dev \
    liblzma-dev \
    libsqlite3-dev \
    libssl-dev \
    zlib1g-dev \
    libjpeg-dev \
    libpng-dev \
    libxft-dev \
    libfreetype6-dev \
    cron \
    tcpdump \
    tshark \
    jq \
    vim \
    supervisor
WORKDIR /app
#RUN pip3 install pyhdfs
RUN pip3 install scapy
#RUN pip3 install hdfs
RUN pip3 install psycopg2-binary
RUN pip3 install scikit-learn
RUN pip3 install pandas
RUN pip3 install tensorflow==2.17.0
COPY crontab /etc/cron.d/crontab
RUN chmod 0644 /etc/cron.d/crontab
RUN /usr/bin/crontab /etc/cron.d/crontab
#COPY notebooks/rotulation_amf.py /app/rotulation_amf.py
#COPY notebooks/rotulation_ausf.py /app/rotulation_ausf.py
#COPY notebooks/rotulation_nrf.py /app/rotulation_nrf.py
#COPY notebooks/rotulation_nssf.py /app/rotulation_nssf.py
#COPY notebooks/rotulation_pcf.py /app/rotulation_pcf.py
#COPY notebooks/rotulation_smf.py /app/rotulation_smf.py
#COPY notebooks/rotulation_udm.py /app/rotulation_udm.py
#COPY notebooks/rotulation_udr.py /app/rotulation_udr.py
COPY notebooks/rotulation_upf.py /app/rotulation_upf.py
COPY notebooks/utils.py /app/utils.py
COPY scripts/start_sniff.sh /app/start_sniff.sh
#COPY scripts/start_metric.sh /app/start_metric.sh
#COPY scripts/monitor_networks.sh /app/monitor_networks.sh
COPY scripts/collect_resource_metrics.py /app/collect_resource_metrics.py
COPY scripts/collect_network_metrics.py /app/collect_network_metrics.py
COPY config/supervisord.conf /etc/supervisor/conf.d/nwdaf.conf
RUN chmod +x /app/start_sniff.sh
#RUN chmod +x /app/start_metric.sh
#RUN chmod +x /app/monitor_networks.sh
RUN mkdir -p /pcaps
#RUN mkdir -p /resources
#RUN mkdir -p /networks
#COPY scripts/gen_model.py /app/gen_model.py
RUN echo $PYTHONPATH

# run crond as main process of container
#CMD ["cron", "-f"]
CMD ["supervisord", "-c", "/etc/supervisor/conf.d/nwdaf.conf"]
