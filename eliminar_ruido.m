function [ALLEEG, EEG, CURRENTSET, eliminados] = ...
    eliminar_ruido(ALLEEG, EEG, CURRENTSET, noisy_epochs, sujeto, gain,secs)

arguments
    ALLEEG
    EEG
    CURRENTSET
    noisy_epochs
    sujeto
    gain (1,1) = 7.5 % ganancia para aumentar escala de canales
    secs (1,1) = false
end
% YA ELIMINA LO EVENTOS, AL PARECER SI NO SE ASIGNAN TODOS LOS DATOS QUE
% DEBE EXPORTAR LA FUNCION, NO ELIMINA LOS DATOS. MODIFICA EL DATASET 
% ACTUAL, FALTA SALVAR UNA COPIA DEL MISMO. NO SE SI DEBA GUARDAR LOS
% EVENTOS CON EL NUMERO QUE SE SUPONE DEBERÍAN TENER O SI AL FINAL LA IDEA
% SERA REETIQUETAR EN LA PSICOFISICA. 
% La idea si seria guardar con el numero que deberían tener.

eliminados = []; % Vector donde guardaremos los ID de las epocas eliminadas
% cancelado = false; % si se cancela toda la revisión

fs = EEG.srate;
if secs == true
    t = (0:EEG.pnts-1)/fs;
else
    t = 1000*(0:EEG.pnts-1)/fs; % En mili - segundos es más intuitivo
end

for k = 1:numel(noisy_epochs)
    
    % Epoch number
    ep = noisy_epochs(k);

    % ----- GRAFICADO DE LA EPOCA SOSPECHOSA (UNICAMENTE) -----
    figure(100);
    clf;
    % fig = uifigure('Name', 'Visualizador de Datos');
   
    datos = squeeze(double(EEG.data(:,:,ep))); % SQUEEZE APACHURRA 
                                               % DIMENSIONES INNECESARIAS.

    % Es para configurar la separación vertical entre canales. Se grafican
    % TODOS
    escala = max(std(datos,0,2))*5;
    % Operador ' (comilla):
    %-> Transpuesta conjugada
    noc = EEG.nbchan; % number of channels
    offsets = (0:noc-1)' * escala; 
    
    % Personalizacion del color
    grises = linspace(0, 0.6, noc)'; 
    mapa_grises = [grises, grises, grises]; % Matriz de 32xn
    
    ax = gca; % 1. Obtenemos el objeto de los ejes actuales
    ax.NextPlot = 'replacechildren';
    ax.ColorOrder = mapa_grises; 
    
    plot(t, gain*datos' + offsets');
    if secs
        xlabel('Tiempo (s)');
    else
        xlabel('Tiempo (ms)');
    end

    % === Marcar posiciones de eventos registrados en el EEG con colores ===
    eventLatencies = EEG.epoch(ep).eventlatency;
    eventTypes = EEG.epoch(ep).eventtype;
    for evIndx = 1:numel(eventLatencies)
        eventLatency = eventLatencies{evIndx};
        eventType = eventTypes{evIndx};
        s = 1/numel(eventLatencies); % parametro para color
        xline(eventLatency, '--', eventType, ...
            'Color', [(1-s*evIndx),s*(evIndx-1),0.5], 'LabelVerticalAlignment', 'top');
    end
    
    pad = 300; % Espacio extra en los ejes
    xlim([t(1)-pad t(end)+pad]);
    axis tight;
    padding = 0.03 * diff(xlim);
    xlim([t(1)-pad t(end)+pad]);

    ylabel(sprintf('Canales [%.2e V]',(1e-6)/gain));
    title(sprintf( ...
        'Sujeto %s — época sospechosa %d (%d/%d)', ...
        sujeto, ep, k, numel(noisy_epochs)));

    xlim([t(1)-pad t(end)+pad]);
    grid('on');

    drawnow;

    % ----- VENTANA GRAFICA DE SELECCIÓN -----
    
    % msg = sprintf("¿Qué hacer con el ruido de la época? %d", ep);
    % title_name = "Revisión de ruido";
    % 
    % respuesta = uiconfirm(fig, msg, title_name, ...
    %     Options = ["Eliminar", "Conservar", "Cancelar"], ...
    %     DefaultOption = 2,CancelOption = 3);

    respuesta = questdlg( ...
        sprintf('¿Qué hacer con la época %d?',ep), ...
        'Revisión de ruido', ...
        'Eliminar','Conservar','Cancelar', ...
        'Conservar');

    switch respuesta

        case "Eliminar"
            eliminados(end+1) = ep; % NO SE PUEDE PREALOCAR, NO SABEMOS NUMERO DE ELMINADOS DE ANTEMANO

        case "Conservar"
            % No hacemos nada

        case {"Cancelar",''}
            % cancelado = true;
            close(100);
            fprintf('Revisión cancelada. No se eliminó ninguna época.\n');
            return;
        otherwise
            % cancelado = true;
            close(100);
            fprintf("Ninguna operación seleccionada. Cancelando")
            return;
    end
end

close(100);

% ----- TODAS las eliminaciones se aplican al final -----
if ~isempty(eliminados)

    rej = false(1,EEG.trials);
    rej(eliminados) = true;

    EEG = pop_rejepoch(EEG,rej,0); % Dataset a eliminar, eliminados, 
                                   % mostrar confirmacion, 0 = no
    EEG = eeg_checkset(EEG); % Nos cercioramos de la integridad del 
                             % set de datos
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
    
    register_folder = 'ens_por_eliminar';
    register_file = [sujeto '_eventos_eliminados.csv'];
    
    % ==== Modificacion de los registros a eliminar en la psicofisica ====
    actualizar_registro(register_folder,register_file,eliminados,198);

% Sincronizacion. Con esto se confirma la modificacion, en principio.
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG,EEG,CURRENTSET);
end