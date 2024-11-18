function robotinoControlApp()
    %IP por defecto
    ip = 'http://192.168.1.101';

    % Base para la interfaz de usuario
    fig = uifigure('Position', [50, 50, 300, 600], 'Name', 'Control remoto Robotino v4');

    % Titulo de la aplicación
    uilabel(fig, 'Text', 'Robotino v4', 'Position', [90, 580, 280, 22], 'FontSize', 20, 'FontWeight', 'bold');

    uilabel(fig, 'Text', 'Ejemplo de control remoto', 'Position', [60, 555, 280, 22], 'FontSize', 16);

    % Menú desplegable
    selectDropdown = uidropdown(fig, ...
        'Items', {'Robotino 1', 'Robotino 2'}, ...
        'Position', [10, 530, 280, 22], ...
        'Value', 'Robotino 1', ...
        'FontSize', 12, 'FontWeight', 'bold');
    selectDropdown.ValueChangedFcn = @(dd, event) dropdownCallback(dd);

    % Panel de agrupación para los controles
    movementPanel = uipanel(fig, 'Title', 'Controles de Movimiento', ...
        'Position', [10, 300, 280, 200], 'FontSize', 14, 'FontWeight', 'bold');

    % Botón para mover hacia adelante
    btnForward = uibutton(movementPanel, 'push', 'Text', char(9650), 'Position', [115, 120, 50, 50], 'FontSize', 20, 'FontWeight', 'bold');
    btnForward.ButtonPushedFcn = @(btn, event) moveRobotino([1, 0, 0]);
    
    % Botón para mover hacia atrás
    btnBackward = uibutton(movementPanel, 'push', 'Text', char(9660), 'Position', [115, 10, 50, 50], 'FontSize', 20, 'FontWeight', 'bold');
    btnBackward.ButtonPushedFcn = @(btn, event) moveRobotino([-1, 0, 0]);
    
    % Botón para mover hacia la izquierda
    btnLeft = uibutton(movementPanel, 'push', 'Text', char(9664), 'Position', [60, 65, 50, 50], 'FontSize', 20, 'FontWeight', 'bold');
    btnLeft.ButtonPushedFcn = @(btn, event) moveRobotino([0, -1, 0]);
    
    % Botón para mover hacia la derecha
    btnRight = uibutton(movementPanel, 'push', 'Text', char(9654), 'Position', [170, 65, 50, 50], 'FontSize', 20, 'FontWeight', 'bold');
    btnRight.ButtonPushedFcn = @(btn, event) moveRobotino([0, 1, 0]);
    
    % Botón para detener el movimiento
    btnStop = uibutton(movementPanel, 'push', 'Text', char(9632), 'Position', [115, 65, 50, 50], 'FontSize', 28, 'FontWeight', 'bold');
    btnStop.ButtonPushedFcn = @(btn, event) moveRobotino([0, 0, 0]);
    
    % Botón para girar en sentido horario
    btnRotateClockwise = uibutton(movementPanel, 'push', 'Text', char(8635), 'Position', [60, 120, 50, 50], 'FontSize', 28, 'FontWeight', 'bold');
    btnRotateClockwise.ButtonPushedFcn = @(btn, event) moveRobotino([0, 0, -1]);
    
    % Botón para girar en sentido antihorario
    btnRotateCounterClockwise = uibutton(movementPanel, 'push', 'Text', char(8634), 'Position', [170, 120, 50, 50], 'FontSize', 28, 'FontWeight', 'bold');
    btnRotateCounterClockwise.ButtonPushedFcn = @(btn, event) moveRobotino([0, 0, 1]);
    
    % Botón para iniciar la actualización de la imagen
    btnStartImage = uibutton(movementPanel, 'push', 'Text', char(9658), 'Position', [60, 10, 50, 50], 'FontSize', 28, 'FontWeight', 'bold');
    btnStartImage.ButtonPushedFcn = @(btn, event) startImageUpdate();

    % Botón para detener la actualización de la imagen
    btnStopImage = uibutton(movementPanel, 'push', 'Text', '||', 'Position', [170, 10, 50, 50], 'FontSize', 28, 'FontWeight', 'bold');
    btnStopImage.ButtonPushedFcn = @(btn, event) stopImageUpdate();
    
    % Eje para mostrar la imagen
    uilabel(fig, 'Text', 'Webcam', ...
        'Position', [120, 265, 280, 22], 'FontSize', 16);
    ax = uiaxes(fig, 'Position', [10, 10, 280, 250]);
    ax.XTick = [];
    ax.YTick = [];
    
    % Variable para el temporizador
    t = timer('ExecutionMode', 'fixedRate', 'Period', 0.2, 'TimerFcn', @(~,~) updateImage());
    isRequestInProgress = false; % Bandera para verificar si una solicitud está en progreso
    
    % Función para mover el Robotino
    function moveRobotino(command)
        endpoint = '/data/omnidrive';
        response = robotinoAPI(ip, 'POST', endpoint, command);
        disp(response);
    end

    % Función para iniciar la actualización de la imagen
    function startImageUpdate()
        if strcmp(t.Running, 'off')
            start(t);
        end
    end

    % Función para detener la actualización de la imagen
    function stopImageUpdate()
        if strcmp(t.Running, 'on')
            stop(t);
        end
    end

    % Función para actualizar la imagen desde /cam0
    function updateImage()
        % Si hay una solicitud en progreso, no hace nada
        if isRequestInProgress
            return; 
        end
        isRequestInProgress = true; 
     
        endpoint = '/cam0';
        try
            % Obtiene los datos de la imagen desde el servidor
            imgData = robotinoAPI(ip, 'GET', endpoint, []);
            
            % Verifica que el eje aún es válido
            if isvalid(ax) 
                [height, width, ~] = size(imgData);
                ax.XLim = [0 width];
                ax.YLim = [0 height];
                imshow(imgData, 'Parent', ax);
            else
                disp('Eje no válido.');
            end
        catch ME
            if strcmp(ME.identifier, 'MATLAB:webservices:HTTP500StatusCodeError')
                disp('Error 500: No se pudo obtener la imagen de /cam0.');
            else
                disp(['Error inesperado: ', ME.message]);
            end
        end
        isRequestInProgress = false;
    end
    
    %Función para seleccionar los tres posibles robots.
    function dropdownCallback(dd)
        selectedOption = dd.Value;
        switch selectedOption
            case 'Robotino 1'
                ip = 'http://192.168.1.101';
            case 'Robotino 2'
                ip = 'http://192.168.1.107';
        end
    end
end