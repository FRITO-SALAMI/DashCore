package com.dashcore.app

import ai.onnxruntime.OnnxTensor
import ai.onnxruntime.OrtEnvironment
import ai.onnxruntime.OrtSession
import android.app.ActivityManager
import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.concurrent.thread
import kotlin.math.roundToInt

internal object LocalVehicleArt {
    private const val side = 320
    private const val pixels = side * side
    private val busy = AtomicBoolean(false)

    fun register(context: Context, messenger: BinaryMessenger) {
        MethodChannel(messenger, "io.dashcore.app/local_vehicle_art")
            .setMethodCallHandler { call, result ->
                if (call.method != "segmentVehicle") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val rgba = call.arguments as? ByteArray
                if (rgba == null || rgba.size != pixels * 4 || !busy.compareAndSet(false, true)) {
                    result.success(null)
                    return@setMethodCallHandler
                }
                thread(name = "dashcore-vehicle-segmentation") {
                    val mask = try {
                        val memory = ActivityManager.MemoryInfo()
                        context.getSystemService(ActivityManager::class.java)?.getMemoryInfo(memory)
                        if (memory.lowMemory) null else segment(context, rgba)
                    } catch (_: Exception) {
                        null
                    } catch (_: LinkageError) {
                        null
                    } catch (_: OutOfMemoryError) {
                        null
                    } finally {
                        busy.set(false)
                    }
                    Handler(Looper.getMainLooper()).post { result.success(mask) }
                }
            }
    }

    private fun segment(context: Context, rgba: ByteArray): ByteArray? {
        val env = OrtEnvironment.getEnvironment()
        env.setTelemetry(false)
        val means = floatArrayOf(.485f, .456f, .406f)
        val deviations = floatArrayOf(.229f, .224f, .225f)
        val input = ByteBuffer.allocateDirect(pixels * 3 * java.lang.Float.BYTES)
            .order(ByteOrder.nativeOrder()).asFloatBuffer()
        var brightest = 1
        for (pixel in 0 until pixels) {
            for (channel in 0..2) {
                brightest = maxOf(brightest, rgba[pixel * 4 + channel].toInt() and 255)
            }
        }
        for (channel in 0..2) {
            for (pixel in 0 until pixels) {
                val value = (rgba[pixel * 4 + channel].toInt() and 255).toFloat() / brightest
                input.put((value - means[channel]) / deviations[channel])
            }
        }
        input.rewind()
        OrtSession.SessionOptions().use { options ->
            options.setIntraOpNumThreads(1)
            options.setInterOpNumThreads(1)
            options.setMemoryPatternOptimization(false)
            options.setCPUArenaAllocator(false)
            val model = context.assets.open("vehicle_art/u2netp.onnx").use { it.readBytes() }
            env.createSession(model, options).use { session ->
                OnnxTensor.createTensor(env, input, longArrayOf(1, 3, side.toLong(), side.toLong())).use { tensor ->
                    session.run(mapOf(session.inputNames.single() to tensor)).use { outputs ->
                        val buffer = (outputs[0] as? OnnxTensor)?.floatBuffer ?: return null
                        if (buffer.remaining() != pixels) return null
                        var minimum = Float.POSITIVE_INFINITY
                        var maximum = Float.NEGATIVE_INFINITY
                        for (i in 0 until pixels) {
                            val value = buffer.get(i)
                            if (!value.isFinite()) return null
                            minimum = minOf(minimum, value)
                            maximum = maxOf(maximum, value)
                        }
                        if (maximum - minimum < .15f) return null
                        val mask = ByteArray(pixels) { index ->
                            val normalized = (buffer.get(index) - minimum) / (maximum - minimum)
                            (((normalized - .15f) / .70f).coerceIn(0f, 1f) * 255f)
                                .roundToInt().toByte()
                        }
                        val foreground = mask.count { (it.toInt() and 255) > 160 }
                        return if (foreground in (pixels / 60)..(pixels * 9 / 10)) mask else null
                    }
                }
            }
        }
    }
}
