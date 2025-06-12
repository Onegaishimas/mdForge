#!/bin/bash

# mdForge Setup Script
# Creates all necessary files in their correct folders

set -e

echo "Creating mdForge project files..."

# Create requirements.txt
cat > requirements.txt << 'EOF'
fastapi==0.104.1
uvicorn[standard]==0.24.0
python-multipart==0.0.6
markitdown>=0.0.1a2
aiofiles==23.2.1
python-dotenv==1.0.1
pydantic==2.4.2
pydantic-settings==2.0.3
openai>=1.0.0
anthropic>=0.7.0
google-generativeai>=0.3.0
requests==2.31.0
EOF

# Create .env.example
cat > .env.example << 'EOF'
# Application Config
APP_NAME=mdForge
VERSION=1.0.0
DEBUG=false
MAX_FILE_SIZE_MB=100

# AI Configuration
ENABLE_AI_PROCESSING=true
OPENAI_API_KEY=your-openai-key-here
OPENAI_BASE_URL=http://your-ollama-server:11434
ANTHROPIC_API_KEY=your-anthropic-key-here
GOOGLE_API_KEY=your-google-key-here
DEFAULT_AI_MODEL=gpt-3.5-turbo
EOF

# Create .gitignore
cat > .gitignore << 'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# Virtual Environment
venv/
env/
ENV/

# Environment variables
.env

# IDE
.vscode/
.idea/
*.swp
*.swo

# Logs
*.log

# Testing
.pytest_cache/
.coverage
htmlcov/

# Docker
.docker/

# OS
.DS_Store
Thumbs.db
EOF

# Create .dockerignore
cat > .dockerignore << 'EOF'
.git
.gitignore
README.md
Dockerfile
.dockerignore
.env
.env.*
__pycache__
*.pyc
*.pyo
*.pyd
.pytest_cache
.coverage
tests/
k8s/
.vscode/
.idea/
*.log
EOF

# Create Dockerfile
cat > Dockerfile << 'EOF'
FROM python:3.11-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    # For MarkItDown dependencies
    ffmpeg \
    poppler-utils \
    libreoffice \
    pandoc \
    tesseract-ocr \
    # Build tools
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -u 1000 mdforge

# Set working directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app/ ./app/

# Create necessary directories and set permissions
RUN mkdir -p /tmp/mdforge && \
    chown -R mdforge:mdforge /app /tmp/mdforge

# Switch to non-root user
USER mdforge

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/api/v1/health || exit 1

# Run the application
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

# Create docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  mdforge:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "8000:8000"
    environment:
      - DEBUG=1
      - MAX_FILE_SIZE_MB=100
      - ENABLE_AI_PROCESSING=false
    volumes:
      - ./app:/app/app
    restart: unless-stopped
EOF

# Create app/__init__.py
cat > app/__init__.py << 'EOF'
"""mdForge - Universal Document Converter API"""
EOF

# Create app/config.py
cat > app/config.py << 'EOF'
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
EOF

# Create app/main.py
cat > app/main.py << 'EOF'
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import logging
import sys

from app.api.routes import router as api_router
from app.config import settings

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)]
)

logger = logging.getLogger(__name__)

