clc;
clear;


% Parámetros del carro
ipAddress = '192.168.1.150'; % IP del Robot
velocidadLineal = 0.2; % Velocidad de avance en m/s
velocidadAngular = 0.2; % Velocidad de giro en rad/s
distanciaUmbral = 75; % Umbral de proximidad en mm
longitudFrente = 50; % Longitud del indicador de frente en mm

    % Cerrar cualquier conexión ROS activa
    rosshutdown;
    
    % Conectar a ROS
    disp('Iniciando conexión ROS...');
    try
        rosinit(ipAddress);
        pause(1); % Pausa para asegurar que la conexión esté completamente activa
    catch
        error('No se pudo conectar a ROS en la dirección IP proporcionada.');
    end

% Definir coordenadas (x, y) en milímetros
coordenadas = [0, 0; 0, 500; 500, 500; 500, 0; 0, 0];

% Configurar el gráfico
figure;
plot(coordenadas(:, 1), coordenadas(:, 2), 'bo-', 'LineWidth', 2); % Ruta completa
hold on;
title('Avance del Carro en Tiempo Real');
xlabel('Posición X (mm)');
ylabel('Posición Y (mm)');
grid on;

% Punto de inicio del robot en el gráfico
robotPlot = plot(coordenadas(1, 1), coordenadas(1, 2), 'ro', 'MarkerFaceColor', 'r');
frentePlot = plot([coordenadas(1, 1), coordenadas(1, 1) + longitudFrente], [coordenadas(1, 2), coordenadas(1, 2)], 'r-', 'LineWidth', 1.5); % Línea que indica el frente
legend('Ruta Definida', 'Posición Actual del Carro', 'Frente del Robot');

% Mover el carro entre las coordenadas
anguloActual = 0; % Ángulo inicial del robot (supuesto como 0)
for i = 1:size(coordenadas, 1) - 1
    % Obtener las posiciones inicial y final
    inicio = coordenadas(i, :);
    destino = coordenadas(i + 1, :);
    
    % Calcular el ángulo de rotación hacia el punto destino
    deltaX = destino(1) - inicio(1);
    deltaY = destino(2) - inicio(2);
    anguloObjetivo = atan2(deltaY, deltaX); % Ángulo necesario en radianes

    % Girar el robot hasta el ángulo deseado en pasos pequeños
    while abs(anguloObjetivo - anguloActual) > 0.05 % Umbral de tolerancia para el ángulo
        % Calcular la velocidad de giro
        errorAngular = anguloObjetivo - anguloActual;
        velocidadGiro = sign(errorAngular) * max(abs(errorAngular), 0.2) * velocidadAngular;

        % Enviar comando de giro
        moverCarro(0, 0, velocidadGiro, 2, ipAddress);
        
        % Actualizar el ángulo actual del robot
        anguloActual = anguloActual + velocidadGiro*2; % Incremento de ángulo en cada iteración

        % Actualizar el gráfico con el nuevo frente del robot
        frenteX = inicio(1) + longitudFrente * cos(anguloActual);
        frenteY = inicio(2) + longitudFrente * sin(anguloActual);
        set(frentePlot, 'XData', [inicio(1), frenteX], 'YData', [inicio(2), frenteY]);
        drawnow; % Actualizar el gráfico en tiempo real

        pause(1); % Pausa para la actualización simultánea
    end
    
    % Avanzar en línea recta hacia el destino
    while true
        % Calcular la distancia restante al destino en mm
        distanciaRestante = sqrt((destino(1) - inicio(1))^2 + (destino(2) - inicio(2))^2);
        
        % Si la distancia es menor al umbral, consideramos que llegó al punto
        if distanciaRestante < distanciaUmbral
            break;
        end
        
        % Calcular la velocidad de avance en mm/s y convertirla a m/s
        velocidadAvance = max(velocidadLineal, 0.25); % Velocidad en m/s
        
        % Enviar comando para avanzar en línea recta
        moverCarro(velocidadAvance, 0, 0, 1, ipAddress);
        
        % Convertir el avance en m/s a mm en cada paso de 0.1 s
        avanceMM = velocidadAvance * 1000 *0.5; % Convertir a mm
        
        % Actualizar la posición del robot en el gráfico y su frente
        inicio(1) = inicio(1) + avanceMM * cos(anguloActual);
        inicio(2) = inicio(2) + avanceMM * sin(anguloActual);
        set(robotPlot, 'XData', inicio(1), 'YData', inicio(2));
        
        % Actualizar la línea del frente del robot
        frenteX = inicio(1) + longitudFrente * cos(anguloActual);
        frenteY = inicio(2) + longitudFrente * sin(anguloActual);
        set(frentePlot, 'XData', [inicio(1), frenteX], 'YData', [inicio(2), frenteY]);
        
        drawnow; % Actualizar el gráfico en tiempo real
        
        pause(1); % Pausar para que el robot se desplace en tiempo real
    end
end
moverCarro(0, 0, 0, 1, '192.168.1.150');
disp('El carro ha completado la ruta.');

hold off;
