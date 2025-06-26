from fastapi import APIRouter, HTTPException, status
from models import MCQExam
from db import mcqs_collection  # Assuming this is where you define your MCQ collection

mcq_router = APIRouter()

@mcq_router.post("/mcqs/")
async def create_mcq(exam: MCQExam):
    exam_data = exam.dict()
    exam_data["created_at"] = str(datetime.utcnow())
    exam_data["updated_at"] = str(datetime.utcnow())

    result = await mcqs_collection.insert_one(exam_data)
    return {"message": "MCQ exam added successfully", "exam_id": str(result.inserted_id)}

@mcq_router.get("/mcqs/{language_code}/exam/{exam_number}")
async def get_mcqs(language_code: str, exam_number: int):
    exam = await mcqs_collection.find_one({
        "language_code": language_code,
        "exam_number": exam_number
    })
    if exam is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Exam not found")
    return exam
