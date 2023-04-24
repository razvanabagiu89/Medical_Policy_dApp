import json
import pytest
from app import app
from flask_testing import TestCase


class TestApp(TestCase):

    patient_id_demo = 1

    def create_app(self):
        app.config["TESTING"] = True
        return app

    @pytest.mark.run(order=1)
    def test_add_patient(self):
        data = {
            "username": "patient1",
            "password": "testpassword",
            "patient_address": '0xACa94ef8bD5ffEE41947b4585a84BdA5a3d3DA6E',
        }

        response = self.client.post(
            "/api/patient", data=json.dumps(data), content_type="application/json"
        )

        TestApp.patient_id_demo = int(response.json["patient_id"])
        assert response.status_code == 201

    def test_add_institution(self):
        data = {
            "username": "institution1",
            "password": "testpassword",
            "CIF": 99,
        }

        response = self.client.post(
            "/api/institution", data=json.dumps(data), content_type="application/json"
        )

        assert response.status_code == 201

    @pytest.mark.run(order=2)
    def test_add_wallet(self):

        data = {
            "patient_id": TestApp.patient_id_demo,
            "patient_address": "0xACa94ef8bD5ffEE41947b4585a84BdA5a3d3DA6E",
            "new_patient_address": "0x28a8746e75304c0780E011BEd21C72cD78cd535E",
        }

        response = self.client.post(
            f"/api/patient/{TestApp.patient_id_demo}/wallet",
            data=json.dumps(data),
            content_type="application/json",
        )

        assert response.status_code == 201
        assert response.json["new_patient_address"] == data["new_patient_address"]

    @pytest.mark.run(order=3)
    def test_get_patient_wallets(self):

        response = self.client.get(f"/api/patient/{TestApp.patient_id_demo}/wallet")

        assert response.status_code == 200
        data = json.loads(response.data)
        assert "wallets" in data
        assert isinstance(data["wallets"], list)
        assert len(data["wallets"]) > 0

    @pytest.mark.run(order=4)
    def test_add_medical_record(self):
        
        data = {
            "patient_id": TestApp.patient_id_demo,
            "patient_address": '0xACa94ef8bD5ffEE41947b4585a84BdA5a3d3DA6E',
            "filename": "testfile"
        }
        response = self.client.post(
            f"/api/patient/{TestApp.patient_id_demo}/medical_record", data=json.dumps(data), content_type="application/json"
        )
        assert response.status_code == 201
        print(response.json["medical_record_hash"])


if __name__ == "__main__":
    pytest.main()
