from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime
import time
import os, io, re, csv, json, shutil, uuid
from pathlib import Path

from dotenv import load_dotenv
load_dotenv()

from langchain_community.vectorstores import FAISS
from langchain.retrievers import EnsembleRetriever
from langchain_community.retrievers import BM25Retriever
from langchain_core.documents import Document
from langchain_google_genai import (
    ChatGoogleGenerativeAI,
    GoogleGenerativeAIEmbeddings,
)

# Ingest helpers
from rag_data import (
    load_data_from_folder,
    build_or_load_faiss,
    DEFAULT_INDEX_DIR,
    route_and_chunk_text,
    _docling_markdown_from_path,
    apply_metadata_quality_gate,
)

ALLOWED_EXTS = {".pdf", ".docx", ".pptx", ".html", ".htm", ".png", ".jpg", ".jpeg", ".tif", ".tiff", ".txt", ".md"}

# ---------- ENV ----------
GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY", "")
if not GOOGLE_API_KEY:
    raise RuntimeError("GOOGLE_API_KEY chưa được thiết lập trong .env")

# Lưu ý:
# - "models/text-embedding-004" (≈3072 dims)
# - "models/embedding-001" (≈768 dims)
GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")
EMB_MODEL = os.getenv("GEMINI_EMB_MODEL", "models/text-embedding-004")

# Tách thư mục index theo tên model để tránh đụng độ
BASE_INDEX_DIR = os.getenv("FAISS_INDEX_DIR", DEFAULT_INDEX_DIR)
MODEL_SAFE = EMB_MODEL.replace("/", "_")
INDEX_DIR = str(Path(BASE_INDEX_DIR) / MODEL_SAFE)

# Logging / Eval paths
LOG_DIR = Path("./_logs"); LOG_DIR.mkdir(parents=True, exist_ok=True)
LOG_JSONL = LOG_DIR / "rag_logs.jsonl"
EVAL_DIR = Path("./eval"); EVAL_DIR.mkdir(parents=True, exist_ok=True)
EVAL_FILE = EVAL_DIR / "eval.jsonl"     
EVAL_OUTPUT_CSV = EVAL_DIR / "eval_results.csv"

# ---------- APP ----------
app = FastAPI(title="RAG Test (Hybrid + Quality Gate + Eval)", version="1.4.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], allow_credentials=True,
    allow_methods=["*"], allow_headers=["*"],
)

# ---------- GLOBAL STATE ----------
vector_store: Optional[FAISS] = None

# Khởi tạo LLM / Embeddings
llm = ChatGoogleGenerativeAI(
    model=GEMINI_MODEL, google_api_key=GOOGLE_API_KEY, temperature=0.01,
)
emb = GoogleGenerativeAIEmbeddings(
    model=EMB_MODEL, google_api_key=GOOGLE_API_KEY,
)

# ---------- Utilities ----------
def get_current_emb_dim() -> int:
    vec = emb.embed_query("dim-probe")
    return len(vec)

EXPECTED_DIM = get_current_emb_dim()

def ensure_index_compatible(vs: Optional[FAISS]) -> Optional[str]:
    try:
        if vs is None:
            return None
        faiss_dim = int(vs.index.d) 
        if faiss_dim != EXPECTED_DIM:
            return (f"FAISS index dim = {faiss_dim} khác với embedding dim = {EXPECTED_DIM}. "
                    f"Có thể do đổi model embeddings ({EMB_MODEL}). "
                    f"Hãy xoá index cũ bằng POST /reset_index rồi ingest lại.")
        return None
    except Exception as e:
        return f"Không đọc được dimension của FAISS index: {e}"

def load_index_if_exists() -> Optional[FAISS]:
    try:
        vs = build_or_load_faiss([], index_dir=INDEX_DIR)
        msg = ensure_index_compatible(vs)
        if msg:
            raise ValueError(msg)
        return vs
    except Exception:
        return None

