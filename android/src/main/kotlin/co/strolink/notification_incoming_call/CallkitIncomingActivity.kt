package co.strolink.notification_incoming_call

import android.app.Activity
import android.app.KeyguardManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.View
import android.view.Window
import android.view.WindowManager
import android.view.animation.AnimationUtils
import android.widget.ImageView
import android.widget.TextView
import co.strolink.notification_incoming_call.CallkitIncomingBroadcastReceiver.Companion.EXTRA_CALLKIT_AVATAR
import co.strolink.notification_incoming_call.CallkitIncomingBroadcastReceiver.Companion.EXTRA_CALLKIT_BACKGROUND_COLOR
import co.strolink.notification_incoming_call.CallkitIncomingBroadcastReceiver.Companion.EXTRA_CALLKIT_BACKGROUND_URL
import co.strolink.notification_incoming_call.CallkitIncomingBroadcastReceiver.Companion.EXTRA_CALLKIT_DURATION
import co.strolink.notification_incoming_call.CallkitIncomingBroadcastReceiver.Companion.EXTRA_CALLKIT_HANDLE
import co.strolink.notification_incoming_call.CallkitIncomingBroadcastReceiver.Companion.EXTRA_CALLKIT_HEADERS
import co.strolink.notification_incoming_call.CallkitIncomingBroadcastReceiver.Companion.EXTRA_CALLKIT_INCOMING_DATA
import co.strolink.notification_incoming_call.CallkitIncomingBroadcastReceiver.Companion.EXTRA_CALLKIT_IS_GROUP
import co.strolink.notification_incoming_call.CallkitIncomingBroadcastReceiver.Companion.EXTRA_CALLKIT_NAME_CALLER
import co.strolink.notification_incoming_call.CallkitIncomingBroadcastReceiver.Companion.EXTRA_CALLKIT_TYPE
import co.strolink.notification_incoming_call.CallkitIncomingBroadcastReceiver.Companion.actionCallIncoming
import co.strolink.notification_incoming_call.widgets.RippleRelativeLayout
import com.squareup.picasso.OkHttp3Downloader
import com.squareup.picasso.Picasso
import de.hdodenhof.circleimageview.CircleImageView
import okhttp3.OkHttpClient
import kotlin.math.abs


class CallkitIncomingActivity : Activity() {

    companion object {

        const val ACTION_ENDED_CALL_INCOMING =
                "co.strolink.notification_incoming_call.ACTION_ENDED_CALL_INCOMING"

        fun getIntent(data: Bundle) = Intent(actionCallIncoming).apply {
            action = actionCallIncoming
            putExtra(EXTRA_CALLKIT_INCOMING_DATA, data)
            flags =
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
        }

        fun getIntentEnded() =
                Intent(ACTION_ENDED_CALL_INCOMING)

    }

