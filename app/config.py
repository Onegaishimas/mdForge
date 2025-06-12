from pydantic_settings import BaseSettings
from typing import List, Optional

class Settings(BaseSettings):
    """Application settings."""
    
    # App Config
    APP_NAME: str = "mdForge"
    VERSION: str = "1.0.0"
    DEBUG: bool = False
    
    # API Config
    API_V1_STR: str = "/api/v1"
    MAX_FILE_SIZE_MB: int = 100
    
    # Supported formats
    SUPPORTED_FORMATS: List[str] = [
        # Documents
        "pdf", "docx", "pptx", "xlsx", "doc", "xls", "ppt",
        "odt", "ods", "odp", "rtf", "txt", "md", "html", "htm",
        "xml", "json", "csv", "tsv",
        # Images
        "png", "jpg", "jpeg", "gif", "bmp", "tiff", "webp",
        # Audio/Video
        "mp3", "wav", "m4a", "mp4", "avi", "mov", "mkv",
        # Archives
        "zip", "tar", "gz"
    ]
    
    # AI Services (Optional)
    OPENAI_API_KEY: Optional[str] = None
    OPENAI_BASE_URL: Optional[str] = None  # For local ollama
    ANTHROPIC_API_KEY: Optional[str] = None
    GOOGLE_API_KEY: Optional[str] = None
    
    # Enable AI features
    ENABLE_AI_PROCESSING: bool = False
    DEFAULT_AI_MODEL: str = "gpt-3.5-turbo"
    
    class Config:
        env_file = ".env"
        case_sensitive = True

settings = Settings()
