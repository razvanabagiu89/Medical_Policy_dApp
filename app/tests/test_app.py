import json
import pytest
import subprocess
import importlib
from app import app
from flask_testing import TestCase


@pytest.fixture(autouse=True)
def reset_app_before_test():
    subprocess.run(["./reset_app.sh"], check=True)
    import app, scripts.utils

    importlib.reload(scripts.utils)
    importlib.reload(app)
    yield


class TestApp(TestCase):
    tag = "[TEST]"
    patient_id_demo = -1
    doctor_id_demo = ""
    file_hash_demo_1 = ""
    file_hash_demo_2 = ""

    def create_app(self):
        app.config["TESTING"] = True
        return app

    def test_add_patient(self):
        data = {
            "username": "patient1",
            "password": "testpassword",
            "patient_address": "0xFFcf8FDEE72ac11b5c542428B35EEF5769C409f0",
        }

        response = self.client.post(
            "/api/patient", data=json.dumps(data), content_type="application/json"
        )

        assert response.status_code == 201

    def test_add_institution(self):
        data = {
            "username": "institution1",
            "password": "testpassword",
            "CIF": "RM",
        }

        response = self.client.post(
            "/api/institution", data=json.dumps(data), content_type="application/json"
        )

        assert response.status_code == 201

    def test_add_doctor(self):
        # add institution
        CIF_demo = "RM"
        data = {
            "username": "institution1",
            "password": "testpassword",
            "CIF": CIF_demo,
        }

        response = self.client.post(
            "/api/institution", data=json.dumps(data), content_type="application/json"
        )
        # add doc
        data = {
            "username": "doc_test",
            "password": "password123",
            "full_name": "Dr. Test",
        }

        response = self.client.post(
            f"/api/{CIF_demo}/doctor",
            data=json.dumps(data),
            content_type="application/json",
        )

        assert response.status_code == 201
        assert response.json["status"] == "success"
        print(TestApp.tag + response.json["doctor_id"])

    def test_add_wallet(self):
        # create patient
        data = {
            "username": "patient1",
            "password": "testpassword",
            "patient_address": "0xFFcf8FDEE72ac11b5c542428B35EEF5769C409f0",
        }

        response = self.client.post(
            "/api/patient", data=json.dumps(data), content_type="application/json"
        )
        TestApp.patient_id_demo = int(response.json["patient_id"])

        # add wallet
        data = {
            "patient_address": "0xFFcf8FDEE72ac11b5c542428B35EEF5769C409f0",
            "new_patient_address": "0x22d491Bde2303f2f43325b2108D26f1eAbA1e32b",
        }

        response = self.client.post(
            f"/api/patient/{TestApp.patient_id_demo}/wallet",
            data=json.dumps(data),
            content_type="application/json",
        )

        assert response.status_code == 201
        assert response.json["new_patient_address"] == data["new_patient_address"]

        # get patient wallets
        response = self.client.get(f"/api/patient/{TestApp.patient_id_demo}/wallet")
        assert response.status_code == 200
        data = json.loads(response.data)
        assert "wallets" in data
        assert isinstance(data["wallets"], list)
        assert len(data["wallets"]) > 0

    def test_add_medical_records(self):
        # create patient
        data = {
            "username": "patient1",
            "password": "testpassword",
            "patient_address": "0xFFcf8FDEE72ac11b5c542428B35EEF5769C409f0",
        }

        response = self.client.post(
            "/api/patient", data=json.dumps(data), content_type="application/json"
        )
        TestApp.patient_id_demo = int(response.json["patient_id"])

        # add wallet
        data = {
            "patient_address": "0xFFcf8FDEE72ac11b5c542428B35EEF5769C409f0",
            "new_patient_address": "0x22d491Bde2303f2f43325b2108D26f1eAbA1e32b",
        }

        response = self.client.post(
            f"/api/patient/{TestApp.patient_id_demo}/wallet",
            data=json.dumps(data),
            content_type="application/json",
        )

        # 1
        data = {
            "patient_id": TestApp.patient_id_demo,
            "patient_address": "0xFFcf8FDEE72ac11b5c542428B35EEF5769C409f0",
            "filename": "testfile",
        }
        response = self.client.post(
            f"/api/patient/{TestApp.patient_id_demo}/medical_record",
            data=json.dumps(data),
            content_type="application/json",
        )
        assert response.status_code == 201
        print(TestApp.tag + response.json["medical_record_hash"])
        TestApp.file_hash_demo_1 = response.json["medical_record_hash"]
        # 2
        data = {
            "patient_id": TestApp.patient_id_demo,
            "patient_address": "0x22d491Bde2303f2f43325b2108D26f1eAbA1e32b",
            "filename": "testfile",
        }
        response = self.client.post(
            f"/api/patient/{TestApp.patient_id_demo}/medical_record",
            data=json.dumps(data),
            content_type="application/json",
        )
        assert response.status_code == 201
        print(TestApp.tag + response.json["medical_record_hash"])

    def test_grant_access_to_medical_record(self):
        # create patient
        data = {
            "username": "patient1",
            "password": "testpassword",
            "patient_address": "0xFFcf8FDEE72ac11b5c542428B35EEF5769C409f0",
        }

        response = self.client.post(
            "/api/patient", data=json.dumps(data), content_type="application/json"
        )
        TestApp.patient_id_demo = int(response.json["patient_id"])

        # add institution
        CIF_demo = "RM"
        data = {
            "username": "institution1",
            "password": "testpassword",
            "CIF": CIF_demo,
        }

        response = self.client.post(
            "/api/institution", data=json.dumps(data), content_type="application/json"
        )
        # add doc
        data = {
            "username": "doc_test",
            "password": "password123",
            "full_name": "Dr. Test",
        }

        response = self.client.post(
            f"/api/{CIF_demo}/doctor",
            data=json.dumps(data),
            content_type="application/json",
        )
        TestApp.doctor_id_demo = response.json["doctor_id"]
        # add wallet
        data = {
            "patient_address": "0xFFcf8FDEE72ac11b5c542428B35EEF5769C409f0",
            "new_patient_address": "0x22d491Bde2303f2f43325b2108D26f1eAbA1e32b",
        }

        response = self.client.post(
            f"/api/patient/{TestApp.patient_id_demo}/wallet",
            data=json.dumps(data),
            content_type="application/json",
        )

        # create #1 MR
        data = {
            "patient_id": TestApp.patient_id_demo,
            "patient_address": "0xFFcf8FDEE72ac11b5c542428B35EEF5769C409f0",
            "filename": "testfile",
        }
        response = self.client.post(
            f"/api/patient/{TestApp.patient_id_demo}/medical_record",
            data=json.dumps(data),
            content_type="application/json",
        )
        assert response.status_code == 201
        print(TestApp.tag + response.json["medical_record_hash"])
        TestApp.file_hash_demo_1 = response.json["medical_record_hash"]

        # grant access
        data = {
            "patient_address": "0xFFcf8FDEE72ac11b5c542428B35EEF5769C409f0",
            "file_hash": TestApp.file_hash_demo_1,
            "doctor_id": TestApp.doctor_id_demo,
        }

        response = self.client.post(
            f"/api/patient/{TestApp.patient_id_demo}/grant_access",
            data=json.dumps(data),
            content_type="application/json",
        )

        assert response.status_code == 200
        assert response.json["status"] == "success"

    def test_revoke_access_to_medical_record(self):
        # create patient
        data = {
            "username": "patient1",
            "password": "testpassword",
            "patient_address": "0xFFcf8FDEE72ac11b5c542428B35EEF5769C409f0",
        }
        response = self.client.post(
            "/api/patient", data=json.dumps(data), content_type="application/json"
        )
        TestApp.patient_id_demo = int(response.json["patient_id"])
        # add institution
        CIF_demo = "RM"
        data = {
            "username": "institution1",
            "password": "testpassword",
            "CIF": CIF_demo,
        }
        response = self.client.post(
            "/api/institution", data=json.dumps(data), content_type="application/json"
        )
        # add doc
        data = {
            "username": "doc_test",
            "password": "password123",
            "full_name": "Dr. Test",
        }

        response = self.client.post(
            f"/api/{CIF_demo}/doctor",
            data=json.dumps(data),
            content_type="application/json",
        )
        TestApp.doctor_id_demo = response.json["doctor_id"]
        # add wallet
        data = {
            "patient_address": "0xFFcf8FDEE72ac11b5c542428B35EEF5769C409f0",
            "new_patient_address": "0x22d491Bde2303f2f43325b2108D26f1eAbA1e32b",
        }

        response = self.client.post(
            f"/api/patient/{TestApp.patient_id_demo}/wallet",
            data=json.dumps(data),
            content_type="application/json",
        )

        # create #1 MR
        data = {
            "patient_id": TestApp.patient_id_demo,
            "patient_address": "0xFFcf8FDEE72ac11b5c542428B35EEF5769C409f0",
            "filename": "testfile",
        }
        response = self.client.post(
            f"/api/patient/{TestApp.patient_id_demo}/medical_record",
            data=json.dumps(data),
            content_type="application/json",
        )
        assert response.status_code == 201
        print(TestApp.tag + response.json["medical_record_hash"])
        TestApp.file_hash_demo_1 = response.json["medical_record_hash"]
        # revoke access
        data = {
            "patient_address": "0xFFcf8FDEE72ac11b5c542428B35EEF5769C409f0",
            "file_hash": TestApp.file_hash_demo_1,
            "doctor_id": TestApp.doctor_id_demo,
        }

        response = self.client.post(
            f"/api/patient/{TestApp.patient_id_demo}/revoke",
            data=json.dumps(data),
            content_type="application/json",
        )

        assert response.status_code == 200
        assert response.json["status"] == "success"

    def test_simple_1(self):
        """setup
        1. patient creation
        2. additional wallet
        3. add MR per wallet
        4. add diff policies
        4. fetch
        """
        # create patient
        data = {
            "username": "patient1",
            "password": "testpassword",
            "patient_address": "0xFFcf8FDEE72ac11b5c542428B35EEF5769C409f0",
        }

        response = self.client.post(
            "/api/patient", data=json.dumps(data), content_type="application/json"
        )
        TestApp.patient_id_demo = int(response.json["patient_id"])

        # add wallet
        data = {
            "patient_address": "0xFFcf8FDEE72ac11b5c542428B35EEF5769C409f0",
            "new_patient_address": "0x22d491Bde2303f2f43325b2108D26f1eAbA1e32b",
        }

        response = self.client.post(
            f"/api/patient/{TestApp.patient_id_demo}/wallet",
            data=json.dumps(data),
            content_type="application/json",
        )

        # create #1 MR
        data = {
            "patient_id": TestApp.patient_id_demo,
            "patient_address": "0xFFcf8FDEE72ac11b5c542428B35EEF5769C409f0",
            "filename": "testfile",
        }
        response = self.client.post(
            f"/api/patient/{TestApp.patient_id_demo}/medical_record",
            data=json.dumps(data),
            content_type="application/json",
        )
        assert response.status_code == 201
        print(TestApp.tag + response.json["medical_record_hash"])
        TestApp.file_hash_demo_1 = response.json["medical_record_hash"]

        # create #2 MR
        data = {
            "patient_id": TestApp.patient_id_demo,
            "patient_address": "0x22d491Bde2303f2f43325b2108D26f1eAbA1e32b",
            "filename": "testfile",
        }
        response = self.client.post(
            f"/api/patient/{TestApp.patient_id_demo}/medical_record",
            data=json.dumps(data),
            content_type="application/json",
        )
        assert response.status_code == 201
        print(TestApp.tag + response.json["medical_record_hash"])
        TestApp.file_hash_demo_2 = response.json["medical_record_hash"]

        # add institution
        CIF_demo = "RM"
        data = {
            "username": "institution1",
            "password": "testpassword",
            "CIF": CIF_demo,
        }

        response = self.client.post(
            "/api/institution", data=json.dumps(data), content_type="application/json"
        )
        # add doc
        data = {
            "username": "doc_test",
            "password": "password123",
            "full_name": "Dr. Test",
        }

        response = self.client.post(
            f"/api/{CIF_demo}/doctor",
            data=json.dumps(data),
            content_type="application/json",
        )
        TestApp.doctor_id_demo = response.json["doctor_id"]

        # #1 MR grant access
        data = {
            "patient_address": "0xFFcf8FDEE72ac11b5c542428B35EEF5769C409f0",
            "file_hash": TestApp.file_hash_demo_1,
            "doctor_id": TestApp.doctor_id_demo,
        }

        response = self.client.post(
            f"/api/patient/{TestApp.patient_id_demo}/grant_access",
            data=json.dumps(data),
            content_type="application/json",
        )

        # #2 MR grant access
        data = {
            "patient_address": "0xFFcf8FDEE72ac11b5c542428B35EEF5769C409f0",
            "file_hash": TestApp.file_hash_demo_2,
            "doctor_id": TestApp.doctor_id_demo,
        }

        response = self.client.post(
            f"/api/patient/{TestApp.patient_id_demo}/grant_access",
            data=json.dumps(data),
            content_type="application/json",
        )

        # #1 MR revoke access
        data = {
            "patient_address": "0xFFcf8FDEE72ac11b5c542428B35EEF5769C409f0",
            "file_hash": TestApp.file_hash_demo_1,
            "doctor_id": TestApp.doctor_id_demo,
        }

        response = self.client.post(
            f"/api/patient/{TestApp.patient_id_demo}/revoke",
            data=json.dumps(data),
            content_type="application/json",
        )

        # get all policies
        response = self.client.get(
            f"/api/patient/{TestApp.patient_id_demo}/all_policies",
            content_type="application/json",
        )
        data = response.json
        print(TestApp.tag + json.dumps(data["medical_record_policies"], indent=4))
        assert data["status"] == "success"
        assert "medical_record_policies" in data
        assert isinstance(data["medical_record_policies"], dict)


if __name__ == "__main__":
    pytest.main()