    inner class EndedCallkitIncomingBroadcastReceiver : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (!isFinishing) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    finishAndRemoveTask()
                } else {
                    finish()
                }
            }
        }
    }

    private var endedCallkitIncomingBroadcastReceiver = EndedCallkitIncomingBroadcastReceiver()

    private lateinit var ivBackground: ImageView
    private lateinit var llBackgroundAnimation: RippleRelativeLayout

    private lateinit var tvNameCaller: TextView
    private lateinit var tvNumber: TextView
    private lateinit var ivAvatar: CircleImageView

    private lateinit var ivAcceptCall: ImageView
    private lateinit var ivDeclineCall: ImageView
    private var holder: Int = 0

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            setTurnScreenOn(true)
            setShowWhenLocked(true)

            val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
            keyguardManager.requestDismissKeyguard(this, null)
        } else {
            window.addFlags(
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                            or WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
                            or WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED
                            or WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
            )
        }
        // transparentStatusAndNavigation()
        setContentView(R.layout.activity_callkit_incoming)
        initView()
        incomingData(intent)
        registerReceiver(
                endedCallkitIncomingBroadcastReceiver,
                IntentFilter(ACTION_ENDED_CALL_INCOMING)
        )
    }

    private fun transparentStatusAndNavigation() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT && Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
            setWindowFlag(
                    WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS
                            or WindowManager.LayoutParams.FLAG_TRANSLUCENT_NAVIGATION, true
            )
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            window.decorView.systemUiVisibility = (View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                    or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                    or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            setWindowFlag(
                    (WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS
                            or WindowManager.LayoutParams.FLAG_TRANSLUCENT_NAVIGATION), false
            )
            window.statusBarColor = Color.TRANSPARENT
            window.navigationBarColor = Color.TRANSPARENT
        }
    }

    private fun setWindowFlag(bits: Int, on: Boolean) {
        val win: Window = window
        val winParams: WindowManager.LayoutParams = win.attributes
        if (on) {
            winParams.flags = winParams.flags or bits
        } else {
            winParams.flags = winParams.flags and bits.inv()
        }
        win.attributes = winParams
    }


    private fun incomingData(intent: Intent) {
        val data = intent.extras?.getBundle(EXTRA_CALLKIT_INCOMING_DATA)
        if (data == null) finish()

        tvNameCaller.text = data?.getString(EXTRA_CALLKIT_NAME_CALLER, "")

        val callTypeText: String = if (data?.getInt(EXTRA_CALLKIT_TYPE, 0) == 0) "Voice call" else "Video Call"
        tvNumber.text = callTypeText// data?.getString(EXTRA_CALLKIT_HANDLE, "")


        val avatarUrl = data?.getString(EXTRA_CALLKIT_AVATAR, "")
        val isGroup = data?.getBoolean(EXTRA_CALLKIT_IS_GROUP, false)
        if (avatarUrl != null && avatarUrl.isNotEmpty()) {
            ivAvatar.visibility = View.VISIBLE
            val headers = data.getSerializable(EXTRA_CALLKIT_HEADERS) as HashMap<String, Any?>


            holder = if (isGroup == true) {
                (R.drawable.bg_group_holder)
            } else {
                (R.drawable.bg_user_holder)
            }
            getPicassoInstance(this@CallkitIncomingActivity, headers)
                    .load(avatarUrl)
                    .placeholder(holder)
                    .error(holder)
                    .into(ivAvatar)
        }
        val callType = data?.getInt(EXTRA_CALLKIT_TYPE, 0) ?: 0
        if (callType > 0) {
            ivAcceptCall.setImageResource(R.drawable.ic_video)
        }
        val duration = data?.getLong(EXTRA_CALLKIT_DURATION, 0L) ?: 0L


        finishTimeout(data, duration)

        val backgroundColor = data?.getString(EXTRA_CALLKIT_BACKGROUND_COLOR, "#ffffff")
        try {
            ivBackground.setBackgroundColor(Color.parseColor(backgroundColor))
        } catch (error: Exception) {
        }
        val backgroundUrl = data?.getString(EXTRA_CALLKIT_BACKGROUND_URL, "")
        if (backgroundUrl != null && backgroundUrl.isNotEmpty()) {
            val headers = data.getSerializable(EXTRA_CALLKIT_HEADERS) as HashMap<String, Any?>
            getPicassoInstance(this@CallkitIncomingActivity, headers)
                    .load(backgroundUrl)
                    .placeholder(R.drawable.transparent)
                    .error(R.drawable.transparent)
                    .into(ivBackground)
        }
    }

    private fun finishTimeout(data: Bundle?, duration: Long) {
        val currentSystemTime = System.currentTimeMillis()
        val timeStartCall =
                data?.getLong(CallkitNotificationManager.EXTRA_TIME_START_CALL, currentSystemTime)
                        ?: currentSystemTime

        val timeOut = duration - abs(currentSystemTime - timeStartCall)
        Handler(Looper.getMainLooper()).postDelayed({
            if (!isFinishing) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    finishAndRemoveTask()
                } else {
                    finish()
                }
            }
        }, timeOut)
    }

    private fun initView() {
        ivBackground = findViewById(R.id.ivBackground)
        llBackgroundAnimation = findViewById(R.id.llBackgroundAnimation)
        llBackgroundAnimation.layoutParams.height =
                Utils.getScreenWidth() + Utils.getStatusBarHeight(this@CallkitIncomingActivity)
        llBackgroundAnimation.startRippleAnimation()

        tvNameCaller = findViewById(R.id.tvNameCaller)
        tvNumber = findViewById(R.id.tvNumber)
        ivAvatar = findViewById(R.id.ivAvatar)

        ivAcceptCall = findViewById(R.id.ivAcceptCall)
        ivDeclineCall = findViewById(R.id.ivDeclineCall)
        animateAcceptCall()

        ivAcceptCall.setOnClickListener {
            onAcceptClick()
        }
        ivDeclineCall.setOnClickListener {
            onDeclineClick()
        }
    }

    private fun animateAcceptCall() {
        val shakeAnimation =
                AnimationUtils.loadAnimation(this@CallkitIncomingActivity, R.anim.shake_anim)
        ivAcceptCall.animation = shakeAnimation
    }


    private fun onAcceptClick() {
        val data = intent.extras?.getBundle(EXTRA_CALLKIT_INCOMING_DATA)
        val intent =
                CallkitIncomingBroadcastReceiver.getIntentAccept(this@CallkitIncomingActivity, data)
        sendBroadcast(intent)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            finishAndRemoveTask()
        } else {
            finish()
        }
    }

    private fun onDeclineClick() {
        val data = intent.extras?.getBundle(EXTRA_CALLKIT_INCOMING_DATA)
        val intent =
                CallkitIncomingBroadcastReceiver.getIntentDecline(this@CallkitIncomingActivity, data)
        sendBroadcast(intent)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            finishAndRemoveTask()
        } else {
            finish()
        }
    }

    private fun getPicassoInstance(context: Context, headers: HashMap<String, Any?>): Picasso {
        val client = OkHttpClient.Builder()
                .addNetworkInterceptor { chain ->
                    val newRequestBuilder: okhttp3.Request.Builder = chain.request().newBuilder()
                    for ((key, value) in headers) {
                        newRequestBuilder.addHeader(key, value.toString())
                    }
                    chain.proceed(newRequestBuilder.build())
                }
                .build()
        return Picasso.Builder(context)
                .downloader(OkHttp3Downloader(client))
                .build()
    }

    override fun onDestroy() {
        unregisterReceiver(endedCallkitIncomingBroadcastReceiver)
        super.onDestroy()
    }

    override fun onBackPressed() {}


}