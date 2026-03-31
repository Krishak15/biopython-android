"""
dna_classifier.py - DNA sequence classification via k-mer frequency analysis.

Converts raw DNA sequences into numerical feature vectors by computing k-mer
frequencies. These vectors can be used for species identification, viral
subtype classification, or genetic marker detection without cloud computing.
"""

import json


def _log(message):
    print(f"[dna_classifier] {message}", flush=True)


def get_kmer_frequencies(sequence: str, k_size: int = 3) -> str:
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
