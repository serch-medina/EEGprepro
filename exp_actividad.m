function exp_actividad(nombreExt,srcDir)
    
% Espera nombre del sujeto para nombrar el archivo donde se exportara la
% actividad. Adicionalmente espera el directorio desde donde se recuperara 
% el archivo de la actividad a exportar

    arguments
        nombreExt (1,:) char;
        srcDir (1,:) char;
    end

    % Directorio donde se exportarán los eventos
    outDir = fullfile('datos_exportados_m','actividad_exportada'); 
    
    % Crear la carpeta si no existe
    if ~exist(outDir,'dir')
        mkdir(outDir);
    end

    [~, nameNoExt] = fileparts(nombreExt); % Separa nombre y extension
    nameNoExt = replace(nameNoExt,'_rejected','_actividad'); %Reemplazamos la ultima parte para nombrar adecuadamente los archivos exportados
    outFile = fullfile(outDir,[nameNoExt,'.txt']);

    if isfile(outFile)
        fprintf('Archivo de %s ya procesado. Ignorando y pasando al siguiente \n',nameNoExt)
        return;
    end

    EEG = pop_loadset('filename', nombreExt, 'filepath', srcDir);
    pop_export(EEG,outFile,'transpose','on','time','off','precision',4);
end