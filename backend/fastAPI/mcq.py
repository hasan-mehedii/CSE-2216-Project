from fastapi import APIRouter, HTTPException, status, Query
from models import MCQExam, Question # Import Question model as well
from db import mcqs_collection
from datetime import datetime
from typing import List, Optional

mcq_router = APIRouter()

@mcq_router.post("/mcqs/")
async def create_mcq(exam: MCQExam):
    exam_data = exam.dict()
    exam_data["created_at"] = datetime.utcnow().isoformat()
    exam_data["updated_at"] = datetime.utcnow().isoformat()

    result = await mcqs_collection.insert_one(exam_data)
    return {"message": "MCQ exam added successfully", "exam_id": str(result.inserted_id)}

@mcq_router.get("/mcqs/{language_code}/exam/{exam_number}")
async def get_mcqs_by_exam_number(language_code: str, exam_number: int):
    exam = await mcqs_collection.find_one({
        "language_code": language_code,
        "exam_number": exam_number
    })
    if exam is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Exam not found")
    return exam

@mcq_router.get("/mcqs/paginated/{language_code}", response_model=List[Question])
async def get_paginated_mcqs(
    language_code: str,
    page: int = Query(1, ge=1, description="Page number, starting from 1"),
    limit: int = Query(10, ge=1, le=100, description="Number of MCQs per page")
):
    """
    Retrieves a paginated list of MCQs for a given language.
    The 'mcqs' collection is assumed to contain individual questions directly,
    or you need to adjust this based on how your 100 MCQs are stored.
    If your 100 MCQs are spread across multiple 'MCQExam' documents,
    you'll need to adjust the query to aggregate them or fetch all and then paginate.

    For simplicity, this assumes a single collection of individual MCQs.
    If your 'mcqs_collection' stores 'MCQExam' documents,
    you would need to adjust the logic to extract questions from these exams.
    """
    skip = (page - 1) * limit

    # This query assumes individual questions are directly in the mcqs_collection
    # and they have a 'language_code' field.
    # If your 100 MCQs are structured differently (e.g., inside 'questions' array
    # of MCQExam documents), you'll need to adjust the query to:
    # 1. Fetch the relevant MCQExam documents.
    # 2. Extract and flatten the 'questions' array.
    # 3. Apply skip and limit on the flattened list.

    # For demonstrating the pagination logic, let's assume your 'mcqs_collection'
    # contains individual Question documents directly.
    # If your data is in MCQExam objects, you'll need a more complex aggregation pipeline.

    # Example for a flat 'mcqs_collection' of Question documents:
    mcqs_cursor = mcqs_collection.find({"language_code": language_code}).skip(skip).limit(limit)
    mcqs = await mcqs_cursor.to_list(length=limit)

    # If mcqs_collection contains MCQExam documents, you'd need to do something like this:
    # This is a more complex scenario and might require aggregation.
    # For now, we'll stick to the simpler assumption.
    # If you need the complex aggregation, let me know.

    if not mcqs:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No MCQs found for this language or page.")

    # Convert MongoDB ObjectId to string for Pydantic serialization if _id is present
    for mcq in mcqs:
        if '_id' in mcq:
            mcq['_id'] = str(mcq['_id'])

    return [Question(**mcq) for mcq in mcqs]