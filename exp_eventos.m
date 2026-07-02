% Juntar con actividad o no? 
% Con el fin de mantener la segmentacion y claridad en el orden de los pasos 
% se mantienen las funciones de exportar eventos y actividades separadas 
function exp_eventos(nombreExt, srcDir)

    arguments
        nombreExt (1,:) char;
        srcDir (1,:) char;
    end
    % Directorio donde se exportarán  archivos de eventos
    outDir = fullfile('datos_exportados_m','eventos_exportados'); 
    
    % Crear la carpeta si no existe
    if ~exist(outDir,'dir')
        mkdir(outDir);
    end
    
    [~, nameNoExt] = fileparts(nombreExt); % Separa nombre y extension
    nameNoExt = replace(nameNoExt,'_rejected','_eventos'); %Reemplazamos la ultima parte para nombrar adecuadamente los archivos exportados
    outFile = fullfile(outDir,[nameNoExt,'.txt']); % Concatenamos vectores 
                                                   % de char con v3 = [v1,v2]
                                                   % (Las cadenas se ven
                                                   % como vectores en
                                                   % MATLAB)
    
    if isfile(outFile)
        fprintf('Archivo de %s ya procesado. Ignorando y pasando al siguiente \n',nameNoExt)
        return;
    end

    EEG = pop_loadset('filename', nombreExt, 'filepath', srcDir);
    % pop_expevents guarda el archivo como tal en la ruta indicada en el
    % segundo argumento (no es solo el nombre del archivo)

    % pop_expevents(EEG, outFile, 'seconds'); Yo estaba exportando en segundos
    pop_expevents(EEG, outFile); % Exportamos en samples por compatibilidad 
                                 % con Janue 
end