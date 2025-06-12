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
