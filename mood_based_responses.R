#' This script provides helper functions and a framework for silly
#' mood based responses to questions with our fun lion avatar guy

EMBED_MODEL <- "text-embedding-3-small"  # low-cost, solid quality, still relies on OpenAI key


# --- Embedding helpers ---
embed_text <- function(texts, model = EMBED_MODEL) {
  # texts: character vector → returns matrix [length(texts) x dim]
  req <- request("https://api.openai.com/v1/embeddings") |>
    req_headers(Authorization = paste("Bearer", Sys.getenv("OPENAI_API_KEY")),
                "Content-Type" = "application/json") |>
    req_body_json(list(model = model, input = as.list(texts)))
  resp <- req_perform(req)
  dat  <- resp_body_json(resp)
  embs <- do.call(rbind, lapply(dat$data, function(x) x$embedding))
  # ensure it's a matrix
  embs <- matrix(unlist(embs), nrow = length(texts), byrow = TRUE)
  embs
}

cosine <- function(a, b) {
  # a: row vector, b: row vector
  sum(a * b) / (sqrt(sum(a * a)) * sqrt(sum(b * b)) + 1e-12)
}

# --- Mood seed phrases (tune these as you like) ---
seed <- list(
  thinking = c(
    "Let me think this through.",
    "I'm considering the options.",
    "Hmm, let's reason step by step."
  ),
  happy = c(
    "Nice, that worked!",
    "Great job, this is going well.",
    "I’m happy with this result."
  ),
  cheering = c(
    "Woohoo! Amazing news!",
    "Fantastic! High five!",
    "Yes! We nailed it!"
  ),
  frustrated = c(
    "This is annoying and not working.",
    "I'm stuck and frustrated.",
    "Ugh, this keeps failing."
  )
)

# --- Build centroids once at startup (cacheable) ---
build_centroids <- function(seed_list) {
  labs <- names(seed_list)
  all_texts <- unlist(seed_list, use.names = FALSE)
  E <- embed_text(all_texts)            # embeddings for all seeds
  # split rows back per label and average
  idx <- rep(labs, times = lengths(seed_list))
  centroids <- lapply(split.data.frame(E, idx), function(m) {
    colMeans(as.matrix(m))
  })
  centroids
}

centroids <- build_centroids(seed)

detect_mood_embed <- function(message, centroids) {
  e <- embed_text(message)              # 1 x dim
  sims <- vapply(centroids, function(c) cosine(e[1,], c), numeric(1))
  names(which.max(sims))
}

mood_img <- function(mood) {
  switch(mood,
         "thinking"    = "thinking.png",
         "happy"       = "happy.png",
         "cheering"    = "cheering.png",
         "frustrated"  = "frustrated.png",
         "neutral.png"
  )
}