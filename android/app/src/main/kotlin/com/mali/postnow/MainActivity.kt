package com.mali.postnow

import android.os.Bundle
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val PAYMNET_CHANNEL = "com.mali.postnow/payments"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PAYMNET_CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "openPayMenu") {
                val amount: Double? = call.argument<Double>("amount")
                if (amount != null) {
                    val returnPayPal = payWithPayPal(amount)

                    if (returnPayPal != null) {
                        result.success(returnPayPal)
                    } else {
                        result.error("PAYMENU_UNAVAILABLE", "Failed to pay.", null)
                    }
                } else {
                    result.notImplemented()
                }
                result.error("PAYMENU_NO_AMOUNT", "Failed to pay, there is no amount.", null)
            }
        }
    }

    private fun payWithPayPal(amount: Double): Double {
        return -amount;
    }

}