import os
from pymongo import MongoClient
from dotenv import load_dotenv
from datetime import datetime

# Load environment variables from .env file
load_dotenv()

# Get MongoDB URI and database name from environment variables
MONGO_URI = os.getenv("MONGODB_URI")
DATABASE_NAME = os.getenv("DATABASE_NAME")

# Create a MongoDB client and connect to the database
client = MongoClient(MONGO_URI)
db = client[DATABASE_NAME]

# Define the MCQ exam data to be inserted
mcq_data ={
        "language_code": "english",
        "exam_number": 1,
        "exam_title": "Basic English Test - Exam 1",
        "questions": [
            {
                "question": "What is the capital of France?",
                "options": ["Berlin", "Madrid", "Paris", "Rome"],
                "answer_index": 2
            },
            {
                "question": "Which one is a fruit?",
                "options": ["Carrot", "Potato", "Apple", "Onion"],
                "answer_index": 2
            },
            {
                "question": "Complete the sentence: I ___ a student.",
                "options": ["am", "is", "are", "be"],
                "answer_index": 0
            }
        ],
        "created_at": datetime.utcnow().isoformat(),
        "updated_at": datetime.utcnow().isoformat()
    }



# Define the collection where the data will be inserted
mcqs_collection = db["mcqs"]

# Insert the data into the collection
result = mcqs_collection.insert_one(mcq_data)

# Print the inserted document ID to confirm
print(f"Data inserted with ID: {result.inserted_id}")
