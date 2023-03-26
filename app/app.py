from flask import Flask, render_template, request, redirect, url_for, session
from functools import wraps
from pymongo import MongoClient
from web3 import Web3, contract
import os
from dotenv import load_dotenv
from scripts.help import get_contract

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

# addresses - TBD with yaml
patient_registry_contract_address = "0x5b1869D9A4C187F2EAa108f3062412ecf0526b24"
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
    address = request.form["address"]

    users.insert_one(
        {
            "username": username,
            "password": password,
            "type": user_type,
            "address": address,
        }
    )

    return "User registered successfully!"


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
    return "bravo1"


@app.route("/get_patient_details", methods=["POST"])
@login_required
def get_patient_details():
    return "bravo2"


if __name__ == "__main__":
    app.run(debug=True)
