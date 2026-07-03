% ***********************************
% 29/05/2024 por mera y sergi
% El siguiente script lo tienes que pegar en la terminal de MATLAB, lo único 
% que debes de cambiar, es el nombre del SUJETO al crear la variable "fileID".
% Vas a recibir un archivo csv en el directorio en el que estés, el cual vas a
% usar después en python. Observa que primero tienes que pegar una parte y 
% verificar si son correctos los datos, luego ya lo puedes exportar. 
% ***********************************
function exp_tiempos(nombreExt,srcDir,duracion_estudio)

    arguments
        nombreExt (1,:) char;
        srcDir (1,:) char;
        duracion_estudio double = 4000;
    end

    % Directorio donde se exportarán los eventos
    outDir = fullfile('datos_exportados_m/','tiempos_exportados');
    
    % Tiempo que duro  el estudio expresado en segundos
    % duracion_estudio = 4000;
    t = duracion_estudio; %renombre para facilitar lectura
    
    % Crear la carpeta si no existe
    if ~exist(outDir,'dir')
        mkdir(outDir);
    end
    
    [~, nameNoExt] = fileparts(nombreExt); % Separa nombre y extension
    nameNoExt = replace(nameNoExt,'_rejected',''); %Quitamos del nombre la palabra '_rejected'
    outFile = fullfile(outDir,['time_vector_corrected_',nameNoExt,'.csv']);

    if isfile(outFile)
        fprintf('Archivo de %s ya procesado. Ignorando y pasando al siguiente \n',nameNoExt)
        return;
    end

    EEG = pop_loadset('filename', nombreExt, 'filepath', srcDir);

    % Asegúrate de que en el EEG struct está cargado 'times'
    if isfield(EEG, 'times')
        time_vector = EEG.times;
    else
        error('El campo "times" no está presente en la estructura EEG.');
    end

    % Verificar el rango de tiempo original
    disp(['Tiempo inicial original: ', num2str(time_vector(1))]);
    disp(['Tiempo final original: ', num2str(time_vector(end))]);
    
    % A continuacion verificamos si el registro excede el valor del 
    % tiempo del estudio en segundos. Esto sería un indicativo de que el
    % tiempo se encuentra expresado en milisegundos. Es una implementacion
    % ingenua, si el valor en
    % segundos aun así es muy grande, podría llegar a corregirla. Pero por
    % la naturaleza de los datos en principio esto no sucedera.
    if max(abs(time_vector)) > t
        time_vector_corrected = time_vector / 1000;
    else
        time_vector_corrected = time_vector;
    end

    % Verificar el rango de tiempo corregido
    disp(['Tiempo inicial corregido: ', num2str(time_vector_corrected(1))]);
    disp(['Tiempo final corregido: ', num2str(time_vector_corrected(end))]);

    % ***********************************
    % AQUÍ tienes que verificar si los valores que suelta concuerdan con los que 
    % muestra la interfaz de EEGLAB, el "Tiempo inicial corregido" debe ser IGUAL
    % al "Epoch start (sec)" y el "Tiempo final corregido", tiene que ser igual 
    % al "Epoch end (sec)". Si son iguales, se va a exportar a un archivo CSV y 
    % redondear a 4 decimales para poder trabajarlo en python. 
    % ************************************

    % Redondear a 4 decimales
    time_vector_rounded = round(time_vector_corrected, 4);

    % Exportar manualmente a un archivo CSV
    
    writematrix(time_vector_rounded(:),outFile);
    % fprintf(fileID, '%.4f\n', time_vector_rounded);
    % fclose(fileID);

    % Verificar el archivo exportado
    disp(['Tiempo inicial: ', num2str(time_vector_rounded(1))]);
    disp(['Tiempo final: ', num2str(time_vector_rounded(end))]);
end