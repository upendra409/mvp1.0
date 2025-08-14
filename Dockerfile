# Use Python base image for CPU deployment
FROM python:3.10-slim

# Set environment variables
ENV MODEL_NAME=meta-llama/Llama-3.2-1B
ENV MAX_MODEL_LEN=4096
ENV DTYPE=float16
ENV HOST=0.0.0.0
ENV PORT=8000
ENV PYTHONUNBUFFERED=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir \
    vllm \
    torch \
    transformers \
    accelerate \
    fastapi \
    uvicorn

# Create directory for model cache
RUN mkdir -p /root/.cache/huggingface

# Set HuggingFace cache directory
ENV HF_HOME=/root/.cache/huggingface
ENV TRANSFORMERS_CACHE=/root/.cache/huggingface

# Create working directory
WORKDIR /app

# Expose the port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Run vLLM server with CPU-optimized settings
CMD python -m vllm.entrypoints.openai.api_server \
    --model ${MODEL_NAME} \
    --max-model-len ${MAX_MODEL_LEN} \
    --dtype ${DTYPE} \
    --host ${HOST} \
    --port ${PORT} \
    --served-model-name llama-3.2-1b \
    --device cpu \
    --disable-log-requests
