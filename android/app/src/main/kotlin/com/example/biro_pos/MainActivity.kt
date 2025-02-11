package com.example.biro_pos

import android.bluetooth.*
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.content.*
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.IOException // <-- Added import for IOException
import java.io.OutputStream // <-- Added import for OutputStream
import java.util.UUID // <-- Added import for UUID

class MainActivity : FlutterActivity() {
    private val CHANNEL = "bluetooth_channel"
    private val bluetoothAdapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()
    private val discoveredDevices = mutableListOf<String>()
    private var currentDevice: BluetoothDevice? = null

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

    override fun configureFlutterEngine(flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val filter =
                IntentFilter().apply {
                    addAction(BluetoothDevice.ACTION_FOUND)
                    addAction(BluetoothAdapter.ACTION_DISCOVERY_STARTED)
                    addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED)
                }
        registerReceiver(discoveryReceiver, filter)

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
                    if (currentDevice != null && dataLines != null) {
                        val device = currentDevice

                        // Directly execute on the main thread to show the error immediately
                        // Execute the Bluetooth communication on a separate thread
                        Thread {
                                    var socket: BluetoothSocket? = null
                                    var outputStream: OutputStream? = null

                                    try {
                                        socket = device?.createRfcommSocketToServiceRecord(MY_UUID)
                                        Log.d(
                                                "Bluetooth",
                                                "Connecting to device: ${device?.name} (${device?.address})"
                                        )

                                        val connectThread = Thread {
                                            try {
                                                socket?.connect() // This can block for several
                                                // seconds!
                                            } catch (e: IOException) {
                                                Log.e(
                                                        "Bluetooth",
                                                        "Connection failed immediately",
                                                        e
                                                )
                                            }
                                        }

                                        connectThread.start()
                                        connectThread.join(
                                                2000
                                        ) // Wait max 3 seconds for connection

                                        if (!socket!!.isConnected
                                        ) { // If still not connected, force fail
                                            connectThread.interrupt()
                                            throw IOException("Bluetooth connection timeout")
                                        }

                                        outputStream = socket?.outputStream
                                        if (outputStream == null)
                                                throw IOException("Output stream is null")

                                        outputStream.write(" ".toByteArray(Charsets.UTF_8))
                                        for (line in dataLines) {
                                            handleLine(line, outputStream)
                                        }
                                        outputStream.flush()
                                        outputStream.write(
                                                byteArrayOf(0x1D, 0x56, 0x41, 0x10)
                                        ) // Paper cut command
                                        outputStream.flush()

                                        activity.runOnUiThread {
                                            result.success("Data sent successfully")
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
                                    } finally {
                                        try {
                                            outputStream?.flush()
                                            outputStream?.close()
                                            socket?.takeIf { it.isConnected }?.close()
                                        } catch (closeException: IOException) {
                                            Log.e(
                                                    "Bluetooth",
                                                    "Error closing socket",
                                                    closeException
                                            )
                                        }
                                    }
                                }
                                .start()
                    } else {
                        result.error("SEND_FAILED", "No device connected or invalid data", null)
                    }
                }
                "connectToDevice" -> {
                    val deviceAddress = call.argument<String>("deviceAddress")
                    if (deviceAddress != null) {
                        try {
                            Log.d(
                                    "Bluetooth",
                                    "Attempting to connect to device with address: $deviceAddress"
                            )
                            val device = bluetoothAdapter?.getRemoteDevice(deviceAddress)
                            if (device != null) {
                                Log.d(
                                        "Bluetooth",
                                        "Device object retrieved: ${device.name} (${device.address})"
                                )
                                currentDevice = device
                                try {
                                    Log.d(
                                            "Bluetooth",
                                            "Successfully connected to ${device.name} (${device.address})"
                                    )
                                    result.success("Connected to device")
                                } catch (e: IOException) {
                                    Log.e("Bluetooth", "Socket connection failed", e)
                                    result.error(
                                            "CONNECTION_FAILED",
                                            "Failed to connect to ${device.name}",
                                            e.message
                                    )
                                }
                            } else {
                                Log.e("Bluetooth", "Device with address $deviceAddress not found")
                                result.error("INVALID_DEVICE", "Device not found", null)
                            }
                        } catch (e: IllegalArgumentException) {
                            Log.e("Bluetooth", "Invalid device address: $deviceAddress", e)
                            result.error("INVALID_ADDRESS", "Invalid device address", null)
                        }
                    } else {
                        Log.e("Bluetooth", "Device address not provided")
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
    }

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
        Log.d("Bluetooth", "Generating QR code for BlueTooth Printer...")

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
                requestBluetoothPermissions()
                return false
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

    override fun onDestroy() {
        super.onDestroy()
        // Unregister the receiver when the activity is destroyed
        unregisterReceiver(discoveryReceiver)
    }

    companion object {
        // A predefined UUID for the Bluetooth RFCOMM socket
        val MY_UUID: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
    }
}
