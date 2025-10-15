# =========================
# FILE: rag_data.py  (optimized v1)
# =========================
import os
import re
import io
import json
import time
import uuid
import hashlib
from typing import Optional, List, Tuple, Dict, Any
from pathlib import Path

# ---- Fast path: PyMuPDF (không OCR) ----
import fitz  # PyMuPDF

# ---- Fallback / universal: Docling (có OCR khi cần) ----
from docling.document_converter import DocumentConverter

from dotenv import load_dotenv
load_dotenv()

from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_google_genai import GoogleGenerativeAIEmbeddings
from langchain_community.vectorstores import FAISS
from langchain_core.documents import Document

# ----------------------
# ENV & Defaults
# ----------------------
GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY", "")
DEFAULT_INDEX_DIR = os.getenv("FAISS_INDEX_DIR", "faiss_index")
EMB_MODEL = os.getenv("GEMINI_EMB_MODEL", "models/embedding-001")  # Nhanh hơn 004
MAX_ADD_BATCH = int(os.getenv("FAISS_ADD_BATCH", "128"))            # add theo lô để ổn định

__all__ = [
    # public APIs giữ tương thích
    "load_data_from_folder",
    "build_or_load_faiss",
    "route_and_chunk_text",
    "DEFAULT_INDEX_DIR",
    # tiện ích mới để rag_server dùng
    "convert_path_to_text",
    "convert_path_to_chunks",
    "file_hash",
    "should_skip_ingest",
    "write_ingest_meta",
]

# =========================
# Cleaning helpers
# =========================
_HTML_COMMENT_RE = re.compile(r"<!--.*?-->", re.S)
_CODE_FENCE_RE   = re.compile(r"```.*?```", re.S)
_IMAGE_LINE_RE   = re.compile(r"^\s*!\[[^\]]*\]\([^)]+\)\s*$", re.M)
_STOP_SECTIONS_RE = re.compile(r"^\s*#{1,6}\s*(comments?|metadata)\s*$", re.I | re.M)

def _clean_markdown(md: str) -> str:
    """Loại HTML comment, code-fence, dòng ảnh rời → giảm nhiễu khi index."""
    md = _HTML_COMMENT_RE.sub(" ", md)
    md = _CODE_FENCE_RE.sub(" ", md)
    md = _IMAGE_LINE_RE.sub(" ", md)
    return md

# =========================
# 1) Fast extractor + OCR fallback
# =========================
def extract_text_fast(pdf_path: str, min_chars_per_page: int = 400) -> Tuple[List[str], bool]:
    """
    Dò nhanh text bằng PyMuPDF. Nếu >25% trang nghèo chữ → recommend OCR (need_ocr=True).
    """
    pages, low_text = [], 0
    with fitz.open(pdf_path) as doc:
        for p in doc:
            t = p.get_text("text") or ""
            pages.append(t)
            if len(t.strip()) < min_chars_per_page:
                low_text += 1
    need_ocr = (low_text / max(1, len(pages))) > 0.25
    return pages, need_ocr

def _docling_markdown_from_path(path: str) -> str:
    conv = DocumentConverter()
    res = conv.convert(path)
    md = res.document.export_to_markdown()
    return _clean_markdown(md)

def convert_path_to_text(path: str) -> str:
    """
    Trả về text/markdown đã làm sạch:
    - PDF: fast-path bằng PyMuPDF, chỉ fallback Docling (có OCR) khi cần
    - DOCX/PPTX/HTML/IMG: Docling
    - TXT/MD: đọc thẳng + clean
    """
    ext = Path(path).suffix.lower()
    if ext == ".pdf":
        pages, need_ocr = extract_text_fast(path)
        if not need_ocr and any(p.strip() for p in pages):
            return _clean_markdown("\n\n".join(pages))
        # Fallback OCR/Docling
        return _docling_markdown_from_path(path)

    if ext in {".docx", ".pptx", ".html", ".htm", ".png", ".jpg", ".jpeg", ".tif", ".tiff"}:
        return _docling_markdown_from_path(path)

    if ext in {".txt", ".md"}:
        with open(path, "r", encoding="utf-8", errors="ignore") as f:
            return _clean_markdown(f.read())

    return ""

