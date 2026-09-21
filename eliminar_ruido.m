function [ALLEEG, EEG, CURRENTSET, eliminados] = ...
    eliminar_ruido(ALLEEG, EEG, CURRENTSET, noisy_epochs, sujeto, secs)

arguments
    ALLEEG
    EEG
    CURRENTSET
    noisy_epochs
    sujeto
    secs (1,1) = false
end
% YA ELIMINA LO EVENTOS, AL PARECER SI NO SE ASIGNAN TODOS LOS DATOS QUE
% DEBE EXPORTAR LA FUNCION, NO ELIMINA LOS DATOS. MODIFICA EL DATASET 
% ACTUAL, FALTA SALVAR UNA COPIA DEL MISMO. NO SE SI DEBA GUARDAR LOS
% EVENTOS CON EL NUMERO QUE SE SUPONE DEBERÍAN TENER O SI AL FINAL LA IDEA
% SERA REETIQUETAR EN LA PSICOFISICA.

eliminados = []; % Vector donde guardaremos los ID de las epocas eliminadas
cancelado = false; % si se cancela toda la revisión

fs = EEG.srate;
if secs == true
    t = (0:EEG.pnts-1)/fs;
else
    t = 1000*(0:EEG.pnts-1)/fs; % En mili - segundos es más intuitivo
end

for k = 1:numel(noisy_epochs)

    ep = noisy_epochs(k);

    % ----- GRAFICADO DE LA EPOCA SOSPECHOSA (UNICAMENTE) -----
    figure(100);
    clf;

    datos = squeeze(double(EEG.data(:,:,ep))); % SQUEEZE APACHURRA DIMENSIONES INNECESARIAS.

    % Es para configurar la separación vertical entre canales. Se grafican
    % TODOS
    escala = max(std(datos,0,2))*5;
    offsets = (0:EEG.nbchan-1)' * escala;

    plot(t, datos' + offsets');
    xlabel('Tiempo (s)');
    ylabel('Canales');
    title(sprintf( ...
        'Sujeto %s — época sospechosa %d (%d/%d)', ...
        sujeto, ep, k, numel(noisy_epochs)));

    xlim([t(1) t(end)]);
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

    EEG = pop_rejepoch(EEG,rej,0); % Dataset a eliminar, eliminados, mostrar confirmacion, 0 = no

    % % ----- Log -----
    % sujeto_col = repmat(string(sujeto),numel(eliminados),1);
    % 
    % T = table( ...
    %     sujeto_col, ...
    %     eliminados(:), ...
    %     'VariableNames',{'Sujeto','Epoca'});
    % 
    % logFile = fullfile('logs','epocas_eliminadas.csv');
    % 
    % if ~exist('logs','dir')
    %     mkdir('logs');
    % end
    % 
    % if isfile(logFile)
    %     writetable(T,logFile,'WriteMode','append');
    % else
    %     writetable(T,logFile);
    % end
end
% Sincronizacion. Con esto se confirma la modificacion, en principio.
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG,EEG,CURRENTSET);
end