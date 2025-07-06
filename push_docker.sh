#!/bin/bash

sudo docker build -t nwdaf-image .
sudo docker tag nwdaf-image juniamaisa/nwdaf:latest
sudo docker push juniamaisa/nwdaf:latest