# ---------- Hybrid Retriever ----------
def _all_docs_from_faiss(vs: FAISS, max_docs: int = 5000) -> List[Document]:
    try:
        values = list(getattr(vs.docstore, "_dict", {}).values())
        if not values:
            values = vs.similarity_search(" ", k=min(1024, max_docs))
        return values[:max_docs]
    except Exception:
        return []

def make_hybrid_retriever(vs: FAISS, k: int = 4) -> EnsembleRetriever:
    retriever_faiss = vs.as_retriever(search_type="similarity", search_kwargs={"k": max(k, 4)})
    corpus_docs = _all_docs_from_faiss(vs)
    bm25 = BM25Retriever.from_documents(corpus_docs) if corpus_docs else BM25Retriever.from_documents([])
    bm25.k = max(k, 4)
    return EnsembleRetriever(retrievers=[retriever_faiss, bm25], weights=[0.5, 0.5])

# ---------- Metadata filters ----------
def _meta_match(d: Document, contains: Dict[str, Any]) -> bool:
    for k, v in contains.items():
        if str(d.metadata.get(k, "")).lower().strip() != str(v).lower().strip():
            return False
    return True

def _apply_filters(
    docs: List[Document],
    min_quality_tier: str = "medium",
    include_low: bool = False,
    source_in: Optional[List[str]] = None,
    section_title_regex: Optional[str] = None,
    metadata_contains: Optional[Dict[str, Any]] = None,
) -> List[Document]:
    docs = apply_metadata_quality_gate(docs, min_tier=min_quality_tier, include_low=include_low)

    if source_in:
        source_set = set(s.lower() for s in source_in)
        docs = [d for d in docs if str(d.metadata.get("source", "")).lower() in source_set]

    if section_title_regex:
        try:
            pat = re.compile(section_title_regex, re.IGNORECASE)
            docs = [d for d in docs if pat.search(str(d.metadata.get("section_title", "")) or "")]
        except re.error:
            pass 

    if metadata_contains:
        docs = [d for d in docs if _meta_match(d, metadata_contains)]

    return docs

# ---------- RAG Chain ----------
def _build_context(docs: List[Document]) -> str:
    return "\n\n----\n\n".join(
        f"[{d.metadata.get('source')}] ({d.metadata.get('section_title') or d.metadata.get('chunk_level')} | {d.metadata.get('quality_tier')})\n{d.page_content}"
        for d in docs
    )

def chat_with_context(vs: FAISS, query: str, k: int = 4,
                      min_quality_tier: str = "medium",
                      include_low: bool = False,
                      source_in: Optional[List[str]] = None,
                      section_title_regex: Optional[str] = None,
                      metadata_contains: Optional[Dict[str, Any]] = None,
                      max_retry_coarse: int = 2) -> Dict[str, Any]:
    msg = ensure_index_compatible(vs)
    if msg:
        return {"error": msg}

    retr = make_hybrid_retriever(vs, k=k)
    # Chiến lược "coarse-to-fine": tăng k nếu sau filter không đủ ngữ cảnh
    coarse_k = k
    docs: List[Document] = []
    for _ in range(max_retry_coarse + 1):
        docs = retr.invoke(query) if hasattr(retr, "invoke") else retr.get_relevant_documents(query)
        docs = _apply_filters(
            docs,
            min_quality_tier=min_quality_tier,
            include_low=include_low,
            source_in=source_in,
            section_title_regex=section_title_regex,
            metadata_contains=metadata_contains,
        )
        if len(docs) >= min(k, 3):
            break
        coarse_k = min(20, coarse_k + k)
        retr = make_hybrid_retriever(vs, k=coarse_k)

    if not docs:
        return {"answer": "Tôi không chắc chắn về tài liệu được cung cấp.", "contexts": []}

    context = _build_context(docs[:k])
    system = (
        "Bạn là NVP-Chatbot. Trả lời NGẮN GỌN và CHỈ dựa trên 'Ngữ cảnh' cho trước. "
        "Nếu thông tin không có trong ngữ cảnh, hãy nói: 'Tôi không chắc chắn về tài liệu được cung cấp'."
    )
    user_msg = (
        f"Ngữ cảnh:\n{context}\n\n"
        f"Câu hỏi: {query}\n"
        f"Yêu cầu: Trả lời bằng tiếng Việt, bám sát ngữ cảnh."
    )
    resp = llm.invoke([("system", system), ("human", user_msg)])
    answer = getattr(resp, "content", str(resp))
    return {
        "answer": answer,
        "contexts": [
            {
                "content": d.page_content,
                "metadata": d.metadata,
            } for d in docs[:k]
        ],
    }

