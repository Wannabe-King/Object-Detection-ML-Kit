package com.example.object_dection_flutter

import android.annotation.SuppressLint
import android.content.Context
import android.util.Log
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.objects.ObjectDetection
import com.google.mlkit.vision.objects.defaults.ObjectDetectorOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    // Constants for communication channels
    private val CHANNEL = "object_detector"            // MethodChannel name
    private val EVENT_CHANNEL = "object_detector_events" // EventChannel name

    private lateinit var cameraExecutor: ExecutorService // Background thread for camera analysis
    private var eventSink: EventChannel.EventSink? = null // Sends detection data back to Flutter


    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

         // Handle method calls from Flutter (initialize, startDetection, stopDetection)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                // Set up a background thread executor
                "initialize" -> {
                    cameraExecutor = Executors.newSingleThreadExecutor()
                    result.success(null)
                }
                // Start camera and object detection
                "startDetection" -> {
                    startCamera()
                    result.success(null)
                }
                // Shut down camera
                "stopDetection" -> {
                    stopCamera()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // Event Channel for sending detections to Flutter
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )
    }

    private fun startCamera() {
        val cameraProviderFuture = ProcessCameraProvider.getInstance(this)

        cameraProviderFuture.addListener({
            val cameraProvider: ProcessCameraProvider = cameraProviderFuture.get()

             // Preview use case (not displayed but needed)
            val preview = Preview.Builder().build()

            // Image analysis use case with a custom analyzer
            val imageAnalyzer = ImageAnalysis.Builder()
                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                .build()
                .also {
                    // Set the custom object detection analyzer
                    it.setAnalyzer(cameraExecutor, ObjectDetectionAnalyzer(this) { detectedObjects ->
                        // Send detection results back to Flutter via EventSink
                        runOnUiThread {
                            eventSink?.success(detectedObjects)
                        }
                    })
                }
             // Choose the back camera
            val cameraSelector = CameraSelector.DEFAULT_BACK_CAMERA

            try {
                // Unbind any previously bound use cases
                cameraProvider.unbindAll()
                // Bind preview and analysis to the lifecycle
                cameraProvider.bindToLifecycle(
                    this, cameraSelector, preview, imageAnalyzer
                )
            } catch(exc: Exception) {
                Log.e("Camera", "Use case binding failed", exc)
            }
        }, ContextCompat.getMainExecutor(this))
    }

    private fun stopCamera() {
        cameraExecutor.shutdown()
        eventSink?.endOfStream()
    }

    // Ensure cleanup on activity destro
    override fun onDestroy() {
        super.onDestroy()
        stopCamera()
    }
}

class ObjectDetectionAnalyzer(
    private val context: Context,
    private val onDetectionResult: (List<Map<String, Any>>) -> Unit
) : ImageAnalysis.Analyzer {
    private val detector = ObjectDetection.getClient(
        ObjectDetectorOptions.Builder()
            .setDetectorMode(ObjectDetectorOptions.STREAM_MODE) // Stream mode = real-time
            .enableMultipleObjects()        // Detect more than 1 object
            .enableClassification()         // Try to classify them
            .build()
    )

    @SuppressLint("UnsafeOptInUsageError")
    override fun analyze(imageProxy: ImageProxy) {
        val mediaImage = imageProxy.image
        if (mediaImage != null) {
            val inputImage = InputImage.fromMediaImage(mediaImage, imageProxy.imageInfo.rotationDegrees)

            // Run ML Kit object detection
            detector.process(inputImage)
                .addOnSuccessListener { results ->
                    // Convert detection results to a list of maps
                    val detectedObjects = results.map { obj ->
                        mapOf<String, Any>(
                        "label" to (obj.labels.firstOrNull()?.text ?: "Unknown"),
                        "confidence" to (obj.labels.firstOrNull()?.confidence ?: 0f).toDouble(),
                        "boundingBox" to mapOf<String, Double>(
                        "left" to obj.boundingBox.left.toDouble(),
                        "top" to obj.boundingBox.top.toDouble(),
                        "right" to obj.boundingBox.right.toDouble(),
                        "bottom" to obj.boundingBox.bottom.toDouble()
                        ),
                        "trackingId" to (obj.trackingId ?: -1)
                        )
                    }
                    // Pass results back to the MainActivity via callback
                    onDetectionResult(detectedObjects)
                }
                .addOnFailureListener {
                    Log.e("MLKit", "Detection failed", it)
                }
                .addOnCompleteListener {
                    imageProxy.close()
                }
        }
    }
}