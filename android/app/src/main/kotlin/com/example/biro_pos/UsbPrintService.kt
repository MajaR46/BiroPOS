package si.flop.BiroPOSF

import android.content.Context
import android.hardware.usb.*
import android.util.Log

class UsbPrintService(private val context: Context) {
    private val usbManager: UsbManager = context.getSystemService(Context.USB_SERVICE) as UsbManager
    private val ACTION_USB_PERMISSION = "com.example.yourapp.USB_PERMISSION"

    fun printData(data: ByteArray): Boolean {
        val deviceList = usbManager.deviceList
        val device = deviceList.values.firstOrNull() ?: return false

        val connection: UsbDeviceConnection? = usbManager.openDevice(device)
        val endpoint =
                device.interfaceCount.let { ifaceIndex ->
                    val iface = device.getInterface(ifaceIndex - 1)
                    iface.getEndpoint(0)
                }

        return try {
            val usbEndpoint = endpoint as UsbEndpoint
            val usbConnection = usbManager.openDevice(device) ?: return false
            usbConnection.claimInterface(device.getInterface(0), true)
            usbConnection.bulkTransfer(usbEndpoint, data, data.size, 1000) > 0
        } catch (e: Exception) {
            Log.e("UsbPrintService", "Print failed", e)
            false
        }
    }
}
