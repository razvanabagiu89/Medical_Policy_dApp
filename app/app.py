from flask import Flask, request, session, jsonify
from pymongo import MongoClient, errors, ASCENDING
from web3 import Web3
from scripts.utils import *
import datetime

app = Flask(__name__)
app.secret_key = app_secret_key

client = MongoClient(mongodb_host)
db = client[db_name]
entities = db[entities]
entities.create_index([("ID", ASCENDING)], unique=True)

web3 = Web3(Web3.HTTPProvider(web3_host))
if web3.is_connected():
    print("Connected to ganache-cli")

patient_registry_contract = get_contract(
    web3, "PatientRegistryContract", patient_registry_contract_address
)
access_policy_contract = get_contract(
    web3, "AccessPolicyContract", access_policy_contract_address
)


@app.route("/api/patient", methods=["POST"])
def add_patient():
    patient_username = request.json["username"]
    patient_password = request.json["password"]
    patient_address = request.json["patient_address"]
    patient_address_converted = Web3.to_checksum_address(patient_address)

    inserted = False
    while not inserted:
        patient_id = randint(0, 2)
        try:
            # db
            entities.insert_one(
                {
                    "username": patient_username,
                    "password": patient_password,
                    "ID": patient_id,
                    "type": "patient",
                    "wallets": [patient_address_converted],
                    "medical_records_hashes": [],
                    "requests": [],
                }
            )
            # blockchain
            create_patient(patient_registry_contract, patient_id, patient_address_converted, web3) # by patientID
            create_policies(access_policy_contract, patient_address_converted, web3) # by address
            inserted = True
            print("Patient inserted with ID:", patient_id)
            return jsonify({"status": "success", "patient_id": patient_id}), 201
        except errors.DuplicateKeyError:
            print(
                "Error: A patient with ID",
                patient_id,
                "already exists. Retrying with a new ID...",
            )

    return (
        jsonify({"message": "Patient created successfully", "patient_id": patient_id}),
        201,
    )


@app.route("/api/institution", methods=["POST"])
def add_institution():
    institution_username = request.json["username"]
    institution_password = request.json["password"]
    institution_CIF = request.json["CIF"]

    try:
        # db
        entities.insert_one(
            {
                "username": institution_username,
                "password": institution_password,
                "ID": institution_CIF,
                "type": "institution",
            }
        )
        print("Institution inserted with CIF:", institution_CIF)
        return jsonify({"status": "success", "CIF": institution_CIF}), 201
    except errors.DuplicateKeyError:
        print("Error: An institution with this CIF already exists.")
        return (
            jsonify(
                {
                    "status": "error",
                    "message": "An institution with this CIF already exists.",
                }
            ),
            400,
        )


@app.route("/api/patient/<patient_id>/wallet", methods=["POST"])
def add_wallet(patient_id):

    patient_id = int(request.json["patient_id"])
    patient = entities.find_one({"ID": patient_id})
    if patient:
        patient_address = request.json["patient_address"]
        new_patient_address = request.json["new_patient_address"]
        patient_address_converted = Web3.to_checksum_address(patient_address)
        new_patient_address_converted = Web3.to_checksum_address(new_patient_address)
        # db
        entities.update_one(
            {"ID": patient_id},
            {"$addToSet": {"wallets": new_patient_address_converted}}
        )
        # blockchain
        try:
            add_wallet_to_patient(
                patient_registry_contract,
                patient_address_converted,
                new_patient_address_converted,
                patient_id,
                web3,
            )
            print("Wallet added to patient with ID:", patient_id)
            return (
                jsonify({"status": "success", "new_patient_address": new_patient_address_converted}),
                201,
            )
        except WalletAddressAlreadyExists:
            return jsonify({"status": "error", "message": "Wallet already exists."}), 400

    else:
        print("Error: Patient not found.")
        return jsonify({"status": "error", "message": "Patient not found."}), 404


@app.route("/api/patient/<patient_id>/wallet", methods=["GET"])
def get_patient_wallets(patient_id):
    blockchain_addresses = get_patient_addresses(
        patient_registry_contract, int(patient_id)
    )
    print(blockchain_addresses)

    patient = entities.find_one({"ID": int(patient_id), "type": "patient"})
    if patient is None:
        return jsonify({"error": "Patient not found"}), 404

    db_addresses = patient.get("wallets", [])
    print(db_addresses)

    # make sure blockchain and db is corellated
    if set(blockchain_addresses) == set(db_addresses):
        return jsonify({"status": "success", "wallets": db_addresses}), 200
    else:
        return jsonify({"error": "Data mismatch between blockchain and MongoDB"}), 500


@app.route("/api/patient/<patient_id>/medical_record", methods=["POST"])
def add_medical_record(patient_id):
    patient_id = int(request.json["patient_id"])
    patient = entities.find_one({"ID": patient_id})

    if patient:
        patient_address = request.json["patient_address"]
        patient_address_converted = Web3.to_checksum_address(patient_address)
        filename = request.json["filename"]
        medical_record_hash = compute_hash(filename + str(datetime.datetime.now()))
        # db
        entities.update_one(
            {"ID": patient_id},
            {"$addToSet": {"medical_records_hashes": medical_record_hash}}
        )
        # blockchain
        add_medical_record_to_patient(
            patient_registry_contract,
            patient_address_converted,
            patient_id,
            medical_record_hash,
            web3,
        )
        print("Medical record added to patient with ID:", patient_id)
        return (
            jsonify(
                {"status": "success", "medical_record_hash": medical_record_hash.hex()}
            ),  # notice hex() because bytes is not JSON serializable
            201,
        )
    else:
        print("Error: Patient not found.")
        return jsonify({"status": "error", "message": "Patient not found."}), 404


if __name__ == "__main__":
    app.run(debug=True)
