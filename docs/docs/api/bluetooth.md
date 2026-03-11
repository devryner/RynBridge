---
sidebar_position: 20
---

# Bluetooth Module API

`@rynbridge/bluetooth` — Bluetooth Low Energy (BLE) scanning, connection, and data transfer.

## Setup

```typescript
import { BluetoothModule } from '@rynbridge/bluetooth';

const bluetooth = new BluetoothModule(bridge);
```

## Methods

### `startScan(payload?): Promise<void>`

Starts scanning for nearby BLE devices.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `serviceUUIDs` | `string[]` | No | Filter by service UUIDs |
| `timeout` | `number` | No | Scan timeout in seconds |

```typescript
await bluetooth.startScan({ serviceUUIDs: ['180D'], timeout: 10 });
```

### `stopScan(): Promise<void>`

Stops the current BLE scan.

```typescript
await bluetooth.stopScan();
```

### `connect(payload): Promise<ConnectionResult>`

Connects to a BLE device.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `deviceId` | `string` | Yes | Device identifier |

```typescript
const result = await bluetooth.connect({ deviceId: 'AA:BB:CC:DD:EE:FF' });
// { connected: true, deviceId: 'AA:BB:CC:DD:EE:FF' }
```

### `disconnect(payload): Promise<void>`

Disconnects from a BLE device.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `deviceId` | `string` | Yes | Device identifier |

```typescript
await bluetooth.disconnect({ deviceId: 'AA:BB:CC:DD:EE:FF' });
```

### `discoverServices(payload): Promise<ServiceList>`

Discovers services on a connected BLE device.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `deviceId` | `string` | Yes | Device identifier |

```typescript
const { services } = await bluetooth.discoverServices({ deviceId: 'AA:BB:CC:DD:EE:FF' });
```

### `read(payload): Promise<ReadResult>`

Reads a characteristic value.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `deviceId` | `string` | Yes | Device identifier |
| `serviceUUID` | `string` | Yes | Service UUID |
| `characteristicUUID` | `string` | Yes | Characteristic UUID |

```typescript
const { value } = await bluetooth.read({
  deviceId: 'AA:BB:CC:DD:EE:FF',
  serviceUUID: '180D',
  characteristicUUID: '2A37',
});
```

### `write(payload): Promise<void>`

Writes a value to a characteristic.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `deviceId` | `string` | Yes | Device identifier |
| `serviceUUID` | `string` | Yes | Service UUID |
| `characteristicUUID` | `string` | Yes | Characteristic UUID |
| `value` | `string` | Yes | Base64-encoded value |

```typescript
await bluetooth.write({
  deviceId: 'AA:BB:CC:DD:EE:FF',
  serviceUUID: '180D',
  characteristicUUID: '2A39',
  value: 'AQ==',
});
```

### `onDeviceDiscovered(listener): () => void`

Subscribes to discovered devices during scan.

```typescript
const unsub = bluetooth.onDeviceDiscovered((device) => {
  console.log(device.name, device.id, device.rssi);
});
```

### `onDisconnected(listener): () => void`

Subscribes to device disconnection events.

```typescript
const unsub = bluetooth.onDisconnected(({ deviceId }) => {
  console.log('Disconnected:', deviceId);
});
```

## Types

```typescript
interface ScanPayload {
  serviceUUIDs?: string[];
  timeout?: number;
}

interface ConnectionResult {
  connected: boolean;
  deviceId: string;
}

interface BleDevice {
  id: string;
  name: string | null;
  rssi: number;
}

interface BleService {
  uuid: string;
  characteristics: BleCharacteristic[];
}

interface BleCharacteristic {
  uuid: string;
  properties: string[];
}

interface ServiceList {
  services: BleService[];
}

interface ReadResult {
  value: string;
}
```

## Native Provider

| Platform | Protocol/Interface | Default Provider |
|----------|-------------------|-----------------|
| iOS | `BluetoothProvider` | `DefaultBluetoothProvider` (CoreBluetooth) |
| Android | `BluetoothProvider` | `DefaultBluetoothProvider` (BLE Scanner/GATT) |
