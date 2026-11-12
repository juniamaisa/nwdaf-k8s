# NWDAF a 5G data analytics implementation

This repository contains a Network Data Analytics Function (NWDAF) developed as part of the **SFI2 – Slicing Future Internet Infrastructures** and **PORVIR 5G – Programmability, Orchestration and Virtualization in 5G Networks** projects. The implementation is based on research published at the **2024 IEEE 13th International Conference on Cloud Networking (CloudNet)** named Anomaly detection employing a 5g core data analytics framework.

## nwdaf-k8s

This repository contains everything needed to build and deploy a Python + cron-based NWDAF system and a PostgreSQL database inside a Kubernetes environment — without using DockerHub or manual steps.

## Structure

- `Dockerfile`: Custom Python 3.10 image with cron and required libraries
- `notebooks/`: Python scripts executed by cron
- `crontab`: Cron schedule definition
- `k8s/`:
  - `nwdaf-pod.yaml`: Kubernetes Pod definition for NWDAF with mounted code
  - `postgres.yaml`: PostgreSQL deployment
  - `volume.yaml`: Persistent volume claim and volume for host file access
  - `secret.yaml`: PostgreSQL password
- `build_deploy.sh`: Script to automate the full process

---

## Requirements

- Kubernetes cluster (minikube, kind, microk8s, etc.)
- `kubectl` installed
- `git` and `bash` available
- Python files to be run by cron should exist on your host machine under `./notebooks`

---

## How it works

- The custom image is built from the `Dockerfile` on your machine (no DockerHub).
- Kubernetes Pod mounts the local `notebooks` directory containing your Python scripts.
- Cron runs those Python scripts at the schedule defined in the `crontab` file.
- PostgreSQL is launched as a separate service with persistent storage and a secret password.

---

## Usage

Clone the repo and run the build script:

```bash
git clone https://github.com/your_user/nwdaf-k8s.git
cd nwdaf-k8s
chmod +x build_deploy.sh
./build_deploy.sh
```

---

## Cite this work

J. M. Oliveira et al., "Anomaly Detection Employing a 5G Core Data Analytics Framework," 2024 IEEE 13th International Conference on Cloud Networking (CloudNet), Rio de Janeiro, Brazil, 2024, pp. 1-9, doi: 10.1109/CloudNet62863.2024.10815754. keywords: {Analytical models;Data analysis;Machine learning algorithms;5G mobile communication;Source coding;Inspection;3GPP;Computer security;Anomaly detection;Application programming interfaces;NWDAF;5G network;5G core;data analytics;network data analytics;anomaly detection;3GPP},

```bash
@INPROCEEDINGS{10815754,
  author={Oliveira, Júnia Maísa and Almeida, Jônatan and De Britto e Silva, Erik and Rodrigues Moreira, Larissa Ferreira and Moreira, Rodrigo and Silva, Flávio O. and Macedo, Daniel F. and Nogueira, José Marcos},
  booktitle={2024 IEEE 13th International Conference on Cloud Networking (CloudNet)}, 
  title={Anomaly Detection Employing a 5G Core Data Analytics Framework}, 
  year={2024},
  volume={},
  number={},
  pages={1-9},
  doi={10.1109/CloudNet62863.2024.10815754}}
```

