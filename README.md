# nwdaf-k8s

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