# ---------- Schemas ----------
class IngestFolderIn(BaseModel):
    folder: str = "data"
    force_rebuild: bool = False

class SearchIn(BaseModel):
    query: str
    k: int = 4
    min_quality_tier: str = Field(default="medium", description="low|medium|high")
    include_low: bool = False
    source_in: Optional[List[str]] = None
    section_title_regex: Optional[str] = None
    metadata_contains: Optional[Dict[str, Any]] = None

class ChatIn(SearchIn):
    pass

class FeedbackIn(BaseModel):
    interaction_id: str
    rating: int = Field(..., description="+1 or -1")
    comment: Optional[str] = None

class EvalIn(BaseModel):
    k: int = 4
    eval_file: Optional[str] = None  # path custom; mặc định ./eval/eval.jsonl

# ---------- Routes ----------
@app.get("/health")
def health():
    return {"ok": True, "emb_model": EMB_MODEL, "emb_dim": EXPECTED_DIM, "index_dir": INDEX_DIR}

@app.get("/")
def root():
    return {
        "ok": True,
        "message": "RAG Test API is running.",
        "endpoints": ["/health", "/ingest_folder", "/ingest_file", "/search", "/chat", "/reset_index", "/feedback", "/eval_offline"]
    }

@app.post("/reset_index")
def reset_index():
    """Xoá toàn bộ thư mục INDEX_DIR của model embeddings hiện tại. (Không xoá ./_uploads)"""
    p = Path(INDEX_DIR)
    if p.exists():
        shutil.rmtree(p, ignore_errors=True)
    global vector_store
    vector_store = None
    return {"ok": True, "message": f"Đã xoá index: {INDEX_DIR}"}

@app.post("/ingest_file")
def ingest_file(file: UploadFile = File(...)):
    global vector_store
    ext = Path(file.filename).suffix.lower()
    if ext not in ALLOWED_EXTS:
        raise HTTPException(status_code=400, detail=f"Unsupported file type: {ext}")

    # Save file to temporary directory
    tmp_dir = Path("./_uploads")
    tmp_dir.mkdir(parents=True, exist_ok=True)
    tmp_path = tmp_dir / file.filename
    with open(tmp_path, "wb") as f:
        f.write(file.file.read())

    # Extract text based on file type
    try:
        if ext in {".txt", ".md"}:
            text = tmp_path.read_text(encoding="utf-8", errors="ignore")
        else:
            text = _docling_markdown_from_path(str(tmp_path))
    except Exception as e:
        return {"ok": False, "error": f"Failed to process file {file.filename}: {str(e)}"}

    # Chunk the text
    chunks = route_and_chunk_text(text=(text or ""), source=file.filename)
    if not chunks:
        return {"ok": False, "error": "Không trích xuất được nội dung tài liệu."}

    # Load existing vector store if available
    if vector_store is None:
        vector_store = load_index_if_exists()

    # Remove existing documents with the same source
    if vector_store is not None:
        try:
            # Get all documents in the current FAISS index
            existing_docs = _all_docs_from_faiss(vector_store)
            docs_to_remove = [d for d in existing_docs if d.metadata.get("source") == file.filename]

            if docs_to_remove:
                # Get chunk IDs to remove
                chunk_ids_to_remove = [d.metadata.get("chunk_id") for d in docs_to_remove]
                # Remove documents from FAISS index
                vector_store.delete(chunk_ids_to_remove)
                vector_store.save_local(INDEX_DIR)
                print(f"[INFO] Removed {len(docs_to_remove)} existing chunks for {file.filename}")
        except Exception as e:
            print(f"[WARN] Failed to remove existing documents for {file.filename}: {e}")

    # Add new chunks to the FAISS index
    vector_store = build_or_load_faiss(chunks, index_dir=INDEX_DIR)

    # Verify index compatibility
    msg = ensure_index_compatible(vector_store)
    if msg:
        return {"ok": False, "error": msg}

    return {"ok": True, "file": file.filename, "added_chunks": len(chunks), "index_dir": INDEX_DIR}