# =========================
# 2) Quality scoring & tier
# =========================
def _score_text_quality(text: str) -> float:
    if not text:
        return 0.0
    n = len(text)
    ascii_ratio = sum(1 for ch in text if ord(ch) < 128) / n
    alnum_ratio = sum(1 for ch in text if ch.isalnum() or ch.isspace()) / n
    lines = [ln for ln in text.splitlines() if ln.strip()]
    avg_line = (sum(len(ln) for ln in lines) / max(1, len(lines))) if lines else 0
    garbage_ratio = sum(1 for ch in text if ord(ch) > 2048) / n
    line_score = 1.0 if 40 <= avg_line <= 300 else 0.6 if 20 <= avg_line < 40 or 300 < avg_line <= 600 else 0.3
    garbage_penalty = max(0.0, 1.0 - 3.0 * garbage_ratio)
    score = 0.40 * ascii_ratio + 0.35 * alnum_ratio + 0.15 * line_score + 0.10 * garbage_penalty
    return max(0.0, min(1.0, score))

def _quality_tier(text: str) -> str:
    s = _score_text_quality(text)
    if s >= 0.8:
        return "high"
    if s >= 0.55:
        return "medium"
    return "low"

# =========================
# 3) Chunking strategies (to, overlap nhỏ)
# =========================
_hdr_re = re.compile(
    r"^(#{1,6}\s.+|[A-Z][A-Z0-9\s\-,:()]{6,}$|\d+(\.\d+)*\s+.+)$",
    re.MULTILINE,
)

def _split_by_headers(text: str, min_body_chars: int = 200) -> List[Tuple[str, str]]:
    sections: List[Tuple[str, str]] = []
    indices = [(m.start(), m.group(0).strip()) for m in _hdr_re.finditer(text)]
    if not indices:
        body = text.strip()
        return [("Body", body)] if len(body) >= min_body_chars else []
    indices.append((len(text), None))
    for i in range(len(indices) - 1):
        start, title = indices[i]
        if title and _STOP_SECTIONS_RE.match(title):
            continue
        end, _ = indices[i + 1]
        line_end = text.find("\n", start)
        content_start = line_end + 1 if line_end != -1 else start
        body = text[content_start:end].strip()
        if len(body) < min_body_chars:
            continue
        norm_title = (title or f"Section-{i+1}").lstrip("# ").strip()
        sections.append((norm_title, body))
    return sections

def _paragraph_chunks(text: str, chunk_size_chars=1600, overlap=120) -> List[str]:
    paragraphs = [p.strip() for p in re.split(r"\n\s*\n+", text) if p.strip()]
    joined = "\n\n".join(paragraphs) if paragraphs else text
    splitter = RecursiveCharacterTextSplitter(
        chunk_size=chunk_size_chars,
        chunk_overlap=overlap,
        separators=["\n# ", "\n## ", "\n### ", "\n\n", "\n", " ", ""],
    )
    docs = splitter.split_documents([Document(page_content=joined)])
    return [d.page_content for d in docs]

def _fixed_chunks(text: str, chunk_size_chars=800, overlap=100) -> List[str]:
    splitter = RecursiveCharacterTextSplitter(
        chunk_size=chunk_size_chars,
        chunk_overlap=overlap,
    )
    docs = splitter.split_documents([Document(page_content=text)])
    return [d.page_content for d in docs]

def _hierarchical_chunks(text: str) -> List[Tuple[str, str]]:
    out: List[Tuple[str, str]] = []
    for title, body in _split_by_headers(text, min_body_chars=220):
        for ch in _paragraph_chunks(body, chunk_size_chars=1600, overlap=120):
            out.append((title, ch))
    if not out:
        for ch in _paragraph_chunks(text, chunk_size_chars=1600, overlap=120):
            out.append(("Body", ch))
    return out

