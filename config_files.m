function config_files()
    % Funcion que asocia eventos con la salida de un canal, se
    % cerciora de que exista el numero correcto de canales, en este caso 33,
    % carga el archivo de localizaciones de los electrodos y renombra los
    % eventos para que el indice de estos coincida con el esperado por el archivo
    % python. Elimina la parte ruidosa del incio del registro y exporta dos 
    % archivos, uno tipo set y otro dft con las modificaciones.
    
    % RUTAS Y ARCHIVOS. (PARA CORRER EL CICLO DESPUES)
    ruta_acanales = fullfile('locs_canales.ced'); 
    ruta_dataset = '/RawData/Samples'; % Ruta interna donde el hdf5 guarda datos
    outDir = fullfile('datos_exportados_m','dft_set_data'); % Donde se guardaran los .set

    % Crear la carpeta si no existe
    if ~exist(outDir,'dir')
        mkdir(outDir);
    end
    
    % CARGAR RUTAS DE ARCHIVOS
    dataDir = 'data';
    ruta_sarch = fullfile('data');
    filExt = '*.hdf5';
    files = dir(fullfile(dataDir,filExt));
    nof = numel(files); % Number of elements
    
    for j = 1:nof
        [~, nmbre, ~] = fileparts(files(j).name);
        narchivo_set = [nmbre,'_rejected','.set'];
    
        % Corrobora que el archivo no haya sido procesado con anterioridad
        if isfile(fullfile(outDir,narchivo_set))
            fprintf('Archivo de %s ya procesado. Ignorando y pasando al siguiente \n',nmbre)
            continue;
        end
    
        nmbreYext = [nmbre,'.hdf5']; % Esta sintaxis sirve para unir los char 
                                     % que bajo esta especificacion son
                                     % tratados como vectores. Es decir sirve
                                     % para unir(concatenar) vectores
        % INCIAR EEGLAB 
        [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
    
        %DEFINIR NUMERO DE CANALES
        ruta_carch = fullfile('data', nmbreYext);
        info = h5info(ruta_carch, ruta_dataset); 
        num_canales = info.ChunkSize(1);
    
        % CONDICIONAL PARA CARGAR LOS DATOS, EXTRAER EL CANAL DE EVENTOS (CANAL 33 O 36)
        % Y BORRAR EL RESTO
    
        % Carga de los datos
        EEG = pop_loadhdf5('filename',nmbreYext,'filepath',ruta_sarch); % Cargamos archivo
    
        if num_canales == 36
            fprintf('Detectado caso de 36 canales. Se conservan 32 de EEG y se toma canal 36 como eventos.\n');
            % CASO 36 CANALES: Cargamos datos de eventos del canal 36 y eliminamos
            % el canal del que se leen los valores
            EEG = pop_chanevent(EEG,36,'edge','leading','delevent','on','delchan','on');
            % Elminamos canales innecesarios, via etiquetas cargadas.
            EEG = pop_select(EEG, 'rmchannel', [33 34 35]);
    
        elseif num_canales == 33
            fprintf('Detectado caso de 33 canales. Se conservan 32 de EEG y se toma el canal 33 como eventos.\n');
            % CASO 33 CANALES:
            EEG = pop_chanevent(EEG,33,'edge','leading','delevent','on','delchan','on');
    
        else
            error('El archivo contiene %d canales. No coincide con los casos de 33 o 36 canales.', num_canales);
        end
    
        % Codigos que se transformaran en las etiquetas correctas
        codes = [1 3 5 9 17 33 65 129];
        % REETIQUETADOS DE LOS EVENTOS PARA QUE COINCIDAN CON LA ETIQUETA
        % ESPERADA
        for k = 1:length(EEG.event)
            val = EEG.event(k).type;
    
            % Devuelve un vector de indices lineales que cumple con la condicion del 
            % operador en este caso marca el indice donde codes guarda el mismo 
            % valor que val. Como solo hay un valor que coincide, devuelve un solo 
            % numero
            idx = find(codes == val); % idx == index
    
            if ~isempty(idx)
                EEG.event(k).type = idx;
            end
        end
    
        EEG = eeg_checkset(EEG, 'eventconsistency'); % Checamos consistencia
        [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 0, 'setname', nmbre, 'gui', 'off');
    
        % CARGA DE LOCALIZACIONES DE LOS ELECTRODOS 
        EEG = pop_editset(EEG,'chanlocs', ruta_acanales);
        fprintf('Carga de archivos de canales completada \n')
    
        % ELIMINACION DE LOS PRIMEROS SEGUNDOS DEL REGISTRO
        marca_evento = EEG.event(1).latency; % Da la latencia (tiempo) del primer 
                                             % evento, en unidades de muestras
        segundos = 2; % Cantidad de segundos que quedan antes del 1er evento
        puntos = segundos*EEG.srate; % Cantidad de puntos a conservar " "
        punto_corte = max(round(marca_evento/2),round(marca_evento-puntos)); % Toma el maximo entre la mitad del intervalo de tiempo transcurrido desde el inicio del registro y el intervalo completo menos dos segundos
        region_elim = [1,punto_corte];
        EEG = eeg_eegrej(EEG,region_elim);

        % CORTAMOS EL EVENTO BOUNDARY
        EEG.event(1) = [];
        EEG = eeg_checkset(EEG);
        fprintf('Primeros segundos del registro eliminados \n')
    
        % GUARDAMOS EL DATASET COMO SE INDICO.
    
        EEG = pop_saveset(EEG, 'filename', narchivo_set, 'filepath', outDir);
    end
end