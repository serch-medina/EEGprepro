function [EEG, eliminados, cancelado] = ...
    revisar_epocas_ruidosas(EEG, noisy_events, sujeto) 
% CAMBIAR POR EL NOMBRE QUE ES DE LA FUNCION 
% TAMBIEN ACTUALIZAR EL
% PIPELINE. ASI ESTA PARA
% USAR LA OTRA FUNCIÓN Y PASARLE SU INFO QUE GENERE A ESTA

eliminados = []; % Vector donde guardaremos los ID de las epocas eliminadas
cancelado = false; % si se cancela toda la revisión

fs = EEG.srate;
t = (0:EEG.pnts-1)/fs; % Esto es para que grafique en segundos pero yo creo
                       % que deberíamos poder cambiarlo. O directamente 
                       % graficar en mumestras no segundos.

for k = 1:numel(noisy_events)

    ep = noisy_events(k);

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
        sujeto, ep, k, numel(noisy_events)));

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

    EEG = pop_rejepoch(EEG,rej,0);

    % ----- Log -----
    sujeto_col = repmat(string(sujeto),numel(eliminados),1);

    T = table( ...
        sujeto_col, ...
        eliminados(:), ...
        'VariableNames',{'Sujeto','Epoca'});

    logFile = fullfile('logs','epocas_eliminadas.csv');

    if ~exist('logs','dir')
        mkdir('logs');
    end

    if isfile(logFile)
        writetable(T,logFile,'WriteMode','append');
    else
        writetable(T,logFile);
    end
end
end