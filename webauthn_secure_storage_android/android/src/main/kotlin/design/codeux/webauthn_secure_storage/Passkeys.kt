package design.codeux.webauthn_secure_storage

import android.app.Activity
import androidx.credentials.CreatePublicKeyCredentialRequest
import androidx.credentials.CreatePublicKeyCredentialResponse
import androidx.credentials.CredentialManager
import androidx.credentials.GetCredentialRequest
import androidx.credentials.GetPublicKeyCredentialOption
import androidx.credentials.PublicKeyCredential
import io.github.oshai.kotlinlogging.KotlinLogging
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.json.JSONObject

private val logger = KotlinLogging.logger {}

fun registerPasskey(
    activity: Activity,
    optionsMap: Map<String, Any>,
    onSuccess: (Map<String, Any>) -> Unit,
    onError: (Exception) -> Unit
) {
    val requestJson = JSONObject(optionsMap).toString()
    val credentialManager = CredentialManager.create(activity)
    val request = CreatePublicKeyCredentialRequest(requestJson)

    CoroutineScope(Dispatchers.Main).launch {
        try {
            val response = credentialManager.createCredential(activity, request)
            if (response is CreatePublicKeyCredentialResponse) {
                val jsonMap = JSONObject(response.registrationResponseJson).toMap()
                onSuccess(jsonMap)
            } else {
                onError(Exception("Unexpected response type: ${response.javaClass.name}"))
            }
        } catch (e: Exception) {
            logger.error(e) { "registerPasskey failed" }
            onError(e)
        }
    }
}

fun authenticateWithPasskey(
    activity: Activity,
    optionsMap: Map<String, Any>,
    onSuccess: (Map<String, Any>) -> Unit,
    onError: (Exception) -> Unit
) {
    val requestJson = JSONObject(optionsMap).toString()
    val credentialManager = CredentialManager.create(activity)
    val getOption = GetPublicKeyCredentialOption(requestJson)
    val request = GetCredentialRequest(listOf(getOption))

    CoroutineScope(Dispatchers.Main).launch {
        try {
            val response = credentialManager.getCredential(activity, request)
            val credential = response.credential
            if (credential is PublicKeyCredential) {
                val jsonMap = JSONObject(credential.authenticationResponseJson).toMap()
                onSuccess(jsonMap)
            } else {
                onError(Exception("Unexpected credential type: ${credential.javaClass.name}"))
            }
        } catch (e: Exception) {
            logger.error(e) { "authenticateWithPasskey failed" }
            onError(e)
        }
    }
}

// Extension to convert JSONObject to Map<String, Any>
fun JSONObject.toMap(): Map<String, Any> {
    val map = mutableMapOf<String, Any>()
    val keys = keys()
    while (keys.hasNext()) {
        val key = keys.next()
        var value = get(key)
        if (value is JSONObject) {
            value = value.toMap()
        } else if (value is org.json.JSONArray) {
            value = value.toList()
        }
        map[key] = value
    }
    return map
}

fun org.json.JSONArray.toList(): List<Any> {
    val list = mutableListOf<Any>()
    for (i in 0 until length()) {
        var value = get(i)
        if (value is JSONObject) {
            value = value.toMap()
        } else if (value is org.json.JSONArray) {
            value = value.toList()
        }
        list.add(value)
    }
    return list
}