@app.post("/ingest_folder")
def ingest_folder(inp: IngestFolderIn):
    global vector_store
    if inp.force_rebuild:
        reset_index()
    chunks = load_data_from_folder(inp.folder)
    vector_store = build_or_load_faiss(chunks, index_dir=INDEX_DIR)
    msg = ensure_index_compatible(vector_store)
    if msg:
        return {"ok": False, "error": msg}
    return {"ok": True, "chunks": len(chunks), "index_dir": INDEX_DIR, "emb_dim": EXPECTED_DIM}

def _ensure_vs_ready() -> Optional[Dict[str, Any]]:
    global vector_store
    if vector_store is None:
        vector_store = load_index_if_exists()
        if vector_store is None:
            return {"ok": False, "error": "Index chưa sẵn sàng. Hãy gọi /ingest_folder hoặc /ingest_file trước."}
    msg = ensure_index_compatible(vector_store)
    if msg:
        return {"ok": False, "error": msg}
    return None

def _log_interaction(kind: str, payload: Dict[str, Any]) -> str:
    interaction_id = str(uuid.uuid4())
    record = {
        "interaction_id": interaction_id,
        "kind": kind, 
        "timestamp": datetime.utcnow().isoformat(),
        **payload,
        "feedback": None, 
    }
    with open(LOG_JSONL, "a", encoding="utf-8") as f:
        f.write(json.dumps(record, ensure_ascii=False) + "\n")
    return interaction_id

@app.post("/search")
def search(inp: SearchIn):
    err = _ensure_vs_ready()
    if err:
        return err

    t0 = time.time()
    retr = make_hybrid_retriever(vector_store, k=inp.k)  # type: ignore[arg-type]
    raw_docs = retr.get_relevant_documents(inp.query)

    docs = _apply_filters(
        raw_docs,
        min_quality_tier=inp.min_quality_tier,
        include_low=inp.include_low,
        source_in=inp.source_in,
        section_title_regex=inp.section_title_regex,
        metadata_contains=inp.metadata_contains,
    )

    results = [{
        "content": d.page_content[:1200],
        "metadata": d.metadata
    } for d in docs[:inp.k]]

    interaction_id = _log_interaction(
        "search",
        {
            "latency_ms": int((time.time() - t0) * 1000),
            "query": inp.query,
            "k": inp.k,
            "filters": inp.model_dump(exclude={"query", "k"}),
            "retrieved_chunk_ids": [d.metadata.get("chunk_id") for d in docs[:inp.k]],
            "sources": list({d.metadata.get("source") for d in docs[:inp.k]}),
        },
    )

    return {"ok": True, "results": results, "interaction_id": interaction_id}

@app.post("/chat")
def chat(inp: ChatIn):
    err = _ensure_vs_ready()
    if err:
        return err

    t0 = time.time()
    out = chat_with_context(
        vector_store,  
        inp.query, k=inp.k,
        min_quality_tier=inp.min_quality_tier,
        include_low=inp.include_low,
        source_in=inp.source_in,
        section_title_regex=inp.section_title_regex,
        metadata_contains=inp.metadata_contains,
    )
    if "error" in out:
        return {"ok": False, "error": out["error"]}

    interaction_id = _log_interaction(
        "chat",
        {
            "latency_ms": int((time.time() - t0) * 1000),
            "query": inp.query,
            "k": inp.k,
            "filters": inp.model_dump(exclude={"query", "k"}),
            "answer": out["answer"],
            "retrieved_chunk_ids": [ctx["metadata"].get("chunk_id") for ctx in out["contexts"]],
            "sources": list({ctx["metadata"].get("source") for ctx in out["contexts"]}),
        },
    )

    return {"ok": True, "answer": out["answer"], "contexts": out["contexts"], "interaction_id": interaction_id}

