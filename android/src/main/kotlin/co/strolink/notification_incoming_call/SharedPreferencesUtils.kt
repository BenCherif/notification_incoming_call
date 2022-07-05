package co.strolink.notification_incoming_call

import android.content.Context
import android.content.SharedPreferences
import com.google.gson.reflect.TypeToken


private const val CALLKIT_PREFERENCES_FILE_NAME = "flutter_callkit_incoming"
private var prefs: SharedPreferences? = null
private var editor: SharedPreferences.Editor? = null

private fun initInstance(context: Context) {
    prefs = context.getSharedPreferences(CALLKIT_PREFERENCES_FILE_NAME, Context.MODE_PRIVATE)
    editor = prefs?.edit()
}


fun addCall(context: Context?, data: Data) {
    val json = getString(context, "ACTIVE_CALLS", "[]")
    val arrayData: ArrayList<Data> = Utils.getGsonInstance()
        .fromJson(json, object : TypeToken<ArrayList<Data>>() {}.type)
    arrayData.add(data)
    putString(context, "ACTIVE_CALLS", Utils.getGsonInstance().toJson(arrayData))
}

fun removeCall(context: Context?, data: Data) {
    val json = getString(context, "ACTIVE_CALLS", "[]")
    val arrayData: ArrayList<Data> = Utils.getGsonInstance()
        .fromJson(json, object : TypeToken<ArrayList<Data>>() {}.type)
    arrayData.remove(data)
    putString(context, "ACTIVE_CALLS", Utils.getGsonInstance().toJson(arrayData))
}

fun removeAllCalls(context: Context?) {
    putString(context, "ACTIVE_CALLS", "[]")
    remove(context, "ACTIVE_CALLS")
}

fun getActiveCalls(context: Context?): String {
    val json = getString(context, "ACTIVE_CALLS", "[]")
    val arrayData: ArrayList<Data> = Utils.getGsonInstance()
        .fromJson(json, object : TypeToken<ArrayList<Data>>() {}.type)
    return Utils.getGsonInstance().toJson(arrayData)
}


fun putString(context: Context?, key: String, value: String?) {
    if (context == null) return
    initInstance(context)
    editor?.putString(key, value)
    editor?.commit()
}

fun getString(context: Context?, key: String, defaultValue: String = ""): String? {
    if (context == null) return null
    initInstance(context)
    return prefs?.getString(key, defaultValue)
}

fun remove(context: Context?, key: String) {
    if (context == null) return
    initInstance(context)
    editor?.remove(key)
    editor?.commit()
}
