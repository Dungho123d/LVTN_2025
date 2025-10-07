migrate((db) => {

  // ========== users (auth collection) ==========
  const users = new Collection({
    id: "_pb_users_auth_", // ID mặc định của hệ thống
    type: "auth",
    name: "users",
    schema: [
      { name: "name", type: "text", required: true, presentable: true },
      { name: "email", type: "email", required: true, unique: true },
      { name: "avatar", type: "file", options: { maxSelect: 1 }, required: false },
      { name: "role", type: "select", options: { values: ["student","admin"] }, required: false },
    ],
    indexes: [
      "CREATE UNIQUE INDEX users_email_unique ON users (email)"
    ],
    listRule: "@request.auth.role = 'admin'",
    viewRule: "@request.auth.id = id || @request.auth.role = 'admin'",
    createRule: "",
    updateRule: "@request.auth.id = id || @request.auth.role = 'admin'",
    deleteRule: "@request.auth.role = 'admin'",
    authRule: "",
    options: {
      allowEmailAuth: true,
      allowOAuth2Auth: true,
      allowUsernameAuth: false,
      requireEmail: true,
      minPasswordLength: 6,
    },
  });
  db.saveCollection(users);

  // ========== documents ==========
  const documents = new Collection({
    type: "base",
    name: "documents",
    schema: [
      { name: "title", type: "text" },
      { name: "file", type: "file", options: { maxSelect: 1 } },
      { name: "owner", type: "relation", options: { collectionId: users.id, maxSelect: 1 } },
      { name: "status", type: "select", options: { values: ["pending","ingested","error"] } },
      { name: "chunk_count", type: "number" },
      { name: "emb_model", type: "text" },
      { name: "ingested_at", type: "date" },
    ],
    indexes: [
      "CREATE INDEX docs_owner_idx ON documents (owner)",
      "CREATE INDEX docs_status_idx ON documents (status)"
    ],
    listRule: "owner.id = @request.auth.id",
    viewRule: "owner.id = @request.auth.id",
    createRule: "@request.auth.id != ''",
    updateRule: "owner.id = @request.auth.id",
    deleteRule: "owner.id = @request.auth.id",
  });
  db.saveCollection(documents);

  // ========== doc_chunks ==========
  const docChunks = new Collection({
    type: "base",
    name: "doc_chunks",
    schema: [
      { name: "document", type: "relation", options: { collectionId: documents.id, maxSelect: 1 } },
      { name: "chunk_id", type: "text" },
      { name: "section_title", type: "text" },
      { name: "quality_tier", type: "select", options: { values: ["low","medium","high"] } },
      { name: "source", type: "text" },
      { name: "snippet", type: "text" },
    ],
    indexes: [
      "CREATE UNIQUE INDEX chunk_id_unique ON doc_chunks (chunk_id)",
      "CREATE INDEX chunks_doc_idx ON doc_chunks (document)"
    ],
    listRule: "document.owner.id = @request.auth.id",
    viewRule: "document.owner.id = @request.auth.id",
    createRule: "document.owner.id = @request.auth.id",
    updateRule: "document.owner.id = @request.auth.id",
    deleteRule: "document.owner.id = @request.auth.id",
  });
  db.saveCollection(docChunks);

  // ========== chat_sessions ==========
  const chatSessions = new Collection({
    type: "base",
    name: "chat_sessions",
    schema: [
      { name: "user", type: "relation", options: { collectionId: users.id, maxSelect: 1 } },
      { name: "title", type: "text" },
      { name: "documents", type: "relation", options: { collectionId: documents.id, maxSelect: null } },
      { name: "created_at", type: "date" },
      { name: "last_message_at", type: "date" },
    ],
    indexes: [
      "CREATE INDEX sess_user_idx ON chat_sessions (user)"
    ],
    listRule: "user.id = @request.auth.id",
    viewRule: "user.id = @request.auth.id",
    createRule: "user.id = @request.auth.id",
    updateRule: "user.id = @request.auth.id",
    deleteRule: "user.id = @request.auth.id",
  });
  db.saveCollection(chatSessions);

  // ========== chat_messages ==========
  const chatMessages = new Collection({
    type: "base",
    name: "chat_messages",
    schema: [
      { name: "session", type: "relation", options: { collectionId: chatSessions.id, maxSelect: 1 } },
      { name: "role", type: "select", options: { values: ["user","assistant","system"] } },
      { name: "content", type: "text" },
      { name: "ctx", type: "json" },
      { name: "k", type: "number" },
      { name: "latency_ms", type: "number" },
      { name: "interaction_id", type: "text" },
      { name: "feedback", type: "number" },
      { name: "feedback_comment", type: "text" },
    ],
    indexes: [
      "CREATE UNIQUE INDEX msg_interaction_unique ON chat_messages (interaction_id)",
      "CREATE INDEX msg_session_idx ON chat_messages (session)"
    ],
    listRule: "session.user.id = @request.auth.id",
    viewRule: "session.user.id = @request.auth.id",
    createRule: "session.user.id = @request.auth.id",
    updateRule: "session.user.id = @request.auth.id",
    deleteRule: "session.user.id = @request.auth.id",
  });
  db.saveCollection(chatMessages);

  // ========== eval_cases ==========
  const evalCases = new Collection({
    type: "base",
    name: "eval_cases",
    schema: [
      { name: "query", type: "text" },
      { name: "gold_chunk_ids", type: "json" },
      { name: "documents", type: "relation", options: { collectionId: documents.id, maxSelect: null } },
      { name: "owner", type: "relation", options: { collectionId: users.id, maxSelect: 1 } },
    ],
    indexes: [
      "CREATE INDEX evalcases_owner_idx ON eval_cases (owner)"
    ],
    listRule: "owner.id = @request.auth.id",
    viewRule: "owner.id = @request.auth.id",
    createRule: "owner.id = @request.auth.id",
    updateRule: "owner.id = @request.auth.id",
    deleteRule: "owner.id = @request.auth.id",
  });
  db.saveCollection(evalCases);

  // ========== eval_runs ==========
  const evalRuns = new Collection({
    type: "base",
    name: "eval_runs",
    schema: [
      { name: "k", type: "number" },
      { name: "summary", type: "json" },
      { name: "output_csv", type: "file", options: { maxSelect: 1 } },
      { name: "run_at", type: "date" },
      { name: "owner", type: "relation", options: { collectionId: users.id, maxSelect: 1 } },
    ],
    indexes: [
      "CREATE INDEX evalruns_owner_idx ON eval_runs (owner)"
    ],
    listRule: "owner.id = @request.auth.id",
    viewRule: "owner.id = @request.auth.id",
    createRule: "owner.id = @request.auth.id",
    updateRule: "owner.id = @request.auth.id",
    deleteRule: "owner.id = @request.auth.id",
  });
  db.saveCollection(evalRuns);

}, (db) => {
  const names = ["eval_runs","eval_cases","chat_messages","chat_sessions","doc_chunks","documents","users"];
  for (const n of names) {
    const c = db.findCollectionByNameOrId(n);
    if (c) db.deleteCollection(c);
  }
});
