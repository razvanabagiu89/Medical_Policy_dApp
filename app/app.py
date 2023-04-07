from flask import Flask, render_template, request, redirect, url_for, session
from functools import wraps
from pymongo import MongoClient
from web3 import Web3
import os
from dotenv import load_dotenv
from scripts.help import get_contract
import time
import boto3
from hashlib import sha256

# app
app = Flask(__name__)
app.secret_key = "mysecretkey"

# mongo
client = MongoClient("mongodb://localhost:27017/")
db = client["app_db"]
users = db["users"]

# setup web3
ganache_url = "http://127.0.0.1:8545"
web3 = Web3(Web3.HTTPProvider(ganache_url))
if web3.is_connected():
    print("Connected to ganache-cli")
load_dotenv(".env")
my_address = os.environ.get("MY_ADDRESS")
private_key = os.getenv("PRIVATE_KEY")
chain_id = int(os.getenv("CHAIN_ID"))

# addresses - TBD with yml/json
patient_registry_contract_address = "0xE8e43b5D61C43375aB7b651F1419F2a81C5E6615"
patient_registry_contract = get_contract(
    web3, "PatientRegistryContract", patient_registry_contract_address
)


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/register", methods=["POST"])
def register():
    username = request.form["username"]
    password = request.form["password"]
    user_type = request.form["type"]
    # address = request.form["address"]
    address = "0x1dF62f291b2E969fB0849d99D9Ce41e2F137006e"

    patient_registry_contract = get_contract(
        web3, "PatientRegistryContract", patient_registry_contract_address
    )
    tx_hash = patient_registry_contract.functions.newPatient(address).transact(
        {"from": my_address}
    )
    tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)

    event_filter = patient_registry_contract.events.newPatientEvent.create_filter(
        fromBlock=tx_receipt.blockNumber,
        toBlock="latest"
        # argument_filters={'patientAddress': Web3.to_checksum_address(address)} TBD
    )
    event = wait_for_event(event_filter)

    patient_id = int(event.args["patientID"])
    users.insert_one(
        {
            "username": username,
            "password": password,
            "type": user_type,
            "address": address,
            "patient_id": patient_id,
        }
    )

    return f"User registered successfully: {event}"


def wait_for_event(event_filter):
    while True:
        events = event_filter.get_all_entries()
        if len(events) > 0:
            return events[0]
        time.sleep(1)


@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        username = request.form["username"]
        password = request.form["password"]

        user = users.find_one({"username": username})

        if user and user["password"] == password:
            session["username"] = username
            return redirect(url_for("dashboard"))
        else:
            return render_template("login.html", error="Invalid username or password")

    return render_template("login.html")


def login_required(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        if "username" in session:
            return func(*args, **kwargs)
        else:
            return redirect(url_for("login"))

    return wrapper


@app.route("/dashboard")
@login_required
def dashboard():
    return render_template("dashboard.html")


@app.route("/logout", methods=["POST"])
@login_required
def logout():
    session.pop("username", None)
    return redirect(url_for("login"))


@app.route("/add_medical_record", methods=["POST"])
@login_required
def add_medical_record():
    username = session.get("username")
    result = users.find_one({"username": username})
    patient_id = result["patient_id"]
    file = request.files["pdfFile"]

    premade_hash = str(patient_id) + "-" + file.filename
    file_hash = bytes.fromhex(sha256(premade_hash.encode("utf-8")).hexdigest())

    bucket_name = "bucket-test-rzw"

    access_key = os.environ.get("ACCESS_KEY")
    secret_key = os.environ.get("SECRET_ACCESS_KEY")

    s3 = boto3.client(
        "s3", aws_access_key_id=access_key, aws_secret_access_key=secret_key
    )
    s3.put_object(
        Bucket=bucket_name, Key=file.filename, Body=file, ServerSideEncryption="AES256"
    )

    # update the patient's medical record on blockchain
    patient_registry_contract = get_contract(
        web3, "PatientRegistryContract", patient_registry_contract_address
    )
    tx_hash = patient_registry_contract.functions.addMedicalRecordToPatient(
        patient_id, file_hash
    ).transact({"from": my_address})
    tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)

    event_filter = patient_registry_contract.events.newMedicalRecordEvent.create_filter(
        fromBlock=tx_receipt.blockNumber,
        toBlock="latest"
        # argument_filters={'patientID': ''} TBD
    )
    event = wait_for_event(event_filter)
    if (event.args["medicalRecordHash"]) == file_hash:
        print(event)
        return "File uploaded successfully"

    return "Failed to upload file"


@app.route("/get_patient_details", methods=["POST"])
@login_required
def get_patient_details():
    username = session.get("username")
    result = users.find_one({"username": username})
    patient_id = result["patient_id"]
    patient_registry_contract = get_contract(
        web3, "PatientRegistryContract", patient_registry_contract_address
    )
    tx_hash = patient_registry_contract.functions.getPatientDetails(
        patient_id
    ).transact({"from": my_address})
    tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)

    event_filter = patient_registry_contract.events.showPatientDetailsEvent.create_filter(
        fromBlock=tx_receipt.blockNumber,
        toBlock="latest"
        # argument_filters={'patientID': ''} TBD
    )
    event = wait_for_event(event_filter)

    return f"Public patient details fetched successfully:{event}"


if __name__ == "__main__":
    app.run(debug=True)
