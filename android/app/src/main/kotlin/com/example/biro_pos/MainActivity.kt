package si.Flop.BiroPOS
import android.app.PendingIntent
import android.bluetooth.*
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.content.*
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.hardware.usb.*
import android.os.Build
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.io.OutputStream
import java.util.*
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import androidx.activity.enableEdgeToEdge
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit


class MainActivity : FlutterActivity() {
    private val CHANNEL = "bluetooth_channel"
    private val USB_CHANNEL = "usb_channel"

    // Bluetooth
    private val bluetoothAdapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()
    private val discoveredDevices = mutableListOf<String>()
    private var currentDevice: BluetoothDevice? = null
    private var bluetoothSocket: BluetoothSocket? = null
    private var outputStream: OutputStream? = null

    // USB
    private var usbManager: UsbManager? = null
    private var usbDevice: UsbDevice? = null
    private var usbInterface: UsbInterface? = null
    private var usbConnection: UsbDeviceConnection? = null
    private var usbOutEndpoint: UsbEndpoint? = null
    private var usbInEndpoint: UsbEndpoint? = null

    private val executorService: ExecutorService = Executors.newSingleThreadExecutor()

    // BroadcastReceivers
    private val discoveryReceiver =
            object : BroadcastReceiver() {
                override fun onReceive(context: Context?, intent: Intent?) {
                    when (intent?.action) {
                        BluetoothDevice.ACTION_FOUND -> {
                            val device: BluetoothDevice? =
                                    intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
                            device?.let {
                                val deviceInfo = "${it.name ?: "Unknown"} (${it.address})"
                                discoveredDevices.add(deviceInfo)
                                Log.d("Bluetooth", "Device Found: $deviceInfo")
                            }
                        }
                        BluetoothAdapter.ACTION_DISCOVERY_STARTED -> {
                            Log.d("Bluetooth", "Discovery started")
                        }
                        BluetoothAdapter.ACTION_DISCOVERY_FINISHED -> {
                            Log.d(
                                    "Bluetooth",
                                    "Discovery finished. Devices found: $discoveredDevices"
                            )
                        }
                    }
                }
            }

