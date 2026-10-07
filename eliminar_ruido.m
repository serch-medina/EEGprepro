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
cancelado = false; % si se cancela toda la revisión

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

    datos = squeeze(double(EEG.data(:,:,ep))); % SQUEEZE APACHURRA DIMENSIONES INNECESARIAS.

    % Es para configurar la separación vertical entre canales. Se grafican
    % TODOS
    escala = max(std(datos,0,2))*5;
    % Operador ' (comilla):
    %-> Transpuesta conjugada
    offsets = (0:EEG.nbchan-1)' * escala; 

    plot(t, gain*datos' + offsets');
    if secs
        xlabel('Tiempo (s)');
    else
        xlabel('Tiempo (ms)');
    end
    
    % === Dibujo de lineas de eventos. ===
    % x0 = EEG.epoch(ep).eventlatency(1); 
    % x0 = x0{1}; % Accedemos a posicion en arreglo
    % tag0 = EEG.epoch(ep).eventtype(1); 
    % tag0 = tag0{1}; % Accedemos a tipo de evento
    % xline(x0, '--r', tag0, 'LabelVerticalAlignment', 'top')

    % Copilot, agrega lineas verticales y de distinto color para el resto
    % de evento y agrega algo de espacio antes y después de las gráficas
    % === Dibujar eventos restantes con colores alternos ===
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
    grid on;

    drawnow;

    % ----- VENTANA GRAFICA DE SELECCIÓN -----
    respuesta = questdlg( ...
        sprintf('¿Qué hacer con la época %d?',ep), ...
        'Revisión de ruido', ...
        'Eliminar','Conservar','Cancelar', ...
        'Conservar');

    switch respuesta

        case 'Eliminar'
            eliminados(end+1) = ep; % NO SE PUEDE PREALOCAR, NO SABEMOS NUMERO DE ELMINADOS DE ANTEMANO

        case 'Conservar'
            % No hacemos nada

        case {'Cancelar',''}
            cancelado = true;
            close(100);
            fprintf('Revisión cancelada. No se eliminó ninguna época.\n');
            return;
    end
end

close(100);

% CREO QUE SERIA MEJOR DEJAR ESTA COMO UNA FUNCION AL FINAL
% ASI SE PODRIA LLAMAR SIN LA INTERFAZ GRAFICA Y PODRIA IMPLEMENTAR MI
% ALGORITMO DE CALCULO DE INDICES PERSONALIZADO. (O SI EL LOG DEL PREPRO
% ESTA VACIO, SOLO APLICAR LA ELIMINACION DIRECTA. 
% ----- Aplicar TODAS las eliminaciones al final -----
if ~isempty(eliminados)

    rej = false(1,EEG.trials);
    rej(eliminados) = true;

    EEG = pop_rejepoch(EEG,rej,0); % Dataset a eliminar, eliminados, 
                                   % mostrar confirmacion, 0 = no
    EEG = eeg_checkset(EEG); % Nos cercioramos de la integridad del 
                             % set de datos
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
    
    register_folder = 'ensayos_por_eliminar';
    register_file = [sujeto '_eventos_eliminados.csv'];
    
    % ==== Modificacion de los registros a eliminar en la psicofisica ====
    actualizar_registro(register_folder,register_file,eliminados,198);

% Sincronizacion. Con esto se confirma la modificacion, en principio.
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG,EEG,CURRENTSET);
end