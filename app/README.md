# Medical Policy dApp

This repository provides the implementation of a decentralized application (dApp) for medical policy management. The dApp utilizes local blockchain, MongoDB, and Flask backend.

Here are the steps to setup and run the application:

## Pre-requisites

1. Make sure you have Ganache and Docker installed. If not, you can install them using the following commands, also navigate to the root directory of the backend:

```bash
npm install ganache
sudo apt install docker.io
cd app/
pip install requirements.txt
```

## Setup and Running Steps

### Step 0: Environment Setup

Activate your Python environment using the provided script.

```bash
source "myenv/bin/activate"
```

### Step 1: Start Local Blockchain

You can start the local blockchain using Ganache with the following command:

```bash
ganache --db ./my_chain -p 8545 -d
```

### Step 2: Start MongoDB Docker Container

Before starting MongoDB, ensure that Docker service is running. Start Docker service and MongoDB with the following commands:

```bash
sudo service docker start
docker start test-mongo
```

### Step 3: Deploy Smart Contract

If the contract is not deployed already, use the provided Python script or shell script to deploy it. Note that the shell script will also reset the database.

```bash
python3 scripts/deploy.py
```

Or

```bash
./reset_app.sh
```

### Step 4: Set PYTHONPATH

Set the PYTHONPATH environment variable to the current directory.

```bash
export PYTHONPATH="$PWD"
```

### Step 5: Run Backend Server

Run the backend server using Gunicorn. Ensure you have the required SSL certificate and key.

```bash
gunicorn --certfile=.localhost-ssl/localhost.crt --keyfile=.localhost-ssl/localhost.key -w 2 --timeout 0 app:app
```

### Step 6: Build and Run Frontend

Build the Flutter web application and start a local HTTPS server to serve the static files.

```bash
cd ../frontend
flutter build web
cd build/web
http-server --ssl --cert ../../.localhost-ssl/localhost.crt --key ../../.localhost-ssl/localhost.key
```
## Note

The command to run the backend server (Step 5) and the frontend server (Step 6) requires SSL certificate and key files. These are not included in the repository for security reasons. You must generate your own SSL certificate and key files for local HTTPS development.

For testing purposes, you can generate self-signed certificate and key files using OpenSSL. Here's a basic command to generate them:

```bash
openssl req -x509 -newkey rsa:4096 -keyout localhost.key -out localhost.crt -days 365 -nodes
```

This command will generate `localhost.key` (private key) and `localhost.crt` (certificate) files. When running the command, you will be prompted to enter some information for the certificate. You can just hit Enter to leave them as default for testing.

Remember, self-signed certificate will cause browser warnings because it's not signed by any of the trusted certificate authorities included with your browser. For a production application, you must use a certificate signed by a trusted certificate authority.
