from flask import Flask, request, jsonify
from flask_cors import CORS
from flask_jwt_extended import JWTManager, jwt_required, create_access_token
from pymongo import MongoClient, errors, ASCENDING
from web3 import Web3, exceptions
from scripts.utils import *
import string
import random
import base64
from io import BytesIO
import boto3
import hashlib
from datetime import timedelta

app = Flask(__name__)
CORS(app, origins="http://127.0.0.1:33225")
ALLOWED_IP = "127.0.0.1"

# TODO: change secret_key
app.secret_key = app_secret_key
app.config["JWT_SECRET_KEY"] = app_secret_key
app.config["JWT_ACCESS_TOKEN_EXPIRES"] = timedelta(minutes=60)
jwt = JWTManager(app)
app.config["app.json.compact"] = False

client = MongoClient(mongodb_host)
db = client[db_name]
entities = db[entities]
entities.create_index([("ID", ASCENDING)], unique=True)

s3 = boto3.client(
    "s3",
    region_name=s3_region,
    aws_access_key_id=s3_access_key,
    aws_secret_access_key=s3_secret_key,
)

# used just for read-only txs (getters) and admin calls (add_patient, create_policies)
web3 = Web3(Web3.HTTPProvider(web3_host))
patient_registry_contract = get_contract(
    web3, "PatientRegistryContract", patient_registry_contract_address
)
access_policy_contract = get_contract(
    web3, "AccessPolicyContract", access_policy_contract_address
)
institution_registry_contract = get_contract(
    web3, "InstitutionRegistryContract", institution_registry_contract_address
)


