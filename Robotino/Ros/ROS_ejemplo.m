% Conexión al maestro ROS en 192.168.1.100
rosshutdown;
rosinit('192.168.1.100');

% Crear un suscriptor para el tema 'chatter'
chatterSub = rossubscriber('/chatter', 'std_msgs/String');

% Bucle while para recibir y procesar mensajes
while true
    % Recibir el siguiente mensaje
    try
        msg = receive(chatterSub, 10);
        disp(msg.Data);

    catch ME
        % Manejo de errores
        disp('Ocurrió un error:');
        disp(ME.message);    
    end
    pause(0.1)
       
    % Aquí puedes agregar alguna condición para salir del bucle si lo deseas
    % Por ejemplo, puedes usar una tecla para salir:
    %if strcmpi(input('Presiona "q" y Enter para salir: ', 's'), 'q')
    %     break;
    %end
end

% Desconectar del maestro ROS
rosshutdown;

