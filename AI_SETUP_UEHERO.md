# UEHero AI Career Assistant (local & free, MVP)

UEHero Flutter already contains a Chatbot screen. This edition connects that screen to a **local FastAPI backend + Ollama model**, grounded in the app's career-events and interview-question assets.

This is **not a newly trained model**. It is a usable first step before collecting a high-quality training dataset and measuring whether fine-tuning actually helps.

## What works in this version

- Natural-language Q&A about career paths, CV, interview prep, event/competition listings.
- Conversation context (last 10 user/assistant turns).
- Built-in app data injected into the prompt when the question mentions a relevant event or interview area.
- Existing deterministic quick questions remain available without AI.
- Friendly error messages if the model/backend is unavailable.
- No paid API keys, no automatic GPU-driver changes, no third-party scripts embedded in this project.

**Limitations:** The event catalog is a *static snapshot* (`assets/data/events.json`, last verified dates in each entry). No live event lookup is performed. The job catalog is demo data. AI still may make mistakes and should be evaluated. Only the **chatbot** is AI-enabled by this patch; the interview scoring screen and CV scoring screen still use their original rules.

## 0. Check existing programs first (read-only)

Open a terminal in the extracted UEHero-main folder:

```bash
flutter --version
python3 --version
ollama --version
nvidia-smi
```

You do **not** need to modify NVIDIA drivers to test the app. If `nvidia-smi` fails, stop before making GPU configuration changes; you can still run some models on the CPU, just slowly.

## 1. Install Ollama if it isn't already available

Install **manually using Ollama's official documentation**: https://docs.ollama.com/linux . Review what will be installed before granting sudo privileges. Do not blindly pipe unknown scripts into a shell. The project does not install or change Ollama on its own.

If Ollama isn't currently running, start it in a *separate terminal*:

```bash
ollama serve
```

If your system already runs Ollama as a service, there's no need for a second server. Check `curl http://127.0.0.1:11434/api/tags` first.

Pull one model. Start with the higher-quality small instruct model (approx. 2.5GB quantized):

```bash
ollama pull qwen3:4b-instruct
```

If this model is too slow or uses too much memory, use the smaller ~1.4GB model instead:

```bash
ollama pull qwen3:1.7b
```

If using the 1.7b model, set `OLLAMA_MODEL=qwen3:1.7b` when starting the backend in step 2. Pulling models uses disk space and an internet connection, but answering queries runs locally.

## 2. Run the FastAPI backend

From inside `UEHero-main`:

```bash
cd ai_backend
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

The server runs in this terminal. Keep it open while testing. The default model is `qwen3:4b-instruct`.

If you chose the smaller model, replace the last command with:

```bash
OLLAMA_MODEL=qwen3:1.7b python -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

If port 8000 is already occupied, change it to 8001 *both* here and in Flutter `--dart-define` below.

In a new terminal, check connectivity:

```bash
curl http://127.0.0.1:8000/health
```

Expected fields: `backend=ok`, `ollama=connected`, `model_installed=true`. A missing model or stopped Ollama will be reported separately. `/docs` is available at http://127.0.0.1:8000/docs.

**Test a real AI request without Flutter:**

```bash
curl -X POST http://127.0.0.1:8000/chat \
  -H 'Content-Type: application/json' \
  -d '{"message":"Nên chuẩn bị gì cho phỏng vấn Business Analyst intern?"}'
```

## 3. Run the Flutter app (Chrome on Ubuntu)

From a **different terminal** inside the extracted UEHero-main root:

```bash
flutter pub get
flutter run -d chrome --dart-define=UEHERO_AI_API_URL=http://127.0.0.1:8000
```

Open the UEHero **Chatbot / AI Companion** screen and ask for an event or interview advice. Existing app quick questions still work even if the backend is down.

For the standard Android emulator, `localhost` points to the emulator, not the Ubuntu PC. Use `http://10.0.2.2:8000` and bind the backend to `0.0.0.0` **only for development on a trusted machine/network**, not on a public server. Android device setups require the device to reach the PC over LAN and appropriate security controls.

## 4. Tests

Run from `ai_backend` (after activating the venv):

```bash
python -m pip install pytest
python -m pytest -q
```

The automated backend tests use a fake model response. They **do not** verify that real Ollama inference works on your laptop or that answers are factually correct. Validate via `/health` and `/chat` on the target computer.

## 5. What about *training* on RTX 4050 (6 GB)?

To make this into an academic AI project, demonstrate **baseline vs fine-tuned vs data-grounded** responses with evaluation questions. Don't train on event deadlines, which go stale. Instead create a reviewed dataset of interview coaching tasks and response rubrics. See `ai_backend/training_data/README.md`.

Hardware reality: RTX 4050 6GB can be appropriate for small quantized local **inference**; fine-tuning needs much stricter VRAM planning and is not implemented in this MVP. Don't claim the chatbot is fine-tuned in a presentation yet. Training data quality and reproducible evaluation come first.

## Architecture

```
Flutter chatbot_screen.dart
   -> lib/services/ai_chat_service.dart (HTTP)
   -> FastAPI /chat
      -> local app event / interview data (grounding)
      -> Ollama /api/chat
      -> reply in Flutter
```

The backend listens on localhost by default. No cloud API keys or external career event searches are involved. Note that local chat history is still saved through the project's existing SharedPreferences code, so avoid sending sensitive student CVs or personal details during a demo unless consent and data handling are addressed.
