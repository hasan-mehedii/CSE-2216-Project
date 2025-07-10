from db import mcqs_collection
from datetime import datetime
import uuid
db.mcqs.find({ "language_code": "english" }).count()
# Sample data generation for 10 exams with 10 questions each
for exam_number in range(1, 11):
    mcq_data = {
        "language_code": "english",
        "exam_number": exam_number,
        "exam_title": f"Basic English Test - Exam {exam_number}",
        "questions": [
            {
                "question": f"What is the capital of country {i+1}?",
                "options": [
                    f"City {i+1}1",
                    f"City {i+1}2",
                    f"City {i+1}3",
                    f"City {i+1}4"
                ],
                "answer_index": i % 4,  # Randomly assign correct answer index (0-3)
                "_id": str(uuid.uuid4())  # Unique ID for each question
            }
            for i in range(10)
        ],
        "created_at": datetime.utcnow().isoformat(),
        "updated_at": datetime.utcnow().isoformat()
    }
    mcqs_collection.insert_one(mcq_data)

print("Successfully inserted 10 exams with 10 questions each into mcqs_collection.")