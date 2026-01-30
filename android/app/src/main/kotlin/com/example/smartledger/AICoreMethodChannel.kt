package com.example.smartledger

import android.content.Context
import com.google.mediapipe.tasks.genai.llminference.LlmInference
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File

/**
 * MediaPipe LLM Inference API를 사용한 온디바이스 AI 처리
 * 
 * 공식 문서: https://ai.google.dev/edge/mediapipe/solutions/genai/llm_inference/android
 */
class AICoreMethodChannel(
    private val context: Context,
    flutterEngine: FlutterEngine
) {
    companion object {
        private const val CHANNEL_NAME = "com.smartledger/aicore"
        private const val MODEL_PATH = "gemini-2b-it-gpu-int4.bin" // 모델 파일명
    }

    private val channel: MethodChannel
    private val coroutineScope = CoroutineScope(Dispatchers.Main)
    private var llmInference: LlmInference? = null
    private var isModelLoaded = false

    init {
        channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME
        )
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "isAICoreAvailable" -> {
                    checkAvailability(result)
                }
                "generateText" -> {
                    val prompt = call.argument<String>("prompt")
                    if (prompt != null) {
                        generateText(prompt, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "Prompt is required", null)
                    }
                }
                "loadModel" -> {
                    loadModel(result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    /**
     * MediaPipe LLM Inference 사용 가능 여부 확인
     */
    private fun checkAvailability(result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                // 모델 파일 존재 여부 확인
                val modelFile = File(context.filesDir, MODEL_PATH)
                val available = modelFile.exists() || isModelLoaded
                
                withContext(Dispatchers.Main) {
                    result.success(available)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.success(false)
                }
            }
        }
    }

    /**
     * MediaPipe LLM 모델 로드
     */
    private fun loadModel(result: MethodChannel.Result) {
        if (isModelLoaded) {
            result.success(true)
            return
        }

        coroutineScope.launch {
            try {
                withContext(Dispatchers.IO) {
                    val modelFile = File(context.filesDir, MODEL_PATH)
                    
                    if (!modelFile.exists()) {
                        withContext(Dispatchers.Main) {
                            result.error(
                                "MODEL_NOT_FOUND",
                                "Model file not found: $MODEL_PATH. Please download the model first.",
                                null
                            )
                        }
                        return@withContext
                    }

                    // MediaPipe LLM Inference 초기화
                    val options = LlmInference.LlmInferenceOptions.builder()
                        .setModelPath(modelFile.absolutePath)
                        .setMaxTokens(2048)
                        .setTopK(40)
                        .setTemperature(0.8f)
                        .setRandomSeed(101)
                        .build()

                    llmInference = LlmInference.createFromOptions(context, options)
                    isModelLoaded = true

                    withContext(Dispatchers.Main) {
                        result.success(true)
                    }
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("LOAD_ERROR", "Failed to load model: ${e.message}", null)
                }
            }
        }
    }

    /**
     * MediaPipe LLM으로 텍스트 생성
     */
    private fun generateText(prompt: String, result: MethodChannel.Result) {
        if (!isModelLoaded || llmInference == null) {
            result.error("MODEL_NOT_LOADED", "Model not loaded. Call loadModel first.", null)
            return
        }

        coroutineScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    llmInference?.generateResponse(prompt)
                }

                withContext(Dispatchers.Main) {
                    if (response != null) {
                        result.success(response)
                    } else {
                        result.error("GENERATION_ERROR", "Failed to generate text", null)
                    }
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("GENERATION_ERROR", "Error: ${e.message}", null)
                }
            }
        }
    }

    /**
     * 리소스 정리
     */
    fun dispose() {
        llmInference?.close()
        llmInference = null
        isModelLoaded = false
    }
}