# ---------- Feedback ----------
@app.post("/feedback")
def feedback(inp: FeedbackIn):
    if not LOG_JSONL.exists():
        return {"ok": False, "error": "Chưa có log nào để gắn feedback."}

    updated = False
    lines = LOG_JSONL.read_text(encoding="utf-8").splitlines()
    new_lines = []
    for line in lines:
        try:
            obj = json.loads(line)
        except json.JSONDecodeError:
            new_lines.append(line); continue
        if obj.get("interaction_id") == inp.interaction_id:
            obj["feedback"] = {"rating": inp.rating, "comment": inp.comment, "ts": datetime.utcnow().isoformat()}
            updated = True
        new_lines.append(json.dumps(obj, ensure_ascii=False))
    LOG_JSONL.write_text("\n".join(new_lines) + ("\n" if new_lines else ""), encoding="utf-8")

    return {"ok": updated, "message": "Đã cập nhật feedback." if updated else "Không tìm thấy interaction_id."}

# ---------- Offline Eval ----------
def _keyword_hit(answer: str, keywords: List[str]) -> bool:
    a = answer.lower()
    return all(kw.lower() in a for kw in keywords)

def _mrr(ranks: List[int]) -> float:
    # ranks: 1-based; None → 0
    return sum(1.0 / r for r in ranks if r and r > 0) / max(1, len(ranks))

@app.post("/eval_offline")
def eval_offline(inp: EvalIn):
    err = _ensure_vs_ready()
    if err:
        return err

    eval_path = Path(inp.eval_file) if inp.eval_file else EVAL_FILE
    if not eval_path.exists():
        return {"ok": False, "error": f"Không tìm thấy eval file: {eval_path}"}

    rows = []
    with open(eval_path, "r", encoding="utf-8") as f:
        for line in f:
            try:
                ex = json.loads(line)
            except json.JSONDecodeError:
                continue
            rows.append(ex)

    if not rows:
        return {"ok": False, "error": "Eval file rỗng hoặc không hợp lệ."}

    k = max(1, inp.k)
    hits, ranks, ans_hits = 0, [], 0

    with open(EVAL_OUTPUT_CSV, "w", encoding="utf-8", newline="") as cf:
        writer = csv.writer(cf)
        writer.writerow(["query", "hit_gold@k", "rank_first_gold", "answer_keyword_hit", "retrieved_chunk_ids"])
        for ex in rows:
            query = ex.get("query", "")
            gold_ids = set(ex.get("gold_chunk_ids", []))
            keywords = ex.get("keywords", [])

            retr = make_hybrid_retriever(vector_store, k=k)  # type: ignore[arg-type]
            docs = retr.get_relevant_documents(query)
            retrieved_ids = [d.metadata.get("chunk_id") for d in docs[:k]]

            # hit/rank
            rank = 0
            for idx, cid in enumerate(retrieved_ids, start=1):
                if cid in gold_ids:
                    rank = idx
                    break
            ranks.append(rank if rank > 0 else None)
            if rank > 0:
                hits += 1

            # keyword hit in generated answer (lightweight proxy)
            out = chat_with_context(vector_store, query, k=k)  # type: ignore[arg-type]
            ans_ok = _keyword_hit(out.get("answer", ""), keywords) if keywords else False
            if ans_ok:
                ans_hits += 1

            writer.writerow([query, 1 if rank > 0 else 0, rank or "", 1 if ans_ok else 0, "|".join(retrieved_ids)])

    n = len(rows)
    hit_rate = hits / n
    mrr = _mrr([r for r in ranks if r]) if any(ranks) else 0.0
    ans_hit_rate = ans_hits / n

    summary = {
        "n": n,
        "k": k,
        "Recall@k/HitRate": round(hit_rate, 4),
        "MRR@k": round(mrr, 4),
        "AnswerKeywordHitRate": round(ans_hit_rate, 4),
        "output_csv": str(EVAL_OUTPUT_CSV),
    }
    return {"ok": True, "summary": summary}
