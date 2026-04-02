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

# NCBI requires an email for Entrez API usage. We no longer provide a fallback;
# the bridge must pass a valid user identity to enable search/fetch.
Entrez.email = None

_entrez_lock = threading.Lock()


def _log(msg):
    print(f"[ncbi_service] {msg}", flush=True)


def search_ncbi(query, db="protein", retmax=10, email=None, api_key=None):
    """
    Search NCBI database using Entrez.esearch + esummary.
    Returns JSON string with search results (id, title, db).
    """
    try:
        _log(f"Searching db={db} for query='{query}' email={email}")
        with _entrez_lock:
            if email:
                Entrez.email = email
            if api_key:
                Entrez.api_key = api_key

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


def fetch_and_analyze(uid, db="protein", limit=100000, email=None, api_key=None):
    """
    Fetch a sequence from NCBI by UID and analyze it.

    Uses Entrez.efetch with rettype="fasta" to get the raw sequence
    as plain text — no Bio.SeqIO needed.

    For proteins: analyzes with Bio.SeqUtils.ProtParam (pure Python).
    For DNA/RNA: computes GC content and length manually.
    """
    try:
        _log(f"Fetching record id={uid} from db={db} email={email}")
        with _entrez_lock:
            if email:
                Entrez.email = email
            if api_key:
                Entrez.api_key = api_key

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
        
        analysis_json = analyze_sequence_only(sequence, db, limit)
        analysis_dict = json.loads(analysis_json)
        
        if analysis_dict.get("status") == "error":
            return json.dumps({
                "status": "error",
                "message": analysis_dict.get("message", "Analysis failed"),
            })

        return json.dumps({
            "status": "success",
            "id": uid,
            "description": description,
            "sequence": sequence,
            "analysis": analysis_dict.get("analysis", {}),
        })

    except Exception as e:
        _log(f"fetch_and_analyze error: {e}")
        return json.dumps({"status": "error", "message": str(e)})


def analyze_sequence_only(sequence: str, db: str = "protein", limit=100000) -> str:
    """
    Analyze a sequence (protein or dna) without fetching from NCBI.
    Returns JSON with analysis results.
    """
    try:
        is_protein = (db == "protein")
        original_length = len(sequence)
        is_truncated = original_length > limit
        
        if is_truncated:
            _log(f"Truncating sequence from {original_length} to {limit}")
            sequence = sequence[:limit]
            
        analysis = {
            "is_truncated": is_truncated,
            "original_length": original_length,
            "limit_used": limit,
        }

        if is_protein:
            from Bio.SeqUtils.ProtParam import ProteinAnalysis

            clean_seq = sequence.upper().replace("X", "").replace("*", "")
            if not clean_seq:
                return json.dumps({
                    "status": "error",
                    "message": "Sequence is empty after cleaning",
                })

            analyzer = ProteinAnalysis(clean_seq)
            sec_struct = analyzer.secondary_structure_fraction()
            molar_ext = analyzer.molar_extinction_coefficient()
            amino_counts = analyzer.count_amino_acids()
            
            analysis.update({
                "type": "protein",
                "molecular_weight": round(analyzer.molecular_weight(), 2),
                "isoelectric_point": round(analyzer.isoelectric_point(), 2),
                "gravy": round(analyzer.gravy(), 4),
                "aromaticity": round(analyzer.aromaticity(), 4),
                "instability_index": round(analyzer.instability_index(), 2),
                "length": len(clean_seq),
                "secondary_structure_fraction": [round(x, 4) for x in sec_struct],
                "molar_extinction_coefficient": list(molar_ext),
                "amino_acid_counts": amino_counts,
                "is_truncated": is_truncated,
                "original_length": original_length,
                "limit_used": limit,
            })
        else:
            import dna_classifier
            dna_json = dna_classifier.get_kmer_frequencies(sequence, 3, limit=limit)
            dna_dict = json.loads(dna_json)
            
            if dna_dict.get("status") == "error":
                return json.dumps({"status": "error", "message": dna_dict.get("message", "DNA analysis failed")})

            analysis.update({
                "type": "nucleotide",
                "kmer_size": dna_dict.get("kmer_size"),
                "sequence_length": dna_dict.get("sequence_length"),
                "frequencies": dna_dict.get("frequencies"),
                "total_kmers": dna_dict.get("total_kmers"),
                "gc_content": dna_dict.get("gc_content"),
                "molecular_weight": dna_dict.get("molecular_weight"),
                "melting_temp": dna_dict.get("melting_temp"),
                "reverse_complement": dna_dict.get("reverse_complement"),
            })

        return json.dumps({
            "status": "success",
            "analysis": analysis,
        })
    except Exception as e:
        _log(f"analyze_sequence_only error: {e}")
        return json.dumps({"status": "error", "message": str(e)})
