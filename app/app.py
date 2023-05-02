from flask import Flask, request, jsonify
from flask_cors import CORS
from pymongo import MongoClient, errors, ASCENDING
from web3 import Web3, exceptions
from scripts.utils import *
import string
import random

app = Flask(__name__)
CORS(app)
app.secret_key = app_secret_key
app.config["app.json.compact"] = False

client = MongoClient(mongodb_host)
db = client[db_name]
entities = db[entities]
entities.create_index([("ID", ASCENDING)], unique=True)

"""
used just for read-only txs (getters) and admin calls (add_patient, create_policies)
just admin will issue txs to add patients and create policies to not get malicious txs from others
"""
web3 = Web3(Web3.HTTPProvider(web3_host))
patient_registry_contract = get_contract(
    web3, "PatientRegistryContract", patient_registry_contract_address
)
access_policy_contract = get_contract(
    web3, "AccessPolicyContract", access_policy_contract_address
)


# called just by admin - Ownable.sol modifier
@app.route("/api/patient", methods=["POST"])
def add_patient():
    patient_username = request.json["username"]
    patient = entities.find_one({"username": patient_username})
    if patient:
        return (
            jsonify(
                {
                    "status": "error",
                    "message": "A patient with this username already exists.",
                }
            ),
            400,
        )
    patient_password = request.json["password"]
    patient_address = request.json["patient_address"]
    patient_address_converted = Web3.to_checksum_address(patient_address)

    inserted = False
    while not inserted:
        patient_id = randint(0, 255)
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


@app.route("/api/institution/add", methods=["POST"])
def add_institution():
    institution_username = request.json["username"]
    # generate a random password for the institution of 8 characters
    institution_password = "".join(
        random.choice(string.ascii_letters) for i in range(8)
    )
    institution_CIF = request.json["CIF"]

    try:
        # db
        entities.insert_one(
            {
                "username": institution_username,
                "password": institution_password,
                "CIF": int(institution_CIF),
                "type": "institution",
            }
        )
        print("Institution inserted with CIF:", institution_CIF)
        return (
            jsonify(
                {
                    "status": "success",
                    "CIF": institution_CIF,
                    "password": institution_password,
                }
            ),
            201,
        )
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


@app.route("/api/institution/remove", methods=["POST"])
def remove_institution():
    institution_username = request.json["username"]
    try:
        # db
        entities.delete_one({"username": institution_username, "type": "institution"})
        print("Institution deleted:", institution_username)
        return jsonify({"status": "success"}), 200
    except Exception as e:
        print(f"Error: {e}")
        return (
            jsonify(
                {
                    "status": "error",
                    "message": "Error in backend: mongodb could not delete institution.",
                }
            ),
            400,
        )


@app.route("/api/<institution_CIF>/doctor", methods=["POST"])
def add_doctor(institution_CIF):
    doctor_username = request.json["username"]
    doctor_password = request.json["password"]
    doctor_full_name = request.json["full_name"]
    doctor_id = institution_CIF + str(randint(0, 5))

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


@app.route("/api/login", methods=["POST"])
def login():
    data = request.get_json()
    username = data.get("username")
    password = data.get("password")

    if not username or not password:
        return (
            jsonify({"status": "error", "message": "Missing username or password"}),
            400,
        )

    user = entities.find_one({"username": username})

    if not user or not user["password"] == password:
        return (
            jsonify({"status": "error", "message": "Invalid username or password"}),
            401,
        )

    return (
        jsonify(
            {
                "status": "success",
                "message": "Login successful",
                "patient_id": user["ID"],
            }
        ),
        200,
    )


@app.route("/api/patient/<patient_id>/wallet", methods=["POST"])
def add_wallet(patient_id):
    patient_id = int(patient_id)
    patient = entities.find_one({"ID": patient_id})
    if patient:
        new_patient_address = request.json["new_patient_address"]
        new_patient_address_converted = Web3.to_checksum_address(new_patient_address)
        # db
        entities.update_one(
            {"ID": patient_id},
            {"$addToSet": {"wallets": new_patient_address_converted}},
        )
        # blockchain
        try:
            check_wallet_exists(
                patient_registry_contract,
                new_patient_address_converted,
                patient_id,
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
        filedata = request.json["filedata"]
        # TODO: filedata up to s3
        medical_record_hash = request.json["medical_record_hash"]
        # upload_file_to_s3(request, medical_record_hash)
        # db
        entities.update_one(
            {"ID": patient_id},
            {"$addToSet": {"medical_records_hashes": medical_record_hash}},
        )
        print("Medical record added to patient with ID:", patient_id)
        return (
            jsonify({"status": "success"}),
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

        for file_hash in patient["medical_records_hashes"]:
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
    patient_id = int(patient_id)
    patient = entities.find_one({"ID": patient_id})

    if patient:
        file_hash = request.json["file_hash"]
        doctor_id = request.json["doctor_id"]
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
        file_hash = request.json["file_hash"]
        doctor_id = request.json["doctor_id"]

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
            return jsonify({"status": "success", "message": "Access revoked."}), 200
        except Exception as e:
            return jsonify({"status": "error", "message": str(e)}), 400
    else:
        return jsonify({"status": "error", "message": "Patient not found."}), 404


if __name__ == "__main__":
    app.run(debug=True)
