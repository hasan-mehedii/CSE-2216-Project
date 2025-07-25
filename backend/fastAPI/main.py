from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from auth import auth_router
from video_routes import router as video_router
from db import client, words_collection
from pydantic import BaseModel
from typing import Dict
from mcq_routes import mcq_router
from picture_match_routes import router as picture_match_router
from sentence_routes import router as sentence_router
from password_reset import router as password_reset_router
from edit_profile_route import router as edit_profile_router
from admin import router as admin_router
from qna_routes import qna_router
from admin_qna_routes import admin_qna_router


app = FastAPI()

origins = ["*"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router)
app.include_router(video_router)
app.include_router(mcq_router)
app.include_router(picture_match_router)
app.include_router(sentence_router)
app.include_router(password_reset_router)
app.include_router(edit_profile_router)
app.include_router(admin_router)
app.include_router(qna_router)
app.include_router(admin_qna_router)

class Word(BaseModel):
    english_word: str
    image_link: str
    translations: Dict[str, str]
    englishMeaning: str

    class Config:
        orm_mode = True

@app.get("/words", response_model=list[Word])
async def get_words():
    words_cursor = words_collection.find()
    words = await words_cursor.to_list(length=100)
    for word in words:
        word["englishMeaning"] = word.get("english_word", "")
        word.pop("_id", None)
    return words

@app.on_event("startup")
async def startup_event():
    try:
        await client.admin.command('ping')
        print("Connected to MongoDB!")
    except Exception as e:
        print("Could not connect to MongoDB:", e)