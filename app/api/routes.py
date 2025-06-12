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
