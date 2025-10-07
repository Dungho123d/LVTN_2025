import os
import re
import uuid
from typing import Optional, List, Tuple, Dict, Any
from pathlib import Path
from docling.document_converter import DocumentConverter

from dotenv import load_dotenv
load_dotenv()

from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_google_genai import GoogleGenerativeAIEmbeddings
from langchain_community.vectorstores import FAISS
from langchain_core.documents import Document

GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY", "")
DEFAULT_INDEX_DIR = os.getenv("FAISS_INDEX_DIR", "faiss_index")
EMB_MODEL = os.getenv("GEMINI_EMB_MODEL", "models/gemini-embedding-001")

__all__ = [
    "load_data_from_folder",
    "build_embeddings",
    "build_or_load_faiss",
    "DEFAULT_INDEX_DIR",
    "route_and_chunk_text",
    "apply_metadata_quality_gate",
]

# =========================
# Docling → Markdown helper
# =========================
def _docling_markdown_from_path(path: str) -> str:
    conv = DocumentConverter()
    res = conv.convert(path)
    return res.document.export_to_markdown()

# =========================
# 1) Quality scoring & tier
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
# 2) Chunking strategies
# =========================
_hdr_re = re.compile(
    r"^(#{1,6}\s.+|[A-Z][A-Z0-9\s\-,:()]{6,}$|\d+(\.\d+)*\s+.+)$",
    re.MULTILINE,
)

def _split_by_headers(text: str) -> List[Tuple[str, str]]:
    sections = []
    indices = [(m.start(), m.group(0).strip()) for m in _hdr_re.finditer(text)]
    if not indices:
        return [("Body", text)]
    indices.append((len(text), None))
    for i in range(len(indices) - 1):
        start, title = indices[i]
        end, _ = indices[i + 1]
        line_end = text.find("\n", start)
        content_start = line_end + 1 if line_end != -1 else start
        body = text[content_start:end].strip()
        sections.append((title or f"Section-{i+1}", body))
    return [(t, b) for t, b in sections if b]

def _paragraph_chunks(text: str, chunk_size_chars=1200, overlap=150) -> List[str]:
    paragraphs = [p.strip() for p in re.split(r"\n\s*\n+", text) if p.strip()]
    joined = "\n\n".join(paragraphs) if paragraphs else text
    splitter = RecursiveCharacterTextSplitter(
        chunk_size=chunk_size_chars,
        chunk_overlap=overlap,
    )
    docs = splitter.split_documents([Document(page_content=joined)])
    return [d.page_content for d in docs]

def _fixed_chunks(text: str, chunk_size_chars=700, overlap=100) -> List[str]:
    splitter = RecursiveCharacterTextSplitter(
        chunk_size=chunk_size_chars,
        chunk_overlap=overlap,
    )
    docs = splitter.split_documents([Document(page_content=text)])
    return [d.page_content for d in docs]

def _hierarchical_chunks(text: str) -> List[Tuple[str, str]]:
    out: List[Tuple[str, str]] = []
    for title, body in _split_by_headers(text):
        for ch in _paragraph_chunks(body, chunk_size_chars=900, overlap=120):
            out.append((title, ch))
    if not out:
        for ch in _paragraph_chunks(text, chunk_size_chars=900, overlap=120):
            out.append(("Body", ch))
    return out

# =========================
# 3) Metadata enrichment
# =========================
def _approx_token_count(s: str) -> int:
    # xấp xỉ theo chars/4 (đủ cho thống kê nhẹ)
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
# 4) Public: route & chunk a raw text
# ==================================
def route_and_chunk_text(text: str, source: str) -> List[Document]:
    """
    Tạo List[Document] kèm metadata phong phú: source, source_ext, quality_tier,
    chunk_level, section_title, chunk_id, content_length, line_count, approx_tokens.
    """
    text = (text or "").strip()
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
        for ch in _paragraph_chunks(text, chunk_size_chars=1000, overlap=150):
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
        for ch in _fixed_chunks(text, chunk_size_chars=600, overlap=80):
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
# 5) Folder loader using the pipeline
# ==================================
def load_data_from_folder(folder_path: str = "data") -> List[Document]:
    all_chunks: List[Document] = []

    if not os.path.isdir(folder_path):
        raise FileNotFoundError(f"Folder không tồn tại: {folder_path}")

    SUPPORTED_DOCLING = {".pdf", ".docx", ".pptx", ".html", ".htm", ".png", ".jpg", ".jpeg", ".tif", ".tiff"}
    SUPPORTED_TEXT    = {".txt", ".md"}

    for filename in os.listdir(folder_path):
        file_path = os.path.join(folder_path, filename)
        if not os.path.isfile(file_path):
            continue
        try:
            ext = Path(filename).suffix.lower()
            text = ""

            if ext in SUPPORTED_DOCLING:
                md = _docling_markdown_from_path(file_path)
                text = (md or "").strip()

            elif ext in SUPPORTED_TEXT:
                with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
                    text = f.read().strip()
            else:
                continue

            if not text:
                continue

            chunks = route_and_chunk_text(text=text, source=filename)
            all_chunks.extend(chunks)

        except Exception as e:
            print(f"[WARN] Bỏ qua {filename}: {e}")

    return all_chunks

# =========================
# 6) Embeddings + FAISS
# =========================
def build_embeddings(model: Optional[str] = None) -> GoogleGenerativeAIEmbeddings:
    if not GOOGLE_API_KEY:
        raise RuntimeError("GOOGLE_API_KEY chưa được thiết lập.")
    model = model or EMB_MODEL
    return GoogleGenerativeAIEmbeddings(
        model=model,
        google_api_key=GOOGLE_API_KEY,
    )

def build_or_load_faiss(
    chunks: List[Document],
    index_dir: str = DEFAULT_INDEX_DIR,
    embeddings_model: Optional[str] = None,
) -> FAISS:
    embeddings = build_embeddings(embeddings_model)

    if os.path.isdir(index_dir) and any(os.scandir(index_dir)):
        vs = FAISS.load_local(index_dir, embeddings, allow_dangerous_deserialization=True)
        if chunks:
            vs.add_documents(chunks)
            vs.save_local(index_dir)
        return vs

    if not chunks:
        raise ValueError("Không có tài liệu để build FAISS.")
    os.makedirs(index_dir, exist_ok=True)
    vs = FAISS.from_documents(chunks, embedding=embeddings)
    vs.save_local(index_dir)
    return vs

# =========================
# 7) Quality gate helper
# =========================
_TIER_ORDER = {"low": 0, "medium": 1, "high": 2}

def apply_metadata_quality_gate(docs: List[Document], min_tier: str = "medium", include_low: bool = False) -> List[Document]:
    """
    Lọc danh sách Document theo quality tier tối thiểu.
    Nếu include_low=True => luôn cho phép low-tier nhưng sẽ đẩy xuống cuối.
    """
    if not docs:
        return []
    min_rank = _TIER_ORDER.get(min_tier, 1)
    good, low = [], []
    for d in docs:
        tier = d.metadata.get("quality_tier", "medium")
        if _TIER_ORDER.get(tier, 1) >= min_rank:
            good.append(d)
        else:
            low.append(d)
    return good + (low if include_low else [])
