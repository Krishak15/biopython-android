"""
protein_analyzer.py - Offline protein sequence analysis using BioPython.

Analyzes amino acid sequences to compute biochemical properties useful for
field researchers and bioinformaticians working offline without cloud access.
"""

import threading
import json

_protein_lock = threading.Lock()
_ProteinAnalysis = None
_status = "IDLE"
_error_message = None


def _log(message):
    print(f"[protein_analyzer] {message}", flush=True)


def _ensure_biopython_loaded():
    """Lazy-load BioPython ProteinAnalysis on first use."""
    global _ProteinAnalysis, _status, _error_message

    with _protein_lock:
        if _ProteinAnalysis is not None:
            return

        _status = "LOADING"
        _error_message = None
        _log("Loading BioPython ProteinAnalysis module")

        try:
            from Bio.SeqUtils.ProtParam import ProteinAnalysis

            _ProteinAnalysis = ProteinAnalysis
            _status = "READY"
            _log("BioPython ProteinAnalysis ready")
        except Exception as exc:
            _ProteinAnalysis = None
            _status = "ERROR"
            _error_message = f"Failed to load ProteinAnalysis: {exc}"
            _log(_error_message)
            raise RuntimeError(_error_message) from exc


def analyze_protein(sequence: str, limit: int = 100000) -> str:
    """
    Analyze a protein sequence to extract biochemical properties.

    Args:
        sequence: Amino acid sequence as a string (e.g., "MKTAYIAKQRQISFVKSHFSRQLEERLGLIEVQAPILSRVGDGTQDNLSGAEKAVQVKVKALPDAQFEVVHSLAKWKRQTLGQHDFSAGEGLYTHMKALRPDEDRLSPLHSVYVDQWDWERVMGDGERQFSTLKSTVEAIWAGIKATEAAVSEEFGLAPFLPDQIHFVHSQELLSRYPDLDAKGRERAIAKDLGAVFLVGIGGKLSDGHRHDVRAPDYDDWSTPSELGHAGLNGDILVWNPVLEDAFELSSMGIRVDADTLKHQLALTGDEDRLELEWHQALLRGEMPQTIGGGIGQSRLTMLLLQLPHIGQVQAGVWPAAVRESVPSLL"):
        Returns a JSON string with analysis results or error.

    Returns:
        JSON string containing:
        - status: "success" or "error"
        - molecular_weight: float (Da) if success
        - isoelectric_point: float (pH) if success
        - aromaticity: float if success
        - instability_index: float if success
        - gravy: float if success
        - secondary_structure_fraction: list of 3 floats if success
        - molar_extinction_coefficient: list of 2 ints if success
        - amino_acid_counts: dict of {amino_acid: count} if success
        - message: error message if status is "error"

    Example:
        >>> result = analyze_protein("MKTAYIAK")
        >>> r = json.loads(result)
        >>> print(r["molecular_weight"])
        1017.11
    """
    try:
        _ensure_biopython_loaded()

        with _protein_lock:
            original_length = len(sequence)
            if original_length > limit:
                _log(f"Truncating sequence from {original_length} to {limit}")
                sequence = sequence[:limit]
                
            # Clean sequence by removing all whitespace and newlines
            clean_sequence = "".join(sequence.split())
            # Initialize the BioPython analyzer
            analyzed_seq = _ProteinAnalysis(clean_sequence.upper())

            # Calculate biochemical properties
            mol_weight = analyzed_seq.molecular_weight()
            iso_point = analyzed_seq.isoelectric_point()
            aromaticity = analyzed_seq.aromaticity()
            instability = analyzed_seq.instability_index()
            gravy = analyzed_seq.gravy()
            sec_struct = analyzed_seq.secondary_structure_fraction()
            molar_ext = analyzed_seq.molar_extinction_coefficient()
            amino_counts = analyzed_seq.count_amino_acids()

            return json.dumps(
                {
                    "status": "success",
                    "molecular_weight": round(mol_weight, 2),
                    "isoelectric_point": round(iso_point, 2),
                    "aromaticity": round(aromaticity, 4),
                    "instability_index": round(instability, 2),
                    "gravy": round(gravy, 4),
                    "secondary_structure_fraction": [round(x, 4) for x in sec_struct],
                    "molar_extinction_coefficient": list(molar_ext),
                    "amino_acid_counts": amino_counts,
                    "is_truncated": original_length > limit,
                    "original_length": original_length,
                    "limit_used": limit,
                }
            )
    except Exception as e:
        _log(f"analyze_protein error: {e}")
        return json.dumps(
            {
                "status": "error",
                "message": str(e),
            }
        )