# =========================
# 4) Metadata enrichment
# =========================
def _approx_token_count(s: str) -> int:
    return max(1, len(s) // 4)

def _enrich_metadata(base: Dict[str, Any], content: str, source: str) -> Dict[str, Any]:
    ext = Path(source).suffix.lower() if source else ""
    return {
        **base,
        "source_ext": ext,
        "content_length": len(content),
        "line_count": content.count("\n") + 1,
        "approx_tokens": _approx_token_count(content),
    }

# ==================================
# 5) Public: route & chunk a raw text
# ==================================
def route_and_chunk_text(text: str, source: str) -> List[Document]:
    """
    Tạo List[Document] kèm metadata phong phú: source, quality_tier, chunk_level,
    section_title, chunk_id, content_length, line_count, approx_tokens.
    """
    text = _clean_markdown((text or "").strip())
    if not text:
        return []
    tier = _quality_tier(text)
    chunks: List[Document] = []

    if tier == "high":
        for section_title, ch in _hierarchical_chunks(text):
            meta = _enrich_metadata(
                {
                    "source": source,
                    "quality_tier": tier,
                    "chunk_level": "section_paragraph",
                    "section_title": section_title,
                    "chunk_id": str(uuid.uuid4()),
                },
                ch,
                source,
            )
            chunks.append(Document(page_content=ch, metadata=meta))

    elif tier == "medium":
        for ch in _paragraph_chunks(text, chunk_size_chars=1600, overlap=120):
            meta = _enrich_metadata(
                {
                    "source": source,
                    "quality_tier": tier,
                    "chunk_level": "paragraph",
                    "section_title": None,
                    "chunk_id": str(uuid.uuid4()),
                },
                ch,
                source,
            )
            chunks.append(Document(page_content=ch, metadata=meta))
    else:
        for ch in _fixed_chunks(text, chunk_size_chars=800, overlap=100):
            meta = _enrich_metadata(
                {
                    "source": source,
                    "quality_tier": tier,
                    "chunk_level": "fixed",
                    "needs_review": True,
                    "section_title": None,
                    "chunk_id": str(uuid.uuid4()),
                },
                ch,
                source,
            )
            chunks.append(Document(page_content=ch, metadata=meta))
    return chunks

# ==================================
# 6) Convert 1 file → chunks
# ==================================
def convert_path_to_chunks(path: str, display_name: Optional[str] = None) -> List[Document]:
    text = convert_path_to_text(path)
    if not text:
        return []
    name = display_name or Path(path).name
    return route_and_chunk_text(text=text, source=name)

# =========================
# 7) Embeddings builder
# =========================
def build_embeddings(model: Optional[str] = None) -> GoogleGenerativeAIEmbeddings:
    if not GOOGLE_API_KEY:
        raise RuntimeError("GOOGLE_API_KEY chưa được thiết lập.")
    model = model or EMB_MODEL
    return GoogleGenerativeAIEmbeddings(
        model=model,
        google_api_key=GOOGLE_API_KEY,
    )

# ==================================
# 8) FAISS: build/load + add theo lô
# ==================================
def build_or_load_faiss(
    chunks: List[Document],
    index_dir: str = DEFAULT_INDEX_DIR,
    embeddings_model: Optional[str] = None,
) -> FAISS:
    """
    - Nếu index tồn tại: load, add tài liệu theo lô nhỏ để ổn định (giảm timeout).
    - Nếu chưa có: build mới từ toàn bộ chunks.
    """
    embeddings = build_embeddings(embeddings_model)
    os.makedirs(index_dir, exist_ok=True)

    if os.path.isdir(index_dir) and any(os.scandir(index_dir)):
        vs = FAISS.load_local(index_dir, embeddings, allow_dangerous_deserialization=True)
        if chunks:
            # add theo lô để tránh call embedding quá dài
            for i in range(0, len(chunks), MAX_ADD_BATCH):
                vs.add_documents(chunks[i:i + MAX_ADD_BATCH])
            vs.save_local(index_dir)
        return vs

    if not chunks:
        raise ValueError("Không có tài liệu để build FAISS.")
    vs = FAISS.from_documents(chunks, embedding=embeddings)
    vs.save_local(index_dir)
    return vs

# =========================
# 9) Folder loader (fast)
# =========================
def load_data_from_folder(folder_path: str = "data") -> List[Document]:
    all_chunks: List[Document] = []
    if not os.path.isdir(folder_path):
        raise FileNotFoundError(f"Folder không tồn tại: {folder_path}")

    for filename in os.listdir(folder_path):
        file_path = os.path.join(folder_path, filename)
        if not os.path.isfile(file_path):
            continue
        try:
            chunks = convert_path_to_chunks(file_path, display_name=filename)
            all_chunks.extend(chunks)
        except Exception as e:
            print(f"[WARN] Bỏ qua {filename}: {e}")
    return all_chunks

# =========================
# 10) Ingest cache theo hash
# =========================
def file_hash(path: str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for b in iter(lambda: f.read(1 << 20), b""):
            h.update(b)
    return h.hexdigest()

def _load_ingest_meta(meta_path: str) -> Dict[str, Any]:
    if not os.path.exists(meta_path):
        return {}
    try:
        with open(meta_path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return {}

def should_skip_ingest(curr_hash: str, meta_path: str) -> bool:
    meta = _load_ingest_meta(meta_path)
    return meta.get("last_hash") == curr_hash

def write_ingest_meta(meta_path: str, curr_hash: str, n_chunks: int) -> None:
    meta = {
        "last_hash": curr_hash,
        "chunks": n_chunks,
        "ts": int(time.time()),
    }
    with open(meta_path, "w", encoding="utf-8") as f:
        json.dump(meta, f, ensure_ascii=False, indent=2)
