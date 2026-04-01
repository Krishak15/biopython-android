package com.akdev.biopy

import android.content.ContentValues
import android.os.Build
import android.provider.MediaStore
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import com.chaquo.python.Python
import com.chaquo.python.PyException
import com.chaquo.python.android.AndroidPlatform
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONObject

class MainActivity : FlutterActivity() {

    companion object {
        private const val TAG = "PythonBridge"
        private const val CHANNEL = "com.akdev.app/python_bridge"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        if (!Python.isStarted()) {
            Python.start(AndroidPlatform(context))
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                Log.d(TAG, "Method call: ${call.method}")
                when (call.method) {
                    "healthBiology" -> handleHealthBiology(result)
                    "proteinAnalyze" -> handleProteinAnalyze(call, result)
                    "dnaClassify" -> handleDnaClassify(call, result)
                    "ncbiSearch" -> handleNcbiSearch(call, result)
                    "ncbiFetch" -> handleNcbiFetch(call, result)
                    "ncbiAnalyzeLocal" -> handleNcbiAnalyzeLocal(call, result)
                    "getTelemetry" -> handleTelemetry(result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun handleHealthBiology(result: MethodChannel.Result) {
        CoroutineScope(Dispatchers.Default).launch {
            try {
                Log.d(TAG, "healthBiology: start")
                val module = Python.getInstance().getModule("biology_health")
                val pyResult = module.callAttr("healthcheck")
                val status = pyResult["status"]?.toString() ?: "UNKNOWN"
                val model = pyResult["model"]?.toString() ?: "biology-analysis-v1"
                val error = pyResult["error"]?.toString() ?: ""
                Log.d(TAG, "healthBiology: status=$status model=$model error=$error")
                withContext(Dispatchers.Main) {
                    val map = mapOf(
                        "status" to status,
                        "model" to model,
                        "error" to error,
                    )
                    result.success(JSONObject(map).toString())
                }
            } catch (e: PyException) {
                Log.e(TAG, "healthBiology Python error", e)
                withContext(Dispatchers.Main) {
                    result.error("PYTHON_ERROR", e.message, e.stackTraceToString())
                }
            } catch (e: Exception) {
                Log.e(TAG, "healthBiology native error", e)
                withContext(Dispatchers.Main) {
                    result.error("NATIVE_ERROR", e.message, e.stackTraceToString())
                }
            }
        }
    }

    private fun handleTelemetry(result: MethodChannel.Result) {
        val runtime = Runtime.getRuntime()
        val usedMem = (runtime.totalMemory() - runtime.freeMemory()) / 1024 / 1024
        val maxMem = runtime.maxMemory() / 1024 / 1024
        
        val map = mapOf(
            "usedMemory" to usedMem,
            "maxMemory" to maxMem,
            "timestamp" to System.currentTimeMillis()
        )
        result.success(JSONObject(map).toString())
    }

    private fun handleProteinAnalyze(call: MethodCall, result: MethodChannel.Result) {
        val sequence = call.argument<String>("sequence")
        if (sequence == null || sequence.isEmpty()) {
            result.error("INVALID_ARGUMENT", "sequence is required", null)
            return
        }

        CoroutineScope(Dispatchers.Default).launch {
            try {
                val limit = (call.argument<Any>("limit") as? Number)?.toInt() ?: 100000
                Log.d(TAG, "proteinAnalyze: start sequence_length=${sequence.length} limit=$limit")
                val module = Python.getInstance().getModule("protein_analyzer")
                val jsonResult = module.callAttr("analyze_protein", sequence, limit).toString()
                Log.d(TAG, "proteinAnalyze: success")
                withContext(Dispatchers.Main) {
                    result.success(jsonResult)
                }
            } catch (e: PyException) {
                Log.e(TAG, "proteinAnalyze Python error", e)
                withContext(Dispatchers.Main) {
                    result.error("PYTHON_ERROR", e.message, e.stackTraceToString())
                }
            } catch (e: Exception) {
                Log.e(TAG, "proteinAnalyze native error", e)
                withContext(Dispatchers.Main) {
                    result.error("NATIVE_ERROR", e.message, e.stackTraceToString())
                }
            }
        }
    }

    private fun handleDnaClassify(call: MethodCall, result: MethodChannel.Result) {
        val sequence = call.argument<String>("sequence")
        if (sequence == null || sequence.isEmpty()) {
            result.error("INVALID_ARGUMENT", "sequence is required", null)
            return
        }
        val kmerSize = call.argument<Int>("kmerSize") ?: 3

        CoroutineScope(Dispatchers.Default).launch {
            try {
                val limit = (call.argument<Any>("limit") as? Number)?.toInt() ?: 100000
                Log.d(TAG, "dnaClassify: start sequence_length=${sequence.length} kmerSize=$kmerSize limit=$limit")
                val module = Python.getInstance().getModule("dna_classifier")
                val jsonResult = module.callAttr("get_kmer_frequencies", sequence, kmerSize, limit).toString()
                Log.d(TAG, "dnaClassify: success")
                withContext(Dispatchers.Main) {
                    result.success(jsonResult)
                }
            } catch (e: PyException) {
                Log.e(TAG, "dnaClassify Python error", e)
                withContext(Dispatchers.Main) {
                    result.error("PYTHON_ERROR", e.message, e.stackTraceToString())
                }
            } catch (e: Exception) {
                Log.e(TAG, "dnaClassify native error", e)
                withContext(Dispatchers.Main) {
                    result.error("NATIVE_ERROR", e.message, e.stackTraceToString())
                }
            }
        }
    }

    private fun handleNcbiSearch(call: MethodCall, result: MethodChannel.Result) {
        val query = call.argument<String>("query") ?: ""
        val db = call.argument<String>("db") ?: "protein"
        val retmax = call.argument<Int>("retmax") ?: 10
        Log.d(TAG, "handleNcbiSearch: start query=$query db=$db retmax=$retmax")
        CoroutineScope(Dispatchers.Default).launch {
            try {
                val module = Python.getInstance().getModule("ncbi_service")
                val jsonResult = module.callAttr("search_ncbi", query, db, retmax).toString()
                Log.d(TAG, "handleNcbiSearch: success")
                withContext(Dispatchers.Main) { result.success(jsonResult) }
            } catch (e: Exception) {
                Log.e(TAG, "handleNcbiSearch error", e)
                withContext(Dispatchers.Main) { result.error("NCBI_SEARCH_ERROR", e.message, null) }
            }
        }
    }

    private fun handleNcbiFetch(call: MethodCall, result: MethodChannel.Result) {
        val uid = call.argument<String>("id") ?: ""
        val db = call.argument<String>("db") ?: "protein"
        val limit = (call.argument<Any>("limit") as? Number)?.toInt() ?: 100000
        Log.d(TAG, "handleNcbiFetch: start id=$uid db=$db limit=$limit")
        CoroutineScope(Dispatchers.Default).launch {
            try {
                val module = Python.getInstance().getModule("ncbi_service")
                val jsonResult = module.callAttr("fetch_and_analyze", uid, db, limit).toString()
                Log.d(TAG, "handleNcbiFetch: success")
                withContext(Dispatchers.Main) { result.success(jsonResult) }
            } catch (e: Exception) {
                Log.e(TAG, "handleNcbiFetch error", e)
                withContext(Dispatchers.Main) { result.error("NCBI_FETCH_ERROR", e.message, null) }
            }
        }
    }

    private fun handleNcbiAnalyzeLocal(call: MethodCall, result: MethodChannel.Result) {
        val sequence = call.argument<String>("sequence") ?: ""
        val db = call.argument<String>("db") ?: "protein"
        val limit = (call.argument<Any>("limit") as? Number)?.toInt() ?: 100000
        Log.d(TAG, "handleNcbiAnalyzeLocal: start sequence_length=${sequence.length} db=$db limit=$limit")
        CoroutineScope(Dispatchers.Default).launch {
            try {
                val module = Python.getInstance().getModule("ncbi_service")
                val jsonResult = module.callAttr("analyze_sequence_only", sequence, db, limit).toString()
                Log.d(TAG, "handleNcbiAnalyzeLocal: success")
                withContext(Dispatchers.Main) { result.success(jsonResult) }
            } catch (e: Exception) {
                Log.e(TAG, "handleNcbiAnalyzeLocal error", e)
                withContext(Dispatchers.Main) { result.error("NCBI_ANALYZE_ERROR", e.message, null) }
            }
        }
    }

}
