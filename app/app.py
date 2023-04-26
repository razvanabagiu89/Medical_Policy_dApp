from flask import Flask, request, session, jsonify
from pymongo import MongoClient, errors, ASCENDING
from web3 import Web3
from scripts.utils import *
import datetime

app = Flask(__name__)
app.secret_key = app_secret_key
app.config["app.json.compact"] = False

client = MongoClient(mongodb_host)
db = client[db_name]
entities = db[entities]
entities.create_index([("ID", ASCENDING)], unique=True)

web3 = Web3(Web3.HTTPProvider(web3_host))
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
        patient_id = randint(0, 5)
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
            try:
                create_policies(
                    access_policy_contract, patient_address_converted, web3
                )  # by address
            except exceptions.ContractLogicError:
                return (
                    jsonify({"status": "error", "message": "Policy already exists"}),
                    400,
                )
            create_patient(
                patient_registry_contract, patient_id, patient_address_converted, web3
            )  # by patient_id
            inserted = True
        except errors.DuplicateKeyError:
            print(
                "Error: A patient with ID",
                patient_id,
                "already exists. Retrying with a new ID...",
            )

    print("Patient inserted with ID:", patient_id)
    return (
        jsonify({"status": "success", "patient_id": patient_id}),
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


@app.route("/api/<institution_CIF>/doctor", methods=["POST"])
def add_doctor(institution_CIF):
    doctor_username = request.json["username"]
    doctor_password = request.json["password"]
    doctor_full_name = request.json["full_name"]
    doctor_id = institution_CIF + str(
        randint(0, 5)
    )  # TODO check with bytes32 compatible

    try:
        institution = entities.find_one({"ID": institution_CIF, "type": "institution"})
        if institution is None:
            raise ValueError("Institution not found")

        entities.insert_one(
            {
                "username": doctor_username,
                "password": doctor_password,
                "full_name": doctor_full_name,
                "ID": doctor_id,
                "type": "doctor",
                "belongs_to": institution_CIF,
                "access_to": [],
            }
        )
        print("Doctor inserted with ID:", doctor_id)
        return jsonify({"status": "success", "doctor_id": doctor_id}), 201
    except errors.DuplicateKeyError:
        print("Error: A doctor with this ID already exists.")
        return (
            jsonify(
                {
                    "status": "error",
                    "message": "A doctor with this ID already exists.",
                }
            ),
            400,
        )
    except ValueError as e:
        print("Error:", str(e))
        return jsonify({"status": "error", "message": str(e)}), 400


@app.route("/api/patient/<patient_id>/wallet", methods=["POST"])
def add_wallet(patient_id):
    patient_id = int(patient_id)
    patient = entities.find_one({"ID": patient_id})
    if patient:
        patient_address = request.json["patient_address"]
        new_patient_address = request.json["new_patient_address"]
        patient_address_converted = Web3.to_checksum_address(patient_address)
        new_patient_address_converted = Web3.to_checksum_address(new_patient_address)
        # db
        entities.update_one(
            {"ID": patient_id},
            {"$addToSet": {"wallets": new_patient_address_converted}},
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
            create_policies(access_policy_contract, new_patient_address_converted, web3)
            print("Wallet and policy added to patient with ID:", patient_id)
            return (
                jsonify(
                    {
                        "status": "success",
                        "new_patient_address": new_patient_address_converted,
                    }
                ),
                201,
            )
        except WalletAddressAlreadyExists:
            return (
                jsonify({"status": "error", "message": "Wallet already exists."}),
                400,
            )

    else:
        print("Error: Patient not found.")
        return jsonify({"status": "error", "message": "Patient not found."}), 404


@app.route("/api/patient/<patient_id>/wallet", methods=["GET"])
def get_patient_wallets(patient_id):
    blockchain_addresses = get_patient_addresses(
        patient_registry_contract, int(patient_id)
    )

    patient = entities.find_one({"ID": int(patient_id), "type": "patient"})
    if patient is None:
        return jsonify({"error": "Patient not found"}), 404

    db_addresses = patient.get("wallets", [])

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
            {"$addToSet": {"medical_records_hashes": medical_record_hash}},
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


@app.route("/api/patient/<int:patient_id>/all_policies", methods=["GET"])
def get_all_policies_for_patient(patient_id):
    patient = entities.find_one({"ID": patient_id, "type": "patient"})

    if patient:
        medical_record_policies = {}

        # convert binary to hex strings
        hex_medical_records_hashes = [
            hash_data.hex() for hash_data in patient["medical_records_hashes"]
        ]
        for file_hash in hex_medical_records_hashes:
            file_hash_policies = {}
            for wallet in patient["wallets"]:
                doctor_ids = get_patient_policy_allowed_by_medical_record_hash(
                    access_policy_contract,
                    wallet,
                    hex_to_bytes32(
                        file_hash
                    ),  # for solidity convert hex strings to bytes32
                )
                # convert bytes to string again
                doctor_ids_str = [
                    Web3.to_text(doctor_id_bytes).rstrip("\x00")
                    for doctor_id_bytes in doctor_ids
                ]
                if len(doctor_ids_str) > 0:
                    file_hash_policies[wallet] = doctor_ids_str
            medical_record_policies[file_hash] = file_hash_policies

        return (
            jsonify(
                {
                    "status": "success",
                    "medical_record_policies": medical_record_policies,
                }
            ),
            200,
        )
    else:
        return jsonify({"status": "error", "message": "Patient not found."}), 404


@app.route("/api/patient/<patient_id>/grant_access", methods=["POST"])
def grant_access_to_medical_record(patient_id):
    # TODO: go to doctor and put the MR hash in his access_to
    # TODO: same for revoke
    patient_id = int(patient_id)
    patient = entities.find_one({"ID": patient_id})

    if patient:
        patient_address = request.json["patient_address"]
        patient_address_converted = Web3.to_checksum_address(patient_address)
        file_hash = request.json["file_hash"]
        doctor_id = request.json["doctor_id"]
        doctor_id_bytes = string_to_bytes32(doctor_id)

        try:
            # db
            doctor = entities.find_one({"ID": doctor_id, "type": "doctor"})
            if doctor:
                entities.update_one(
                    {"ID": doctor_id, "type": "doctor"},
                    {"$addToSet": {"access_to": file_hash}},
                )
            else:
                return jsonify({"status": "error", "message": "Doctor not found."}), 404
            # blockchain
            grant_access(
                access_policy_contract,
                patient_address_converted,
                hex_to_bytes32(file_hash),
                doctor_id_bytes,
                web3,
            )
            return jsonify({"status": "success", "message": "Access granted."}), 200
        except Exception as e:
            return jsonify({"status": "error", "message": str(e)}), 400
    else:
        return jsonify({"status": "error", "message": "Patient not found."}), 404


@app.route("/api/patient/<patient_id>/revoke", methods=["POST"])
def revoke_access_to_medical_record(patient_id):
    patient_id = int(patient_id)
    patient = entities.find_one({"ID": patient_id})

    if patient:
        patient_address = request.json["patient_address"]
        patient_address_converted = Web3.to_checksum_address(patient_address)
        file_hash = request.json["file_hash"]
        doctor_id = request.json["doctor_id"]
        doctor_id_bytes = string_to_bytes32(doctor_id)

        try:
            # db
            doctor = entities.find_one({"ID": doctor_id, "type": "doctor"})
            if doctor:
                entities.update_one(
                    {"ID": doctor_id, "type": "doctor"},
                    {"$pull": {"access_to": file_hash}},
                )
            else:
                return jsonify({"status": "error", "message": "Doctor not found."}), 404
            # blockchain
            revoke_access(
                access_policy_contract,
                patient_address_converted,
                hex_to_bytes32(file_hash),
                doctor_id_bytes,
                web3,
            )
            return jsonify({"status": "success", "message": "Access revoked."}), 200
        except Exception as e:
            return jsonify({"status": "error", "message": str(e)}), 400
    else:
        return jsonify({"status": "error", "message": "Patient not found."}), 404


if __name__ == "__main__":
    app.run(debug=True)
