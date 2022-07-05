package co.strolink.notification_incoming_call

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper

class CallkitIncomingBroadcastReceiver : BroadcastReceiver() {

    companion object {

        const val actionCallIncoming =
            "co.strolink.notification_incoming_call.actionCallIncoming"
        const val actionCallStart = "co.strolink.notification_incoming_call.actionCallStart"
        const val actionCallAccept =
            "co.strolink.notification_incoming_call.actionCallAccept"
        const val actionCallDecline =
            "co.strolink.notification_incoming_call.actionCallDecline"
        const val actionCallEnded =
            "co.strolink.notification_incoming_call.actionCallEnded"
        const val actionCallTimeout =
            "co.strolink.notification_incoming_call.actionCallTimeout"
        const val actionCallCallback =
            "co.strolink.notification_incoming_call.actionCallCallback"


        const val EXTRA_CALLKIT_INCOMING_DATA = "EXTRA_CALLKIT_INCOMING_DATA"

        const val EXTRA_CALLKIT_ID = "EXTRA_CALLKIT_ID"
        const val EXTRA_CALLKIT_NAME_CALLER = "EXTRA_CALLKIT_NAME_CALLER"
        const val EXTRA_CALLKIT_APP_NAME = "EXTRA_CALLKIT_APP_NAME"
        const val EXTRA_CALLKIT_HANDLE = "EXTRA_CALLKIT_HANDLE"
        const val EXTRA_CALLKIT_TYPE = "EXTRA_CALLKIT_TYPE"
        const val EXTRA_CALLKIT_AVATAR = "EXTRA_CALLKIT_AVATAR"
        const val EXTRA_CALLKIT_IS_GROUP = "EXTRA_CALLKIT_IS_GROUP"
        const val EXTRA_CALLKIT_DURATION = "EXTRA_CALLKIT_DURATION"
        const val EXTRA_CALLKIT_EXTRA = "EXTRA_CALLKIT_EXTRA"
        const val EXTRA_CALLKIT_HEADERS = "EXTRA_CALLKIT_HEADERS"
        const val EXTRA_CALLKIT_IS_CUSTOM_NOTIFICATION = "EXTRA_CALLKIT_IS_CUSTOM_NOTIFICATION"
        const val EXTRA_CALLKIT_IS_SHOW_LOGO = "EXTRA_CALLKIT_IS_SHOW_LOGO"
        const val EXTRA_CALLKIT_RINGTONE_PATH = "EXTRA_CALLKIT_RINGTONE_PATH"
        const val EXTRA_CALLKIT_BACKGROUND_COLOR = "EXTRA_CALLKIT_BACKGROUND_COLOR"
        const val EXTRA_CALLKIT_BACKGROUND_URL = "EXTRA_CALLKIT_BACKGROUND_URL"
        const val EXTRA_CALLKIT_ACTION_COLOR = "EXTRA_CALLKIT_ACTION_COLOR"

        const val EXTRA_CALLKIT_ACTION_FROM = "EXTRA_CALLKIT_ACTION_FROM"

        fun getIntentIncoming(context: Context, data: Bundle?) =
            Intent(context, CallkitIncomingBroadcastReceiver::class.java).apply {
                action = actionCallIncoming
                putExtra(EXTRA_CALLKIT_INCOMING_DATA, data)
            }

        fun getIntentStart(context: Context, data: Bundle?) =
            Intent(context, CallkitIncomingBroadcastReceiver::class.java).apply {
                action = actionCallStart
                putExtra(EXTRA_CALLKIT_INCOMING_DATA, data)
            }

        fun getIntentAccept(context: Context, data: Bundle?) =
            Intent(context, CallkitIncomingBroadcastReceiver::class.java).apply {
                action = actionCallAccept
                putExtra(EXTRA_CALLKIT_INCOMING_DATA, data)
            }

        fun getIntentDecline(context: Context, data: Bundle?) =
            Intent(context, CallkitIncomingBroadcastReceiver::class.java).apply {
                action = actionCallDecline
                putExtra(EXTRA_CALLKIT_INCOMING_DATA, data)
            }

        fun getIntentEnded(context: Context, data: Bundle?) =
            Intent(context, CallkitIncomingBroadcastReceiver::class.java).apply {
                action = actionCallEnded
                putExtra(EXTRA_CALLKIT_INCOMING_DATA, data)
            }

        fun getIntentTimeout(context: Context, data: Bundle?) =
            Intent(context, CallkitIncomingBroadcastReceiver::class.java).apply {
                action = actionCallTimeout
                putExtra(EXTRA_CALLKIT_INCOMING_DATA, data)
            }

        fun getIntentCallback(context: Context, data: Bundle?) =
            Intent(context, CallkitIncomingBroadcastReceiver::class.java).apply {
                action = actionCallCallback
                putExtra(EXTRA_CALLKIT_INCOMING_DATA, data)
            }
    }



