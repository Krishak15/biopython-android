"""
dna_classifier.py - DNA sequence classification via k-mer frequency analysis.

Converts raw DNA sequences into numerical feature vectors by computing k-mer
frequencies. These vectors can be used for species identification, viral
subtype classification, or genetic marker detection without cloud computing.
"""

import json
from Bio.SeqUtils import gc_fraction, molecular_weight, MeltingTemp as mt
from Bio.Seq import Seq


def _log(message):
    print(f"[dna_classifier] {message}", flush=True)


def get_kmer_frequencies(sequence: str, k_size: int = 3, limit: int = 100000) -> str:
    """
    Extract k-mer frequencies from a DNA sequence for ML classification.

    A k-mer is a substring of length k. For example, "AGAT" contains
    three 2-mers: "AG", "GA", "AT". These frequencies form the basis of
    DNA feature vectors used in species identification and viral subtyping.

    Args:
        sequence: DNA sequence string (ATCG only recommended).
        k_size: Size of k-mers to extract (default 3). Common values: 2-6.

    Returns:
        JSON string containing:
        - status: "success" or "error"
        - kmer_size: the k value used (if success)
        - frequencies: dict of {kmer: count} (if success)
        - message: error message (if status is "error")
        - gc_content: GC percentage
        - molecular_weight: daltons
        - melting_temp: NN melting temp estimate
        - reverse_complement: matching reverse strand

    Example:
        >>> result = get_kmer_frequencies("AGAT", k_size=2)
        >>> r = json.loads(result)
        >>> print(r["frequencies"])
        {"AG": 1, "GA": 1, "AT": 1}
    """
    try:
        # Validate k-mer size
        if not isinstance(k_size, int) or k_size < 1:
            raise ValueError(f"k_size must be a positive integer, got {k_size}")

        original_length = len(sequence)
        if original_length > limit:
            _log(f"Truncating sequence from {original_length} to {limit}")
            sequence = sequence[:limit]
            
        # Clean sequence by removing all whitespace and newlines
        sequence = "".join(sequence.split()).upper()
        seq_length = len(sequence)

        if seq_length < k_size:
            raise ValueError(
                f"Sequence length ({seq_length}) is less than k_size ({k_size})"
            )

        # Count k-mers
        kmer_counts = {}
        for i in range(seq_length - k_size + 1):
            kmer = sequence[i : i + k_size]
            # Only count k-mers with valid ATCG characters
            if all(c in "ATCG" for c in kmer):
                kmer_counts[kmer] = kmer_counts.get(kmer, 0) + 1

        total_kmers = sum(kmer_counts.values())
        if total_kmers == 0:
            raise ValueError(
                "No valid k-mers found (sequence may contain invalid characters)"
            )

        gc_content = gc_fraction(sequence) * 100.0
        try:
            mol_weight = molecular_weight(sequence, seq_type="DNA")
        except:
            mol_weight = 0.0
            
        try:
            tm = mt.Tm_NN(sequence)
        except:
            tm = 0.0
            
        bio_seq = Seq(sequence)
        rev_comp = str(bio_seq.reverse_complement())

        _log(
            f"get_kmer_frequencies: k={k_size} seq_len={seq_length} unique_kmers={len(kmer_counts)}"
        )

        return json.dumps(
            {
                "status": "success",
                "kmer_size": k_size,
                "sequence_length": seq_length,
                "frequencies": kmer_counts,
                "total_kmers": total_kmers,
                "gc_content": gc_content,
                "molecular_weight": mol_weight,
                "melting_temp": tm,
                "reverse_complement": rev_comp,
                "is_truncated": seq_length < original_length,
                "original_length": original_length,
                "limit_used": limit,
            }
        )
    except Exception as e:
        _log(f"get_kmer_frequencies error: {e}")
        return json.dumps(
            {
                "status": "error",
                "message": str(e),
            }
        )
