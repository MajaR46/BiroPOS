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
                            Log.d("Bluetooth", "Discovery finished")
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
                        val pairedDevices: Set<BluetoothDevice>? = bluetoothAdapter?.bondedDevices
                        val devicesList =
                                pairedDevices?.map { device ->
                                    "${device.name ?: "Unknown"} (${device.address})"
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
                        val socket = currentDevice?.createRfcommSocketToServiceRecord(MY_UUID)
                        try {
                            socket?.connect()
                            val outputStream: OutputStream? = socket?.outputStream

                            if (outputStream != null) {
                                for (line in dataLines) {
                                    when {
                                        line.contains("#QRKODA#") -> {
                                            var qrCodeData = line.replace("#QRKODA#", "").trim()
                                            if (qrCodeData.endsWith("#")) {
                                                qrCodeData =
                                                        qrCodeData.substring(
                                                                0,
                                                                qrCodeData.length - 1
                                                        )
                                            }
                                            if (qrCodeData.isNotEmpty() && qrCodeData.length <= 400
                                            ) {

                                                val toSend = mutableListOf<Byte>()

                                                // Model
                                                toSend.addAll(
                                                        byteArrayOf(
                                                                        29,
                                                                        40,
                                                                        107,
                                                                        4,
                                                                        0,
                                                                        49,
                                                                        65,
                                                                        50,
                                                                        0
                                                                )
                                                                .toList()
                                                )

                                                // Size
                                                toSend.addAll(
                                                        byteArrayOf(29, 40, 107, 3, 0, 49, 67, 5)
                                                                .toList()
                                                )

                                                // Error correction
                                                toSend.addAll(
                                                        byteArrayOf(29, 40, 107, 3, 0, 49, 69, 49)
                                                                .toList()
                                                )

                                                // Store data
                                                val qrDataBytes = qrCodeData.toByteArray()
                                                toSend.addAll(
                                                        byteArrayOf(
                                                                        29,
                                                                        40,
                                                                        107,
                                                                        (qrDataBytes.size + 3)
                                                                                .toByte(),
                                                                        0,
                                                                        49,
                                                                        80,
                                                                        48
                                                                )
                                                                .toList()
                                                )
                                                toSend.addAll(qrDataBytes.toList())

                                                // Print command
                                                toSend.addAll(
                                                        byteArrayOf(29, 40, 107, 3, 0, 49, 81, 48)
                                                                .toList()
                                                )

                                                // Write to the printer's output stream
                                                outputStream.write(toSend.toByteArray())
                                                outputStream.write("\r\n".toByteArray())
                                            } else if (qrCodeData.length > 400) {
                                                val errorMessage =
                                                        "QR Code data too long. Please check. Backend, ${qrCodeData.length}, $qrCodeData"
                                                outputStream.write(
                                                        (errorMessage + "\n").toByteArray()
                                                )
                                            } else {
                                                val invalidMessage =
                                                        "QR Code data is empty or invalid."
                                                outputStream.write(
                                                        (invalidMessage + "\n").toByteArray()
                                                )
                                            }
                                        }
                                        line.contains("#VELIKOST-START#") -> {
                                            val largeFontCommand =
                                                    byteArrayOf(
                                                            27,
                                                            33,
                                                            16
                                                    ) // Alternative for double width/height
                                            outputStream.write(largeFontCommand)
                                        }
                                        line.contains("#VELIKOST-END#") -> {
                                            val defaultFontCommand = byteArrayOf(27, 33, 0)
                                            outputStream.write(defaultFontCommand)
                                        }
                                        else -> {
                                            // Append line feed or carriage return as needed
                                            outputStream.write((line + "\r\n").toByteArray())
                                        }
                                    }
                                }

                                outputStream.write(
                                        byteArrayOf(0x1D, 0x56, 0x41, 0x10)
                                ) // Paper cut command

                                result.success("Data sent successfully")
                            } else {
                                result.error("SEND_FAILED", "Output stream is null", null)
                            }
                            socket?.close()
                        } catch (e: IOException) {
                            Log.e("Bluetooth", "Error while sending data", e)
                            result.error(
                                    "SEND_FAILED",
                                    "Error while sending data: ${e.message}",
                                    null
                            )
                        }
                    } else {
                        result.error("SEND_FAILED", "No device connected or invalid data", null)
                    }
                }
                "connectToDevice" -> {
                    val deviceAddress = call.argument<String>("deviceAddress")
                    if (deviceAddress != null) {
                        val device = bluetoothAdapter?.getRemoteDevice(deviceAddress)
                        if (device != null) {
                            currentDevice = device
                            val socket = device.createRfcommSocketToServiceRecord(MY_UUID)
                            try {
                                socket.connect()
                                result.success("Connected to device")
                            } catch (e: IOException) {
                                Log.e("Bluetooth", "Connection failed", e)
                                result.error("CONNECTION_FAILED", "Failed to connect", null)
                            }
                        } else {
                            result.error("INVALID_DEVICE", "Device not found", null)
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
        val MY_UUID: UUID = UUID.fromString("00001101-0000-1000-8000-00805f9b34fb")
    }
}