@app.before_request
def check_ip():
    client_ip = request.headers.get("X-Forwarded-For", request.remote_addr)
    if client_ip != ALLOWED_IP:
        return "Access denied", 403


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
@jwt_required()
def add_institution():
    institution_username = request.json["username"]
    # generate a random password for the institution of 8 characters
    institution_password = "".join(
        random.choice(string.ascii_letters) for i in range(8)
    )
    institution_password_hash = str(
        hashlib.sha256(institution_password.encode()).hexdigest()
    )
    institution_CIF = request.json["CIF"]

    # blockchain
    try:
        add_institution_helper(
            institution_registry_contract,
            string_to_bytes32(institution_username),
            int(institution_CIF),
            web3,
        )
    except exceptions.ContractLogicError:
        return (
            jsonify({"status": "error", "message": "Institution already exists"}),
            400,
        )

    try:
        # db
        entities.insert_one(
            {
                "username": institution_username,
                "password": institution_password_hash,
                "ID": int(institution_CIF),
                "type": "institution",
            }
        )
        print("Institution inserted with ID:", institution_CIF)
        return (
            jsonify(
                {
                    "status": "success",
                    "ID": institution_CIF,
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
@jwt_required()
def remove_institution():
    institution_username = request.json["username"]
    # blockchain
    try:
        # find institution by username and extract id
        institution = entities.find_one(
            {"username": institution_username, "type": "institution"}
        )
        if institution is None:
            return jsonify({"error": "Institution not found"}), 404

        remove_institution_helper(
            institution_registry_contract,
            int(institution.get("ID")),
            web3,
        )
    except exceptions.ContractLogicError:
        return (
            jsonify(
                {"status": "error", "message": "No institution with this name exists"}
            ),
            400,
        )
    # db
    try:
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


@app.route("/api/<institution_CIF>/employee/add", methods=["POST"])
@jwt_required()
def add_employee(institution_CIF):
    institution_CIF = int(institution_CIF)
    institution_username = request.json["institution_username"]
    employee_username = request.json["username"]
    employee_password = "".join(random.choice(string.ascii_letters) for i in range(8))
    employee_password_hash = str(hashlib.sha256(employee_password.encode()).hexdigest())
    employee_full_name = request.json["full_name"]
    employee_id = str(institution_CIF) + str(randint(0, 20))

    try:
        institution = entities.find_one({"ID": institution_CIF, "type": "institution"})
        if institution is None:
            raise ValueError("Institution not found")

        entities.insert_one(
            {
                "username": employee_username,
                "password": employee_password_hash,
                "full_name": employee_full_name,
                "ID": employee_id,
                "type": "employee",
                "belongs_to": institution_username,
                "access_to": [],
            }
        )
        print("Employee inserted with ID:", employee_id)
        return (
            jsonify(
                {
                    "status": "success",
                    "employee_id": employee_id,
                    "password": employee_password,
                }
            ),
            201,
        )
    except errors.DuplicateKeyError:
        print("Error: An employee with this ID already exists.")
        return (
            jsonify(
                {
                    "status": "error",
                    "message": "An employee with this ID already exists.",
                }
            ),
            400,
        )
    except ValueError as e:
        print("Error:", str(e))
        return jsonify({"status": "error", "message": str(e)}), 400


@app.route("/api/<institution_CIF>/employee/remove", methods=["POST"])
@jwt_required()
def remove_employee(institution_CIF):
    employee_username = request.json["username"]
    try:
        entities.delete_one({"username": employee_username, "type": "employee"})
        print("Employee deleted:", employee_username)
        return jsonify({"status": "success"}), 200
    except Exception as e:
        print(f"Error: {e}")
        return (
            jsonify(
                {
                    "status": "error",
                    "message": "Error in backend: mongodb could not delete employee.",
                }
            ),
            400,
        )


@app.route("/api/login", methods=["POST"])
def login():
    data = request.get_json()
    username = data.get("username")
    password = data.get("password")
    type = data.get("type")

    if not username or not password:
        return (
            jsonify({"status": "error", "message": "Missing username or password"}),
            400,
        )

    user = entities.find_one({"username": username, "type": type})

    if not user or not user["password"] == password:
        return (
            jsonify({"status": "error", "message": "Invalid username or password"}),
            401,
        )
    access_token = create_access_token(identity=username)

    return (
        jsonify(
            {
                "status": "success",
                "message": "Login successful",
                "id": user["ID"],
                "access_token": access_token,
            }
        ),
        200,
    )


@app.route("/api/change_password", methods=["POST"])
@jwt_required()
def change_password():
    data = request.get_json()
    username = data.get("username")
    old_password = data.get("old_password")
    new_password = data.get("new_password")
    type = data.get("type")
    print(type)

    if not username or not old_password or not new_password:
        return (
            jsonify({"status": "error", "message": "Missing fields"}),
            400,
        )

    user = entities.find_one({"username": username, "type": type})

    if not user or not user["password"] == old_password:
        return (
            jsonify({"status": "error", "message": "Invalid username or password"}),
            401,
        )

    entities.update_one(
        {"username": username, "type": type}, {"$set": {"password": new_password}}
    )

    return (
        jsonify(
            {
                "status": "success",
                "message": "Password changed successfully",
            }
        ),
        200,
    )


@app.route("/api/patient/<patient_id>/wallet", methods=["POST"])
@jwt_required()
def add_wallet(patient_id):
    patient_id = int(patient_id)
    patient = entities.find_one({"ID": patient_id})
    if patient:
        new_patient_address = request.json["new_patient_address"]
        new_patient_address_converted = Web3.to_checksum_address(new_patient_address)
        # blockchain
        try:
            check_wallet_exists(
                patient_registry_contract,
                new_patient_address_converted,
                patient_id,
            )
            create_policies(access_policy_contract, new_patient_address_converted, web3)
            # db
            entities.update_one(
                {"ID": patient_id},
                {"$addToSet": {"wallets": new_patient_address_converted}},
            )
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
@jwt_required()
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
@jwt_required()
def add_medical_record(patient_id):
    patient_id = int(request.json["patient_id"])
    patient = entities.find_one({"ID": patient_id})

    if patient:
        filedata = request.json["filedata"]
        decoded_filedata = base64.b64decode(filedata)
        file_like_object = BytesIO(decoded_filedata)
        medical_record_hash = request.json["medical_record_hash"]
        # s3
        upload_file_to_s3(file_like_object, medical_record_hash, s3)
        print("Medical record added to patient with ID:", patient_id)
        return (
            jsonify({"status": "success"}),
            201,
        )
    else:
        print("Error: Patient not found.")
        return jsonify({"status": "error", "message": "Patient not found."}), 404


@app.route("/api/patient/<patient_id>/delete_medical_record", methods=["POST"])
@jwt_required()
def delete_medical_record(patient_id):
    patient_id = int(request.json["patient_id"])
    patient = entities.find_one({"ID": patient_id, "type": "patient"})

    if patient:
        medical_record_hash = request.json["medical_record_hash"]
        # s3
        delete_file_from_s3(medical_record_hash, s3)
        print("Medical record deleted to patient with ID:", patient_id)
        return (
            jsonify({"status": "success"}),
            201,
        )
    else:
        print("Error: Patient not found.")
        return jsonify({"status": "error", "message": "Patient not found."}), 404


@app.route("/api/patient/<int:patient_id>/all_policies", methods=["GET"])
@jwt_required()
def get_all_policies_for_patient(patient_id):
    patient = entities.find_one({"ID": patient_id, "type": "patient"})

    if patient:
        medical_record_policies = {}

        # file_hashes now comes from blockchain as bytes32 array
        file_hashes = get_patient_medical_records_hashes(
            patient_registry_contract, patient_id
        )
        for file_hash in file_hashes:
            file_hash_policies = {}
            for wallet in patient["wallets"]:
                employee_ids = get_patient_policy_allowed_by_medical_record_hash(
                    access_policy_contract,
                    wallet,
                    file_hash,
                )
                # convert bytes to string
                employee_ids_str = [
                    Web3.to_text(employee_id_bytes).rstrip("\x00")
                    for employee_id_bytes in employee_ids
                ]
                if len(employee_ids_str) > 0:
                    file_hash_policies[wallet] = employee_ids_str
            # here we convert bytes32 to string to look good in the dict
            medical_record_policies[Web3.to_text(file_hash)] = file_hash_policies

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
@jwt_required()
def grant_access_to_medical_record(patient_id):
    patient_id = int(patient_id)
    patient = entities.find_one({"ID": patient_id})

    if patient:
        file_hash = request.json["file_hash"]
        employee_id = request.json["employee_id"]
        try:
            employee = entities.find_one({"ID": employee_id, "type": "employee"})
            if employee:
                entities.update_one(
                    {"ID": employee_id, "type": "employee"},
                    {"$addToSet": {"access_to": file_hash}},
                )
            else:
                return (
                    jsonify({"status": "error", "message": "Employee not found."}),
                    404,
                )
            return jsonify({"status": "success", "message": "Access granted."}), 200
        except Exception as e:
            return jsonify({"status": "error", "message": str(e)}), 400
    else:
        return jsonify({"status": "error", "message": "Patient not found."}), 404


@app.route("/api/patient/<patient_id>/revoke", methods=["POST"])
@jwt_required()
def revoke_access_to_medical_record(patient_id):
    patient_id = int(patient_id)
    patient = entities.find_one({"ID": patient_id})

    if patient:
        file_hash = request.json["file_hash"]
        employee_id = request.json["employee_id"]

        try:
            employee = entities.find_one({"ID": employee_id, "type": "employee"})
            if employee:
                entities.update_one(
                    {"ID": employee_id, "type": "employee"},
                    {"$pull": {"access_to": file_hash}},
                )
            else:
                return (
                    jsonify({"status": "error", "message": "Employee not found."}),
                    404,
                )
            return jsonify({"status": "success", "message": "Access revoked."}), 200
        except Exception as e:
            return jsonify({"status": "error", "message": str(e)}), 400
    else:
        return jsonify({"status": "error", "message": "Patient not found."}), 404


@app.route("/api/employee/<employee_id>/request_access", methods=["POST"])
@jwt_required()
def request_access(employee_id):
    employee = entities.find_one({"ID": employee_id})

    if employee:
        patient_username = request.json["patient_username"]
        file_hash = request.json["file_hash"]
        try:
            patient = entities.find_one(
                {"username": patient_username, "type": "patient"}
            )
            if patient:
                new_request = {
                    "from": employee["full_name"],
                    "ID": employee["ID"],
                    "belongs_to": employee["belongs_to"],
                    "document": file_hash,
                }
                entities.update_one(
                    {"username": patient_username, "type": "patient"},
                    {"$push": {"requests": new_request}},
                )
            else:
                return (
                    jsonify({"status": "error", "message": "Patient not found."}),
                    404,
                )
            return jsonify({"status": "success", "message": "Request sent"}), 200
        except Exception as e:
            return jsonify({"status": "error", "message": str(e)}), 400
    else:
        return jsonify({"status": "error", "message": "Employee not found."}), 404


@app.route("/api/employee/<employee_id>/show_documents", methods=["GET"])
@jwt_required()
def show_documents(employee_id):
    try:
        employee = entities.find_one({"ID": employee_id, "type": "employee"})
        if employee:
            access_to_list = employee.get("access_to", [])
            return jsonify({"status": "success", "access_to": access_to_list}), 200
        else:
            return (
                jsonify({"status": "error", "message": "Employee not found."}),
                404,
            )
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 400


@app.route("/api/get_file/<file_name>")
@jwt_required()
def get_pdf(file_name):
    s3 = boto3.client(
        "s3",
        region_name=s3_region,
        aws_access_key_id=s3_access_key,
        aws_secret_access_key=s3_secret_key,
    )
    bucket_name = s3_bucket_name

    response = s3.get_object(Bucket=bucket_name, Key=file_name)
    file_data = response["Body"].read()

    file_base64 = base64.b64encode(file_data).decode("utf-8")

    return jsonify({"filedata": file_base64})


@app.route("/api/patient/<int:patient_id>/requests", methods=["GET"])
@jwt_required()
def get_requests(patient_id):
    patient_id = int(patient_id)
    patient = entities.find_one({"ID": patient_id, "type": "patient"})

    if patient:
        requests = patient["requests"]
        return jsonify({"status": "success", "requests": requests}), 200
    else:
        return jsonify({"status": "error", "message": "Patient not found."}), 404


@app.route("/get_db_institutions", methods=["GET"])
@jwt_required()
def get_db_institutions():
    institutions = entities.find({"type": "institution"})
    result = []
    for institution in institutions:
        result.append({"username": institution["username"], "ID": institution["ID"]})
    return jsonify(result), 200


@app.route("/get_blockchain_institutions", methods=["GET"])
@jwt_required()
def get_blockchain_institutions():
    result = []
    for id in range(
        institution_registry_contract.functions.getInstitutionCount().call()
    ):
        institution = institution_registry_contract.functions.getInstitutionById(
            id
        ).call()
        result.append(
            {
                "name": institution[0].decode("utf-8").rstrip("\x00"),
                "id": institution[1],
            }
        )
    return jsonify(result), 200


@app.route("/get_employees", methods=["GET"])
@jwt_required()
def get_employees():
    employees = entities.find({"type": "employee"})
    result = []
    for employee in employees:
        result.append(
            {
                "username": employee["username"],
                "ID": employee["ID"],
                "full_name": employee["full_name"],
            }
        )
    return jsonify(result), 200


@app.route("/api/patient/<patient_id>/delete_request", methods=["DELETE"])
@jwt_required()
def delete_request(patient_id):
    employee_id = request.json["employee_id"]
    document_hash = request.json["document_hash"]

    patient = db.entities.find_one({"ID": int(patient_id)})

    if patient:
        new_requests = [
            request
            for request in patient["requests"]
            if not (
                request["ID"] == employee_id and request["document"] == document_hash
            )
        ]

        db.entities.update_one(
            {"ID": int(patient_id)}, {"$set": {"requests": new_requests}}
        )

        return jsonify({"status": "success"}), 200
    else:
        return jsonify({"error": "patient not found"}), 404


@app.route("/api/employee/<employee_id>/get_details", methods=["GET"])
@jwt_required()
def get_employee_details(employee_id):
    employee = entities.find_one({"ID": employee_id})

    if employee:
        return (
            jsonify(
                {
                    "status": "success",
                    "full_name": employee["full_name"],
                    "username": employee["username"],
                    "belongs_to": employee["belongs_to"],
                }
            ),
            200,
        )
    else:
        return jsonify({"error": "user not found"}), 404


if __name__ == "__main__":
    app.run(debug=True)
