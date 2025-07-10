from fastapi import APIRouter, HTTPException, status, Depends
from models import User, UserLogin
from db import collection
from pydantic import BaseModel
from typing import Optional
from passlib.context import CryptContext
from jose import jwt, JWTError
from datetime import datetime, timedelta
from fastapi.security import OAuth2PasswordBearer
import secrets
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

auth_router = APIRouter()

# Password hashing setup
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# JWT settings
SECRET_KEY = "B24TGRWvKBCIHzHKJdhZocdMKhZO0ovAi0nuydx2PAQ"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

# Email settings (configure with your SMTP service)
SMTP_SERVER = "smtp.gmail.com"
SMTP_PORT = 587
SMTP_USERNAME = "your-email@gmail.com"  # Replace with your Gmail address
SMTP_PASSWORD = "your-16-character-app-password"  # Replace with your App Password

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="login")

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def create_access_token(data: dict, expires_delta: timedelta | None = None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=15))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

def send_email(to_email: str, temp_password: str):
    msg = MIMEMultipart()
    msg['From'] = SMTP_USERNAME
    msg['To'] = to_email
    msg['Subject'] = "Password Reset Request"

    body = f"""
    Your temporary password is: {temp_password}
    Please use this to log in and update your password in the app settings.
    """
    msg.attach(MIMEText(body, 'plain'))

    try:
        server = smtplib.SMTP(SMTP_SERVER, SMTP_PORT)
        server.starttls()
        server.login(SMTP_USERNAME, SMTP_PASSWORD)
        server.sendmail(SMTP_USERNAME, to_email, msg.as_string())
        server.quit()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to send email: {str(e)}")

class ForgotPasswordRequest(BaseModel):
    email: str

@auth_router.post("/forgot-password")
async def forgot_password(request: ForgotPasswordRequest):
    existing_user = await collection.find_one({"email": request.email})
    if not existing_user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Email not found")

    # Generate a temporary password
    temp_password = secrets.token_urlsafe(8)  # Generates a random 8-character password
    hashed_temp_password = hash_password(temp_password)

    # Update the user's password in the database
    await collection.update_one(
        {"email": request.email},
        {"$set": {"password": hashed_temp_password}}
    )

    # For testing, return the temporary password instead of sending email
    return {"message": "Temporary password (for testing)", "temp_password": temp_password}

@auth_router.post("/signup")
async def signup(user: User):
    existing_user = await collection.find_one({"email": user.email})
    if existing_user:
        raise HTTPException(status_code=400, detail="Email already registered")

    hashed_pwd = hash_password(user.password)
    user_dict = user.dict()
    user_dict["password"] = hashed_pwd

    await collection.insert_one(user_dict)
    return {"message": "User created successfully"}

@auth_router.post("/login")
async def login(user: UserLogin):
    existing_user = await collection.find_one({"email": user.email})
    if not existing_user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")

    if not verify_password(user.password, existing_user["password"]):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")

    access_token = create_access_token(data={"sub": existing_user["email"]},
                                       expires_delta=timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    return {"access_token": access_token, "token_type": "bearer"}

async def get_current_user(token: str = Depends(oauth2_scheme)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    user = await collection.find_one({"email": email})
    if user is None:
        raise credentials_exception
    return user

@auth_router.get("/protected")
async def protected_route(current_user: dict = Depends(get_current_user)):
    return {"message": f"Hello, {current_user['email']}! You have accessed a protected route."}

@auth_router.get("/user/profile")
async def get_user_profile(current_user: dict = Depends(get_current_user)):
    user_profile = {
        "fullName": current_user["fullName"],
        "username": current_user["username"],
        "email": current_user["email"],
        "phoneNumber": current_user["phoneNumber"],
        "countryCode": current_user["countryCode"],
        "gender": current_user.get("gender"),
        "nid": current_user["nid"],
        "dob": current_user["dob"].isoformat(),
        "is_premium": current_user.get("is_premium", False)
    }
    return user_profile

class PremiumUpdate(BaseModel):
    is_premium: bool

@auth_router.patch("/user/premium")
async def update_premium_status(update: PremiumUpdate, current_user: dict = Depends(get_current_user)):
    result = await collection.update_one(
        {"email": current_user["email"]},
        {"$set": {"is_premium": update.is_premium}}
    )
    if result.modified_count == 0:
        raise HTTPException(status_code=400, detail="Failed to update premium status")
    return {"message": f"Premium status updated to {update.is_premium}"}