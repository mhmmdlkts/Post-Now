package com.mali.postnow

import android.content.Intent
import android.net.Uri
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val PAYMNET_CHANNEL = "com.mali.postnow/payments"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PAYMNET_CHANNEL).setMethodCallHandler { call, result ->
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

    protected override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val action: String? = intent?.action
        if (action === android.content.Intent.ACTION_VIEW) {
            val data: Uri? = intent?.data
            val paymentId: String? = data?.getQueryParameter("id")

            // Optional: Do stuff with the payment ID
        }
    }

    private fun payWithPayPal(amount: Double): Double {
        return -amount;
    }

}