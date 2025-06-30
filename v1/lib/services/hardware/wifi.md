# Wi-Fi Service Specification

This document outlines the API for managing Wi-Fi connections on a Luna device.

## Connect to a Wi-Fi Network

Connects the Luna device to a specified Wi-Fi network.

**Endpoint:** `/wifi/connect`
**Method:** `POST`
**Request Body (JSON):**
```json
{
  "ssid": "your_wifi_name",
  "password": "your_wifi_password"
}
```

**Response:**
- `200 OK`: If the connection process is initiated successfully.
- `400 Bad Request`: If the SSID or password is not provided.
- `500 Internal Server Error`: If the device fails to connect.

## Usage Example

To connect a Luna device at IP `192.168.1.100` to a network, send a POST request to `http://192.168.1.100:1306/wifi/connect` with the appropriate JSON body.