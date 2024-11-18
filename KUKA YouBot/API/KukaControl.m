function kukaControlApp()
    % Declaración de variables globales
    global gripperPub ipAddress rosConectado;
    ipAddress = '192.168.1.150'; % Dirección IP del robot KUKA
    rosConectado = false;        % Estado de conexión ROS

    % Crear la ventana principal
    hFig = figure('Name', 'Control del KUKA YouBot', ...
                  'NumberTitle', 'off', ...
                  'Position', [50, 50, 400, 550], ...
                  'MenuBar', 'none', ...
                  'Resize', 'off');
              
    % Conexión ROS
    uicontrol('Style', 'pushbutton', 'String', 'Conectar ROS', ...
              'Position', [50, 470, 150, 40], ...
              'Callback', @conectarROS);
    uicontrol('Style', 'pushbutton', 'String', 'Desconectar ROS', ...
              'Position', [200, 470, 150, 40], ...
              'Callback', @desconectarROS);

    % Control del gripper
    uicontrol('Style', 'pushbutton', 'String', 'Abrir Pinza', ...
              'Position', [50, 410, 150, 40], ...
              'Callback', @abrirPinza);
    uicontrol('Style', 'pushbutton', 'String', 'Cerrar Pinza', ...
              'Position', [200, 410, 150, 40], ...
              'Callback', @cerrarPinza);

    % Control del brazo
    uicontrol('Style', 'pushbutton', 'String', 'Mover a Coordenada', ...
              'Position', [50, 350, 150, 40], ...
              'Callback', @moverBrazoCoord);
    uicontrol('Style', 'pushbutton', 'String', 'Volver al Origen', ...
              'Position', [200, 350, 150, 40], ...
              'Callback', @volverOrigen);

    % Flechas para mover el carro
    uicontrol('Style', 'pushbutton', 'String', '↑', ...
              'Position', [175, 260, 50, 50], ...
              'Callback', @(~,~) moverCarroCallback(0.3, 0, 0));
    uicontrol('Style', 'pushbutton', 'String', '↓', ...
              'Position', [175, 160, 50, 50], ...
              'Callback', @(~,~) moverCarroCallback(-0.3, 0, 0));
    uicontrol('Style', 'pushbutton', 'String', '←', ...
              'Position', [125, 210, 50, 50], ...
              'Callback', @(~,~) moverCarroCallback(0, -0.3, 0));
    uicontrol('Style', 'pushbutton', 'String', '→', ...
              'Position', [225, 210, 50, 50], ...
              'Callback', @(~,~) moverCarroCallback(0, 0.3, 0));
    uicontrol('Style', 'pushbutton', 'String', '↻', ...
              'Position', [275, 210, 50, 50], ...
              'Callback', @(~,~) moverCarroCallback(0, 0, 0.3));
    uicontrol('Style', 'pushbutton', 'String', '↺', ...
              'Position', [75, 210, 50, 50], ...
              'Callback', @(~,~) moverCarroCallback(0, 0, -0.3));

    % Estado de conexión
    hStatus = uicontrol('Style', 'text', ...
                        'String', 'Estado: Desconectado', ...
                        'Position', [50, 80, 300, 40], ...
                        'FontSize', 12, ...
                        'HorizontalAlignment', 'center');

    % Funciones Callback
    function conectarROS(~, ~)
        try
            rosshutdown;
            rosinit(ipAddress);
            rosConectado = true;
            set(hStatus, 'String', 'Estado: Conectado');
        catch
            set(hStatus, 'String', 'Error al conectar con ROS');
        end
    end

    function desconectarROS(~, ~)
        try
            rosshutdown;
            rosConectado = false;
            set(hStatus, 'String', 'Estado: Desconectado');
        catch
            set(hStatus, 'String', 'Error al desconectar ROS');
        end
    end

    function abrirPinza(~, ~)
        if rosConectado
            gripperPub = rospublisher(...
                '/arm_1/gripper_controller/position_command', ...
                'brics_actuator/JointPositions');
            abrirGripper(gripperPub);
            set(hStatus, 'String', 'Pinza abierta');
        else
            set(hStatus, 'String', 'Conéctate primero a ROS');
        end
    end

    function cerrarPinza(~, ~)
        if rosConectado
            gripperPub = rospublisher(...
                '/arm_1/gripper_controller/position_command', ...
                'brics_actuator/JointPositions');
            cerrarGripper(gripperPub);
            set(hStatus, 'String', 'Pinza cerrada');
        else
            set(hStatus, 'String', 'Conéctate primero a ROS');
        end
    end

    function moverBrazoCoord(~, ~)
        if rosConectado
            moverBrazo([2.8, 0.3, -3, 0.42, 0], 15, ipAddress);
            set(hStatus, 'String', 'Brazo movido a coordenada');
        else
            set(hStatus, 'String', 'Conéctate primero a ROS');
        end
    end

    function volverOrigen(~, ~)
        if rosConectado
            moverBrazo([0.0, 0.0, 0.0, 0.0, 0.0], 15, ipAddress);
            set(hStatus, 'String', 'Brazo vuelto al origen');
        else
            set(hStatus, 'String', 'Conéctate primero a ROS');
        end
    end

    function moverCarroCallback(velX, velY, velTheta)
        if rosConectado
            moverCarro(velX, velY, velTheta, ipAddress, 2);
            set(hStatus, 'String', sprintf(...
                'Carro movido: [%.2f, %.2f, %.2f]', velX, velY, velTheta));
        else
            set(hStatus, 'String', 'Conéctate primero a ROS');
        end
    end
end