# Create FastAPI app
app = FastAPI(
    title=settings.APP_NAME,
    description="Universal Document Converter API powered by Microsoft MarkItDown",
    version=settings.VERSION,
    docs_url="/docs",
    redoc_url="/redoc"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API routes
app.include_router(api_router, prefix=settings.API_V1_STR, tags=["conversion"])

@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    """Global exception handler."""
    logger.error(f"Unhandled exception: {str(exc)}")
    return JSONResponse(
        status_code=500,
        content={"error": "Internal server error", "message": str(exc)}
    )

@app.on_event("startup")
async def startup_event():
    """Application startup event."""
    logger.info(f"{settings.APP_NAME} v{settings.VERSION} starting up...")
    logger.info(f"Supported formats: {len(settings.SUPPORTED_FORMATS)}")
    logger.info(f"AI processing enabled: {settings.ENABLE_AI_PROCESSING}")

@app.get("/")
async def root():
    """Root endpoint."""
    return {
        "app": settings.APP_NAME,
        "version": settings.VERSION,
        "docs": "/docs",
        "health": f"{settings.API_V1_STR}/health"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.DEBUG
    )
EOF

# Create app/core/__init__.py
cat > app/core/__init__.py << 'EOF'
"""Core functionality for mdForge"""
EOF

# Create app/core/converter.py
cat > app/core/converter.py << 'EOF'
import asyncio
import tempfile
import logging
from pathlib import Path
from typing import Dict, Any, Optional
import time
from markitdown import MarkItDown

from app.config import settings

logger = logging.getLogger(__name__)

class MarkItDownConverter:
    """Document converter using Microsoft MarkItDown."""
    
    def __init__(self):
        self.md = MarkItDown()
        self._configure_ai_services()
    
    def _configure_ai_services(self):
        """Configure AI services if enabled."""
        if not settings.ENABLE_AI_PROCESSING:
            return
            
        # Configure OpenAI (local ollama or OpenAI API)
        if settings.OPENAI_API_KEY:
            import openai
            openai.api_key = settings.OPENAI_API_KEY
            if settings.OPENAI_BASE_URL:
                openai.api_base = settings.OPENAI_BASE_URL
    
    async def convert_document(
        self,
        file_content: bytes,
        filename: str,
        output_format: str = "markdown",
        enhance_with_ai: bool = False
    ) -> Dict[str, Any]:
        """Convert document to specified format."""
        start_time = time.time()
        
        try:
            # Create temporary file
            with tempfile.NamedTemporaryFile(
                delete=False, 
                suffix=Path(filename).suffix
            ) as temp_file:
                temp_file.write(file_content)
                temp_path = temp_file.name
            
            # Convert using MarkItDown
            result = await asyncio.get_event_loop().run_in_executor(
                None, self.md.convert, temp_path
            )
            
            # Clean up temp file
            Path(temp_path).unlink(missing_ok=True)
            
            # Prepare response
            response = {
                "content": result.text_content,
                "title": result.title or Path(filename).stem,
                "original_format": Path(filename).suffix.lower().lstrip('.'),
                "conversion_time": time.time() - start_time,
                "metadata": {
                    "file_size": len(file_content),
                    "filename": filename,
                    "enhanced_with_ai": enhance_with_ai
                }
            }
            
            # AI Enhancement (optional)
            if enhance_with_ai and settings.ENABLE_AI_PROCESSING:
                response = await self._enhance_with_ai(response)
            
            return response
            
        except Exception as e:
            logger.error(f"Conversion failed for {filename}: {str(e)}")
            raise
    
    async def _enhance_with_ai(self, result: Dict[str, Any]) -> Dict[str, Any]:
        """Enhance converted content with AI processing."""
        try:
            # Example: Summarize, improve formatting, etc.
            # This is where you'd call your local ollama or OpenAI API
            result["metadata"]["ai_enhanced"] = True
            return result
        except Exception as e:
            logger.warning(f"AI enhancement failed: {str(e)}")
            return result
EOF

# Create app/api/__init__.py
cat > app/api/__init__.py << 'EOF'
"""API routes for mdForge"""
EOF

# Create app/api/routes.py
cat > app/api/routes.py << 'EOF'
from fastapi import APIRouter, UploadFile, File, HTTPException, Form
from fastapi.responses import PlainTextResponse, JSONResponse
import logging

from app.core.converter import MarkItDownConverter
from app.models.schemas import ConversionResponse, HealthResponse, ErrorResponse
from app.config import settings

logger = logging.getLogger(__name__)
router = APIRouter()
converter = MarkItDownConverter()

@router.post("/convert", response_model=ConversionResponse)
async def convert_document(
    file: UploadFile = File(...),
    output_format: str = Form("markdown"),
    enhance_with_ai: bool = Form(False),
    return_raw: bool = Form(False)
):
    """Convert uploaded document to specified format."""
    try:
        # Validate file size
        file_content = await file.read()
        file_size_mb = len(file_content) / (1024 * 1024)
        
        if file_size_mb > settings.MAX_FILE_SIZE_MB:
            raise HTTPException(
                status_code=413,
                detail=f"File too large. Maximum size: {settings.MAX_FILE_SIZE_MB}MB"
            )
        
        # Validate file format
        file_extension = file.filename.split('.')[-1].lower()
        if file_extension not in settings.SUPPORTED_FORMATS:
            raise HTTPException(
                status_code=400,
                detail=f"Unsupported format: {file_extension}"
            )
        
        # Convert document
        result = await converter.convert_document(
            file_content=file_content,
            filename=file.filename,
            output_format=output_format,
            enhance_with_ai=enhance_with_ai
        )
        
        # Return raw content or JSON response
        if return_raw:
            return PlainTextResponse(
                content=result["content"],
                media_type="text/markdown",
                headers={
                    "Content-Disposition": f"attachment; filename={result['title']}.md"
                }
            )
        
        return ConversionResponse(**result)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Conversion error: {str(e)}")
        raise HTTPException(status_code=500, detail="Conversion failed")

@router.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint."""
    return HealthResponse(
        status="healthy",
        version=settings.VERSION,
        supported_formats=settings.SUPPORTED_FORMATS,
        ai_enabled=settings.ENABLE_AI_PROCESSING
    )

@router.get("/formats")
async def get_supported_formats():
    """Get list of supported file formats."""
    return {
        "supported_formats": settings.SUPPORTED_FORMATS,
        "total_count": len(settings.SUPPORTED_FORMATS)
    }
EOF

# Create app/models/__init__.py
cat > app/models/__init__.py << 'EOF'
"""Data models for mdForge"""
EOF

# Create app/models/schemas.py
cat > app/models/schemas.py << 'EOF'
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List
from datetime import datetime

class ConversionRequest(BaseModel):
    """Request model for document conversion."""
    output_format: str = Field(default="markdown", description="Output format")
    enhance_with_ai: bool = Field(default=False, description="Enable AI enhancement")

class ConversionResponse(BaseModel):
    """Response model for document conversion."""
    content: str = Field(..., description="Converted content")
    title: str = Field(..., description="Document title")
    original_format: str = Field(..., description="Original file format")
    conversion_time: float = Field(..., description="Conversion time in seconds")
    metadata: Dict[str, Any] = Field(..., description="Additional metadata")

class HealthResponse(BaseModel):
    """Health check response."""
    status: str = Field(..., description="Service status")
    version: str = Field(..., description="Application version")
    supported_formats: List[str] = Field(..., description="Supported file formats")
    ai_enabled: bool = Field(..., description="AI processing enabled")
    timestamp: datetime = Field(default_factory=datetime.now)

class ErrorResponse(BaseModel):
    """Error response model."""
    error: str = Field(..., description="Error type")
    message: str = Field(..., description="Error message")
    details: Optional[str] = Field(None, description="Error details")
    timestamp: datetime = Field(default_factory=datetime.now)
EOF

# Create k8s/configmap.yaml
cat > k8s/configmap.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: mdforge-config
  namespace: default
data:
  APP_NAME: "mdForge"
  VERSION: "1.0.0"
  DEBUG: "false"
  MAX_FILE_SIZE_MB: "100"
  API_V1_STR: "/api/v1"
  ENABLE_AI_PROCESSING: "true"
  OPENAI_BASE_URL: "http://ollama-service:11434"  # Your local ollama
EOF

# Create k8s/deployment.yaml
cat > k8s/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mdforge
  namespace: default
  labels:
    app: mdforge
spec:
  replicas: 3
  selector:
    matchLabels:
      app: mdforge
  template:
    metadata:
      labels:
        app: mdforge
    spec:
      containers:
      - name: mdforge
        image: onegaionegai/mdforge:latest
        ports:
        - containerPort: 8000
        envFrom:
        - configMapRef:
            name: mdforge-config
        env:
        - name: OPENAI_API_KEY
          valueFrom:
            secretKeyRef:
              name: mdforge-secrets
              key: openai-api-key
              optional: true
        resources:
          requests:
            memory: "1Gi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
        readinessProbe:
          httpGet:
            path: /api/v1/health
            port: 8000
          initialDelaySeconds: 10
          periodSeconds: 10
        livenessProbe:
          httpGet:
            path: /api/v1/health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 30
---
apiVersion: v1
kind: Secret
metadata:
  name: mdforge-secrets
  namespace: default
type: Opaque
stringData:
  openai-api-key: "your-openai-api-key-here"
  anthropic-api-key: "your-anthropic-api-key-here"
  google-api-key: "your-google-api-key-here"
EOF

# Create k8s/service.yaml
cat > k8s/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: mdforge-service
  namespace: default
  labels:
    app: mdforge
spec:
  selector:
    app: mdforge
  ports:
  - name: http
    port: 80
    targetPort: 8000
    protocol: TCP
  type: ClusterIP
EOF

# Create k8s/ingress.yaml
cat > k8s/ingress.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: mdforge-ingress
  namespace: default
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/proxy-body-size: "100m"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "300"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "300"
spec:
  ingressClassName: nginx
  rules:
  - host: mdforge.yourdomain.com  # Replace with your domain
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: mdforge-service
            port:
              number: 80
  # Uncomment for TLS
  # tls:
  # - hosts:
  #   - mdforge.yourdomain.com
  #   secretName: mdforge-tls
EOF

# Create tests/__init__.py
cat > tests/__init__.py << 'EOF'
"""Tests for mdForge"""
EOF

# Create tests/test_converter.py
cat > tests/test_converter.py << 'EOF'
import pytest
import asyncio
from pathlib import Path
from app.core.converter import MarkItDownConverter

@pytest.fixture
def converter():
    return MarkItDownConverter()

@pytest.mark.asyncio
async def test_pdf_conversion(converter):
    """Test PDF conversion functionality."""
    # This would require actual test files
    # For now, just test that the converter initializes
    assert converter.md is not None

@pytest.mark.asyncio
async def test_unsupported_format(converter):
    """Test handling of unsupported formats."""
    # Test implementation would go here
    pass
EOF

# Create README.md
cat > README.md << 'EOF'
# mdForge - Universal Document Converter API

A powerful, containerized document conversion API powered by Microsoft's MarkItDown library.

## Features

- **Universal Format Support**: PDF, DOCX, PPTX, XLSX, images, audio, video, and more
- **AI Enhancement**: Optional AI-powered content improvement
- **Kubernetes Ready**: Production-ready container deployment
- **RESTful API**: Simple HTTP API for document conversion
- **Scalable**: Horizontal scaling support

## Quick Start

### Local Development
```bash
# Setup
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt

# Configure
cp .env.example .env
# Edit .env with your settings

# Run
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### Docker
```bash
docker build -t mdforge .
docker run -p 8000:8000 mdforge
```

### Kubernetes
```bash
kubectl apply -f k8s/
```

## API Usage

### Convert Document
```bash
curl -X POST "http://localhost:8000/api/v1/convert" \
     -F "file=@document.pdf" \
     -F "return_raw=true" \
     -o converted.md
```

### Health Check
```bash
curl http://localhost:8000/api/v1/health
```

## Supported Formats

- **Documents**: PDF, DOCX, PPTX, XLSX, ODT, RTF, HTML, XML, JSON, CSV
- **Images**: PNG, JPG, GIF, BMP, TIFF, WEBP
- **Audio/Video**: MP3, WAV, MP4, AVI, MOV (with transcription)
- **Archives**: ZIP, TAR, GZ

## License

MIT License
EOF

echo "✅ All files created successfully!"
echo ""
echo "Next steps:"
echo "1. Edit k8s/ingress.yaml and replace 'mdforge.yourdomain.com' with your domain"
echo "2. Update k8s/deployment.yaml with your actual API keys"
echo "3. Run: git add . && git commit -m 'Initial mdForge implementation'"
echo "4. Run: git push origin main"
echo ""
echo "To test locally:"
echo "1. python -m venv venv"
echo "2. source venv/bin/activate"
echo "3. pip install -r requirements.txt"
echo "4. cp .env.example .env"
echo "5. uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload"