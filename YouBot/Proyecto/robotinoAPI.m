function response = robotinoAPI(ip, method, endpoint, data)
    % robotinoAPI - Interfaz para interactuar con la API de Robotino.
    % 
    % ip: Dirección IP del Robotino (por ejemplo, 'http://192.168.1.100').
    % method: 'GET', 'PUT', 'POST'
    % endpoint: La URL del endpoint (por ejemplo, '/data/odometry').
    % data: Vector o estructura de datos a enviar en caso de PUT o POST (dejar vacío para GET).
    %
    % Ejemplos de uso:
    % 1. Solicitudes GET
    %    - response = robotinoAPI('http://192.168.1.100', 'GET', '/cam0', []);
    %    - response = robotinoAPI('http://192.168.1.100', 'GET', '/sensorimage', []);
    %    - response = robotinoAPI('http://192.168.1.100', 'GET', '/data/powermanagement', []);
    %    - response = robotinoAPI('http://192.168.1.100', 'GET', '/data/charger0', []);
    %    - response = robotinoAPI('http://192.168.1.100', 'GET', '/data/charger1', []);
    %    - response = robotinoAPI('http://192.168.1.100', 'GET', '/data/controllerinfo', []);
    %    - response = robotinoAPI('http://192.168.1.100', 'GET', '/data/services', []);
    %    - response = robotinoAPI('http://192.168.1.100', 'GET', '/data/servicestatus/xxx', []); % xxx es un placeholder
    %    - response = robotinoAPI('http://192.168.1.100', 'GET', '/data/analoginputarray', []);
    %    - response = robotinoAPI('http://192.168.1.100', 'GET', '/data/digitalinputarray', []);
    %    - response = robotinoAPI('http://192.168.1.100', 'GET', '/data/digitaloutputstatus', []);
    %    - response = robotinoAPI('http://192.168.1.100', 'GET', '/data/relaystatus', []);
    %    - response = robotinoAPI('http://192.168.1.100', 'GET', '/data/bumper', []);
    %    - response = robotinoAPI('http://192.168.1.100', 'GET', '/data/distancesensorarray', []);
    %    - response = robotinoAPI('http://192.168.1.100', 'GET', '/data/scan0', []);
    %    - response = robotinoAPI('http://192.168.1.100', 'GET', '/data/odometry', []);
    %    - response = robotinoAPI('http://192.168.1.100', 'GET', '/data/imageversion', []);
    %    - response = robotinoAPI('http://192.168.1.100', 'GET', '/data/poweroutputcurrent', []);
    %
    % 2. Solicitudes PUT o POST con estructuras
    %    - response = robotinoAPI('http://192.168.1.100', 'POST', '/data/digitaloutput', struct('outputId', 1, 'value', 1));
    %    - response = robotinoAPI('http://192.168.1.100', 'POST', '/data/digitaloutputarray', struct('outputs', [1, 0, 1, 1]));
    %    - response = robotinoAPI('http://192.168.1.100', 'POST', '/data/relay', struct('relayId', 1, 'value', 1));
    %    - response = robotinoAPI('http://192.168.1.100', 'POST', '/data/relayarray', struct('relays', [1, 0, 1, 1]));
    %
    % 3. Solicitudes PUT o POST con vectores
    %    - response = robotinoAPI('http://192.168.1.100', 'POST', '/data/omnidrive', [vx, vy, omega]);
    
    % Crear la URL completa
    url = [ip, endpoint];

    % Crear opciones de la solicitud
    options = weboptions('MediaType', 'application/json');
    
    % Hacer la solicitud según el método
    switch upper(method)
        case 'GET'
            response = webread(url, options);
        case {'PUT', 'POST'}
            if isempty(data)
                error('Se requieren datos para métodos PUT o POST.');
            end
            
            % Verificar si los datos son un vector o una estructura
            if isstruct(data)
                response = webwrite(url, data, options);
            elseif isnumeric(data) || ischar(data)
                % Si es un vector numérico o una cadena, enviarlo directamente
                response = webwrite(url, data);
            else
                error('Tipo de dato no soportado para PUT/POST.');
            end
        otherwise
            error('Método no soportado. Usa GET, PUT o POST.');
    end
end
