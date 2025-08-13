package com.hasa.app

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKeys
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.hasa.app/pin"
    private lateinit var encryptedSharedPreferences: SharedPreferences
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        try {
            val masterKeyAlias = MasterKeys.getOrCreate(MasterKeys.AES256_GCM_SPEC)
            encryptedSharedPreferences = EncryptedSharedPreferences.create(
                "pin_prefs",
                masterKeyAlias,
                this,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            )
        } catch (e: Exception) {
            // Fallback to regular SharedPreferences if encryption fails
            encryptedSharedPreferences = getSharedPreferences("pin_prefs", Context.MODE_PRIVATE)
        }
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "savePin" -> {
                    val pin = call.argument<String>("pin")
                    if (pin != null) {
                        val success = savePin(pin)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENT", "PIN cannot be null", null)
                    }
                }
                "verifyPin" -> {
                    val pin = call.argument<String>("pin")
                    if (pin != null) {
                        val isValid = verifyPin(pin)
                        result.success(isValid)
                    } else {
                        result.error("INVALID_ARGUMENT", "PIN cannot be null", null)
                    }
                }
                "isPinSet" -> {
                    val isSet = isPinSet()
                    result.success(isSet)
                }
                "resetPin" -> {
                    val success = resetPin()
                    result.success(success)
                }
                "incrementAttempts" -> {
                    val attempts = incrementAttempts()
                    result.success(attempts)
                }
                "resetAttempts" -> {
                    val success = resetAttempts()
                    result.success(success)
                }
                "getRemainingAttempts" -> {
                    val remaining = getRemainingAttempts()
                    result.success(remaining)
                }
                "isLocked" -> {
                    val locked = isLocked()
                    result.success(locked)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun savePin(pin: String): Boolean {
        return try {
            encryptedSharedPreferences.edit().putString("user_pin", pin).apply()
            true
        } catch (e: Exception) {
            false
        }
    }
    
    private fun verifyPin(pin: String): Boolean {
        return try {
            val storedPin = encryptedSharedPreferences.getString("user_pin", null)
            storedPin == pin
        } catch (e: Exception) {
            false
        }
    }
    
    private fun isPinSet(): Boolean {
        return try {
            encryptedSharedPreferences.contains("user_pin")
        } catch (e: Exception) {
            false
        }
    }
    
    private fun resetPin(): Boolean {
        return try {
            encryptedSharedPreferences.edit().remove("user_pin").apply()
            resetAttempts()
            true
        } catch (e: Exception) {
            false
        }
    }
    
    private fun incrementAttempts(): Int {
        return try {
            val currentAttempts = encryptedSharedPreferences.getInt("failed_attempts", 0)
            val newAttempts = currentAttempts + 1
            encryptedSharedPreferences.edit().putInt("failed_attempts", newAttempts).apply()
            newAttempts
        } catch (e: Exception) {
            0
        }
    }
    
    private fun resetAttempts(): Boolean {
        return try {
            encryptedSharedPreferences.edit().remove("failed_attempts").apply()
            true
        } catch (e: Exception) {
            false
        }
    }
    
    private fun getRemainingAttempts(): Int {
        return try {
            val maxAttempts = 5
            val failedAttempts = encryptedSharedPreferences.getInt("failed_attempts", 0)
            maxOf(0, maxAttempts - failedAttempts)
        } catch (e: Exception) {
            5
        }
    }
    
    private fun isLocked(): Boolean {
        return try {
            val failedAttempts = encryptedSharedPreferences.getInt("failed_attempts", 0)
            failedAttempts >= 5
        } catch (e: Exception) {
            false
        }
    }
}