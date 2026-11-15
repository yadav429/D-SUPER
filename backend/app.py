import os

import httpx
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

app = FastAPI(title="D-SUPER AI API", version="1.0.0")

# The mobile app never receives the provider key. Configure it only as a
# server-side environment variable in the hosting dashboard.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["POST", "GET"],
    allow_headers=["*"],
)


class ChatRequest(BaseModel):
    message: str = Field(min_length=1, max_length=8000)
    language: str = Field(default="en", pattern="^(hi|en)$")


@app.get("/health")
async def health():
    return {"status": "ok", "service": "d-super-ai-api"}


@app.post("/v1/chat")
async def chat(request: ChatRequest):
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        raise HTTPException(status_code=503, detail="AI provider is not configured")

    model = os.getenv("AI_MODEL", "gpt-4o-mini")
    endpoint = os.getenv(
        "AI_API_URL", "https://api.openai.com/v1/chat/completions"
    )
    language_instruction = (
        "Reply in natural Hindi (Devanagari)." if request.language == "hi"
        else "Reply in clear English."
    )
    payload = {
        "model": model,
        "messages": [
            {
                "role": "system",
                "content": (
                    "You are D-SUPER, a helpful personal assistant. "
                    "Be accurate, concise, and transparent about uncertainty. "
                    + language_instruction
                ),
            },
            {"role": "user", "content": request.message},
        ],
        "temperature": 0.5,
    }

    try:
        async with httpx.AsyncClient(timeout=35.0) as client:
            response = await client.post(
                endpoint,
                headers={
                    "Authorization": f"Bearer {api_key}",
                    "Content-Type": "application/json",
                },
                json=payload,
            )
        response.raise_for_status()
        data = response.json()
        answer = data["choices"][0]["message"]["content"]
        if not isinstance(answer, str) or not answer.strip():
            raise ValueError("Empty model response")
        return {"answer": answer.strip(), "model": model}
    except httpx.HTTPStatusError as exc:
        # Do not return provider response bodies, which may contain sensitive data.
        raise HTTPException(
            status_code=502,
            detail=f"AI provider error ({exc.response.status_code})",
        ) from exc
    except (httpx.HTTPError, KeyError, IndexError, ValueError) as exc:
        raise HTTPException(status_code=502, detail="AI service temporarily unavailable") from exc
