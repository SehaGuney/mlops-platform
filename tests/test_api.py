import sys 
import pytest
from fastapi.testclient import TestClient

sys.path.append(".")
from app.main import app

client = TestClient(app)

def test_health():
    response = client.get("/health")
    assert response.status_code == 200


# DOĞRU SENARYONUN TESTİ 
@pytest.mark.parametrize("input_data, expected_label", [
    ([5.1, 3.5, 1.4, 0.2], "setosa"),
    ([6.5, 2.8, 4.6, 1.5], "versicolor"),
    ([6.9, 3.1, 5.4, 2.1], "virginica")
])

def test_predict_all_classes(input_data, expected_label):
    response = client.post("/predict", json={"features": input_data})
    assert response.status_code == 200
    assert response.json()["label"] == expected_label
    

# YANLIŞ SENARYONUN TESTİ
def test_predict_wrong_input():
    response = client.post("/predict", json={"features": [1.0,2.0]})
    assert response.status_code in [400, 422]
