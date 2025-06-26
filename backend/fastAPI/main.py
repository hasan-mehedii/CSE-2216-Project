from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from auth import auth_router  # Import the router that handles /signup and /login
from db import client, words_collection  # Ensure your MongoDB collection for words is correctly imported
from pydantic import BaseModel
from typing import Dict
from mcq import mcq_router
# Initialize FastAPI app
app = FastAPI()

# Add CORS middleware to allow cross-origin requests
origins = [
    "*"  # Allow all origins for now (you can change this in production)
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],  # Allow all HTTP methods (GET, POST, etc.)
    allow_headers=["*"],  # Allow all headers
)

# Define the Word Pydantic model to match MongoDB document structure
class Word(BaseModel):
    english_word: str
    image_link: str
    translations: Dict[str, str]
    englishMeaning: str

    class Config:
        orm_mode = True

app.include_router(mcq_router)
# Include the auth router for login and signup
app.include_router(auth_router)

# Endpoint to get words from MongoDB
@app.get("/words", response_model=list[Word])
async def get_words():
    words_cursor = words_collection.find()
    words = await words_cursor.to_list(length=100)

    # Add englishMeaning dynamically from english_word if it's missing in the DB
    for word in words:
        word["englishMeaning"] = word.get("english_word", "")  # Use english_word as englishMeaning

    return words

# Event to test MongoDB connection on application startup
@app.on_event("startup")
async def startup_event():
    try:
        await client.admin.command('ping')
        print("Connected to MongoDB!")
    except Exception as e:
        print("Could not connect to MongoDB:", e)
