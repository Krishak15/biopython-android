"""
biology_health.py - Health check for biology analysis modules.

Verifies that all required dependencies (BioPython, NumPy) are
available and ready for use on the Android device.
"""


def healthcheck():
    """
    Check the health and readiness of biology analysis modules.

    Returns:
        dict with:
        - status: "READY" if all dependencies are available, "ERROR" otherwise
        - model: "biology-analysis-v1" (model identifier)
        - error: error message string (empty if no errors)
        - dependencies: dict of available modules {name: available}
    """
    print("[biology_health] healthcheck: start", flush=True)

    dependencies = {}
    all_ready = True

    # Check numpy
    try:
        import numpy

        dependencies["numpy"] = True
    except ImportError:
        dependencies["numpy"] = False
        all_ready = False

    # Check BioPython
    try:
        from Bio.SeqUtils.ProtParam import ProteinAnalysis

        dependencies["biopython"] = True
    except ImportError:
        dependencies["biopython"] = False
        all_ready = False

    status = "READY" if all_ready else "ERROR"
    error = "" if all_ready else "One or more dependencies missing"

    result = {
        "status": status,
        "model": "biology-analysis-v1",
        "error": error,
        "dependencies": dependencies,
    }

    print(f"[biology_health] healthcheck: {result}", flush=True)
    return result
