import asyncio
import websockets
import json

async def enviar_comando():
    # Conectar al servidor WebSocket en el equipo remoto con ROS
    uri = "ws://192.168.1.150:11311"  # Asegúrate de que esta IP y puerto sean correctos
    async with websockets.connect(uri) as websocket:
        
        # Crear el mensaje para mover articulaciones
        comando = {
            "op": "publish",
            "topic": "/arm_1/arm_controller/follow_joint_trajectory/goal",
            "msg": {
                "goal": {
                    "trajectory": {
                        "joint_names": ["arm_joint_1", "arm_joint_2", "arm_joint_3", "arm_joint_4", "arm_joint_5"],
                        "points": [
                            {
                                "positions": [0.5, 0.5, 0.5, 0.5, 0.5],
                                "velocities": [0.1, 0.1, 0.1, 0.1, 0.1],
                                "time_from_start": {"secs": 5, "nsecs": 0}
                            }
                        ]
                    }
                }
            }
        }
        
        # Enviar el mensaje al servidor ROS
        await websocket.send(json.dumps(comando))
        print("Comando enviado para mover las articulaciones.")

# Ejecutar la función asíncrona
asyncio.get_event_loop().run_until_complete(enviar_comando())
