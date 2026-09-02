import Foundation

/// JSON payloads shaped exactly like the metabook-py responses.
enum Fixtures {
    static let structure = """
        {
          "book": {
            "gutenberg_id": 1342,
            "title": "Pride and Prejudice",
            "authors": [{"name": "Austen, Jane", "birth_year": 1775, "death_year": 1817}],
            "language": "en",
            "subjects": ["Courtship -- Fiction"]
          },
          "structure": {
            "schema": "sectioned_book",
            "schema_confidence": "medium",
            "summary": {
              "total_top_level_nodes": 1,
              "total_mid_level_nodes": 2,
              "total_paragraphs": 3,
              "total_sentences": 12,
              "total_words": 240,
              "avg_paragraphs_per_chapter": 1.5,
              "avg_sentences_per_paragraph": 4.0,
              "avg_words_per_sentence": 20.0
            },
            "nodes": [
              {
                "level": "volume",
                "index": 0,
                "label": "Volume I",
                "child_count": 2,
                "total_paragraphs": 3,
                "total_words": 240,
                "children": [
                  {
                    "level": "chapter",
                    "index": 0,
                    "label": "Chapter I",
                    "paragraph_count": 1,
                    "avg_sentences_per_paragraph": 4.0,
                    "avg_words_per_sentence": 20.0,
                    "total_words": 80,
                    "total_sentences": 4,
                    "paragraphs": [
                      {
                        "index": 0,
                        "sentence_count": 4,
                        "word_count": 80,
                        "avg_words_per_sentence": 20.0,
                        "sentences": [
                          {"index": 0, "clause_count": 2, "word_count": 20,
                           "clauses": [{"index": 0, "word_count": 10, "words": [{"index": 0}]}]}
                        ]
                      }
                    ]
                  },
                  {
                    "level": "chapter",
                    "index": 1,
                    "label": "Chapter II",
                    "paragraph_count": 2,
                    "avg_sentences_per_paragraph": 4.0,
                    "avg_words_per_sentence": 20.0,
                    "total_words": 160,
                    "total_sentences": 8,
                    "paragraphs": null
                  }
                ]
              }
            ]
          },
          "meta": {
            "fetched_at": "2026-09-01T02:44:30.123456Z",
            "cached": false,
            "processing_time_ms": 812
          }
        }
        """

    static let flatStructure = """
        {
          "book": {"gutenberg_id": 7, "title": "Flat", "authors": [], "language": "en", "subjects": []},
          "structure": {
            "schema": "flat",
            "schema_confidence": "low",
            "summary": {
              "total_top_level_nodes": 2,
              "total_mid_level_nodes": null,
              "total_paragraphs": 2,
              "total_sentences": 2,
              "total_words": 10,
              "avg_paragraphs_per_chapter": 2.0,
              "avg_sentences_per_paragraph": 1.0,
              "avg_words_per_sentence": 5.0
            },
            "nodes": [
              {"index": 0, "sentence_count": 1, "word_count": 5, "avg_words_per_sentence": 5.0},
              {"index": 1, "sentence_count": 1, "word_count": 5, "avg_words_per_sentence": 5.0}
            ]
          },
          "meta": {"fetched_at": "2026-09-01T02:44:30Z", "cached": true, "processing_time_ms": 3}
        }
        """

    static let disambiguation = """
        {
          "status": 300,
          "message": "Multiple books matched. Retry with a specific gutenberg_id.",
          "matches": [
            {"gutenberg_id": 1342, "title": "Pride and Prejudice", "authors": ["Austen, Jane"], "language": "en"},
            {"gutenberg_id": 42671, "title": "Pride and Prejudice", "authors": ["Austen, Jane"], "language": "en"}
          ]
        }
        """

    static let schemas = """
        [
          {"name": "canonical_scripture", "description": "Scripture", "hierarchy": ["book", "chapter", "verse"]},
          {"name": "sectioned_book", "description": "Sectioned", "hierarchy": ["part", "chapter", "paragraph"]},
          {"name": "standard_book", "description": "Standard", "hierarchy": ["chapter", "paragraph"]},
          {"name": "essay_or_story_collection", "description": "Essays", "hierarchy": ["essay", "paragraph"]},
          {"name": "flat", "description": "Flat", "hierarchy": ["paragraph"]}
        ]
        """

    static let upload = """
        {
          "book": {
            "source": "upload",
            "title": "My Book",
            "authors": [{"name": "Someone"}],
            "language": "en",
            "subjects": [],
            "isbn": "9780000000000"
          },
          "blob": {"url": "https://blob.vercel-storage.com/books/my-book.epub", "pathname": "books/my-book.epub", "size_bytes": 4096},
          "structure": {
            "schema": "standard_book",
            "schema_confidence": "high",
            "summary": {
              "total_top_level_nodes": 1,
              "total_paragraphs": 1,
              "total_sentences": 1,
              "total_words": 5,
              "avg_paragraphs_per_chapter": 1.0,
              "avg_sentences_per_paragraph": 1.0,
              "avg_words_per_sentence": 5.0
            },
            "nodes": [
              {"level": "chapter", "index": 0, "label": "Chapter 1", "paragraph_count": 1,
               "avg_sentences_per_paragraph": 1.0, "avg_words_per_sentence": 5.0,
               "total_words": 5, "total_sentences": 1, "paragraphs": null}
            ]
          },
          "meta": {"uploaded_at": "2026-09-01T02:44:30.000001Z", "spine_document_count": 3, "processing_time_ms": 50}
        }
        """

    static let health = """
        {"status": "ok", "version": "1.0.0", "cache_entries": 4}
        """
}
