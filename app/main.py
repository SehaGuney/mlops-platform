from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import joblib
import numpy as np

app = FastAPI(title="MLOPS Platform - Week 1")
model = joblib.load("app/models/model.pkl")
labels = ["setosa", "versicolor", "virginica"]

@app.get("/health")
def health_check():
    return {"status":"healthy"}

class PredictRequest(BaseModel):
    features: list[float]

class PredictResponse(BaseModel):
    prediction: int
    label: str
    probability: float

@app.post("/predict", response_model=PredictResponse)

def predict(req: PredictRequest):
    if len(req.features) != 4:
        raise HTTPException(status_code=400, detail="Input must have 4 features.")
    
    X = np.array(req.features).reshape(1, -1)
    pred = model.predict(X)[0]
    prob = model.predict_proba(X)[0][pred]

    return PredictResponse(prediction=int(pred), label=labels[pred], probability=round(float(prob) , 3))