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
