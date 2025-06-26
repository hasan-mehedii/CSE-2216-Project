from pydantic import BaseModel, EmailStr
from typing import Optional, List, Dict
from datetime import datetime

class User(BaseModel):
    fullName: str
    username: str
    email: EmailStr
    phoneNumber: str
    countryCode: str
    gender: Optional[str] = None
    nid: str
    dob: datetime
    password: str
    is_premium: bool = False  # Add is_premium field with default value False

class UserLogin(BaseModel):
    email: EmailStr
    password: str


class Question(BaseModel):
    question: str
    options: List[str]
    answer_index: int

class MCQExam(BaseModel):
    language_code: str  # e.g., 'es' for Spanish
    exam_number: int    # e.g., 1, 2, 3, etc.
    exam_title: str
    questions: List[Question]
    created_at: str
    updated_at: str

    class Config:
        orm_mode = True
