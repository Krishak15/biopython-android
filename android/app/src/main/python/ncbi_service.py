"""
ncbi_service.py - Query NCBI Entrez and analyze sequences.

Uses ONLY Bio.Entrez (pure Python, no C-extensions) to search and fetch
data from NCBI databases. Avoids Bio.SeqIO/Bio.AlignIO/Bio.Align entirely
to prevent ImportError on Android (missing compiled _aligncore).

Sequence analysis is done via Bio.SeqUtils.ProtParam (also pure Python).
"""

import json
import threading

from Bio import Entrez

# NCBI requires an email for Entrez API usage
Entrez.email = "your_email@example.com"

_entrez_lock = threading.Lock()


def _log(msg):
    print(f"[ncbi_service] {msg}", flush=True)


def search_ncbi(query, db="protein", retmax=10):
    """
    Search NCBI database using Entrez.esearch + esummary.
    Returns JSON string with search results (id, title, db).
    """
    try:
        _log(f"Searching db={db} for query='{query}'")
        with _entrez_lock:
            # Step 1: Search for IDs matching the query
            handle = Entrez.esearch(db=db, term=query, retmax=retmax)
            record = Entrez.read(handle)
            handle.close()

            ids = record.get("IdList", [])
            if not ids:
                _log("No results found")
                return json.dumps({"status": "success", "results": []})

            _log(f"Found {len(ids)} IDs: {ids}")

            # Step 2: Fetch summaries for these IDs
            handle = Entrez.esummary(db=db, id=",".join(ids))
            summaries = Entrez.read(handle)
            handle.close()

            results = []
            for summary in summaries:
                title = (
                    summary.get("Title")
                    or summary.get("Caption")
                    or "No Title"
                )
                results.append({
                    "id": str(summary["Id"]),
                    "title": str(title),
                    "db": db,
                })

            _log(f"Returning {len(results)} results")
            return json.dumps({"status": "success", "results": results})

    except Exception as e:
        _log(f"search_ncbi error: {e}")
        return json.dumps({"status": "error", "message": str(e)})


def fetch_and_analyze(uid, db="protein"):
    """
    Fetch a sequence from NCBI by UID and analyze it.

    Uses Entrez.efetch with rettype="fasta" to get the raw sequence
    as plain text — no Bio.SeqIO needed.

    For proteins: analyzes with Bio.SeqUtils.ProtParam (pure Python).
    For DNA/RNA: computes GC content and length manually.
    """
    try:
        _log(f"Fetching record id={uid} from db={db}")
        with _entrez_lock:
            # Fetch as FASTA plain text — no SeqIO parser needed
            handle = Entrez.efetch(
                db=db, id=uid, rettype="fasta", retmode="text"
            )
            fasta_text = handle.read()
            handle.close()

        # Parse FASTA manually (trivial: skip first line, join the rest)
        lines = fasta_text.strip().split("\n")
        if not lines or not lines[0].startswith(">"):
            return json.dumps({
                "status": "error",
                "message": "Invalid FASTA response from NCBI",
            })

        description = lines[0][1:].strip()  # Remove leading '>'
        sequence = "".join(line.strip() for line in lines[1:])

        _log(f"Got sequence: {description[:60]}... len={len(sequence)}")

        is_protein = (db == "protein")
        analysis = {}

        if is_protein:
            # ProtParam is pure Python — no C-extensions
            from Bio.SeqUtils.ProtParam import ProteinAnalysis

            clean_seq = sequence.upper().replace("X", "").replace("*", "")
            if not clean_seq:
                return json.dumps({
                    "status": "error",
                    "message": "Sequence is empty after cleaning",
                })

            analyzer = ProteinAnalysis(clean_seq)
            analysis = {
                "type": "protein",
                "molecular_weight": round(analyzer.molecular_weight(), 2),
                "isoelectric_point": round(analyzer.isoelectric_point(), 2),
                "gravy": round(analyzer.gravy(), 4),
                "aromaticity": round(analyzer.aromaticity(), 4),
                "instability_index": round(analyzer.instability_index(), 2),
                "length": len(clean_seq),
            }
        else:
            # Manual GC content calculation — no Bio.SeqUtils.gc_fraction
            upper_seq = sequence.upper()
            gc_count = upper_seq.count("G") + upper_seq.count("C")
            total = len(upper_seq)
            gc_content = round((gc_count / total) * 100, 2) if total else 0.0

            analysis = {
                "type": "dna",
                "gc_content": gc_content,
                "length": total,
                "at_content": round(100.0 - gc_content, 2),
            }

        return json.dumps({
            "status": "success",
            "id": uid,
            "description": description,
            "sequence": sequence,
            "analysis": analysis,
        })

    except Exception as e:
        _log(f"fetch_and_analyze error: {e}")
        return json.dumps({"status": "error", "message": str(e)})
