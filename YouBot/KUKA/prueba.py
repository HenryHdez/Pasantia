import matlab.engine

# Iniciar el motor de MATLAB
eng = matlab.engine.start_matlab()

# Configurar la IP (en caso de necesitar cambiarla dinámicamente)
ipAddress = '192.168.1.150'
eng.workspace['ipAddress'] = ipAddress

# Ejecutar el script `rutina_robotino.m`
try:
    eng.moverCarroPorCoordenadas(nargout=0)  # Ejecuta el script sin capturar salida
except Exception as e:
    print("Error al ejecutar la rutina:", e)

# Cerrar el motor de MATLAB cuando termines
eng.quit()
