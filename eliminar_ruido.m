function [ALLEEG, EEG, CURRENTSET, eliminados] = ...
    eliminar_ruido(ALLEEG, EEG, CURRENTSET, noisy_epochs, sujeto, gain,secs,del_direct)
%ELIMINAR_RUIDO - Revisa épocas ruidosas y elimina las seleccionadas
%
% Input arguments:
%   ALLEEG      - conjuntos EEG acumulado de EEGLAB
%   EEG         - dataset EEG actual
%   CURRENTSET   - índice del dataset actual
%   noisy_epochs - índices de épocas sospechosas
%   sujeto      - identificador del sujeto
%   gain        - ganancia para escalar la visualización
%   secs        - usa segundos en vez de milisegundos
%   del_direct  - si es 'true': elimina directamente las épocas indicadas
%
% Output arguments:
%   ALLEEG      - conjuntos EEG actualizados
%   EEG         - dataset EEG actualizado
%   CURRENTSET  - índice actualizado del dataset
%   eliminados  - épocas finalmente eliminadas
% Funcion encargada de mostrar la interfaz grafica para seleccionar eventos
% potencialmente ruidosos.
% BUG: NO SE DEBE SELECCIONAR CON LA TECLA TABULADOR, DE LO CONTRARIO LA
% OPCION SELECCIONADA SERA DISTINTA A LA DESEADA. ERROR proveniente de
% questdlg

arguments
    ALLEEG
    EEG
    CURRENTSET
    noisy_epochs
    sujeto
    gain (1,1) = 7.5 % ganancia para aumentar escala de canales
    secs (1,1) = false
    del_direct = false % Option used to directly delete a serie of events
end

% Omitir revisión interactiva si la eliminación es directa
if del_direct
    rej = false(1,EEG.trials);
    rej(noisy_epochs) = true;

    EEG = pop_rejepoch(EEG,rej,0); % Dataset a eliminar, eliminados, 
    % mostrar confirmacion, 0 = no
    EEG = eeg_checkset(EEG); % Nos cercioramos de la integridad del 
    % set de datos
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);

    register_folder = 'ens_por_eliminar';
    register_file = [sujeto '_eventos_eliminados.csv'];

    % ==== Modificacion de los registros a eliminar en la psicofisica ====
    actualizar_registro(register_folder,register_file,eliminados,198);
end

eliminados = []; % Vector donde guardaremos los ID de las epocas eliminadas
% cancelado = false; % si se cancela toda la revisión

% Preparar eje temporal según la unidad solicitada
fs = EEG.srate;
if secs == true
    t = (0:EEG.pnts-1)/fs;
else
    t = 1000*(0:EEG.pnts-1)/fs; % En mili - segundos es más intuitivo
end

% Revisar cada época marcada como ruidosa
for k = 1:numel(noisy_epochs)
    
    % Epoch number
    ep = noisy_epochs(k);

    % ----- GRAFICADO DE LA EPOCA SOSPECHOSA (UNICAMENTE) -----
    figure(100);
    clf;
   
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

    ylabel(sprintf('Canales [%.2e V]',(1e-6)/gain));
    title(sprintf( ...
        'Sujeto %s — época sospechosa %d (%d/%d)', ...
        sujeto, ep, k, numel(noisy_epochs)));

    pad = 300; % Espacio extra en los ejes
    axis tight; % establece los limites a los datos (en x;y)
    xlim([t(1)-pad t(end)+pad]); %  cambiamos los limites de x.
    grid('on');

    drawnow;

    % ----- VENTANA GRAFICA DE SELECCIÓN -----
   
    respuesta = questdlg( ...
        sprintf('¿Qué hacer con la época %d?',ep), ...
        'Revisión de ruido', ...
        'Eliminar','Conservar','Cancelar', ...
        'Eliminar');
        disp(respuesta);
    switch respuesta
        case 'Eliminar'
            eliminados(end+1) = ep; % NO SE PUEDE PREALOCAR, NO SABEMOS NUMERO DE ELMINADOS DE ANTEMANO
            disp(eliminados);
        case 'Conservar'
            % No hacemos nada
            continue;
        case {'Cancelar',''}
            % cancelado = true;
            close(100);
            fprintf('Revisión cancelada. No se eliminó ninguna época.\n');
            return;
        % otherwise
        % %     cancelado = true;
        %     close(100);
        %     fprintf("Ninguna operación seleccionada. Cancelando")
        %     return;
    end
end

close(100);

% Aplicar todas las eliminaciones acumuladas al finalizar la revisión
disp(eliminados)
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
end