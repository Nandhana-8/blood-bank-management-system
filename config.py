import os
from dotenv import load_dotenv

# Explicitly load .env from the application's root directory
BASE_DIR = os.path.abspath(os.path.dirname(__file__))
env_file_path = os.path.join(BASE_DIR, '.env')
load_dotenv(env_file_path, override=True)

class Config:
    SECRET_KEY = os.getenv('SECRET_KEY', 'blood_bank_super_secret_session_key_2026')
    
    # Exclusively MySQL database connection
    DB_TYPE = os.getenv('DB_TYPE', 'mysql').lower()
    
    MYSQL_HOST = os.getenv('MYSQL_HOST', 'localhost')
    MYSQL_PORT = int(os.getenv('MYSQL_PORT', 3306))
    MYSQL_USER = os.getenv('MYSQL_USER', 'root')
    MYSQL_PASSWORD = os.getenv('MYSQL_PASSWORD', '')
    MYSQL_DB = os.getenv('MYSQL_DB', 'blood_bank_db')
    
    # Connection timeout in seconds
    MYSQL_CONNECT_TIMEOUT = 5
