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
