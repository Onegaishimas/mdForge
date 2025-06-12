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