    override fun onReceive(context: Context, intent: Intent) {
        val callkitSoundPlayer = CallkitSoundPlayer.getInstance(context.applicationContext)
        val callkitNotificationManager = CallkitNotificationManager(context)
        val action = intent.action ?: return
        val data = intent.extras?.getBundle(EXTRA_CALLKIT_INCOMING_DATA) ?: return
        when (action) {
            actionCallIncoming -> {
                try {
                    sendEventFlutter(actionCallIncoming, data)
                    val duration = data.getLong(EXTRA_CALLKIT_DURATION, 0L)
                    callkitSoundPlayer.setDuration(duration)
                    callkitSoundPlayer.play(data)
                } catch (error: Exception) {
                    error.printStackTrace()
                }
            }
            actionCallStart -> {
                try {
                    sendEventFlutter(actionCallStart, data)
                    addCall(context, Data.fromBundle(data))
                } catch (error: Exception) {
                    error.printStackTrace()
                }
            }
            actionCallAccept -> {
                try {
                    Utils.backToForeground(context)
                    sendEventFlutter(actionCallAccept, data)
                    callkitSoundPlayer.stop()
                    callkitNotificationManager.clearIncomingNotification(data)
                    addCall(context, Data.fromBundle(data))
                } catch (error: Exception) {
                    error.printStackTrace()
                }
            }
            actionCallDecline -> {
                try {
                    sendEventFlutter(actionCallDecline, data)
                    callkitSoundPlayer.stop()
                    callkitNotificationManager.clearIncomingNotification(data)
                    removeCall(context, Data.fromBundle(data))
                } catch (error: Exception) {
                    error.printStackTrace()
                }
            }
            actionCallEnded -> {
                try {
                    sendEventFlutter(actionCallEnded, data)
                    callkitSoundPlayer.stop()
                    callkitNotificationManager.clearIncomingNotification(data)
                    removeCall(context, Data.fromBundle(data))
                } catch (error: Exception) {
                    error.printStackTrace()
                }
            }
            actionCallTimeout -> {
                try {
                    sendEventFlutter(actionCallTimeout, data)
                    callkitSoundPlayer.stop()
                    callkitNotificationManager.showMissCallNotification(data)
                    removeCall(context, Data.fromBundle(data))
                } catch (error: Exception) {
                    error.printStackTrace()
                }
            }
            actionCallCallback -> {
                try {
                    callkitNotificationManager.clearMissCallNotification(data)
                    sendEventFlutter(actionCallCallback, data)
                    Utils.backToForeground(context)
                    val closeNotificationPanel = Intent(Intent.ACTION_CLOSE_SYSTEM_DIALOGS)
                    context.sendBroadcast(closeNotificationPanel)
                } catch (error: Exception) {
                    error.printStackTrace()
                }
            }
        }
    }

    @Suppress("UNCHECKED_CAST")
    private fun sendEventFlutter(event: String, data: Bundle) {
        val android = mapOf(
            "isCustomNotification" to data.getBoolean(EXTRA_CALLKIT_IS_CUSTOM_NOTIFICATION, false),
            "ringtonePath" to data.getString(EXTRA_CALLKIT_RINGTONE_PATH, ""),
            "backgroundColor" to data.getString(EXTRA_CALLKIT_BACKGROUND_COLOR, ""),
            "backgroundUrl" to data.getString(EXTRA_CALLKIT_BACKGROUND_URL, ""),
            "actionColor" to data.getString(EXTRA_CALLKIT_ACTION_COLOR, "")
        )
        val forwardData = mapOf(
            "id" to data.getString(EXTRA_CALLKIT_ID, ""),
            "nameCaller" to data.getString(EXTRA_CALLKIT_NAME_CALLER, ""),
            "avatar" to data.getString(EXTRA_CALLKIT_AVATAR, ""),
            "isGroup" to data.getBoolean(EXTRA_CALLKIT_IS_GROUP, false),
            "number" to data.getString(EXTRA_CALLKIT_HANDLE, ""),
            "type" to data.getInt(EXTRA_CALLKIT_TYPE, 0),
            "duration" to data.getLong(EXTRA_CALLKIT_DURATION, 0L),
            "extra" to data.getSerializable(EXTRA_CALLKIT_EXTRA) as HashMap<String, Any?>,
            "android" to android
        )
        NotificationIncomingCallPlugin.sendEvent(event, forwardData)
    }
}