    private val usbReceiver =
            object : BroadcastReceiver() {
                override fun onReceive(context: Context, intent: Intent) {
                    if (ACTION_USB_PERMISSION == intent.action) {
                        synchronized(this) {
                            val device: UsbDevice? =
                                    intent.getParcelableExtra(UsbManager.EXTRA_DEVICE)
                            if (intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)
                            ) {
                                device?.also { initializeUsbDevice(it) }
                            } else {
                                Log.d("USB", "Permission denied for device ${device?.deviceName}")
                            }
                        }
                    } else if (UsbManager.ACTION_USB_DEVICE_DETACHED == intent.action) {
                        val device: UsbDevice? = intent.getParcelableExtra(UsbManager.EXTRA_DEVICE)
                        if (device == usbDevice) {
                            disconnectUsb()
                        }
                    }
                }
            }

    override fun configureFlutterEngine(flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Bluetooth Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call,
                result ->
            when (call.method) {
                "startDiscovery" -> {
                    if (checkPermissions()) {
                        if (bluetoothAdapter?.isDiscovering == true) {
                            bluetoothAdapter.cancelDiscovery()
                        }
                        val isDiscovering = bluetoothAdapter?.startDiscovery() ?: false
                        if (isDiscovering) {
                            Log.d("Bluetooth", "Discovery process successfully started.")
                            result.success("Discovery started")
                        } else {
                            result.error("DISCOVERY_FAILED", "Failed to start discovery", null)
                        }
                    } else {
                        result.error("PERMISSION_DENIED", "Permissions not granted", null)
                    }
                }
                "getDiscoveredDevices" -> {
                    result.success(discoveredDevices)
                }
                "initializeBluetooth" -> {
                    initializeBluetooth(result)
                }
                "getBondedDevices" -> {
                    if (checkPermissions()) {
                        val pairedDevices = bluetoothAdapter?.bondedDevices
                        val devicesList =
                                pairedDevices?.map { device ->
                                    val deviceInfo =
                                            "${device.name ?: "Unknown"} (${device.address})"
                                    Log.d("Bluetooth", "Bonded Device: $deviceInfo")
                                    deviceInfo
                                }
                                        ?: emptyList()
                        result.success(devicesList)
                    } else {
                        result.error("PERMISSION_DENIED", "Permissions not granted", null)
                    }
                }
                "sendData" -> {
                    val dataLines = call.argument<List<String>>("dataLines")

                    try {
                        // Zapri staro povezavo, če obstaja
                        bluetoothSocket?.close()
                        bluetoothSocket = null
                        outputStream = null

                        // Ponovno se poveži
                        bluetoothSocket = currentDevice?.createRfcommSocketToServiceRecord(MY_UUID)
                        bluetoothSocket?.connect()
                        outputStream = bluetoothSocket?.outputStream

                        if (outputStream != null && dataLines != null) {
                            outputStream?.write(" ".toByteArray(Charsets.UTF_8))
                            for (line in dataLines) {
                                handleLine(line, outputStream!!)
                            }
                            outputStream?.flush()
                            outputStream?.write(byteArrayOf(0x1D, 0x56, 0x41, 0x10))
                            outputStream?.flush()
                            activity.runOnUiThread { result.success(null) }
                        } else {
                            result.error("SEND_FAILED", "No device connected or invalid data", null)
                        }
                    } catch (e: IOException) {
                        Log.e("Bluetooth", "Error while sending data", e)
                        activity.runOnUiThread {
                            result.error(
                                    "SEND_FAILED",
                                    "Error while sending data: ${e.message}",
                                    e.message
                            )
                        }
                    }
                }
                "connectToDevice" -> {
                    val deviceAddress = call.argument<String>("deviceAddress")
                    if (deviceAddress != null) {
                        try {
                            Log.d("Bluetooth", "Connecting to device: $deviceAddress")
                            val device = bluetoothAdapter?.getRemoteDevice(deviceAddress)
                            if (device != null) {
                                currentDevice = device
                                bluetoothSocket = device.createRfcommSocketToServiceRecord(MY_UUID)
                                bluetoothSocket?.connect()
                                outputStream = bluetoothSocket?.outputStream
                                startKeepAlive()

                                Log.d("Bluetooth", "Connected to ${device.name}")
                                result.success("Connected to device")
                            } else {
                                result.error("INVALID_DEVICE", "Device not found", null)
                            }
                        } catch (e: IOException) {
                            result.error("CONNECTION_FAILED", "Connection failed", e.message)
                        }
                    } else {
                        result.error("INVALID_PARAMETER", "Device address not provided", null)
                    }
                }
                "isBluetoothConnected" -> {
                    result.success(isBluetoothConnected())
                }
                "isBluetoothEnabled" -> {
                    result.success(isBluetoothEnabled())
                }
                else -> result.notImplemented()
            }
        }

        // USB Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, USB_CHANNEL)
                .setMethodCallHandler { call, result ->
                    when (call.method) {
                        "connectUsbPrinter" -> {
                            connectUsbPrinter(result)
                        }
                        "sendDataUsb" -> {
                            val data = call.argument<List<String>>("dataLines")
                            if (data != null) {
                                sendDataUsb(data, result)
                            } else {
                                result.error("INVALID_ARGUMENT", "Data argument is null", null)
                            }
                        }
                        "printQrCodeUsb" -> {
                            val qrCodeData = call.argument<String>("qrCodeData")
                            if (qrCodeData != null) {
                                printQrCodeTextUsb(qrCodeData, result)
                            } else {
                                result.error("INVALID_ARGUMENT", "QR Code data is null", null)
                            }
                        }
                        "disconnectUsb" -> {
                            disconnectUsb()
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                }

        // Register Bluetooth receiver
        val filter =
                IntentFilter().apply {
                    addAction(BluetoothDevice.ACTION_FOUND)
                    addAction(BluetoothAdapter.ACTION_DISCOVERY_STARTED)
                    addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED)
                }
        registerReceiver(discoveryReceiver, filter)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(discoveryReceiver, filter, Context.RECEIVER_EXPORTED)
        } else {
            registerReceiver(discoveryReceiver, filter)
        }
        // Register USB receiver
        val filterUsb = IntentFilter(ACTION_USB_PERMISSION)
        filterUsb.addAction(UsbManager.ACTION_USB_DEVICE_DETACHED)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(usbReceiver, filterUsb, Context.RECEIVER_EXPORTED)
        } else {
            registerReceiver(usbReceiver, filterUsb)
        }

        usbManager = getSystemService(Context.USB_SERVICE) as UsbManager
    }

    // ----------------------------------Bluetooth---------------------------------------------------
    private fun handleLine(line: String, outputStream: OutputStream) {

        when {
            line.contains("#QRKODA#") -> handleQrCode(line, outputStream)
            line.contains("#VELIKOST-START#") -> handleVelikostStart(outputStream)
            line.contains("#VELIKOST-END#") -> handleVelikostEnd(outputStream)
            else -> {
                outputStream.write((line + "\r\n").toByteArray())
            }
        }
    }

    private fun handleQrCode(line: String, outputStream: OutputStream) {
        var qrCodeData = line.replace("#QRKODA#", "").trim()
        if (qrCodeData.endsWith("#")) {
            qrCodeData = qrCodeData.substring(0, qrCodeData.length - 1)
        }
        // Remove newline characters
        qrCodeData = qrCodeData.replace("\n", "").replace("\r", "")

        if (qrCodeData.isNotEmpty() && qrCodeData.length <= 400) {
            val toSend = mutableListOf<Byte>()
            when (currentDevice?.name) {
                "InnerPrinter" -> qrCodeInnerPrinter(toSend, qrCodeData)
                "IPosPrinter" -> qrCodeIPosPrinter(toSend, qrCodeData)
                "IPos2Printer" -> qrCodeIPos2Printer(toSend, qrCodeData)
                "BlueTooth Printer" -> qrCodeBlueToothPrinter(toSend, qrCodeData)
                "OM BP" -> qrCodeOmBp(toSend, qrCodeData)
                "P58E" -> qrCodeP58E(toSend, qrCodeData)
                "RPP-02", "RPP02N", "TIMPOS" -> qrCodeRpp(toSend)
                else -> null
            }?.let {
                outputStream.write(toSend.toByteArray())
                outputStream.write("\r\n".toByteArray())
            }
        } else if (qrCodeData.length > 400) {
            val errorMessage =
                    "QR Code data too long. Please check. Backend, ${qrCodeData.length}, $qrCodeData"
            outputStream.write((errorMessage + "\n").toByteArray())
        } else {
            val invalidMessage = "QR Code data is empty or invalid."
            outputStream.write((invalidMessage + "\n").toByteArray())
        }
    }

    private fun handleVelikostStart(outputStream: OutputStream) {
        val largeFontCommand =
                when (currentDevice?.name) {
                    "InnerPrinter", "IPosPrinter", "IPos2Printer", "OM BP" ->
                            byteArrayOf(27, 33, 16)
                    "BlueTooth Printer" -> byteArrayOf(27, 33, 16)
                    "P58E", "RPP-02", "RPP02N", "TimPOS" -> byteArrayOf(27, 33, 88)
                    else -> null
                }
        largeFontCommand?.let { outputStream.write(it) }
    }

    private fun handleVelikostEnd(outputStream: OutputStream) {
        val defaultFontCommand =
                when (currentDevice?.name) {
                    "InnerPrinter", "OM BP" -> byteArrayOf(27, 33, 0)
                    "IPosPrinter", "IPos2Printer", "P58E", "RPP-02", "RPP02N", "TimPOS" ->
                            byteArrayOf(27, 33, 8)
                    "BlueTooth Printer" -> byteArrayOf(27, 33, 8)
                    else -> null
                }
        defaultFontCommand?.let { outputStream.write(it) }
    }

    private fun qrCodeInnerPrinter(
            toSend: MutableList<Byte>,
            qrCodeData: String
    ): MutableList<Byte> {
        // Model
        toSend.addAll(byteArrayOf(29, 40, 107, 4, 0, 49, 65, 50, 0).toList())

        // Size
        toSend.addAll(byteArrayOf(29, 40, 107, 3, 0, 49, 67, 5).toList())

        // Error correction
        toSend.addAll(byteArrayOf(29, 40, 107, 3, 0, 49, 69, 49).toList())

        // Store data
        val qrDataBytes = qrCodeData.toByteArray()
        toSend.addAll(
                byteArrayOf(29, 40, 107, (qrDataBytes.size + 3).toByte(), 0, 49, 80, 48).toList()
        )
        toSend.addAll(qrDataBytes.toList())

        // Print command
        toSend.addAll(byteArrayOf(29, 40, 107, 3, 0, 49, 81, 48).toList())

        return toSend
    }

    private fun qrCodeIPosPrinter(
            toSend: MutableList<Byte>,
            qrCodeData: String
    ): MutableList<Byte> {
        // Error correction
        toSend.addAll(byteArrayOf(29, 40, 107, 3, 0, 49, 69, 49).toList())

        // Store data
        val qrDataBytes = qrCodeData.toByteArray()
        toSend.addAll(
                byteArrayOf(29, 40, 107, (qrDataBytes.size + 3).toByte(), 0, 49, 80, 48).toList()
        )
        toSend.addAll(qrDataBytes.toList())

        // Print command
        toSend.addAll(byteArrayOf(29, 40, 107, 3, 0, 49, 81, 48).toList())
        return toSend
    }

    private fun qrCodeIPos2Printer(
            toSend: MutableList<Byte>,
            qrCodeData: String
    ): MutableList<Byte> {
        // Size
        toSend.addAll(byteArrayOf(29, 40, 107, 3, 0, 49, 67, 8).toList())

        // Error correction
        toSend.addAll(byteArrayOf(29, 40, 107, 3, 0, 49, 69, 49).toList())

        // Store data
        val qrDataBytes = qrCodeData.toByteArray()
        toSend.addAll(
                byteArrayOf(29, 40, 107, (qrDataBytes.size + 3).toByte(), 0, 49, 80, 48).toList()
        )
        toSend.addAll(qrDataBytes.toList())

        // Print command
        toSend.addAll(byteArrayOf(29, 40, 107, 3, 0, 49, 81, 48).toList())

        return toSend
    }

    private fun qrCodeBlueToothPrinter(
            toSend: MutableList<Byte>,
            qrCodeData: String
    ): MutableList<Byte> {

        // 1. Select the model: QR Code Model 2
        toSend.addAll(byteArrayOf(0x1D, 0x28, 0x6B, 0x04, 0x00, 0x31, 0x41, 0x32, 0x00).toList())

        // 2. Set the size:  (value will make it larger or smaller)
        toSend.addAll(
                byteArrayOf(0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x43, 0x05).toList()
        ) // size of 5 is fine

        // 3. Set error correction level: (76=H  - hight error correction)
        toSend.addAll(byteArrayOf(0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x45, 0x4C).toList()) // low

        // 4. Store the data
        val qrDataBytes = qrCodeData.toByteArray(Charsets.UTF_8)
        val dataLength = qrDataBytes.size + 3
        toSend.addAll(
                byteArrayOf(
                                0x1D,
                                0x28,
                                0x6B,
                                dataLength.toByte(),
                                (dataLength shr 8).toByte(),
                                0x31,
                                0x50,
                                0x30
                        )
                        .toList()
        )
        toSend.addAll(qrDataBytes.toList())

        // 5. Print the QR code
        toSend.addAll(byteArrayOf(0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x51, 0x30).toList())

        return toSend
    }

    private fun qrCodeOmBp(toSend: MutableList<Byte>, qrCodeData: String): MutableList<Byte> {
        // Model
        toSend.addAll(byteArrayOf(29, 40, 107, 4, 0, 49, 65, 50, 0).toList())

        // Size
        toSend.addAll(byteArrayOf(29, 40, 107, 3, 0, 49, 67, 5).toList())

        // Error correction
        toSend.addAll(byteArrayOf(29, 40, 107, 3, 0, 49, 69, 49).toList())

        // Store data
        val qrDataBytes = qrCodeData.toByteArray()
        toSend.addAll(
                byteArrayOf(29, 40, 107, (qrDataBytes.size + 3).toByte(), 0, 49, 80, 48).toList()
        )
        toSend.addAll(qrDataBytes.toList())

        // Print command
        toSend.addAll(byteArrayOf(29, 40, 107, 3, 0, 49, 81, 48).toList())
        return toSend
    }

    private fun qrCodeP58E(toSend: MutableList<Byte>, qrCodeData: String): MutableList<Byte> {
        // Model
        toSend.addAll(byteArrayOf(29, 40, 107, 4, 0, 49, 65, 50, 0).toList())

        // Size
        toSend.addAll(byteArrayOf(29, 40, 107, 3, 0, 49, 67, 5).toList())

        // Error correction
        toSend.addAll(byteArrayOf(29, 40, 107, 3, 0, 49, 69, 49).toList())

        // Store data
        val qrDataBytes = qrCodeData.toByteArray()
        toSend.addAll(
                byteArrayOf(29, 40, 107, (qrDataBytes.size + 3).toByte(), 0, 49, 80, 48).toList()
        )
        toSend.addAll(qrDataBytes.toList())

        // Print command
        toSend.addAll(byteArrayOf(29, 40, 107, 3, 0, 49, 81, 48).toList())
        return toSend
    }

    private fun qrCodeRpp(toSend: MutableList<Byte>): MutableList<Byte> {
        val command =
                byteArrayOf(
                        29,
                        40,
                        107,
                        3,
                        0,
                        49,
                        67,
                        5, // Size
                        29,
                        40,
                        107,
                        3,
                        0,
                        49,
                        69,
                        49, // Error correction
                        29,
                        40,
                        107,
                        3,
                        0,
                        49,
                        80,
                        48 // Print command
                )
        toSend.addAll(command.toList())
        return toSend
    }

    private fun checkPermissions(): Boolean {
        // For Android 12 and above
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val scanGranted =
                    ContextCompat.checkSelfPermission(
                            this,
                            android.Manifest.permission.BLUETOOTH_SCAN
                    ) == PackageManager.PERMISSION_GRANTED
            val connectGranted =
                    ContextCompat.checkSelfPermission(
                            this,
                            android.Manifest.permission.BLUETOOTH_CONNECT
                    ) == PackageManager.PERMISSION_GRANTED
            Log.d(
                    "Bluetooth",
                    "Permissions: BLUETOOTH_SCAN=$scanGranted, BLUETOOTH_CONNECT=$connectGranted"
            )

            if (!scanGranted || !connectGranted) {
                return false // Return false if permissions are not granted
            }
            return true
        }
        return true // No runtime permission required for below Android 12
    }

    private fun isBluetoothConnected(): Boolean {
        return currentDevice != null && bluetoothAdapter?.isEnabled == true
    }

    private fun isBluetoothEnabled(): Boolean {
        return bluetoothAdapter?.isEnabled == true
    }

    private fun requestBluetoothPermissions() {
        val permissionsToRequest = mutableListOf<String>()

        if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.BLUETOOTH_SCAN) !=
                        PackageManager.PERMISSION_GRANTED
        ) {
            permissionsToRequest.add(android.Manifest.permission.BLUETOOTH_SCAN)
        }

        if (ContextCompat.checkSelfPermission(
                        this,
                        android.Manifest.permission.BLUETOOTH_CONNECT
                ) != PackageManager.PERMISSION_GRANTED
        ) {
            permissionsToRequest.add(android.Manifest.permission.BLUETOOTH_CONNECT)
        }

        if (permissionsToRequest.isNotEmpty()) {
            ActivityCompat.requestPermissions(this, permissionsToRequest.toTypedArray(), 1)
        }
    }

    // Handle permission request results
    override fun onRequestPermissionsResult(
            requestCode: Int,
            permissions: Array<out String>,
            grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        when (requestCode) {
            1 -> {
                var allPermissionsGranted = true
                for (grantResult in grantResults) {
                    if (grantResult != PackageManager.PERMISSION_GRANTED) {
                        allPermissionsGranted = false
                    }
                }
                if (allPermissionsGranted) {
                    Log.d("Bluetooth", "All Bluetooth permissions granted")
                } else {
                    Log.d("Bluetooth", "Bluetooth permissions not granted")
                    // Optionally, show a message to the user or handle the case where permissions
                    // were denied
                }
            }
        }
    }

    private fun initializeBluetooth(result: MethodChannel.Result) {
        if (currentDevice != null) {
            val deviceName = currentDevice?.name ?: ""
            Log.d("Bluetooth", "Initializing printer: $deviceName")
            Thread {
                        var socket: BluetoothSocket? = null
                        var outputStream: OutputStream? = null

                        try {
                            socket = currentDevice?.createRfcommSocketToServiceRecord(MY_UUID)
                            socket?.connect()
                            outputStream = socket?.outputStream

                            val toSend = mutableListOf<Byte>()

                            when {
                                deviceName.contains("IPosPrinter", ignoreCase = true) -> {
                                    toSend.addAll(byteArrayOf(27, 64).toList())
                                }
                                deviceName.contains("IPos2Printer", ignoreCase = true) -> {
                                    toSend.addAll(byteArrayOf(27, 64).toList()) // ESC @
                                }
                                deviceName.contains("BlueTooth Printer", ignoreCase = true) -> {

                                    toSend.addAll(byteArrayOf(27, 33, 5).toList()) // ESC ! 0x05
                                    // }
                                }
                                deviceName.contains("OM BP", ignoreCase = true) -> {
                                    toSend.addAll(byteArrayOf(27, 64).toList()) // ESC @
                                }
                                deviceName.contains("RPP-02", ignoreCase = true) ||
                                        deviceName.contains("RPP02N", ignoreCase = true) ||
                                        deviceName.contains("TimPOS", ignoreCase = true) -> {
                                    toSend.addAll(byteArrayOf(27, 33, 8).toList()) // ESC ! 0x08
                                }
                                deviceName.contains("InnerPrinter", ignoreCase = true) -> {
                                    // No initialization needed as per Delphi code
                                }
                                deviceName.contains("P58E", ignoreCase = true) -> {
                                    // No initialization needed as per Delphi code
                                }
                                else -> {
                                    Log.d(
                                            "Bluetooth",
                                            "Neznan printer: $deviceName. Inicializacija prekinjena"
                                    )
                                }
                            }

                            if (toSend.isNotEmpty()) {
                                outputStream?.write(toSend.toByteArray())
                                outputStream?.flush()
                                Log.d("Bluetooth", "inicializacija poslana na printer")
                            } else {
                                Log.d("Bluetooth", "Naprava ne potrebuje inicializacije")
                            }

                            activity.runOnUiThread { result.success("Inicializacija uspešna.") }
                        } catch (e: IOException) {
                            Log.d("Bluetooth", "Napaka pri inicializaciji $e", e)
                            activity.runOnUiThread {
                                result.error(
                                        "INIT_FAILED",
                                        "Bluetooth initialization failed: ${e.message}",
                                        e.message
                                )
                            }
                        } finally {
                            try {
                                outputStream?.close()
                                socket?.close()
                            } catch (closeException: IOException) {
                                Log.d("Bluetooth", "Napaka pri zapiranju socketa", closeException)
                            }
                        }
                    }
                    .start()
        } else {
            Log.w("Bluetooth", "No device connected. Cannot initialize Bluetooth.")
            result.error("NO_DEVICE", "No device connected.", null)
        }
    }
