# database.py
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import pyodbc

Base = declarative_base()

# Kết nối SQL Server bằng pyodbc
def get_connection():
    conn_str = (
        "DRIVER={ODBC Driver 17 for SQL Server};"
        "SERVER=name database;DATABASE=database name;"
        "Trusted_Connection=yes;Encrypt=no;TrustServerCertificate=yes;"
    )
    try:
        conn = pyodbc.connect(conn_str)
        print("Kết nối database thành công!")
        return conn
    except Exception as e:
        print(f"Database connection error: {str(e)}")
        raise e

# Tạo engine cho SQLAlchemy (nếu cần)
engine = create_engine('mssql+pyodbc://', creator=get_connection)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)