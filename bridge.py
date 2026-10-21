import serial
import asyncio
import websockets

# Remplacez 'COM3' par le port de votre Arduino
ser = serial.Serial('COM4', 9600, timeout=1)

async def send_joystick_data(websocket):
    while True:
        if ser.in_waiting > 0:
            line = ser.readline().decode('utf-8').strip()
            if line:
                await websocket.send(line)
        await asyncio.sleep(0.01)

async def main():
    async with websockets.serve(send_joystick_data, "localhost", 8080):
        print("Serveur WebSocket démarré sur ws://localhost:8080")
        await asyncio.Future()  # tourne indéfiniment

if __name__ == "__main__":
    asyncio.run(main())