private var keepAliveExecutor: ScheduledExecutorService? = null

private fun startKeepAlive() {
    stopKeepAlive()

    keepAliveExecutor = Executors.newSingleThreadScheduledExecutor()
    keepAliveExecutor?.scheduleAtFixedRate({
        try {
            if (bluetoothSocket?.isConnected == true) {
                outputStream?.write(byteArrayOf(0x00))
                outputStream?.flush()
            }
        } catch (e: IOException) {
            Log.e("Bluetooth", "KeepAlive error", e)
            stopKeepAlive()
        }
    }, 1, 60, TimeUnit.SECONDS)
}

private fun stopKeepAlive() {
    keepAliveExecutor?.shutdownNow()
    keepAliveExecutor = null
}

    // ----------------------------------USB---------------------------------------------------
    private fun connectUsbPrinter(result: MethodChannel.Result) {
        executorService.execute {
            usbDevice = findUsbPrinter()
            if (usbDevice == null) {
                activity.runOnUiThread {
                    result.error("NO_USB_PRINTER", "No USB printer found", null)
                }
                return@execute
            }

            if (usbManager?.hasPermission(usbDevice) == true) {
                initializeUsbDevice(usbDevice!!)
                activity.runOnUiThread { result.success("USB printer connected") }
            } else {
                val permissionIntent =
                        PendingIntent.getBroadcast(
                                this@MainActivity,
                                0,
                                Intent(ACTION_USB_PERMISSION),
                                PendingIntent.FLAG_IMMUTABLE
                        )
                usbManager?.requestPermission(usbDevice, permissionIntent)
                // Permission result is handled in the usbReceiver
                activity.runOnUiThread { result.success("USB printer Permission requested.") }
            }
        }
    }

    private fun findUsbPrinter(): UsbDevice? {
        usbManager?.deviceList?.values?.forEach { device ->
            // Check device class and interface class to identify printer
            if (device.deviceClass == 0) {
                if (device.interfaceCount > 0 && device.getInterface(0).interfaceClass == 7) {
                    return device
                }
            }
        }
        return null
    }

    private fun initializeUsbDevice(device: UsbDevice) {
        usbInterface = device.getInterface(0)
        for (i in 0 until usbInterface!!.endpointCount) {
            val endpoint = usbInterface!!.getEndpoint(i)
            if (endpoint.type == UsbConstants.USB_ENDPOINT_XFER_BULK) {
                if (endpoint.direction == UsbConstants.USB_DIR_OUT) {
                    usbOutEndpoint = endpoint
                } else {
                    usbInEndpoint = endpoint
                }
            }
        }

        usbConnection = usbManager?.openDevice(device)
        usbConnection?.claimInterface(usbInterface!!, true)
        Log.d("USB", "USB printer initialized")
    }

    private fun sendDataUsb(dataLines: List<String>, result: MethodChannel.Result) {
        if (usbOutEndpoint == null || usbConnection == null) {
            activity.runOnUiThread {
                result.error("NO_USB_CONNECTION", "USB printer not connected", null)
            }
            return
        }

        executorService.execute {
            try {
                for (line in dataLines) {
                    handleLineUsb(line)
                    if (line.contains("Podpis:", ignoreCase = true)) {
                        // Add three empty lines after the "Podpis" line
                        sendDataToUsb("\r\n")
                        sendDataToUsb("\r\n")
                        sendDataToUsb("\r\n")
                    }
                }
                sendDataToUsb("\r\n")
                sendDataToUsb("\r\n")

                 activity.runOnUiThread {
                result.success("Data sent to USB printer")   // ✅ MANJKAJOČI KLIC
            }
            } catch (e: Exception) {
                Log.e("USB", "Error sending data to USB printer", e)
                activity.runOnUiThread {
                    result.error(
                            "USB_SEND_ERROR",
                            "Error sending data to USB printer: ${e.message}",
                            null
                    )
                }
            }
        }
    }

    private fun handleLineUsb(line: String) {
        when {
            line.contains("#VELIKOST-START#") -> handleVelikostStartUsb()
            line.contains("#VELIKOST-END#") -> handleVelikostEndUsb()
            line.contains("#QRKODA#") -> handleQrCodeUsb(line) // Process QR code
            else -> sendDataToUsb(line + "\r\n")
        }
    }
    private fun handleQrCodeUsb(line: String) {
        var qrCodeData = line.replace("#QRKODA#", "").trim()
        if (qrCodeData.endsWith("#")) {
            qrCodeData = qrCodeData.substring(0, qrCodeData.length - 1)
        }
        qrCodeData = qrCodeData.replace("\n", "").replace("\r", "")

        if (qrCodeData.isNotEmpty() && qrCodeData.length <= 400) { // Limit QR code length
            // Adapt the Bluetooth QR code generation here
            // For a generic ESC/POS printer, this is an example:

            val qrCodeBytes = generateEscPosQrCode(qrCodeData)
            sendDataToUsb(qrCodeBytes)
        } else {
            Log.e("USB", "Invalid QR Code Data")
            sendDataToUsb("Invalid QR Code Data\r\n") // Send an error message
        }
    }

    private fun generateEscPosQrCode(data: String): ByteArray {
        val bytes = mutableListOf<Byte>()

        // QR Code: Select the model
        bytes.addAll(byteArrayOf(0x1D, 0x28, 0x6B, 0x04, 0x00, 0x31, 0x41, 0x32, 0x00).toList())

        // QR Code: Set the size
        bytes.addAll(byteArrayOf(0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x43, 0x06).toList()) // Size 6

        // QR Code: Set the error correction level
        bytes.addAll(
                byteArrayOf(0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x45, 0x30).toList()
        ) // Error correction level L

        // QR Code: Store the data
        val dataBytes = data.toByteArray(Charsets.UTF_8)
        val dataLength = dataBytes.size + 3
        bytes.addAll(
                byteArrayOf(
                                0x1D,
                                0x28,
                                0x6B,
                                dataLength.toByte(),
                                (dataLength shr 8).toByte(),
                                0x31,
                                0x50,
                                0x30
                        )
                        .toList()
        )
        bytes.addAll(dataBytes.toList())

        // QR Code: Print the QR code
        bytes.addAll(byteArrayOf(0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x51, 0x30).toList())

        return bytes.toByteArray()
    }
    private fun handleVelikostStartUsb() {
        val largeFontCommand = byteArrayOf(27, 33, 16) // Example command, adjust as needed
        sendDataToUsb(largeFontCommand)
    }

    private fun handleVelikostEndUsb() {
        val defaultFontCommand = byteArrayOf(27, 33, 0) // Example command, adjust as needed
        sendDataToUsb(defaultFontCommand)
    }
    private fun printQrCodeTextUsb(qrCodeData: String, result: MethodChannel.Result) {
        if (usbOutEndpoint == null || usbConnection == null) {
            activity.runOnUiThread {
                result.error("NO_USB_CONNECTION", "USB printer not connected", null)
            }
            return
        }

        executorService.execute {
            try {
                // Uporabi besedilo namesto generiranja QR kode
                val textData = "QR Code Data: $qrCodeData"
                val bytes = textData.toByteArray(Charsets.UTF_8) // Eksplicitno kodiranje UTF-8
                sendDataToUsb(bytes)
                activity.runOnUiThread { result.success("QR code data printed as text via USB") }
            } catch (e: Exception) {
                Log.e("USB", "Error printing QR code data via USB", e)
                activity.runOnUiThread {
                    result.error(
                            "USB_QR_ERROR",
                            "Error printing QR code data via USB: ${e.message}",
                            null
                    )
                }
            }
        }
    }

    private fun sendDataToUsb(data: ByteArray) {
        usbConnection?.bulkTransfer(usbOutEndpoint, data, data.size, 0)
    }

    private fun sendDataToUsb(data: String) {
        val bytes = data.toByteArray(Charsets.UTF_8)
        sendDataToUsb(bytes)
    }

    private fun disconnectUsb() {
        executorService.execute {
            usbConnection?.releaseInterface(usbInterface)
            usbConnection?.close()
            usbConnection = null
            usbInterface = null
            usbOutEndpoint = null
            usbInEndpoint = null
            usbDevice = null
            Log.d("USB", "USB printer disconnected")
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        unregisterReceiver(discoveryReceiver)
        unregisterReceiver(usbReceiver) // Unregister USB receiver
        try {
            outputStream?.close()
            bluetoothSocket?.close()
        } catch (e: IOException) {
            Log.e("Bluetooth", "Error closing socket", e)
        }
        disconnectUsb()
    }

    companion object {
        // Bluetooth
        val MY_UUID: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")

        // USB
        private const val ACTION_USB_PERMISSION = "si.Flop.BiroPOS.USB_PERMISSION"
    }
}
